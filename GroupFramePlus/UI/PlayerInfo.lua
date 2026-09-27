local A = GroupFramePlus
local P = {}
A.PlayerInfo = P
function P:Name(frame, data)
    local label = frame.nameLabel
    if not label then return end
    local text, font = label:GetText(), label:GetFont()
    if text ~= data.decoratedName then data.nativeName = text end
    if font ~= data.decoratedFont then data.nativeFont = font end
    local name = data.nativeName or text
    if A.active then
        if A.sv.account then name = GetUnitDisplayName(frame.unitTag) end
        if A.sv.class then
            local icon = ZO_GetClassIcon(GetUnitClassId(frame.unitTag))
            if icon then name = zo_iconFormat(icon, 12, 12) .. " " .. name end
        end
    end
    local wantedFont = A.active and frame.style == "ZO_RaidUnitFrame"
        and "$(BOLD_FONT)|12|soft-shadow-thin" or data.nativeFont
    label:SetText(name)
    if wantedFont then label:SetFont(wantedFont) end
    data.decoratedName, data.decoratedFont = name, wantedFont
end
function P:Create(frame)
    local parent = frame.frame
    local data = {}
    for _, key in ipairs({ "info", "stats" }) do
        local label = WINDOW_MANAGER:CreateControl(parent:GetName() .. "GFP" .. key, parent, CT_LABEL)
        label:SetMouseEnabled(false)
        label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
        label:SetColor(0.85, 0.85, 0.85, 1)
        label:SetDrawLayer(DL_TEXT)
        data[key] = label
    end
    data.ultimate = A.UltimateUI:Create(frame)
    return data
end
function P:Layout(frame, data)
    local raid = frame.style == "ZO_RaidUnitFrame"
    local gamepad = IsInGamepadPreferredMode()
    local bar = frame.healthBar.barControls[1]
    local width = bar:GetWidth()
    for _, label in ipairs({ data.info, data.stats }) do
        label:ClearAnchors()
        label:SetFont(raid and "$(MEDIUM_FONT)|10|soft-shadow-thin" or "ZoFontGameSmall")
        -- A fixed 12/16px box can be shorter than ESO's localized font line and
        -- suppress the entire line. Measure the font, including Cyrillic fallback.
        label:SetDimensions(math.max(0, width - (raid and 8 or 0)), label:GetFontHeight() + 2)
        label:SetAlpha(IsUnitInGroupSupportRange(frame.unitTag) and 1 or 0.3)
    end
    if raid then
        data.info:SetAnchor(TOPLEFT, bar, TOPLEFT, 3, 16)
        data.stats:SetAnchor(BOTTOMLEFT, bar, BOTTOMLEFT, 3, 0)
    else
        data.info:SetAnchor(BOTTOMLEFT, frame.nameLabel, TOPLEFT, 0, 0)
        data.stats:SetAnchor(TOPLEFT, bar, BOTTOMLEFT, 0, 1)
    end
end
function P:CanShow(frame)
    return A.active and DoesUnitExist(frame.unitTag) and IsUnitOnline(frame.unitTag)
        and not IsUnitDead(frame.unitTag)
        -- ApplyVisualStyle can expose the status control with empty text. Only an
        -- actual visible status message should suppress our member information.
        and (not frame.statusLabel or frame.statusLabel:IsHidden() or frame.statusLabel:GetText() == "")
end
function P:Update(frame, data)
    self:Name(frame, data)
    self:Layout(frame, data)
    local tag, pieces = frame.unitTag, {}
    if IsUnitChampion(tag) then
        if A.sv.cp then pieces[#pieces + 1] = string.format(A:T("cpValue"), GetUnitChampionPoints(tag)) end
    elseif A.sv.level then
        pieces[#pieces + 1] = string.format(A:T("levelValue"), GetUnitLevel(tag))
    end
    -- Class/account belong to the native name line; this row contains level only.
    data.info:SetText(table.concat(pieces, "  "))
    data.info:SetHidden(not self:CanShow(frame) or #pieces == 0)
    self:Stats(frame, data)
end
function P:Format(value)
    if value == nil then return A:T("unavailable") end
    if value >= 1000000 then return string.format(A:T("million"), value / 1000000) end
    if value >= 1000 then return string.format(A:T("kilo"), value / 1000) end
    return tostring(math.floor(value + 0.5))
end
function P:Stats(frame, data)
    local dps, hps = A.CombatStats:Values(frame.unitTag)
    local pieces = {}
    local role = GetGroupMemberSelectedRole(frame.unitTag)
    if role == LFG_ROLE_DPS and A.sv.dps then pieces[#pieces + 1] = A:T("dpsLabel") .. ": " .. self:Format(dps) end
    if role == LFG_ROLE_HEAL and A.sv.hps then pieces[#pieces + 1] = A:T("hpsLabel") .. ": " .. self:Format(hps) end
    data.stats:SetText(table.concat(pieces, "  "))
    data.stats:SetHidden(not self:CanShow(frame) or #pieces == 0)
    A.UltimateUI:Update(frame, data)
end
