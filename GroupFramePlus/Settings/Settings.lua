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
    local function description(key) options[#options + 1] = { type = "description", text = A:T(key) } end
    local function checkbox(key, tooltip)
        options[#options + 1] = { type = "checkbox", name = A:T(key), tooltip = tooltip and A:T(tooltip),
            getFunc = function() return A.sv[key] end,
            setFunc = function(value) A.sv[key] = value; A:ApplySettings() end,
            default = A.defaults[key], disabled = function() return key ~= "enabled" and not A.sv.enabled end }
    end
    header("general"); checkbox("enabled"); checkbox("sort", "sortTip")
    header("interactionSection"); checkbox("interaction"); checkbox("contextMenu")
    header("info"); description("infoTip")
    for _, key in ipairs({ "account", "class", "level", "cp" }) do checkbox(key) end
    header("colors")
    for _, entry in ipairs({ { "tank", LFG_ROLE_TANK }, { "healer", LFG_ROLE_HEAL }, { "damage", LFG_ROLE_DPS } }) do
        local key, role = entry[1], entry[2]
        local default = A.defaults.colors[role]
        options[#options + 1] = { type = "colorpicker", name = A:T(key),
            getFunc = function() return unpack(A.sv.colors[role]) end,
            setFunc = function(r, g, b)
                A.sv.colors[role] = { r, g, b, 1 }
                A.sv.customColors[role] = math.abs(r - default[1]) > 0.00001
                    or math.abs(g - default[2]) > 0.00001 or math.abs(b - default[3]) > 0.00001
                A:ApplySettings()
            end,
            default = { r = default[1], g = default[2], b = default[3], a = 1 } }
    end
    options[#options + 1] = { type = "button", name = A:T("restore"), func = function()
        for role in pairs(A.roleResources) do A.sv.colors[role] = A:ResourceColor(role) end
        A.sv.customColors = {}; A:ApplySettings()
        CALLBACK_MANAGER:FireCallbacks("LAM-RefreshPanel", self.panel)
    end }
    header("stats"); description("statsTip"); checkbox("dps"); checkbox("hps"); checkbox("hodor", "hodorTip")
    header("shields"); checkbox("shield", "shieldTip")
    options[#options + 1] = { type = "colorpicker", name = A:T("shieldColor"),
        getFunc = function() return unpack(A.sv.shieldColor) end,
        setFunc = function(r, g, b) A.sv.shieldColor = { r, g, b }; A:ApplySettings() end,
        default = { r = .5, g = .5, b = 1, a = 1 } }
    options[#options + 1] = { type = "slider", name = A:T("shieldOpacity"), min = 0, max = 100, step = 1,
        getFunc = function() return A.sv.shieldOpacity * 100 end,
        setFunc = function(value) A.sv.shieldOpacity = value / 100; A:ApplySettings() end, default = 45 }
    LAM:RegisterOptionControls(A.name .. "Panel", options)
end
