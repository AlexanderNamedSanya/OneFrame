local A = GroupFramePlus
local R = { anchors = {}, applying = false, revision = 0 }
A.RoleSorting = R
local priorities = { [LFG_ROLE_TANK] = 1, [LFG_ROLE_HEAL] = 2, [LFG_ROLE_DPS] = 3 }
function R:Capture(frame)
    if self.applying or not A.GroupData:IsPlayerFrame(frame) then return end
    local anchors = {}
    for i = 0, frame.frame:GetNumAnchors() - 1 do
        local valid, point, relative, relativePoint, x, y, constraints = frame.frame:GetAnchor(i)
        if valid then anchors[#anchors + 1] = { point, relative, relativePoint, x, y, constraints } end
    end
    local previous = self.anchors[frame]
    local changed = not previous or #previous ~= #anchors
    if not changed then
        for i, anchor in ipairs(anchors) do
            for j = 1, 6 do if anchor[j] ~= previous[i][j] then changed = true end end
        end
    end
    self.anchors[frame] = anchors
    -- A native anchor write may replace our sorted position even when its native
    -- target is unchanged. Invalidate only on actual native calls, never our writes.
    self.revision = self.revision + 1
    return changed
end
function R:Restore()
    if not self.sorted then return end
    self.applying = true
    for frame, anchors in pairs(self.anchors) do
        if #anchors > 0 then
            frame.frame:ClearAnchors()
            for _, anchor in ipairs(anchors) do frame.frame:SetAnchor(unpack(anchor, 1, 6)) end
        end
    end
    self.applying = false
    self.sorted = false
    self.signature = nil
end
function R:Apply(members)
    -- Companion frames can be interleaved and native drag/drop uses index slots.
    -- Keep vanilla positioning in those modes rather than corrupt its layout contracts.
    if not A.active or not A.sv.sort or IsUnitInCombat("player")
        or UNIT_FRAMES:GetCompanionGroupSize() > 0
        or not (SCENE_MANAGER:IsShowing("hud") or SCENE_MANAGER:IsShowing("hudui")) then self:Restore(); return end
    local keys = {tostring(self.revision)}
    if #members < GetGroupSize() then return end
    for _, member in ipairs(members) do
        local frame = UNIT_FRAMES:GetFrame(member.tag)
        -- Zone transitions can temporarily remove/hide one native frame. Keep the
        -- last complete layout until all frame objects exist; hidden frames retain slots.
        if not frame or not self.anchors[frame] then return end
        keys[#keys + 1] = table.concat({member.tag, member.identity, tostring(member.role),
            tostring(UNIT_FRAMES:GetFrame(member.tag))}, ":")
    end
    local signature = table.concat(keys, "|")
    if self.sorted and self.signature == signature then return end
    self:Restore()
    local slots, sorted = {}, {}
    for _, member in ipairs(members) do
        local frame = UNIT_FRAMES:GetFrame(member.tag)
        local control, parent = frame.frame, frame.frame:GetParent()
        slots[#slots + 1] = { parent, control:GetLeft() - parent:GetLeft(), control:GetTop() - parent:GetTop() }
        sorted[#sorted + 1] = { member = member, frame = frame }
    end
    table.sort(sorted, function(a, b)
        local ar, br = priorities[a.member.role] or 4, priorities[b.member.role] or 4
        if ar ~= br then return ar < br end
        -- Account identity is stable across unitTag reassignment and composition changes.
        if a.member.identity ~= b.member.identity then return a.member.identity < b.member.identity end
        return a.member.index < b.member.index
    end)
    self.applying = true
    for i, entry in ipairs(sorted) do
        local slot = slots[i]
        entry.frame.frame:ClearAnchors()
        entry.frame.frame:SetAnchor(TOPLEFT, slot[1], TOPLEFT, slot[2], slot[3])
    end
    self.applying = false
    self.sorted, self.signature = true, signature
end
