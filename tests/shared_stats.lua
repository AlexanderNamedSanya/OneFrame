-- Provider-boundary tests. Values/units reflect the supplied 2026-07-26 source,
-- including absent timestamps on the event payload and silent unchanged packets.
local A = GroupFramePlus
local count = 0
local function eq(a, b) assert(a == b, tostring(a) .. " ~= " .. tostring(b)) end
local function test(name, fn) fn(); count = count + 1; print("PASS: " .. name) end
local now = 20000
function GetGameTimeMilliseconds() return now end
local roster = {
    player = { account = "@me", character = "Me" },
    group1 = { account = "@me", character = "Me" },
    group2 = { account = "@alice", character = "Alice" },
}
function DoesUnitExist(tag) return roster[tag] ~= nil end
function IsUnitGrouped(tag) return DoesUnitExist(tag) end
function IsUnitOnline(tag) return DoesUnitExist(tag) and not roster[tag].offline end
function GetUnitName(tag) return roster[tag] and roster[tag].character or "" end
function GetUnitDisplayName(tag) return roster[tag] and roster[tag].account or "" end
function GetGroupMemberSelectedRole(tag) return roster[tag] and roster[tag].role or LFG_ROLE_DPS end
function AreUnitsEqual(tag, other) return tag == other or ((tag == "group1" or tag == "player") and other == "player") end

local callbacks, hrCallbacks, data, registrations, requested, notifications
local function makeProvider()
    callbacks, hrCallbacks, data, registrations, notifications = {}, {}, {}, 0, 0
    local object = {}
    function object:GetUnitStats(tag) return data[GetUnitName(tag)] end
    function object:RegisterForEvent(event, callback) callbacks[event] = callback end
    function object:UnregisterForEvent(event, callback) if callbacks[event] == callback then callbacks[event] = nil end end
    LibGroupCombatStats = {
        version = "2026-07-26", DAMAGE_UNKNOWN = 0, DAMAGE_TOTAL = 1, DAMAGE_BOSS = 2,
        RegisterAddon = function(name, stats)
            registrations = registrations + 1; requested = stats
            assert(registrations == 1, "duplicate provider registration")
            return object
        end,
    }
    for _, name in ipairs({ "EVENT_GROUP_DPS_UPDATE", "EVENT_GROUP_HPS_UPDATE", "EVENT_PLAYER_DPS_UPDATE", "EVENT_PLAYER_HPS_UPDATE" }) do
        LibGroupCombatStats[name] = name
    end
    HodorReflexes = {
        version = "2026-05-17", modules = {
            dps = { IsEnabled = function() return true end }, hps = { IsEnabled = function() return true end },
        },
        RegisterCallback = function(event, callback) hrCallbacks[event] = callback end,
        UnregisterCallback = function(event, callback) if hrCallbacks[event] == callback then hrCallbacks[event] = nil end end,
    }
    for _, name in ipairs({ "HR_EVENT_COMBAT_START", "HR_EVENT_COMBAT_END", "HR_EVENT_PLAYER_ACTIVATED",
        "HR_EVENT_GROUP_CHANGED", "HR_EVENT_TEST_STARTED", "HR_EVENT_TEST_STOPPED" }) do HodorReflexes[name] = name end
    A.Frames.UpdateStats = function() notifications = notifications + 1 end
    return object
end
local function fresh(tag, dps, hps, stamp)
    stamp = stamp or now
    data[GetUnitName(tag)] = {
        name = GetUnitName(tag), displayName = GetUnitDisplayName(tag),
        dps = { dps = dps, dmg = 123, dmgType = 1, _lastUpdated = stamp, _lastChanged = stamp },
        hps = { hps = hps, overheal = 234, _lastUpdated = stamp, _lastChanged = stamp },
    }
    return data[GetUnitName(tag)]
end
local function reload()
    if A.SharedStats then A.SharedStats:Disconnect() end
    load_module("Integrations/HodorReflexes.lua")
    A.active, A.sv.hodor, A.sv.dps, A.sv.hps = true, true, true, true
    return A.SharedStats
