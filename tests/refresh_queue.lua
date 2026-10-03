local previous = OneFrame
local resets, configurations, layouts, stats = 0, 0, 0, 0
OneFrame = {
    name = "OneFrameQueueTest",
    CombatStats = {
        ResetShared = function() resets = resets + 1 end,
        Configure = function() configurations = configurations + 1 end,
    },
    Frames = {
        Refresh = function() layouts = layouts + 1 end,
        UpdateStats = function() stats = stats + 1 end,
    },
}
local oldLoaded = EVENT_ADD_ON_LOADED
EVENT_ADD_ON_LOADED = EVENT_ADD_ON_LOADED or 99999
load_module("Core.lua")
local A = OneFrame
for i = 1, 48 do A:QueueRosterRefresh(); A:QueueStatsRefresh() end
assert(resets == 1 and configurations == 0 and layouts == 0 and stats == 0)
EVENT_MANAGER.updates[A.name .. "Refresh"]()
assert(configurations == 1 and layouts == 1 and not A.rosterDirty)
for i = 1, 48 do A:QueueStatsRefresh() end
EVENT_MANAGER.updates[A.name .. "StatsRefresh"]()
assert(stats == 1)
A:QueueStatsRefresh(); A:QueueRosterRefresh()
EVENT_MANAGER.updates[A.name .. "Refresh"]()
assert(stats == 1 and layouts == 2 and configurations == 2 and resets == 2)
assert(EVENT_MANAGER.updates[A.name .. "StatsRefresh"] == nil)
A:QueueRosterRefresh(); A:QueueRefresh(false)
EVENT_MANAGER.updates[A.name .. "Refresh"]()
assert(resets == 3 and configurations == 3 and layouts == 3)
EVENT_MANAGER:UnregisterForEvent(A.name, EVENT_ADD_ON_LOADED)
EVENT_ADD_ON_LOADED = oldLoaded
OneFrame = previous
print("PASS: roster bursts configure once; health bursts update once; layout absorbs queued stats")
