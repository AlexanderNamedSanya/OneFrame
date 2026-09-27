local A = GroupFramePlus
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
    objects.Ally.ult1ID = 0; eq(H:Ultimate("group2"), nil)
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
    objects.Ally.ultValue = 0; eq(H:Ultimate("group2"), nil)
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
ZO_NO_TEXTURE_FILE = "/esoui/art/icons/icon_missing.dds"
function DoesAbilityExist(id) return id > 0 and id ~= 999 end
local iconCalls = 0
function GetAbilityIcon(id) iconCalls = iconCalls + 1; return id == 998 and ZO_NO_TEXTURE_FILE or "native/" .. id .. ".dds" end
local created = 0
local function control()
    local c = { textureWrites = 0 }
    function c:SetDimensions(w, h) self.width, self.height = w, h end
    function c:SetWidth(w) self.width = w end
    function c:SetMouseEnabled(value) self.mouse = value end
    function c:SetHidden(value) self.hidden = value end
    function c:SetAnchorFill() end
    function c:SetDrawLayer(value) self.layer = value end
    function c:SetHorizontalAlignment(value) self.align = value end
    function c:GetFontHeight() return 11 end
    function c:SetAnchor(...) self.anchor = { ... } end
    function c:ClearAnchors() end
    function c:SetFont() end
    function c:SetColor() end
    function c:SetDesaturation(value) self.desat = value end
    function c:SetAlpha(value) self.alpha = value end
    function c:SetTexture(value) self.texture = value; self.textureWrites = self.textureWrites + 1 end
    function c:SetText(value) self.text = value end
    return c
end
WINDOW_MANAGER = { CreateControl = function() created = created + 1; return control() end }
local frame = { unitTag = "group2", style = "ZO_GroupUnitFrame",
    frame = { GetName = function() return "NativeFrame" end },
    healthBar = { barControls = { { GetWidth = function() return 170 end } } } }
local ui = { info = control(), stats = control() }
ui.ultimate = A.UltimateUI:Create(frame)
test("controls created once, actual native icons and separate point label", function()
    eq(created, 6); A.UltimateUI:Update(frame, ui)
    eq(ui.ultimate[1].icon.texture, "native/303.dds"); eq(ui.ultimate[1].points.text, "122")
    eq(ui.ultimate[1].icon.layer, DL_CONTROLS); eq(ui.ultimate[1].points.layer, DL_OVERLAY)
    eq(ui.ultimate[1].points.width, 24); eq(ui.ultimate[1].points.height, 13)
    for _, slot in ipairs(ui.ultimate) do eq(slot.root.mouse, false); eq(slot.icon.mouse, false); eq(slot.points.mouse, false) end
    local writesBefore, callsBefore = ui.ultimate[1].icon.textureWrites, iconCalls
    objects.New.ultValue = 124; A.UltimateUI:Update(frame, ui)
    eq(created, 6); eq(ui.ultimate[1].icon.textureWrites, writesBefore); eq(iconCalls, callsBefore)
    eq(ui.ultimate[1].points.text, "124")
    objects.New.ult1ID = 404; A.UltimateUI:Update(frame, ui); eq(ui.ultimate[1].icon.texture, "native/404.dds")
end)
test("unknown/generic ability textures hide instead of displaying placeholders", function()
    objects.New.ult1ID = 999; A.UltimateUI:Update(frame, ui); eq(ui.ultimate[1].root.hidden, true)
    objects.New.ult1ID = 998; A.UltimateUI:Update(frame, ui); eq(ui.ultimate[1].root.hidden, true)
    objects.New.ult1ID = 303
end)
test("role-aware statistics and Ultimate for tank, healer and damage dealer", function()
    local oldValues = A.CombatStats.Values
    A.CombatStats.Values = function() return 87000, 24000 end
    A.sv.dps, A.sv.hps = true, true
    for _, selected in ipairs({ LFG_ROLE_TANK, LFG_ROLE_HEAL, LFG_ROLE_DPS }) do
        role = selected; A.PlayerInfo:Stats(frame, ui)
        eq(ui.ultimate[1].root.hidden, false)
        if selected == LFG_ROLE_TANK then eq(ui.stats.text, ""); eq(ui.stats.hidden, true)
        elseif selected == LFG_ROLE_HEAL then assert(ui.stats.text:find(A:T("hpsLabel"), 1, true)); assert(not ui.stats.text:find(A:T("dpsLabel"), 1, true))
        else assert(ui.stats.text:find(A:T("dpsLabel"), 1, true)); assert(not ui.stats.text:find(A:T("hpsLabel"), 1, true)) end
    end
    A.CombatStats.Values = oldValues
end)
test("disabled/expired Ultimate restores full text width; no extra frame or bar", function()
    A.sv.ultimate = false; A.UltimateUI:Update(frame, ui)
    eq(ui.stats.width, 170); eq(ui.ultimate[1].root.hidden, true); eq(created, 6)
    A.sv.ultimate = true; now = now + 10001; A.UltimateUI:Update(frame, ui)
    eq(ui.ultimate[1].root.hidden, true)
end)
test("empty visible native status does not hide raid information", function()
    frame.statusLabel = { IsHidden = function() return false end, GetText = function() return "" end }
    eq(A.PlayerInfo:CanShow(frame), true)
    frame.statusLabel.GetText = function() return "Offline" end
    eq(A.PlayerInfo:CanShow(frame), false)
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
    function zo_iconFormat(path) return "|t12:12:" .. path .. "|t" end
    frame.nameLabel, frame.style = label, "ZO_RaidUnitFrame"
    local data = {}
    A.active, A.sv.class, A.sv.account = true, true, false
    A.PlayerInfo:Name(frame, data)
    eq(label.text, "|t12:12:class.dds|t @ally")
    A.PlayerInfo:Name(frame, data); eq(label.text, "|t12:12:class.dds|t @ally")
    label.text = "@replacement" -- native name refresh on frame reuse
    A.PlayerInfo:Name(frame, data); eq(label.text, "|t12:12:class.dds|t @replacement")
    A.active = false; A.PlayerInfo:Name(frame, data)
    eq(label.text, "@replacement"); eq(label.font, "NativeFont")
    A.active = true
end)
print("PASS: " .. tests .. " Ultimate tests")
