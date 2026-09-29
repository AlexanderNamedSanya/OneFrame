local tests = 0
local function test(name, fn)
    fn(); tests = tests + 1; print("PASS: " .. name)
end
local function eq(a, b) assert(a == b, tostring(a) .. " ~= " .. tostring(b)) end
LFG_ROLE_TANK, LFG_ROLE_HEAL, LFG_ROLE_DPS = 1, 2, 3
COMBAT_MECHANIC_FLAGS_HEALTH, COMBAT_MECHANIC_FLAGS_MAGICKA, COMBAT_MECHANIC_FLAGS_STAMINA = 1, 2, 4
COMBAT_UNIT_TYPE_PLAYER = 1
COMBAT_UNIT_TYPE_GROUP = 3
ACTION_RESULT_DAMAGE, ACTION_RESULT_CRITICAL_DAMAGE, ACTION_RESULT_DOT_TICK, ACTION_RESULT_DOT_TICK_CRITICAL = 1, 2, 3, 4
ACTION_RESULT_BLOCKED_DAMAGE, ACTION_RESULT_HEAL, ACTION_RESULT_CRITICAL_HEAL = 5, 6, 7
ACTION_RESULT_HOT_TICK, ACTION_RESULT_HOT_TICK_CRITICAL = 8, 9
EVENT_COMBAT_EVENT, EVENT_PLAYER_COMBAT_STATE, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE = 10, 11, 12
ATTRIBUTE_HEALTH = 1
TOPLEFT, MOUSE_BUTTON_INDEX_RIGHT, MOUSE_CONTENT_EMPTY, CHAT_CHANNEL_WHISPER = 1, 2, 0, 3
local now, combat = 0, false
function GetFrameTimeMilliseconds() return now end
function IsUnitInCombat() return combat end
function GetCVar() return "en" end
local roster = {
    group1 = { account = "@self", character = "Self", role = LFG_ROLE_DPS },
    group2 = { account = "@alice", character = "Alice", role = LFG_ROLE_TANK },
    group3 = { account = "@bob", character = "Bob", role = LFG_ROLE_HEAL },
}
function DoesUnitExist(tag) return roster[tag] ~= nil end
function GetUnitDisplayName(tag) return roster[tag].account end
function GetRawUnitName(tag) return roster[tag].character end
function GetUnitName(tag) return roster[tag].character end
function IsUnitOnline(tag) return roster[tag] ~= nil end
function GetGroupMemberSelectedRole(tag) return roster[tag].role end
function GetGroupSize() return 3 end
function GetGroupUnitTagByIndex(i) if roster["group" .. i] then return "group" .. i end end
function AreUnitsEqual(tag, other) return tag == other or (other == "player" and tag == "group1") end
ZO_ColorDef = {}
function ZO_ColorDef:New(r, g, b, a)
    return { rgba = { r, g, b, a or 1 }, UnpackRGBA = function(self) return unpack(self.rgba) end }
end
ZO_POWER_BAR_GRADIENT_COLORS = {}
for _, id in ipairs({ 1, 2, 4 }) do
    ZO_POWER_BAR_GRADIENT_COLORS[id] = { ZO_ColorDef:New(id / 10, 0, 0), ZO_ColorDef:New(0, id / 10, 0) }
end
EVENT_MANAGER = { events = {}, updates = {} }
function EVENT_MANAGER:RegisterForEvent(ns, event, fn) self.events[ns .. event] = fn end
function EVENT_MANAGER:UnregisterForEvent(ns, event) self.events[ns .. event] = nil end
function EVENT_MANAGER:AddFilterForEvent(...) end
function EVENT_MANAGER:RegisterForUpdate(ns, interval, fn) self.updates[ns] = fn end
function EVENT_MANAGER:UnregisterForUpdate(ns) self.updates[ns] = nil end
function ZO_PostHook(object, name, fn)
    if type(object) == "string" then object, name, fn = _G, object, name end
    local old = assert(object[name], name)
    object[name] = function(...) local result = { old(...) }; fn(...); return unpack(result) end
end
function ZO_PreHookHandler(control, name, fn)
    local old = control.handlers[name]
    control.handlers[name] = function(...) if not fn(...) and old then return old(...) end end
end
function ZO_PostHookHandler(control, name, fn)
    local old = control.handlers[name]
    control.handlers[name] = function(...) if old then old(...) end; fn(...) end
