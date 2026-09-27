local A = GroupFramePlus
A.roleResources = {
    [LFG_ROLE_TANK] = COMBAT_MECHANIC_FLAGS_HEALTH,
    [LFG_ROLE_HEAL] = COMBAT_MECHANIC_FLAGS_MAGICKA,
    [LFG_ROLE_DPS] = COMBAT_MECHANIC_FLAGS_STAMINA,
}
function A:ResourceColor(role)
    local resource = self.roleResources[role] or COMBAT_MECHANIC_FLAGS_HEALTH
    return { ZO_POWER_BAR_GRADIENT_COLORS[resource][1]:UnpackRGBA() }
end
function A:MakeDefaults()
    local colors = {}
    for role in pairs(self.roleResources) do colors[role] = self:ResourceColor(role) end
    return {
        enabled = true, sort = false, account = false, class = true, level = true, cp = true,
        colors = colors, customColors = {}, dps = false, hps = false, hodor = true,
        shield = true, shieldColor = { 0.5, 0.5, 1 }, shieldOpacity = 0.45,
        interaction = true, contextMenu = true,
    }
end
function A:RoleGradient(tag)
    local role = GetGroupMemberSelectedRole(tag)
    if self.sv.customColors[role] and self.sv.colors[role] then
        local color = ZO_ColorDef:New(unpack(self.sv.colors[role]))
        return { color, color }
    end
    return ZO_POWER_BAR_GRADIENT_COLORS[self.roleResources[role] or COMBAT_MECHANIC_FLAGS_HEALTH]
end
