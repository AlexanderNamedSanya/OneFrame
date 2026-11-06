-- Run from the repository root with Lua 5.1+ (or Fengari).
local now, registrations, refreshes = 100, 0, 0
local timers, callbacks = {}, {}
OneFrame = { name = "OneFrame", active = true,
    sv = { hodor = true, dps = true, hps = true, ultimate = true },
    Frames = { UpdateStats = function() refreshes = refreshes + 1 end } }
function GetGameTimeMilliseconds() return now end
function GetGroupSize() return 2 end
function GetUnitName(tag) return tag == "player" and "Self" or "Ally" end
function GetUnitDisplayName(tag) return "@" .. GetUnitName(tag) end
function DoesUnitExist() return true end
function IsUnitGrouped() return true end
function IsUnitOnline() return true end
function AreUnitsEqual(a, b) return a == b end
EVENT_MANAGER = {
    RegisterForUpdate = function(_, name, _, fn) timers[name] = fn end,
    UnregisterForUpdate = function(_, name) timers[name] = nil end,
}
function ZO_PostHook(owner, key, fn)
    local original = owner[key]
    owner[key] = function(...) original(...); fn(...) end
end
local meta = {
    __index = function(t, k) return t._data[k] end,
    __newindex = function(t, k, v)
        t._lastUpdated = now
        if t._data[k] ~= v then t._lastChanged = now; t._data[k] = v end
    end,
}
local function observable(data)
    return setmetatable({ _data = data, _lastUpdated = 0, _lastChanged = 0 }, meta)
end
local ults = { player = observable({ultValue = 0}), group1 = observable({ultValue = 0}) }
local stats = { name = "Ally", displayName = "@Ally",
    dps = {dps = 87, dmgType = 1, _lastUpdated = now},
    hps = {hps = 42, _lastUpdated = now} }
local reader = {
    GetUnitStats = function() return stats end,
    GetUnitULT = function(_, tag) return ults[tag] end,
    RegisterForEvent = function(_, event, fn) callbacks[event] = fn end,
    UnregisterForEvent = function(_, event, fn)
        assert(callbacks[event] == fn); callbacks[event] = nil
    end,
}
LibGroupCombatStats = { version = "2026-10-04", DAMAGE_UNKNOWN = 0, DAMAGE_TOTAL = 1, DAMAGE_BOSS = 2,
    RegisterAddon = function(name, requested)
        registrations = registrations + 1
        assert(name == "OneFrame" and table.concat(requested, ",") == "DPS,HPS,ULT")
        return reader
    end,
}
for _, name in ipairs({"GROUP_DPS", "GROUP_HPS", "GROUP_ULT", "PLAYER_DPS", "PLAYER_HPS", "PLAYER_ULT"}) do
    LibGroupCombatStats["EVENT_" .. name .. "_UPDATE"] = name
end
dofile("OneFrame/Integrations/HodorReflexes.lua")
local H = OneFrame.SharedStats
H:Configure()
assert(H:IsAvailable() and registrations == 1 and HodorReflexes == nil)
local dps, hps = H:Values("group1")
assert(dps == 87000 and hps == 42000)
assert(H:Ultimate("group1") == nil, "default zero must not be shown")
ults.group1.ult1ID, ults.group1.ult1Cost = 123, 200
assert(H:Ultimate("group1") == nil, "type packet is not a points packet")
ults.group1.ultValue = 0
assert(H:Ultimate("group1")[1].points == 0, "received unchanged zero is valid")
ults.group1.ultValue = 250
assert(H:Ultimate("group1")[1].ready == true)
H:Configure()
assert(registrations == 1, "reconfigure must not duplicate broadcasting")
LibGroupCombatStats.version = "a future API-compatible version"
HodorReflexes = { internal = {}, modules = {} }
assert(H:IsAvailable(), "Hodor version and disabled modules must not affect LGCS")
now = now + 10001
stats.hps._lastUpdated = now
dps, hps = H:Values("group1")
assert(dps == nil and hps == 42000, "metrics expire independently")
assert(H:Ultimate("group1") == nil)
H:Reset(true)
assert(H:Values("group1") == nil)
assert(H:Ultimate("group1") == nil)
now = now + 1
stats.dps._lastUpdated, stats.hps._lastUpdated = now, now
stats.dps.dps = 0
dps, hps = H:Values("group1")
assert(dps == 0 and hps == 42000)
ults.group1.ultValue = 250
assert(H:Ultimate("group1")[1].points == 250, "points-only packet survives reset")
stats.displayName = "@SomeoneElse"
assert(H:Values("group1") == nil and H:Ultimate("group1") == nil, "reject reused unit identity")
stats.displayName = "@Ally"
OneFrame.active = false
H:Configure()
assert(not H:IsAvailable() and next(timers) == nil and next(callbacks) == nil)
OneFrame.active = true
H:Configure()
assert(H:IsAvailable() and registrations == 1)
LibGroupCombatStats = nil
H:Configure()
assert(not H:IsAvailable() and next(callbacks) == nil)
print("shared_stats: passed (direct library sharing, no Hodor, freshness, Ultimate receipts, identity, lifecycle)")