end
local nativeStrings, nextId = {}, 100000
function ZO_CreateStringId(name, value) _G[name] = nextId; nativeStrings[nextId] = value; nextId = nextId + 1 end
function SafeAddString(id, value) assert(id); nativeStrings[id] = value end
function GetString(id) return assert(nativeStrings[id], tostring(id)) end
load_module("Namespace.lua"); load_module("Lang/en.lua"); load_module("Defaults.lua")
load_module("Data/GroupData.lua"); load_module("Integrations/HodorReflexes.lua"); load_module("Data/CombatStats.lua"); load_module("Data/RoleSorting.lua")
load_module("UI/Interaction.lua"); load_module("UI/ShieldOverlay.lua")
local A = GroupFramePlus
A.sv, A.active = A:MakeDefaults(), true
A.Frames = { cache = {}, UpdateStats = function() end }

test("resource defaults and unknown-role fallback", function()
    eq(A:RoleGradient("group2"), ZO_POWER_BAR_GRADIENT_COLORS[1])
    eq(A:RoleGradient("group3"), ZO_POWER_BAR_GRADIENT_COLORS[2])
    eq(A:RoleGradient("group1"), ZO_POWER_BAR_GRADIENT_COLORS[4])
    roster.group2.role = 0; eq(A:RoleGradient("group2"), ZO_POWER_BAR_GRADIENT_COLORS[1]); roster.group2.role = 1
end)
local C = A.CombatStats
local function hit(result, source, amount) C:Event(0, result, false, "", 0, 0, "", source, "", 0, amount) end
test("local damage/healing only, elapsed time and remote unavailable", function()
    A.sv.dps = true; C:Configure(); combat = true; now = 1000; C:State(true)
    hit(ACTION_RESULT_DAMAGE, 1, 1000); hit(ACTION_RESULT_CRITICAL_HEAL, 1, 400)
    hit(ACTION_RESULT_DAMAGE, 2, 999999); hit(999, 1, 999999)
    now = 3000; local d, h = C:Values("group1"); eq(d, 500); eq(h, 200)
    eq(C:Values("group2"), nil)
    C:State(false); now = 8000; eq(C:Values("group1"), 500)
    C:State(true); eq(C:Values("group1"), 0)
end)
test("post-combat rates last five minutes and reset for new combat", function()
    local original = A.SharedStats.Values
    C:Reset(); now = 1000; C:State(true)
    A.SharedStats.Values = function() return 12345, nil end
    eq(C:Values("group2"), 12345)
    now = 2000; C:State(false)
    A.SharedStats.Values = function() return nil, nil end
    now = 301999; eq(C:Values("group2"), 12345)
    now = 302000; eq(C:Values("group2"), nil)
    C:State(true); eq(C:Values("group2"), nil)
    A.SharedStats.Values = original
end)

test("partial group DPS counts group and self damage, excludes enemies and healing", function()
    C:Reset(); now = 1000; C:State(true)
    hit(ACTION_RESULT_DAMAGE, COMBAT_UNIT_TYPE_PLAYER, 1000)
    hit(ACTION_RESULT_DAMAGE, COMBAT_UNIT_TYPE_GROUP, 3000)
    hit(ACTION_RESULT_DAMAGE, 99, 9000)
    hit(ACTION_RESULT_HEAL, COMBAT_UNIT_TYPE_GROUP, 9000)
    now = 3000; eq(C:GroupDPS(), 2000); eq(C.damage, 1000)
    C:State(false); now = 9000; eq(C:GroupDPS(), 2000)
    C:State(true); eq(C:GroupDPS(), nil)
end)

test("first hit before combat-state event is preserved; disable removes handlers", function()
    C:Reset(); combat = false; now = 100; hit(ACTION_RESULT_DAMAGE, 1, 200)
    now = 120; C:State(true); eq(C.damage, 200)
    A.sv.dps = false; A.active = false; C:Configure(); eq(next(EVENT_MANAGER.events), nil); eq(next(EVENT_MANAGER.updates), nil); A.active = true
end)

