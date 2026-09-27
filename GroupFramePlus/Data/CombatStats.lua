local A = GroupFramePlus
local C = { damage = 0, healing = 0 }
A.CombatStats = C
local damageResults = {
    [ACTION_RESULT_DAMAGE] = true, [ACTION_RESULT_CRITICAL_DAMAGE] = true,
    [ACTION_RESULT_DOT_TICK] = true, [ACTION_RESULT_DOT_TICK_CRITICAL] = true,
    [ACTION_RESULT_BLOCKED_DAMAGE] = true,
}
local healResults = {
    [ACTION_RESULT_HEAL] = true, [ACTION_RESULT_CRITICAL_HEAL] = true,
    [ACTION_RESULT_HOT_TICK] = true, [ACTION_RESULT_HOT_TICK_CRITICAL] = true,
}
function C:Reset()
    self.damage, self.healing, self.started, self.finished = 0, 0, nil, nil
end
function C:State(inCombat)
    if inCombat then
        if not self.started or self.finished then
            self:Reset()
            self.started = GetFrameTimeMilliseconds()
        end
    elseif self.started and not self.finished then
        self.finished = GetFrameTimeMilliseconds()
    end
    self:Timer(inCombat)
end
function C:Timer(active)
    EVENT_MANAGER:UnregisterForUpdate(A.name .. "Stats")
    if active and self.listening then
        EVENT_MANAGER:RegisterForUpdate(A.name .. "Stats", 500, function() A.Frames:UpdateStats() end)
    end
    if A.Frames then A.Frames:UpdateStats() end
end
function C:Event(_, result, isError, _, _, _, _, sourceType, _, _, hitValue)
    -- Never map sourceName/sourceUnitId to a remote group member: that stream is incomplete.
    if isError or sourceType ~= COMBAT_UNIT_TYPE_PLAYER or not hitValue or hitValue <= 0 then return end
    local kind = damageResults[result] and "damage" or (healResults[result] and "healing")
    if not kind then return end
    -- The first attack can arrive before EVENT_PLAYER_COMBAT_STATE.
    if (not self.started or self.finished) and (kind == "damage" or IsUnitInCombat("player")) then
        self:State(true)
    end
    if self.started and not self.finished then self[kind] = self[kind] + hitValue end
end
function C:Values(tag)
    local dps, hps = A.SharedStats:Values(tag)
    if not AreUnitsEqual(tag, "player") then return dps, hps end
    if not self.started then return dps, hps end
    local seconds = math.max(1, ((self.finished or GetFrameTimeMilliseconds()) - self.started) / 1000)
    return dps ~= nil and dps or self.damage / seconds, hps ~= nil and hps or self.healing / seconds
end
function C:Configure()
    A.SharedStats:Configure()
    local wanted = A.active and (A.sv.dps or A.sv.hps)
    if wanted == self.listening then return end
    self.listening = wanted
    self:Reset()
    local ns = A.name .. "Combat"
    EVENT_MANAGER:UnregisterForEvent(ns, EVENT_COMBAT_EVENT)
    EVENT_MANAGER:UnregisterForEvent(ns, EVENT_PLAYER_COMBAT_STATE)
    if wanted then
        EVENT_MANAGER:RegisterForEvent(ns, EVENT_COMBAT_EVENT, function(...) self:Event(...) end)
        EVENT_MANAGER:AddFilterForEvent(ns, EVENT_COMBAT_EVENT, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
        EVENT_MANAGER:RegisterForEvent(ns, EVENT_PLAYER_COMBAT_STATE, function(_, combat) self:State(combat) end)
        self:State(IsUnitInCombat("player"))
    else
        self:Timer(false)
    end
end
function C:ResetShared()
    A.SharedStats:Reset(true)
end
function C:Ultimate(tag)
    return A.SharedStats:Ultimate(tag)
end
