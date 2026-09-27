local A = GroupFramePlus
local F = { cache = {}, coloring = false }
A.Frames = F
function F:Color(frame)
    if self.coloring or not frame.healthBar then return end
    self.coloring = true
    frame.healthBar:SetColor(COMBAT_MECHANIC_FLAGS_HEALTH, A.active and A:RoleGradient(frame.unitTag) or nil)
    self.coloring = false
end
function F:Attach(frame)
    if not A.GroupData:IsPlayerFrame(frame) or not frame.frame or not frame.nameLabel
        or not frame.healthBar or not frame.healthBar.barControls or not frame.healthBar.barControls[1] then return end
    if not self.cache[frame] then
        self.cache[frame] = A.PlayerInfo:Create(frame)
        A.Interaction:Attach(frame)
        if not A.RoleSorting.anchors[frame] then A.RoleSorting:Capture(frame) end
        ZO_PostHook(frame.healthBar, "SetColor", function() if A.active then self:Color(frame) end end)
    end
    self:Color(frame)
    A.PlayerInfo:Update(frame, self.cache[frame])
end
function F:Refresh()
    if not A.supported then return end
    local members = A.GroupData:Members()
    for _, member in ipairs(members) do self:Attach(UNIT_FRAMES:GetFrame(member.tag)) end
    for frame, data in pairs(self.cache) do
        if not A.active or UNIT_FRAMES:GetFrame(frame.unitTag) ~= frame or not DoesUnitExist(frame.unitTag) then
            data.info:SetHidden(true)
            data.stats:SetHidden(true)
            if not A.active then self:Color(frame) end
        end
    end
    A.ShieldOverlay:Refresh()
    if A.sortDirty then
        A.sortDirty = false
        A.RoleSorting:Apply(members)
    end
end
function F:UpdateStats()
    for frame, data in pairs(self.cache) do
        if UNIT_FRAMES and UNIT_FRAMES:GetFrame(frame.unitTag) == frame then A.PlayerInfo:Stats(frame, data) end
    end
end
function F:Initialize()
    local function refresh(frame)
        if A.GroupData:IsPlayerFrame(frame) then A:QueueRefresh(false) end
    end
    ZO_PostHook(ZO_UnitFrameObject, "SetAnchor", function(frame)
        if A.GroupData:IsPlayerFrame(frame) then
            A.RoleSorting:Capture(frame)
            A:QueueRefresh(true)
        end
    end)
    for _, method in ipairs({ "ApplyVisualStyle", "UpdateName", "UpdateLevel", "UpdateStatus", "UpdateAssignment", "DoAlphaUpdate" }) do
        ZO_PostHook(ZO_UnitFrameObject, method, refresh)
    end
    ZO_PostHook("ZO_UnitFrames_UpdateWindow", function(tag)
        if tag and tag:match("^group%d+$") then A:QueueRefresh(false) end
    end)
end
