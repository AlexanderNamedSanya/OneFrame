local S = GroupFramePlus.strings
local en = {
    general = "General", enabled = "Enable addon", sort = "Sort group by role",
    sortTip = "Tanks, healers, damage dealers, then unknown roles. Visual positions only. Sorting is suspended with companions, during combat and in group-frame rearrangement mode.",
    info = "Player information", account = "Show account/display name", class = "Show class icon",
    level = "Show level", cp = "Show Champion Points", cpValue = "CP %d", levelValue = "%d",
    colors = "Role colors", tank = "Tank color", healer = "Healer color", damage = "Damage Dealer color",
    restore = "Restore vanilla resource colors",
    stats = "Combat statistics", dps = "Show DPS", hps = "Show HPS", dpsLabel = "DPS", hpsLabel = "HPS",
    unavailable = "—", kilo = "%.1fk",
    statsTip = "Local player's direct outgoing damage and raw healing event values per combat second (minimum 1 second). Not an effective-healing meter; excludes pets, companions and shield absorption. Other members: unavailable. Final values remain until the next combat or zone change.",
    shields = "Damage shields", shield = "Show damage shields", shieldColor = "Shield color", shieldOpacity = "Shield opacity",
    shieldTip = "Enable enhanced colors on the existing vanilla shield overlay. Disabled restores the vanilla shield presentation; ESO's shields, trauma and healing restrictions remain functional.",
    infoTip = "Details use a compact line inside the frame; statistics use the bottom. No vanilla frame is resized. Status messages take priority over added text.",
    interactionSection = "Interaction", interaction = "Enable frame interaction", contextMenu = "Right-click context menu",
    whisper = "Whisper", travel = "Travel to Player", remove = "Remove from Group",
    unsupported = "GroupFrame+: this ESO UI version is not verified; frame enhancements are disabled.",
    missing = "GroupFrame+: vanilla frame support is unavailable; enhancements were not attached.",
}
for key, value in pairs(en) do S[key] = value end
