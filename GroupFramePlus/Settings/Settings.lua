local A = GroupFramePlus
A.Settings = {}
function A.Settings:Initialize()
    local LAM = LibAddonMenu2
    if not LAM then return end -- Manifest normally prevents this; never fail on a missing menu.
    self.panel = LAM:RegisterAddonPanel(A.name .. "Panel", {
        type = "panel", name = "GroupFrame+", displayName = "GroupFrame+", author = "GroupFramePlus contributors",
        version = A.version, registerForRefresh = true, registerForDefaults = true,
    })
    local options = {}
    local function header(key) options[#options + 1] = { type = "header", name = A:T(key) } end
    local function checkbox(key, get, set, default)
        options[#options + 1] = { type = "checkbox", name = A:T(key),
            getFunc = get or function() return A.sv[key] end,
            setFunc = function(value)
                if set then set(value) else A.sv[key] = value end
                A:ApplySettings()
            end,
            default = default == nil and A.defaults[key] or default }
    end
    header("general")
    checkbox("sort")
    checkbox("contextMenu", function() return A.sv.interaction and A.sv.contextMenu end,
        function(value) A.sv.interaction = value; A.sv.contextMenu = value end, true)
    header("display")

    for _, entry in ipairs({ { "tankRole", LFG_ROLE_TANK }, { "healerRole", LFG_ROLE_HEAL }, { "damageRole", LFG_ROLE_DPS } }) do
        local role = entry[2]
        local default = A.defaults.colors[role]
        options[#options + 1] = { type = "colorpicker", name = A:T(entry[1]), width = "half",
                getFunc = function() return unpack(A.sv.colors[role]) end,
                setFunc = function(r, g, b)
                    A.sv.colors[role] = {r, g, b, 1}
                    A.sv.customColors[role] = math.abs(r-default[1]) > 0.00001
                        or math.abs(g-default[2]) > 0.00001 or math.abs(b-default[3]) > 0.00001
                    A:ApplySettings()
                end,
                default = {r=default[1], g=default[2], b=default[3], a=1} }
        options[#options + 1] = { type = "dropdown", name = A:T("showStatistic"), width = "half",
                choices = {A:T("dpsLabel"), A:T("hpsLabel"), A:T("nothing")},
                choicesValues = {"dps", "hps", "none"},
                getFunc = function() return A:RoleStatistic(role) end,
                setFunc = function(value) A.sv.roleStats[role] = value; A:ApplySettings() end,
                default = "none" }
    end
    options[#options + 1] = { type = "colorpicker", name = A:T("shieldColor"),
        getFunc = function() return unpack(A.sv.shieldColor) end,
        setFunc = function(r, g, b) A.sv.shieldColor = {r, g, b}; A.sv.shield = true; A:ApplySettings() end,
        default = {r=.5, g=.5, b=1, a=1} }
    checkbox("class")
    checkbox("levelCP", function() return A.sv.level or A.sv.cp end,
        function(value) A.sv.level = value; A.sv.cp = value end, true)
    LAM:RegisterOptionControls(A.name .. "Panel", options)
end
