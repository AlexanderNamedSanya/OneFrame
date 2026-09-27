local A = GroupFramePlus
local U = {}
A.UltimateUI = U
function U:Color(points)
    if points <= 175 then return 1, points / 175, 0 end
    return 1 - (points - 175) / 325, 1, 0
end
function U:Create(frame)
    local name = frame.frame:GetName() .. "GFPUltimate"
    local track = WINDOW_MANAGER:CreateControl(name .. "Track", frame.frame, CT_TEXTURE)
    local fill = WINDOW_MANAGER:CreateControl(name .. "Fill", track, CT_TEXTURE)
    for _, control in ipairs({track, fill}) do
        control:SetMouseEnabled(false)
        control:SetDrawLayer(DL_OVERLAY)
    end
    track:SetHidden(true)
    fill:SetAnchor(BOTTOMLEFT, track, BOTTOMLEFT, 0, 0)
    return { track = track, fill = fill }
end
function U:Hide(data)
    if data then data.track:SetHidden(true) end
end
function U:Update(frame, data)
    if not data.ultimate then return end
    local values = A.PlayerInfo:CanShow(frame) and A.CombatStats:Ultimate(frame.unitTag) or nil
    local current = values and values[1] and values[1].points
    local track, fill = data.ultimate.track, data.ultimate.fill
    track:SetHidden(current == nil)
    if current == nil then return end
    current = math.max(0, math.min(500, current))
    local bar = frame.healthBar.barControls[1]
    local raid = frame.style == "ZO_RaidUnitFrame"
    local height = raid and bar:GetHeight() - 2 or 42
    height = math.max(1, height)
    track:ClearAnchors()
    track:SetAnchor(BOTTOMRIGHT, bar, BOTTOMRIGHT, 0, raid and -1 or 22)
    track:SetDimensions(3, height)
    local r, g, b = self:Color(current)
    track:SetColor(r, g, b, 0.2)
    track:SetAlpha(A.PlayerInfo:Alpha(frame))
    fill:SetColor(r, g, b, 1)
    fill:SetDimensions(3, math.max(1, height * current / 500))
end
