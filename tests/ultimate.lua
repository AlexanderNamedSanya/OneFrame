local A = OneFrame
if A.SharedStats then A.SharedStats:Disconnect() end
load_module("Integrations/HodorReflexes.lua")
load_module("UI/Ultimate.lua")
local H = A.SharedStats
local tests, now = 0, 100000
local function eq(a, b) assert(a == b, tostring(a) .. " ~= " .. tostring(b)) end
local function test(name, fn) fn(); tests = tests + 1; print("PASS: " .. name) end
function GetGameTimeMilliseconds() return now end
local roster = { player = { "@me", "Me" }, group1 = { "@me", "Me" }, group2 = { "@ally", "Ally" } }
function GetGroupSize() return 2 end
function DoesUnitExist(tag) return roster[tag] ~= nil end
function IsUnitGrouped(tag) return DoesUnitExist(tag) end
function IsUnitOnline(tag) return DoesUnitExist(tag) end
function GetUnitDisplayName(tag) return roster[tag][1] end
function GetUnitName(tag) return roster[tag][2] end
function AreUnitsEqual(tag, other) return tag == other or (tag == "group1" and other == "player") end
local role = LFG_ROLE_TANK
function GetGroupMemberSelectedRole() return role end
function IsUnitDead() return false end
function IsUnitInGroupSupportRange() return true end
local meta = {}
function meta:__index(key) return self._data[key] end
local writes = 0
function meta:__newindex(key, value)
    writes = writes + 1
    self._data[key] = value
    rawset(self, "_lastUpdated", now)
end
local function observable()
    return setmetatable({ _data = { ultValue = 0, ult1ID = 0, ult2ID = 0, ult1Cost = 0, ult2Cost = 0 }, _lastUpdated = 0 }, meta)
end
local objects = { Me = observable(), Ally = observable() }
local reader = {}
function reader:GetUnitULT(tag) return objects[GetUnitName(tag)] end
function reader:GetUnitStats(tag)
    if not objects[GetUnitName(tag)] then return nil end
    return { name = GetUnitName(tag), displayName = GetUnitDisplayName(tag) }
end
function reader:RegisterForEvent() end
function reader:UnregisterForEvent() end
HodorReflexes = { version = "2026-05-17", modules = { ult = { IsEnabled = function() return true end } },
    RegisterCallback = function() end, UnregisterCallback = function() end }
for _, key in ipairs({ "HR_EVENT_COMBAT_START", "HR_EVENT_COMBAT_END", "HR_EVENT_GROUP_CHANGED",
    "HR_EVENT_PLAYER_ACTIVATED", "HR_EVENT_TEST_STARTED", "HR_EVENT_TEST_STOPPED" }) do HodorReflexes[key] = key end
LibGroupCombatStats = { version = "2026-07-26", DAMAGE_UNKNOWN = 0, DAMAGE_TOTAL = 1, DAMAGE_BOSS = 2,
    RegisterAddon = function(_, needed) eq(next(needed), nil); return reader end }
for _, key in ipairs({ "EVENT_GROUP_DPS_UPDATE", "EVENT_PLAYER_DPS_UPDATE", "EVENT_GROUP_HPS_UPDATE",
    "EVENT_PLAYER_HPS_UPDATE", "EVENT_GROUP_ULT_UPDATE", "EVENT_PLAYER_ULT_UPDATE" }) do LibGroupCombatStats[key] = key end
A.active, A.sv.hodor, A.sv.ultimate, A.sv.dps, A.sv.hps = true, true, true, false, false
H:Configure()
local function typePacket(object, first, second, cost1, cost2)
    object.ult1ID, object.ult2ID, object.ult1Cost, object.ult2Cost = first, second, cost1, cost2
