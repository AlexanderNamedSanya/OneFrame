local A = GroupFramePlus
local U = {}
A.UltimateUI = U
function U:Create(frame)
    local points = WINDOW_MANAGER:CreateControl(frame.frame:GetName() .. "GFPUltimatePoints", frame.frame, CT_LABEL)
    points:SetFont("$(BOLD_FONT)|16|thick-outline")
    points:SetDimensions(30, points:GetFontHeight() + 2)
    points:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
    points:SetMouseEnabled(false)
    points:SetDrawLayer(DL_OVERLAY)
    points:SetHidden(true)
    return { points = points }
end
function U:Hide(data)
    if data then data.points:SetHidden(true) end
end
function U:Update(frame, data)
    if not data.ultimate then return end
    local values = A.PlayerInfo:CanShow(frame) and A.CombatStats:Ultimate(frame.unitTag) or nil
    local current, progress
    for _, value in ipairs(values or {}) do
        current = value.points
        if value.progress then progress = math.max(progress or 0, value.progress) end
    end
    local label = data.ultimate.points
    local bar = frame.healthBar.barControls[1]
    local raid = frame.style == "ZO_RaidUnitFrame"
    label:SetHidden(current == nil)
    if current ~= nil then
        label:ClearAnchors()
        label:SetAnchor(raid and BOTTOMRIGHT or TOPRIGHT, bar, BOTTOMRIGHT, raid and -3 or 0, raid and -1 or 1)
        label:SetAlpha(IsUnitInGroupSupportRange(frame.unitTag) and 1 or 0.3)
        local text = tostring(math.floor(current))
        if data.ultimate.lastPoints ~= text then label:SetText(text); data.ultimate.lastPoints = text end
        if progress then
            label:SetColor(math.min(1, 2 * (1 - progress)), math.min(1, 2 * progress), 0, 1)
        else label:SetColor(0.85, 0.85, 0.85, 1) end
    end
    local width = bar:GetWidth() - (raid and 8 or 0)
    data.stats:SetWidth(math.max(0, width - (current ~= nil and 34 or 0) - (data.statsCaption and 23 or 0)))
end
