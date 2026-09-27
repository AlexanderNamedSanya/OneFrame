local A = GroupFramePlus
local H = { maxAge = 10000, cutoff = 0, subscriptions = {} }
A.SharedStats = H

-- Source-verified pair: Hodor 2026-05-17 + LGCS 2026-07-26.
-- LGCS's actual encoder (not its outdated README) stores both rates in thousands.
-- No access to playersData: its merged lastUpdate cannot establish per-metric freshness.
local function finite(value)
    return type(value) == "number" and value == value and value >= 0 and value < math.huge
end
function H:Compatible()
    local hr, lib = HodorReflexes, LibGroupCombatStats
    if type(hr) ~= "table" or hr.version ~= "2026-05-17" or hr.internal ~= nil
        or type(hr.modules) ~= "table" or type(hr.RegisterCallback) ~= "function"
        or type(hr.UnregisterCallback) ~= "function" then return false end
    if type(lib) ~= "table" or lib.version ~= "2026-07-26"
        or type(lib.RegisterAddon) ~= "function" then return false end
    if lib.DAMAGE_UNKNOWN ~= 0 or lib.DAMAGE_TOTAL ~= 1 or lib.DAMAGE_BOSS ~= 2 then return false end
    for _, name in ipairs({ "EVENT_GROUP_DPS_UPDATE", "EVENT_GROUP_HPS_UPDATE",
        "EVENT_PLAYER_DPS_UPDATE", "EVENT_PLAYER_HPS_UPDATE" }) do
        if type(lib[name]) ~= "string" then return false end
    end
    for _, name in ipairs({ "HR_EVENT_COMBAT_START", "HR_EVENT_COMBAT_END",
        "HR_EVENT_PLAYER_ACTIVATED", "HR_EVENT_GROUP_CHANGED",
        "HR_EVENT_TEST_STARTED", "HR_EVENT_TEST_STOPPED" }) do
        if type(hr[name]) ~= "string" then return false end
    end
    return true
end
function H:IsAvailable()
    return self.connected == true and not self.failed and self:Compatible()
        and self.hodor == HodorReflexes and self.library == LibGroupCombatStats
end
function H:Notify()
    if self.pending or not self.connected then return end
    self.pending = true
    EVENT_MANAGER:RegisterForUpdate(A.name .. "SharedRefresh", 50, function()
        EVENT_MANAGER:UnregisterForUpdate(A.name .. "SharedRefresh")
        self.pending = false
        if A.Frames then A.Frames:UpdateStats() end
    end)
end
function H:Reset()
    -- Equality is rejected too: data written in the same millisecond may precede reset.
    self.cutoff = GetGameTimeMilliseconds()
    self.ended = nil
    self:Notify()
end
function H:Disconnect()
    self.connected = false
    for _, item in ipairs(self.subscriptions) do
        if item.kind == "library" then
            pcall(item.owner.UnregisterForEvent, item.owner, item.event, item.callback)
        else
            pcall(item.owner.UnregisterCallback, item.event, item.callback)
        end
    end
    self.subscriptions = {}
    EVENT_MANAGER:UnregisterForUpdate(A.name .. "SharedExpiry")
    EVENT_MANAGER:UnregisterForUpdate(A.name .. "SharedRefresh")
    self.pending = false
