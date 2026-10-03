-- Isolated regression tests: deliberately no external combat library.
local previous, oldClock, oldInCombat = OneFrame, GetFrameTimeMilliseconds, IsUnitInCombat
local time, inCombat = 0, true
GetFrameTimeMilliseconds = function() return time end
IsUnitInCombat = function() return inCombat end
OneFrame = {CombatStats = {started = 0}}
local A = OneFrame
load_module("Data/GroupCombat.lua")
local G = A.GroupCombat
function A.CombatStats:State(active)
    if active then G:Reset(); self.started, self.finished = time, nil end
end
local function hit(sourceType, targetType, amount, sourceId, targetId, result)
    G:Event(0, result or ACTION_RESULT_DAMAGE, false, "", 0, 0, "", sourceType, "", targetType, amount, 0, 0, 0, sourceId, targetId)
end
G:Configure(true)
hit(0, 0, 3000, 0, 100) -- unknown attacker/target is buffered
assert(G:Value() == nil)
time = 1000
hit(COMBAT_UNIT_TYPE_PLAYER, 0, 1000, 1, 100)
time = 3000
hit(COMBAT_UNIT_TYPE_PLAYER, 0, 1000, 1, 100)
assert(G:Value() == 2500) -- includes buffered anonymous damage
hit(0, COMBAT_UNIT_TYPE_GROUP, 9999, 100, 3) -- incoming not outgoing
assert(G:Value() == 2500)
hit(0, 0, 200, 0, 100, ACTION_RESULT_DAMAGE_SHIELDED)
assert(G:Value() == 2600)
hit(0, 0, 999999, 0, 100) -- same outlier guard as upstream
hit(0, 0, 1, 0, 100)
hit(0, 0, 200, 0, 0) -- invalid ID
assert(G:Value() == 2600)
hit(COMBAT_UNIT_TYPE_GROUP, COMBAT_UNIT_TYPE_GROUP, 100, 3, 100, ACTION_RESULT_HEAL)
assert(G:Value() == nil) -- a reclassified friendly cannot retain outgoing damage
G:Reset(); time = 4000
hit(COMBAT_UNIT_TYPE_GROUP, 0, 1000, 3, 100)
time = 6000; hit(0, 0, 3000, 0, 100)
assert(G:Value() == 2000) -- healer with no personal outgoing damage
G:Configure(false); hit(COMBAT_UNIT_TYPE_PLAYER, 0, 1000, 1, 100)
assert(G:Value() == nil and next(G.units) == nil)
G:Configure(true); assert(G:Value() == nil)
time = 7000; hit(COMBAT_UNIT_TYPE_PLAYER_PET, 0, 1000, 2, 100)
assert(G:Value() == 1000)
inCombat = false; A.CombatStats.finished = 7000
hit(0, 0, 1000, 0, 100, ACTION_RESULT_DOT_TICK)
assert(G:Value() == 1000) -- late DoT cannot restart a finished fight
G:Reset(); assert(G:Value() == nil)
OneFrame, GetFrameTimeMilliseconds, IsUnitInCombat = previous, oldClock, oldInCombat
print("PASS: built-in group DPS without LibCombat: classification, pending damage, incoming, shields, timing, reset and toggle")

local saved = OneFrame
load_module("Data/GroupCombat.lua")
local savedShared = OneFrame.SharedStats
OneFrame.SharedStats = {Configure = function() end}
load_module("Data/CombatStats.lua")
local c = OneFrame.CombatStats
OneFrame.active = true
OneFrame.sv.groupDps, OneFrame.sv.dps = true, true
c:Configure(); c.damage = 4321
OneFrame.sv.groupDps = false; c:Configure()
assert(not OneFrame.GroupCombat.enabled and c.damage == 4321)
OneFrame.sv.groupDps = true; c:Configure()
assert(OneFrame.GroupCombat.enabled and c.damage == 4321 and c:GroupDPS() == nil)
local oldLAM = LibAddonMenu2
local options
LibAddonMenu2 = {
    RegisterAddonPanel = function() return {} end,
    RegisterOptionControls = function(_, _, list) options = list end,
}
OneFrame.defaults = OneFrame:MakeDefaults()
load_module("Settings/Settings.lua")
OneFrame.Settings:Initialize()
local option
for _, item in ipairs(options) do
    if item.type == "checkbox" and item.name == GetString(ONEFRAME_GROUP_DPS) then option = item end
end
assert(option and option.default == true and option.getFunc() == true)
local oldApply = OneFrame.ApplySettings
OneFrame.ApplySettings = function() c:Configure() end
option.setFunc(false)
assert(not OneFrame.sv.groupDps and not OneFrame.GroupCombat.enabled and c.damage == 4321)
OneFrame.ApplySettings, OneFrame.SharedStats, LibAddonMenu2 = oldApply, savedShared, oldLAM
print("PASS: General checkbox toggles collection without resetting personal statistics")
