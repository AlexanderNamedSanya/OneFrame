local A = GroupFramePlus
local P = {}
A.PlayerInfo = P
function P:Create(frame)
    local parent = frame.frame
    local data = {}
    for _, key in ipairs({ "info", "stats" }) do
        local label = WINDOW_MANAGER:CreateControl(parent:GetName() .. "GFP" .. key, parent, CT_LABEL)
        label:SetMouseEnabled(false)
        label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
        label:SetColor(0.85, 0.85, 0.85, 1)
        label:SetDrawLayer(DL_OVERLAY)
        data[key] = label
    end
    return data
end
function P:Layout(frame, data)
    local raid = frame.style == "ZO_RaidUnitFrame"
    local gamepad = IsInGamepadPreferredMode()
    local bar = frame.healthBar.barControls[1]
    local width = bar:GetWidth()
    for _, label in pairs(data) do
        label:ClearAnchors()
        label:SetFont(raid and "$(MEDIUM_FONT)|10|soft-shadow-thin" or "ZoFontGameSmall")
        label:SetDimensions(math.max(0, width - (raid and 8 or 0)), raid and 12 or 16)
        label:SetAlpha(IsUnitInGroupSupportRange(frame.unitTag) and 1 or 0.3)
    end
    if raid then
        data.info:SetAnchor(TOPLEFT, bar, TOPLEFT, 3, gamepad and 13 or 14)
        data.stats:SetAnchor(BOTTOMLEFT, bar, BOTTOMLEFT, 3, 0)
    else
        data.info:SetAnchor(BOTTOMLEFT, frame.nameLabel, TOPLEFT, 0, 0)
        data.stats:SetAnchor(TOPLEFT, bar, BOTTOMLEFT, 0, 1)
    end
end
function P:CanShow(frame)
    return A.active and DoesUnitExist(frame.unitTag) and IsUnitOnline(frame.unitTag)
        and not IsUnitDead(frame.unitTag)
        and (not frame.statusLabel or frame.statusLabel:IsHidden())
end
function P:Update(frame, data)
    self:Layout(frame, data)
    local tag, pieces = frame.unitTag, {}
    if A.sv.class then
        local icon = ZO_GetClassIcon(GetUnitClassId(tag))
        if icon then pieces[#pieces + 1] = zo_iconFormat(icon, 12, 12) end
    end
    if IsUnitChampion(tag) then
        if A.sv.cp then pieces[#pieces + 1] = string.format(A:T("cpValue"), GetUnitChampionPoints(tag)) end
    elseif A.sv.level then
        pieces[#pieces + 1] = string.format(A:T("levelValue"), GetUnitLevel(tag))
    end
    -- Put truncatable names last, preserving the icon and level/CP in narrow raid frames.
    if A.sv.account then pieces[#pieces + 1] = GetUnitDisplayName(tag) end
    data.info:SetText(table.concat(pieces, "  "))
    data.info:SetHidden(not self:CanShow(frame) or #pieces == 0)
    self:Stats(frame, data)
end
function P:Format(value)
    if value == nil then return A:T("unavailable") end
    if value >= 1000 then return string.format(A:T("kilo"), value / 1000) end
    return tostring(math.floor(value + 0.5))
end
function P:Stats(frame, data)
    local dps, hps = A.CombatStats:Values(frame.unitTag)
    local pieces = {}
    if A.sv.dps then pieces[#pieces + 1] = A:T("dpsLabel") .. ": " .. self:Format(dps) end
    if A.sv.hps then pieces[#pieces + 1] = A:T("hpsLabel") .. ": " .. self:Format(hps) end
    data.stats:SetText(table.concat(pieces, "  "))
    data.stats:SetHidden(not self:CanShow(frame) or #pieces == 0)
end