end
function H:Subscribe(owner, kind, event, callback)
    -- Keep cleanup metadata before registration, including a partially failing provider.
    self.subscriptions[#self.subscriptions + 1] = { owner = owner, kind = kind, event = event, callback = callback }
    if kind == "library" then return pcall(owner.RegisterForEvent, owner, event, callback) end
    return pcall(owner.RegisterCallback, event, callback)
end
function H:Configure()
    local wanted = A.active and A.sv.hodor and (A.sv.dps or A.sv.hps) and GetGroupSize() > 0
    if not wanted or not self:Compatible() then self:Disconnect(); return end
    if self:IsAvailable() then return end
    self:Disconnect()
    if self.failed then return end
    local hr, lib = HodorReflexes, LibGroupCombatStats
    -- RegisterAddon is once-only and has no unregister-addon counterpart. Reuse its
    -- lightweight getter object across toggles, but remove every callback/timer on disable.
    if self.library ~= lib then
        local ok, object = pcall(lib.RegisterAddon, A.name .. "HodorReader", {})
        if not ok or type(object) ~= "table" then self.failed = true; return end
        self.reader, self.library = object, lib
    end
    local reader = self.reader
    for _, method in ipairs({ "GetUnitStats", "RegisterForEvent", "UnregisterForEvent" }) do
        if type(reader[method]) ~= "function" then self.failed = true; return end
    end
    self.hodor, self.connected = hr, true
    -- Existing packets can be used on first enable, provided they are still fresh.
    -- Explicit combat/zone/roster resets retain a stricter cutoff across toggles.
    local function subscribe(owner, kind, event, fn)
        if not self:Subscribe(owner, kind, event, fn) then self.failed = true end
    end
    for _, name in ipairs({ "EVENT_GROUP_DPS_UPDATE", "EVENT_GROUP_HPS_UPDATE",
        "EVENT_PLAYER_DPS_UPDATE", "EVENT_PLAYER_HPS_UPDATE" }) do
        -- Callback payloads are deliberately ignored: callbacks can carry an old tag
        -- during LGCS's delayed group remapping. Resolve identity through the getter.
        subscribe(reader, "library", lib[name], function() self:Notify() end)
    end
    for _, name in ipairs({ "HR_EVENT_COMBAT_START", "HR_EVENT_PLAYER_ACTIVATED",
        "HR_EVENT_GROUP_CHANGED", "HR_EVENT_TEST_STARTED", "HR_EVENT_TEST_STOPPED" }) do
        subscribe(hr, "hodor", hr[name], function() self:Reset() end)
    end
    subscribe(hr, "hodor", hr.HR_EVENT_COMBAT_END, function(confirmed)
        if confirmed then self.ended = GetGameTimeMilliseconds(); self:Notify() end
    end)
    if self.failed then self:Disconnect(); return end
    -- LGCS updates _lastUpdated without callbacks when packets repeat unchanged values
    -- (including explicit zero). This bounded sweep also expires data without new packets.
    EVENT_MANAGER:RegisterForUpdate(A.name .. "SharedExpiry", 1000, function()
        if not self:IsAvailable() then self:Disconnect() end
        if A.Frames then A.Frames:UpdateStats() end
    end)
    self:Notify()
end
function H:MetricEnabled(kind)
    local module = self.hodor.modules[kind]
    if type(module) ~= "table" or type(module.IsEnabled) ~= "function" or module.isTestRunning then return false end
    local ok, enabled = pcall(module.IsEnabled, module)
    return ok and enabled == true
end
function H:Value(stats, kind, now, localPlayer)
    if not self:MetricEnabled(kind) then return nil end
    local metric = stats[kind]
    if type(metric) ~= "table" or not finite(metric[kind]) or not finite(metric._lastUpdated)
        or metric._lastUpdated <= self.cutoff or metric._lastUpdated <= 0
        or metric._lastUpdated > now or now - metric._lastUpdated > self.maxAge then return nil end
    -- LGCS periodically rewrites local values even while idle. Those writes alone
    -- must not resurrect the previous encounter's rates after our reset/expiry.
    if localPlayer and (not finite(metric._lastChanged) or metric._lastChanged <= self.cutoff
        or metric._lastChanged > now or now - metric._lastChanged > self.maxAge) then return nil end
    if kind == "dps" and metric.dmgType ~= self.library.DAMAGE_TOTAL
        and metric.dmgType ~= self.library.DAMAGE_BOSS
        and not (metric.dmgType == self.library.DAMAGE_UNKNOWN and metric.dps == 0) then return nil end
    return metric[kind] * 1000
end
function H:Values(tag)
    if not A.active or not A.sv.hodor or not self:IsAvailable()
        or not DoesUnitExist(tag) or not IsUnitGrouped(tag) or not IsUnitOnline(tag) then return nil, nil end
    local now = GetGameTimeMilliseconds()
    local localPlayer = AreUnitsEqual(tag, "player")
    if localPlayer and self.ended and now - self.ended > self.maxAge then return nil, nil end
    local ok, stats = pcall(self.reader.GetUnitStats, self.reader, tag)
    if not ok then self.failed = true; self:Disconnect(); return nil, nil end
    local account, character = GetUnitDisplayName(tag), GetUnitName(tag)
    if type(account) ~= "string" or account == "" or type(character) ~= "string" or character == ""
        or type(stats) ~= "table" or stats.displayName ~= account or stats.name ~= character then return nil, nil end
    -- No frame-index cache. Match BOTH account and character for the current unitTag.
    return self:Value(stats, "dps", now, localPlayer), self:Value(stats, "hps", now, localPlayer)
end
