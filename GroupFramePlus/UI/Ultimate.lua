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
    local fill = WINDOW_MANAGER:CreateControl(name .. "Fill", frame.frame, CT_TEXTURE)
    for _, control in ipairs({track, fill}) do
        control:SetMouseEnabled(false)
        control:SetDrawLayer(DL_OVERLAY)
        control:SetDrawLevel(10)
    end
    track:SetHidden(true)
    fill:SetHidden(true)
    fill:SetAnchor(BOTTOMLEFT, track, BOTTOMLEFT, 0, 0)
    return { track = track, fill = fill }
end
function U:Hide(data)
    if data then data.track:SetHidden(true); data.fill:SetHidden(true) end
end
function U:Update(frame, data)
    if not data.ultimate then return end
    local state = data.ultimate
    local identity = DoesUnitExist(frame.unitTag)
        and (GetUnitDisplayName(frame.unitTag) .. ":" .. GetUnitName(frame.unitTag)) or nil
    if state.identity ~= identity then state.identity, state.lastPoints = identity, nil end
    local visible = A.PlayerInfo:CanShow(frame) and A.sv.ultimate and A.sv.hodor
    if not visible then state.lastPoints = nil end
    local values = visible and A.CombatStats:Ultimate(frame.unitTag) or nil
    local current = values and values[1] and values[1].points
    if current ~= nil then state.lastPoints = current end
    current = visible and state.lastPoints or nil
    local track, fill = data.ultimate.track, data.ultimate.fill
    track:SetHidden(current == nil)
    fill:SetHidden(current == nil)
    if current == nil then return end
    current = math.max(0, math.min(500, current))
    local bar = frame.healthBar.barControls[1]
    local raid = frame.style == "ZO_RaidUnitFrame"
    local width = math.max(1, bar:GetWidth() - 2)
    track:ClearAnchors()
    track:SetAnchor(BOTTOMLEFT, bar, BOTTOMLEFT, 1, raid and 0 or 22)
    track:SetDimensions(width, 4)
    local r, g, b = self:Color(current)
    track:SetColor(0, 0, 0, 0)
    track:SetAlpha(A.PlayerInfo:Alpha(frame))
    fill:SetAlpha(A.PlayerInfo:Alpha(frame))
    fill:SetColor(r, g, b, 1)
    fill:SetDimensions(math.max(1, width * current / 500), 4)
end
