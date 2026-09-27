local A = GroupFramePlus
local P = {}
A.PlayerInfo = P
function P:Name(frame, data)
    local label = frame.nameLabel
    if not label then return end
    local text, font = label:GetText(), label:GetFont()
    local width = label:GetWidth()
    if width ~= data.nameWidth then data.nativeNameWidth = width end
    if text ~= data.decoratedName then data.nativeName = text end
    if font ~= data.decoratedFont then data.nativeFont = font end
    local name = data.nativeName or text
    if A.active then
        if A.sv.account then name = GetUnitDisplayName(frame.unitTag) end
        if frame.style == "ZO_RaidUnitFrame" then
            local prefix = name:sub(1, 1) == "@" and "@" or ""
            local characters = {}
            local limit = IsUnitGroupLeader(frame.unitTag) and 5 or 7
            for character in name:sub(#prefix + 1):gmatch("[%z\1-\127\194-\244][\128-\191]*") do
                characters[#characters + 1] = character
                if #characters == limit then break end
            end
            name = prefix .. table.concat(characters)
        end
        if A.sv.class then
            local icon = ZO_GetClassIcon(GetUnitClassId(frame.unitTag))
            if icon then name = zo_iconFormat(icon, 16, 16) .. " " .. name end
        end
    end
    local wantedFont = A.active
        and "$(BOLD_FONT)|16|soft-shadow-thin" or data.nativeFont
    label:SetText(name)
    if wantedFont then label:SetFont(wantedFont) end
    local wantedWidth = data.nativeNameWidth
    if A.active and data.info and data.info:GetText() ~= "" then
        local bar = frame.healthBar.barControls[1]
        wantedWidth = math.max(20, bar:GetWidth() - data.info:GetTextWidth() - 8)
    end
    label:SetWidth(wantedWidth)
    data.nameWidth = wantedWidth
    data.decoratedName, data.decoratedFont = name, wantedFont
end
function P:Create(frame)
    local parent = frame.frame
    local data = {}
    for _, key in ipairs({ "info", "stats", "statsCaption" }) do
        local label = WINDOW_MANAGER:CreateControl(parent:GetName() .. "GFP" .. key, parent, CT_LABEL)
        label:SetMouseEnabled(false)
        label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
        label:SetColor(1, 1, 1, 1)
        label:SetDrawLayer(DL_TEXT)
        data[key] = label
    end
    data.ultimate = A.UltimateUI:Create(frame)
    return data
end
function P:Layout(frame, data)
    local raid = frame.style == "ZO_RaidUnitFrame"
    local bar = frame.healthBar.barControls[1]
    local width = bar:GetWidth()
    for _, label in ipairs({ data.info, data.stats }) do
        label:ClearAnchors()
        label:SetFont(raid and "$(BOLD_FONT)|12|soft-shadow-thin" or "ZoFontGameSmall")
        -- A fixed 12/16px box can be shorter than ESO's localized font line and
        -- suppress the entire line. Measure the font, including Cyrillic fallback.
        label:SetDimensions(math.max(0, width - (raid and 8 or 0)), label:GetFontHeight() + 2)
        label:SetAlpha(IsUnitInGroupSupportRange(frame.unitTag) and 1 or 0.3)
    end
    if raid then
        data.info:SetAnchor(TOPRIGHT, bar, TOPRIGHT, -3, 3)
        data.stats:SetAnchor(BOTTOMLEFT, bar, BOTTOMLEFT, 3, 0)
    else
        -- The native small-group control is much wider than its visible health bar.
        -- Keep metadata inside the bar's right edge and immediately above it.
        data.info:SetAnchor(BOTTOMRIGHT, bar, TOPRIGHT, 0, -4)
        data.stats:SetAnchor(TOPLEFT, bar, BOTTOMLEFT, 0, 4)
    end
    data.info:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
    data.stats:SetFont("$(BOLD_FONT)|16|soft-shadow-thin")
    data.stats:SetHeight(data.stats:GetFontHeight() + 2)
    if data.statsCaption then
        local caption = data.statsCaption
        caption:ClearAnchors()
        caption:SetFont(raid and "$(MEDIUM_FONT)|9|soft-shadow-thin" or "$(MEDIUM_FONT)|10|soft-shadow-thin")
        caption:SetDimensions(raid and 21 or 27, caption:GetFontHeight() + 2)
        caption:SetAnchor(raid and BOTTOMLEFT or TOPLEFT, bar, BOTTOMLEFT, raid and 3 or 0, raid and -3 or 8)
        caption:SetAlpha(IsUnitInGroupSupportRange(frame.unitTag) and 1 or 0.3)
        data.stats:ClearAnchors()
        data.stats:SetAnchor(raid and BOTTOMLEFT or TOPLEFT, bar, BOTTOMLEFT, raid and 26 or 30, raid and -1 or 4)
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
    self:Layout(frame, data)
    local tag, pieces = frame.unitTag, {}
    if IsUnitChampion(tag) then
        if A.sv.cp then pieces[#pieces + 1] = tostring(GetUnitChampionPoints(tag)) end
    elseif A.sv.level then
        pieces[#pieces + 1] = tostring(GetUnitLevel(tag))
    end
    -- Class/account belong to the native name line; this row contains level only.
    data.info:SetText(table.concat(pieces, "  "))
    if IsUnitChampion(tag) then data.info:SetColor(1, 1, 1, 1)
    else data.info:SetColor(0.3, 1, 0.3, 1) end
    data.info:SetWidth(data.info:GetTextWidth() + 2)
    self:Name(frame, data)
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
    local caption, value
    local role = GetGroupMemberSelectedRole(frame.unitTag)
    if role == LFG_ROLE_DPS and A.sv.dps then caption, value = A:T("dpsLabel"), dps end
    if role == LFG_ROLE_HEAL and A.sv.hps then caption, value = A:T("hpsLabel"), hps end
    local hidden = not self:CanShow(frame) or not caption
    data.stats:SetText(caption and self:Format(value) or "")
    data.stats:SetHidden(hidden)
    if data.statsCaption then
        data.statsCaption:SetText(caption and caption .. ":" or "")
        data.statsCaption:SetHidden(hidden)
    end
    A.UltimateUI:Update(frame, data)
end
