local A = GroupFramePlus
local U = {}
A.UltimateUI = U
local SIZE, GAP = 20, 2
function U:Create(frame)
    local slots = {}
    for i = 1, 2 do
        local name = frame.frame:GetName() .. "GFPUltimate" .. i
        local root = WINDOW_MANAGER:CreateControl(name, frame.frame, CT_CONTROL)
        root:SetDimensions(SIZE, SIZE)
        root:SetMouseEnabled(false)
        root:SetHidden(true)
        local icon = WINDOW_MANAGER:CreateControl(name .. "Icon", root, CT_TEXTURE)
        icon:SetAnchorFill(root)
        icon:SetMouseEnabled(false)
        icon:SetDrawLayer(DL_CONTROLS)
        local points = WINDOW_MANAGER:CreateControl(name .. "Points", root, CT_LABEL)
        points:SetAnchor(BOTTOMRIGHT, root, BOTTOMRIGHT, 0, 0)
        points:SetFont("$(BOLD_FONT)|13|thick-outline")
        points:SetDimensions(24, points:GetFontHeight() + 2)
        points:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
        points:SetColor(1, 1, 1, 1)
        points:SetMouseEnabled(false)
        points:SetDrawLayer(DL_OVERLAY)
        slots[i] = { root = root, icon = icon, points = points }
    end
    return slots
end
function U:Hide(slots)
    for _, slot in ipairs(slots or {}) do slot.root:SetHidden(true) end
end
function U:Update(frame, data)
    if not data.ultimate then return end
    local values = A.PlayerInfo:CanShow(frame) and A.CombatStats:Ultimate(frame.unitTag) or nil
    local bar = frame.healthBar.barControls[1]
    local raid = frame.style == "ZO_RaidUnitFrame"
    local shown = 0
    for i, slot in ipairs(data.ultimate) do
        local value = values and values[i]
        if value and DoesAbilityExist(value.abilityId) then
            -- Hodor's misc list uses this exact native resolver. No second ID map.
            if slot.abilityId ~= value.abilityId then
                slot.abilityId = value.abilityId
                slot.texture = GetAbilityIcon(value.abilityId)
                if type(slot.texture) == "string" and slot.texture ~= "" then slot.icon:SetTexture(slot.texture) end
            end
            local path = type(slot.texture) == "string" and slot.texture:lower():gsub("^/", "") or ""
            local missing = ZO_NO_TEXTURE_FILE:lower():gsub("^/", "")
            if path ~= "" and path ~= missing then
                slot.root:ClearAnchors()
                if raid then
                    slot.root:SetAnchor(BOTTOMRIGHT, bar, BOTTOMRIGHT, -3 - shown * (SIZE + GAP), 0)
                else
                    slot.root:SetAnchor(TOPRIGHT, bar, BOTTOMRIGHT, -shown * (SIZE + GAP), 1)
                end
                slot.root:SetAlpha(IsUnitInGroupSupportRange(frame.unitTag) and 1 or 0.3)
                slot.icon:SetDesaturation(value.ready == false and 0.8 or 0)
                slot.icon:SetAlpha(value.ready == true and 1 or (value.ready == false and 0.45 or 0.75))
                local text = tostring(math.floor(value.points))
                if slot.lastPoints ~= text then slot.points:SetText(text); slot.lastPoints = text end
                slot.root:SetHidden(false)
                shown = shown + 1
            else slot.root:SetHidden(true) end
        else slot.root:SetHidden(true) end
    end
    local reserve = shown > 0 and shown * (SIZE + GAP) + 3 or 0
    local width = math.max(0, bar:GetWidth() - (raid and 8 or 0))
    data.stats:SetWidth(math.max(0, width - reserve))
    -- CP is on the name row, independent of the bottom-right Ultimate icons.
end