end
local H = reload()
test("missing/partially initialized/incompatible providers fail closed", function()
    HodorReflexes, LibGroupCombatStats = nil, nil
    H:Configure(); eq(H:IsAvailable(), false); eq(H:Values("group2"), nil)
    makeProvider(); HodorReflexes.internal = {}; H:Configure(); eq(registrations, 0)
    HodorReflexes.internal = nil; LibGroupCombatStats.version = "other"; H:Configure(); eq(registrations, 0)
    LibGroupCombatStats.version = "2026-07-26"; LibGroupCombatStats.DAMAGE_TOTAL = nil
    H:Configure(); eq(registrations, 0)
end)
local reader
test("receive-only registration, no broadcasting request; encoded units converted correctly", function()
    H = reload(); reader = makeProvider(); H:Configure(); eq(H:IsAvailable(), true)
    eq(registrations, 1); eq(next(requested), nil)
    fresh("group2", 87, 24)
    local d, h = H:Values("group2"); eq(d, 87000); eq(h, 24000)
    data.Alice.dps.dmgType = 2; data.Alice.dps.dmg = 1234
    eq(H:Values("group2"), 87000) -- Total DPS, not boss DPS in the separate dmg field.
end)
test("default zero is unavailable, explicit received zero valid, metrics age independently", function()
    fresh("group2", 0, 0, 0); local d, h = H:Values("group2"); eq(d, nil); eq(h, nil)
    fresh("group2", 0, 0); d, h = H:Values("group2"); eq(d, 0); eq(h, 0)
    data.Alice.hps._lastUpdated = now - 10001; d, h = H:Values("group2"); eq(d, 0); eq(h, nil)
    data.Alice.dps.dps = 0/0; eq(H:Values("group2"), nil)
    data.Alice.dps.dps = math.huge; eq(H:Values("group2"), nil)
    fresh("group2", 87, 24, now + 1); eq(H:Values("group2"), nil)
end)
test("current account and character matching defeats stale tag callbacks and recycled frames", function()
    fresh("group2", 87, 24)
    roster.group2 = { account = "@bob", character = "Bob" }
    callbacks.EVENT_GROUP_DPS_UPDATE("group2", { dps = 999 })
    eq(H:Values("group2"), nil)
    data.Bob = data.Alice; eq(H:Values("group2"), nil)
    fresh("group2", 42, 7); eq(H:Values("group2"), 42000)
    roster.group2.account = "@other"; eq(H:Values("group2"), nil)
    roster.group2 = { account = "@alice", character = "Alice" }
end)
test("combat start/group/zone resets reject previous records; zero after reset accepted", function()
    fresh("group2", 87, 24); hrCallbacks.HR_EVENT_COMBAT_START(); eq(H:Values("group2"), nil)
    now = now + 1; fresh("group2", 0, 0); eq(H:Values("group2"), 0)
    hrCallbacks.HR_EVENT_GROUP_CHANGED(); eq(H:Values("group2"), nil)
    now = now + 1; fresh("group2", 12, 8); eq(H:Values("group2"), 12000)
    hrCallbacks.HR_EVENT_PLAYER_ACTIVATED(); eq(H:Values("group2"), nil)
end)
test("expiry works without callbacks and unchanged zero packets become visible via sweep", function()
    now = now + 1; fresh("group2", 0, 0)
    local before = notifications
    EVENT_MANAGER.updates[A.name .. "SharedExpiry"](); eq(notifications, before + 1)
    eq(H:Values("group2"), 0)
    now = now + 10001; eq(H:Values("group2"), nil)
    data.Alice.dps._lastUpdated = now; eq(H:Values("group2"), 0)
end)
test("confirmed end caps local shared lifetime, but fresh remote packets remain usable", function()
    hrCallbacks.HR_EVENT_COMBAT_END(false); eq(H.ended, nil)
    hrCallbacks.HR_EVENT_COMBAT_END(true); now = now + 10001
    fresh("group1", 50, 10); eq(H:Values("group1"), nil)
    fresh("group2", 50, 10); eq(H:Values("group2"), 50000)
    hrCallbacks.HR_EVENT_COMBAT_START(); now = now + 1; fresh("group2", 50, 10)
    eq(H:Values("group2"), 50000)
end)
test("disabled module, Hodor test mode and disconnected player yield unavailable", function()
    HodorReflexes.modules.dps.IsEnabled = function() return false end
    local d, h = H:Values("group2"); eq(d, nil); eq(h, 10000)
    HodorReflexes.modules.dps.IsEnabled = function() return true end
    HodorReflexes.modules.hps.isTestRunning = true
    d, h = H:Values("group2"); eq(d, 50000); eq(h, nil)
    HodorReflexes.modules.hps.isTestRunning = false
    roster.group2.offline = true; eq(H:Values("group2"), nil); roster.group2.offline = nil
end)
test("toggle unregisters callbacks/timers; reader reused and stale data not revived", function()
    H:Reset(); A.sv.hodor = false; H:Configure()
    eq(next(callbacks), nil); eq(next(hrCallbacks), nil)
    eq(EVENT_MANAGER.updates[A.name .. "SharedExpiry"], nil)
    A.sv.hodor = true; H:Configure(); eq(registrations, 1); eq(H:Values("group2"), nil)
end)
test("local preference is per metric, shared zero never replaced by fallback", function()
    now = now + 1; fresh("group1", 99, 0)
    local C = A.CombatStats
    C.started, C.finished, C.damage, C.healing = 1, 1001, 500, 250
    local d, h = C:Values("group1"); eq(d, 99000); eq(h, 0)
    data.Me.hps._lastUpdated = 0; d, h = C:Values("group1"); eq(d, 99000); eq(h, 250)
    A.sv.hodor = false; d, h = C:Values("group1"); eq(d, 500); eq(h, 250)
    eq(C:Values("group2"), nil); A.sv.hodor = true
    C.started = nil; data.Me.dps._lastUpdated = 0; d, h = C:Values("group1"); eq(d, nil); eq(h, nil)
end)
test("periodic local timestamp writes cannot resurrect an old encounter", function()
    fresh("group1", 99, 20); H:Reset(); now = now + 100
    data.Me.dps._lastUpdated = now; eq(H:Values("group1"), nil)
end)
test("provider exceptions disable only integration and clean callback registrations", function()
    reader.GetUnitStats = function() error("provider broke") end
    eq(H:Values("group2"), nil); eq(H:IsAvailable(), false); eq(next(callbacks), nil)
    eq(A.active, true)
end)
test("numeric formatting and Russian label contract", function()
    load_module("UI/Ultimate.lua")
    load_module("UI/PlayerInfo.lua")
    local P = A.PlayerInfo
    eq(P:Format(nil), "—"); eq(P:Format(0), "0"); eq(P:Format(985), "985")
    eq(P:Format(12400), "12.4k"); eq(P:Format(87200), "87.2k"); eq(P:Format(1240000), "1.24m")
    function GetCVar() return "ru" end
    load_module("Lang/ru.lua"); eq(A:T("dpsLabel"), "ДПС"); eq(A:T("hpsLabel"), "ХПС")
    eq(P:Format(1240000), "1.24m")
end)
test("registration failures and missing reader methods cannot break addon", function()
    H = reload(); makeProvider(); LibGroupCombatStats.RegisterAddon = function() error("uninitialized") end
    H:Configure(); eq(H:IsAvailable(), false); eq(A.active, true)
    H = reload(); makeProvider(); LibGroupCombatStats.RegisterAddon = function() return {} end
    H:Configure(); eq(H:IsAvailable(), false)
end)
test("native name refresh replaces reused frame statistics before deferred layout", function()
    H = reload(); makeProvider(); H:Configure()
    now = now + 1; fresh("group2", 87, 24)
    load_module("UI/VanillaFrames.lua")
    function IsUnitDead() return false end
    local text = {}
    local frame = { unitTag = "group2", style = "ZO_GroupUnitFrame" }
    local label = { SetText = function(_, value) text.value = value end, SetHidden = function() end }
    A.Frames.cache[frame] = { stats = label }
    ZO_UnitFrameObject = {}
    for _, method in ipairs({ "SetAnchor", "ApplyVisualStyle", "UpdateName", "UpdateLevel", "UpdateStatus", "UpdateAssignment", "DoAlphaUpdate" }) do
        ZO_UnitFrameObject[method] = function() end
    end
    function ZO_UnitFrames_UpdateWindow() end
    A.QueueRefresh = function() end
    A.Frames:Initialize()
    ZO_UnitFrameObject.UpdateName(frame); assert(text.value:find("87.0k", 1, true))
    roster.group2 = { account = "@replacement", character = "Replacement" }
    ZO_UnitFrameObject.UpdateName(frame); assert(not text.value:find("87.0k", 1, true))
    fresh("group2", 42, 3); ZO_UnitFrameObject.UpdateName(frame)
    assert(text.value:find("42.0k", 1, true))
end)
print("PASS: " .. count .. " shared-statistics tests")
