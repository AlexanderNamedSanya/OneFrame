local S = GroupFramePlus.strings
local en = {
    general = "General", enabled = "Enable addon", sort = "Sort group by role",
    sortTip = "Tanks, healers, damage dealers, then unknown roles. Visual positions only. Sorting is suspended with companions, during combat and in group-frame rearrangement mode.",
    info = "Player information", account = "Show account/display name", class = "Show class icon",
    level = "Show level", cp = "Show Champion Points", cpValue = "CP %d", levelValue = "%d",
    colors = "Role colors", tank = "Tank color", healer = "Healer color", damage = "Damage Dealer color",
    restore = "Restore vanilla resource colors",
    stats = "Combat statistics", dps = "Show DPS", hps = "Show HPS", dpsLabel = "DPS", hpsLabel = "HPS",
    unavailable = "—", kilo = "%.1fk", million = "%.2fm",
    hodor = "Use Hodor Reflexes data",
    hodorTip = "Read existing shared DPS and effective HPS through Hodor's LibGroupCombatStats dependency. No extra broadcasting. Requires the verified Hodor 2026-05-17 / library 2026-07-26 versions. Missing, stale or incompatible data shows — for other members.",
    statsTip = "Shared data takes priority independently for DPS/HPS. Local fallback measures direct outgoing damage/raw healing only (not effective HPS), without pets, companions or shield absorption. Shared values expire after 10 seconds without updates and reset with combat/group/zone changes. No measurement is shown as —; a received zero remains 0.",
    shields = "Damage shields", shield = "Show damage shields", shieldColor = "Shield color", shieldOpacity = "Shield opacity",
    shieldTip = "Enable enhanced colors on the existing vanilla shield overlay. Disabled restores the vanilla shield presentation; ESO's shields, trauma and healing restrictions remain functional.",
    infoTip = "Details use a compact line inside the frame; statistics use the bottom. No vanilla frame is resized. Status messages take priority over added text.",
    interactionSection = "Interaction", interaction = "Enable frame interaction", contextMenu = "Right-click context menu",
    whisper = "Whisper", travel = "Travel to Player", remove = "Remove from Group",
    unsupported = "GroupFrame+: this ESO UI version is not verified; frame enhancements are disabled.",
    missing = "GroupFrame+: vanilla frame support is unavailable; enhancements were not attached.",
}
for key, value in pairs(en) do S[key] = value end