local parent = { GetLeft = function() return 0 end, GetTop = function() return 0 end }
local frames = {}
local function makeControl(y)
    local c = { anchors = { { TOPLEFT, parent, TOPLEFT, 0, y, 0 } }, handlers = {}, hidden = false }
    function c:IsHidden() return self.hidden end
    function c:GetNumAnchors() return #self.anchors end
    function c:GetAnchor(index) return true, unpack(self.anchors[index + 1]) end
    function c:ClearAnchors() self.anchors = {} end
    function c:SetAnchor(...) self.anchors[#self.anchors + 1] = { ... } end
    function c:GetParent() return parent end
    function c:GetLeft() return self.anchors[1][2]:GetLeft() + self.anchors[1][4] end
    function c:GetTop() return self.anchors[1][2]:GetTop() + self.anchors[1][5] end
    return c
end
for i = 1, 3 do
    local tag = "group" .. i
    frames[tag] = { unitTag = tag, style = "ZO_GroupUnitFrame", frame = makeControl((i - 1) * 70) }
    frames[tag].frame.m_unitTag = tag
end
local companions, scene = 0, "hud"
UNIT_FRAMES = { GetFrame = function(_, tag) return frames[tag] end,
    GetCompanionGroupSize = function() return companions end }
SCENE_MANAGER = { IsShowing = function(_, name) return scene == name end }
local R = A.RoleSorting
test("sort only anchors, keep unit identity, restore original order", function()
    for _, frame in pairs(frames) do R:Capture(frame) end
    combat = false; A.sv.sort = true; R:Apply(A.GroupData:Members())
    eq(frames.group2.frame:GetTop(), 0); eq(frames.group3.frame:GetTop(), 70); eq(frames.group1.frame:GetTop(), 140)
    eq(frames.group2.frame.m_unitTag, "group2")
    R:Apply(A.GroupData:Members()); eq(frames.group2.frame:GetTop(), 0)
    A.sv.sort = false; R:Apply(A.GroupData:Members()); eq(frames.group2.frame:GetTop(), 70)
end)
test("combat and menus keep sorted order; companions restore native anchors", function()
    A.sv.sort = true
    companions = 1; R:Apply(A.GroupData:Members()); eq(frames.group1.frame:GetTop(), 0); companions = 0
    combat = true; R:Apply(A.GroupData:Members()); eq(frames.group1.frame:GetTop(), 140); combat = false
    scene = "groupMenu"; R:Apply(A.GroupData:Members()); eq(frames.group1.frame:GetTop(), 140); scene = "hudui"
    R:Apply(A.GroupData:Members()); eq(frames.group1.frame:GetTop(), 140)
    R:Restore()
end)
test("native anchor refresh retains sorted slot synchronously", function()
    R:Apply(A.GroupData:Members())
    local frame = frames.group1
    frame.frame:ClearAnchors()
    for _, anchor in ipairs(R.anchors[frame]) do frame.frame:SetAnchor(unpack(anchor, 1, 6)) end
    R:Capture(frame)
    eq(frame.frame:GetTop(), 140)
    R:Restore(); eq(frame.frame:GetTop(), 0)
end)

test("raid companions keep player sorting and native companion slots", function()
    companions = 1
    for _, frame in pairs(frames) do frame.style = "ZO_RaidUnitFrame" end
    R:Apply(A.GroupData:Members())
    eq(frames.group2.frame:GetTop(), 0); eq(frames.group1.frame:GetTop(), 140)
    companions = 0; R:Apply(A.GroupData:Members())
    eq(frames.group1.frame:GetTop(), 140)
    R:Restore()
    for _, frame in pairs(frames) do frame.style = "ZO_GroupUnitFrame" end
end)

test("relative native anchor chains survive sorting and repeated restore", function()
    frames.group3.frame.anchors = { { TOPLEFT, frames.group2.frame, TOPLEFT, 0, 70, 0 } }
    R:Capture(frames.group3); R:Apply(A.GroupData:Members()); R:Restore()
    eq(frames.group3.frame:GetTop(), 140)
end)
test("unchanged sorting and repeated restore do not rewrite anchors", function()
    R:Apply(A.GroupData:Members())
    local writes = 0
    local c = frames.group1.frame
    local original = c.ClearAnchors
    c.ClearAnchors = function(self) writes = writes + 1; return original(self) end
    R:Apply(A.GroupData:Members()); eq(writes, 0)
    R:Restore(); eq(writes, 1)
    R:Restore(); eq(writes, 1)
    c.ClearAnchors = original
end)
test("zoning member keeps its slot and missing frame does not reset others", function()
    R:Apply(A.GroupData:Members())
    local expected = frames.group1.frame:GetTop()
    frames.group2.frame.hidden = true
    R.signature = nil -- simulate a fresh layout request during zoning
    R:Apply(A.GroupData:Members()); eq(frames.group1.frame:GetTop(), expected)
    local saved = frames.group2
    frames.group2 = nil
    R:Apply(A.GroupData:Members()); eq(frames.group1.frame:GetTop(), expected)
    frames.group2 = saved; saved.frame.hidden = false
    R:Apply(A.GroupData:Members()); eq(frames.group1.frame:GetTop(), expected)
    R:Restore()
end)

local menu, calls, cursor, leader, voting, canModify = {}, {}, 0, true, false, true
function ClearMenu() menu = {} end
function AddMenuItem(label, action) menu[label] = action end
function ShowMenu(owner) calls.owner = owner end
function GetCursorContentType() return cursor end
function IsChatSystemAvailableForCurrentPlatform() return true end
function IsUnitGroupLeader() return leader end
function IsGroupModificationAvailable() return canModify end
function DoesGroupModificationRequireVote() return voting end
function StartChatInput(_, _, target) calls.whisper = target end
function JumpToGroupMember(target) calls.travel = target end
function GroupKick(tag) calls.kick = tag end
local I, control, nativeCalls = A.Interaction, frames.group2.frame, 0
local nativeMenu = false
control.handlers.OnMouseUp = function()
    nativeCalls = nativeCalls + 1; cursor = MOUSE_CONTENT_EMPTY
    if nativeMenu then ClearMenu(); AddMenuItem("native", function() end); ShowMenu(control) end
end
I:Initialize(); I:Attach(frames.group2)
local function click(button, inside) control.handlers.OnMouseUp(control, button or 2, inside ~= false) end
test("right click preserves vanilla handler and opens native menu actions", function()
    click(); eq(nativeCalls, 1); eq(calls.owner, control)
    menu[GetString(ONEFRAME_WHISPER)](); eq(calls.whisper, "@alice")
    menu[GetString(ONEFRAME_TRAVEL)](); eq(calls.travel, "@alice")
    menu[GetString(ONEFRAME_REMOVE)](); eq(calls.kick, "group2")
end)
test("reused frame targets B; an open A menu cannot act on B", function()
    click(); local oldWhisper, oldKick = menu[GetString(ONEFRAME_WHISPER)], menu[GetString(ONEFRAME_REMOVE)]
    roster.group2 = { account = "@new", character = "New", role = 1 }; calls = {}
    oldWhisper(); oldKick(); eq(calls.whisper, nil); eq(calls.kick, nil)
    click(); menu[GetString(ONEFRAME_WHISPER)](); eq(calls.whisper, "@new")
    menu[GetString(ONEFRAME_TRAVEL)](); eq(calls.travel, "@new")
end)
test("travel uses account identity even when raw name has grammar suffix", function()
    local original = roster.group2.character
    roster.group2.character = "New^Mx"
    click(); menu[GetString(ONEFRAME_TRAVEL)](); eq(calls.travel, "@new")
    roster.group2.character = original
end)
test("permissions checked both at display and action; no self removal or vote bypass", function()
    click(); local remove = menu[GetString(ONEFRAME_REMOVE)]; leader = false; calls.kick = nil; remove(); eq(calls.kick, nil)
    click(); eq(menu[GetString(ONEFRAME_REMOVE)], nil); leader = true
    voting = true; click(); eq(menu[GetString(ONEFRAME_REMOVE)], nil); voting = false
    canModify = false; click(); eq(menu[GetString(ONEFRAME_REMOVE)], nil); canModify = true
    I:Open(frames.group1.frame); eq(menu[GetString(ONEFRAME_REMOVE)], nil)
end)
test("cancelled drag, left click and mouse-up outside do not open a menu", function()
    calls.owner = nil; cursor = 99; click(); eq(calls.owner, nil)
    click(1); eq(calls.owner, nil); click(2, false); eq(calls.owner, nil)
end)
test("existing native menu is retained; interaction toggles respected", function()
    nativeMenu = true; click(); assert(menu.native); eq(menu[GetString(ONEFRAME_WHISPER)], nil); nativeMenu = false
    A.sv.interaction = false; calls.owner = nil; click(); eq(calls.owner, nil); A.sv.interaction = true
    A.sv.contextMenu = false; click(); eq(calls.owner, nil); A.sv.contextMenu = true
    A.active = false; click(); eq(calls.owner, nil); A.active = true
end)
test("departed or hidden frame cannot execute pending action", function()
    click(); local travel = menu[GetString(ONEFRAME_TRAVEL)]; calls.travel = nil
    local saved = roster.group2; roster.group2 = nil; travel(); eq(calls.travel, nil); roster.group2 = saved
    control.hidden = true; travel(); eq(calls.travel, nil); control.hidden = false
end)
function ZO_StatusBar_SetGradientColor(control, gradient) control.gradient = gradient end
test("shield customization changes only gradients and restores native defaults", function()
    local owner = {}; frames.group2.attributeVisualizer = owner
    local overlay = { fakeHealthBar = {}, traumaBar = {}, noHealingInner = {} }
    local info = { overlayControls = { overlay }, visualInfo = {} }
    local module = { GetUnitTag = function() return "group2" end, GetOwner = function() return owner end,
        layoutData = {}, attributeInfo = { [ATTRIBUTE_HEALTH] = info } }
    A.ShieldOverlay:Apply(module); eq(overlay.gradient[1].rgba[4], .45)
    eq(overlay.traumaBar.gradient, nil); eq(overlay.noHealingInner.gradient, nil)
    A.sv.shield = false; A.ShieldOverlay:Apply(module); eq(overlay.gradient[1].rgba[4], .3)
    A.active = false; A.ShieldOverlay:Apply(module); eq(overlay.fakeHealthBar.gradient, ZO_POWER_BAR_GRADIENT_COLORS[1]); A.active = true
end)
print("PASS: " .. tests .. " behavioral tests")