end
test("Ultimate independent of DPS/HPS; type packet never fabricates zero points", function()
    eq(H:IsAvailable(), true); typePacket(objects.Ally, 101, 202, 180, 240)
    eq(H:Ultimate("group2"), nil)
    local before = writes; objects.Ally.ultValue = 0; eq(writes, before + 1)
    local values = H:Ultimate("group2"); eq(#values, 2); eq(values[1].points, 0)
    eq(values[1].abilityId, 101); eq(values[2].abilityId, 202)
end)
test("remote readiness accounts for actual cost and 2-point quantization", function()
    objects.Ally.ultValue = 178; eq(H:Ultimate("group2")[1].ready, false)
    objects.Ally.ultValue = 180; eq(H:Ultimate("group2")[1].ready, nil)
    objects.Ally.ultValue = 182; eq(H:Ultimate("group2")[1].ready, true)
    objects.Ally.ult1Cost = 0; eq(H:Ultimate("group2")[1].ready, nil)
    objects.Ally.ult1Cost = 180
end)
test("same shared ability collapses, unknown IDs never synthesize generic Ultimate", function()
    objects.Ally.ult2ID = 101; eq(#H:Ultimate("group2"), 1)
    objects.Ally.ult2ID = 0; eq(#H:Ultimate("group2"), 1)
    objects.Ally.ult1ID = 0; eq(H:Ultimate("group2")[1].abilityId, nil)
    typePacket(objects.Ally, 101, 202, 180, 240)
end)
test("type/cost updates cannot refresh expired points; unchanged zero receipt can", function()
    now = now + 10001; typePacket(objects.Ally, 101, 202, 180, 240)
    eq(H:Ultimate("group2"), nil)
    objects.Ally.ultValue = 0; eq(H:Ultimate("group2")[1].points, 0)
end)
test("combat reset preserves Ultimate; roster reset requires new received data", function()
    H:Reset(false); eq(H:Ultimate("group2")[1].points, 0)
    H:Reset(true); eq(H:Ultimate("group2"), nil)
    objects.Ally.ultValue = 0; eq(H:Ultimate("group2")[1].points, 0)
    typePacket(objects.Ally, 101, 202, 180, 240); eq(H:Ultimate("group2")[1].points, 0)
end)
test("local exact readiness uses shared cost, never fixed 250", function()
    typePacket(objects.Me, 101, 0, 173, 0); objects.Me.ultValue = 173
    eq(H:Ultimate("group1")[1].ready, true)
    objects.Me.ultValue = 172; eq(H:Ultimate("group1")[1].ready, false)
end)
test("new occupant cannot inherit previous source object or points", function()
    roster.group2 = { "@new", "New" }; eq(H:Ultimate("group2"), nil)
    objects.New = observable(); typePacket(objects.New, 303, 0, 100, 0)
    eq(H:Ultimate("group2"), nil)
    objects.New.ultValue = 118; eq(H:Ultimate("group2")[1].abilityId, 303)
end)
test("disabled Ultimate observer is inert and does not suppress original writes", function()
    A.sv.ultimate = false; local before = writes; objects.New.ultValue = 120
    eq(writes, before + 1); eq(H:Ultimate("group2"), nil)
    A.sv.ultimate = true; objects.New.ultValue = 122
end)

CT_CONTROL, CT_TEXTURE, CT_LABEL, DL_OVERLAY, DL_TEXT = 1, 2, 3, 4, 5
DL_CONTROLS, TEXT_ALIGN_RIGHT = 2, 2
BOTTOMRIGHT, TOPRIGHT = 6, 7
RIGHT, LEFT = 8, 9
ZO_NO_TEXTURE_FILE = "/esoui/art/icons/icon_missing.dds"
function DoesAbilityExist(id) return id > 0 and id ~= 999 end
local iconCalls = 0
function GetAbilityIcon(id) iconCalls = iconCalls + 1; return id == 998 and ZO_NO_TEXTURE_FILE or "native/" .. id .. ".dds" end
local created = 0
local function control()
    local c = { textureWrites = 0 }
    function c:SetDimensions(w, h) self.width, self.height = w, h end
    function c:SetWidth(w) self.width = w end
    function c:SetHeight(h) self.height = h end
    function c:SetMouseEnabled(value) self.mouse = value end
    function c:SetHidden(value) self.hidden = value end
    function c:SetAnchorFill() end
    function c:SetDrawLayer(value) self.layer = value end
    function c:SetDrawLevel(value) self.drawLevel = value end
    function c:SetHorizontalAlignment(value) self.align = value end
    function c:GetFontHeight() return 11 end
    function c:SetAnchor(...) self.anchor = { ... } end
    function c:ClearAnchors() end
    function c:SetFont() end
    function c:SetColor(...) self.color = {...} end
    function c:SetDesaturation(value) self.desat = value end
    function c:SetAlpha(value) self.alpha = value end
    function c:SetHandler(name, callback) self[name] = callback end
    function c:SetGradientColors(...) self.gradient = {...} end
    function c:SetTexture(value) self.texture = value; self.textureWrites = self.textureWrites + 1 end
    function c:SetText(value) self.text = value end
    return c
end
WINDOW_MANAGER = { CreateControl = function() created = created + 1; return control() end }
local frame = { unitTag = "group2", style = "ZO_GroupUnitFrame",
    frame = { GetName = function() return "NativeFrame" end },
    healthBar = { barControls = { { GetWidth = function() return 170 end, GetHeight = function() return 39 end, GetAlpha = function() return 0.25 end } } } }
local ui = { info = control(), stats = control(), statsCaption = control() }
ui.ultimate = A.UltimateUI:Create(frame)
test("horizontal 4px Ultimate strip exact colors and proportional fill", function()
    eq(created, 2)
    local original = A.CombatStats.Ultimate
    local value = {points = 0}
    A.CombatStats.Ultimate = function() return {value} end
    frame.style = "ZO_RaidUnitFrame"
    for _, item in ipairs({{0,1,0}, {175,1,1}, {500,0,1}}) do
        value.points = item[1]; A.UltimateUI:Update(frame, ui)
        eq(ui.ultimate.fill.color[1], item[2]); eq(ui.ultimate.fill.color[2], item[3])
        eq(ui.ultimate.fill.width, math.max(1, 168 * item[1] / 500))
        eq(ui.ultimate.fill.height, 4)
    end
    eq(ui.ultimate.track.width, 168); eq(ui.ultimate.track.height, 4); eq(ui.ultimate.track.alpha, 0.25)
    eq(ui.ultimate.track.mouse, false); eq(ui.ultimate.fill.mouse, false)
    A.CombatStats.Ultimate = function() return nil end
    A.UltimateUI:Update(frame, ui); eq(ui.ultimate.track.hidden, false)
    A.CombatStats.Ultimate = original
end)
test("current health in thousands and native alpha on all labels", function()
    ui.health = control()
    function GetUnitPower() return 25449, 40000, 40000 end
    A.PlayerInfo:Stats(frame, ui)
    assert(ui.health.text:find("25.4", 1, true))
    for _, key in ipairs({"info", "stats", "statsCaption", "health"}) do eq(ui[key].alpha, 0.25) end
    GetUnitPower = function() return 0, 40000, 40000 end
    A.PlayerInfo:Stats(frame, ui); assert(ui.health.text:find("0.0", 1, true))
end)
test("death hides health; offline immediately hides all added data", function()
    local oldDead, oldOnline = IsUnitDead, IsUnitOnline
    IsUnitDead = function() return true end
    A.PlayerInfo:Stats(frame, ui); eq(ui.health.hidden, true)
    IsUnitDead = oldDead
    A.PlayerInfo:Stats(frame, ui); eq(ui.health.hidden, false)
    ui.info:SetHidden(false)
    IsUnitOnline = function() return false end
    A.PlayerInfo:Stats(frame, ui)
    for _, key in ipairs({"info", "stats", "statsCaption", "health"}) do eq(ui[key].hidden, true) end
    eq(ui.ultimate.track.hidden, true)
    IsUnitOnline = oldOnline
    A.PlayerInfo:Stats(frame, ui); eq(ui.health.hidden, false)
end)
test("missing rates hide captions, received zero stays visible", function()
    local original = A.CombatStats.Values
    role = LFG_ROLE_DPS; A.sv.dps = true
    ui.lastRates = {}
    A.CombatStats.Values = function() return nil, nil end
    A.PlayerInfo:Stats(frame, ui)
    eq(ui.stats.hidden, true); eq(ui.statsCaption.hidden, true)
    A.CombatStats.Values = function() return 0, nil end
    A.PlayerInfo:Stats(frame, ui)
    eq(ui.stats.hidden, false); eq(ui.stats.text, "0")
    A.CombatStats.Values = original
end)

test("empty visible native status does not hide raid information", function()
    frame.statusLabel = { IsHidden = function() return false end, GetText = function() return "" end }
    eq(A.PlayerInfo:CanShow(frame), true)
    frame.statusLabel.GetText = function() return "Offline" end
    eq(A.PlayerInfo:CanShow(frame), true)
    frame.statusLabel.IsHidden = function() return true end
    eq(A.PlayerInfo:CanShow(frame), true)
    frame.statusLabel = nil
end)
test("layout fits actual font metrics for raid and small-group labels", function()
    function IsInGamepadPreferredMode() return false end
    for _, label in ipairs({ui.info, ui.stats}) do
        function label:GetFontHeight() return 18 end
    end
    for _, style in ipairs({"ZO_RaidUnitFrame", "ZO_GroupUnitFrame"}) do
        frame.style = style
        A.PlayerInfo:Layout(frame, ui)
        eq(ui.info.height, 20); eq(ui.stats.height, 20)
    end
end)
test("native name gets one class icon and restores text/font on disable", function()
    local label = {text = "@ally", font = "NativeFont", width = 86}
    function label:GetWidth() return self.width end
    function label:SetWidth(v) self.width = v end
    function label:GetText() return self.text end
    function label:GetFont() return self.font end
    function label:SetText(v) self.text = v end
    function label:SetFont(v) self.font = v end
    function GetUnitClassId() return 1 end
    function ZO_GetClassIcon() return "class.dds" end
    function zo_iconFormat(path, w, h) return "|t" .. w .. ":" .. h .. ":" .. path .. "|t" end
    local isLeader = false
    function IsUnitGroupLeader() return isLeader end
    frame.nameLabel, frame.style = label, "ZO_RaidUnitFrame"
    local data = {}
    A.active, A.sv.class, A.sv.account = true, true, false
    A.PlayerInfo:Name(frame, data)
    eq(label.text, "|t16:16:class.dds|t @ally")
    A.PlayerInfo:Name(frame, data); eq(label.text, "|t16:16:class.dds|t @ally")
    label.text = "@replacement" -- native name refresh on frame reuse
    A.PlayerInfo:Name(frame, data); eq(label.text, "|t16:16:class.dds|t @replace")
    isLeader = true
    A.PlayerInfo:Name(frame, data); eq(label.text, "|t16:16:class.dds|t @repla")
    isLeader = false
    A.PlayerInfo:Name(frame, data); eq(label.text, "|t16:16:class.dds|t @replace")
    local oldOnline = IsUnitOnline
    IsUnitOnline = function() return false end
    A.PlayerInfo:Name(frame, data); eq(label.text, "@replacement")
    IsUnitOnline = oldOnline
    A.PlayerInfo:Name(frame, data); eq(label.text, "|t16:16:class.dds|t @replace")
    A.active = false; A.PlayerInfo:Name(frame, data)
    eq(label.text, "@replacement"); eq(label.font, "NativeFont")
    A.active = true
end)
print("PASS: " .. tests .. " Ultimate tests")
test("leader border follows leadership, fades, and restores crown on disable", function()
    local oldManager, oldLeader, oldCrown = UNIT_FRAMES, IsUnitGroupLeader, ZO_UnitFrames_Leader
    local leader = true
    IsUnitGroupLeader = function() return leader end
    UNIT_FRAMES = {GetFrame = function() return frame end}
    frame.SetTextIndented = function(_, value) frame.indented = value end
    local data = {}
    A.Frames:Leader(frame, data)
    eq(#data.leaderBorder, 4); eq(frame.indented, false)
    eq(data.leaderGlint, nil); eq(data.leaderGlow, nil)
    for _, edge in ipairs(data.leaderBorder) do
        eq(edge.hidden, false); eq(edge.mouse, false); eq(edge.alpha, 0.25)
    end
    frame.style = "ZO_GroupUnitFrame"
    A.Frames:Leader(frame, data)
    for _, edge in ipairs(data.leaderBorder) do eq(edge.hidden, true) end
    frame.style = "ZO_RaidUnitFrame"
    leader = false; A.Frames:Leader(frame, data)
    for _, edge in ipairs(data.leaderBorder) do eq(edge.hidden, true) end
    ZO_UnitFrames_Leader = {alpha = 0.7, GetAlpha = function(self) return self.alpha end,
        SetAlpha = function(self, value) self.alpha = value end}
    A.Frames:Crown(); eq(ZO_UnitFrames_Leader.alpha, 0)
    A.active = false; A.Frames:Crown(); eq(ZO_UnitFrames_Leader.alpha, 0.7)
    A.active = true
    UNIT_FRAMES, IsUnitGroupLeader, ZO_UnitFrames_Leader = oldManager, oldLeader, oldCrown
end)

test("each role independently selects DPS HPS or none", function()
    local original, oldChoices = A.CombatStats.Values, A.sv.roleStats
    A.CombatStats.Values = function() return 123, 456 end
    A.sv.roleStats = {}
    for _, selectedRole in ipairs({LFG_ROLE_TANK, LFG_ROLE_HEAL, LFG_ROLE_DPS}) do
        role = selectedRole
        for _, choice in ipairs({"dps", "hps", "none"}) do
            A.sv.roleStats[role] = choice
            A.PlayerInfo:Stats(frame, ui)
            eq(ui.stats.hidden, choice == "none")
            if choice ~= "none" then eq(ui.stats.text, choice == "dps" and "123" or "456") end
        end
    end
    A.CombatStats.Values, A.sv.roleStats = original, oldChoices
end)
test("legacy role preferences migrate and aggregate collection flags", function()
    local old = A.sv
    A.sv = {dps=true, hps=false}
    A:PrepareRoleStatistics()
    eq(A.sv.roleStats[LFG_ROLE_DPS], "dps")
    eq(A.sv.roleStats[LFG_ROLE_HEAL], "none")
    A.sv.roleStats[LFG_ROLE_DPS] = "none"
    A.sv.roleStats[LFG_ROLE_TANK] = "hps"
    A:PrepareRoleStatistics()
    eq(A.sv.dps, false); eq(A.sv.hps, true)
    A.sv = old
end)

test("presentation survives packet gaps but never crosses player identity", function()
    local rates, ult, choices = A.CombatStats.Values, A.CombatStats.Ultimate, A.sv.roleStats
    local name = GetUnitName
    A.sv.roleStats = {[LFG_ROLE_DPS]="dps"}; role = LFG_ROLE_DPS
    A.CombatStats.Values = function() return 12345, nil end
    A.CombatStats.Ultimate = function() return {{points=175}} end
    A.PlayerInfo:Stats(frame, ui)
    local text = ui.stats.text
    A.CombatStats.Values = function() return nil, nil end
    A.CombatStats.Ultimate = function() return nil end
    A.PlayerInfo:Stats(frame, ui)
    eq(ui.stats.hidden, false); eq(ui.stats.text, text); eq(ui.ultimate.track.hidden, false)
    GetUnitName = function() return "Replacement" end
    A.PlayerInfo:Stats(frame, ui)
    eq(ui.stats.hidden, true); eq(ui.ultimate.track.hidden, true)
    GetUnitName = name
    A.CombatStats.Values, A.CombatStats.Ultimate, A.sv.roleStats = rates, ult, choices
end)

test("Ultimate cost colors prefer highest cost and retain unknown-cost fallback", function()
    local original = A.CombatStats.Ultimate
    local values = {{points=100, cost=200, progress=0.5}}
    A.CombatStats.Ultimate = function() return values end
    A.UltimateUI:Update(frame, ui)
    eq(ui.ultimate.fill.color[1], 1); eq(ui.ultimate.fill.color[2], 1)
    values[1].points, values[1].progress = 200, 1
    A.UltimateUI:Update(frame, ui)
    eq(ui.ultimate.fill.color[1], 0); eq(ui.ultimate.fill.color[2], 1)
    values[2] = {points=200, cost=300, progress=2/3}
    A.UltimateUI:Update(frame, ui)
    eq(ui.ultimate.fill.color[1], 2 * (1 - 2/3))
    values[1], values[2] = values[2], values[1]
    A.UltimateUI:Update(frame, ui)
    eq(ui.ultimate.fill.color[1], 2 * (1 - 2/3))
    values[2].progress = nil
    A.UltimateUI:Update(frame, ui)
    eq(ui.ultimate.fill.color[1], 1 - 25/325)
    values = {{points=175}}
    A.UltimateUI:Update(frame, ui)
    eq(ui.ultimate.fill.color[1], 1); eq(ui.ultimate.fill.color[2], 1)
    A.CombatStats.Ultimate = original
end)
