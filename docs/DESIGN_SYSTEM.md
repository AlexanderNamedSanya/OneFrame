# Design system

1.5.6: Ultimate track is fully transparent (color alpha 0); only the independently parented colored fill is visible.

1.5.5: retain last received DPS/HPS for 300 seconds after local combat ends. Cache validates account and character, resets on new combat/roster/zone, and never invents missing metrics. Local statistics timer continues until expiration. Ultimate remains live data.

1.5.4: native writes of unchanged anchors synchronously recover cached sorted positions, guarded by identity/tag/style/group size. Changed layouts still defer to coalesced sorting. Scene transitions defer instead of restoring native order; companions and disabling sorting still restore.

1.5.3: startup enables Ultimate regardless of the obsolete hidden toggle (installed saved variables had ultimate=false). Missing receipts still hide the strip. Lower captions, rate/HP values and Ultimate strip move down 3px together to preserve clearance.

1.5.2: Ultimate is a horizontal 4px strip along the bottom, filling left-to-right over 0–500 points. Native bar width minus 2px; raid statistics/HP move up 4px for clearance. Small-group strip sits below the statistics row. Colors, missing-data hiding and distance alpha remain unchanged.

1.5.1: statistics use all space up to the measured health text width, with a 3px gap and 7px right inset. Removes the oversized fixed HP reservation without changing fonts or frame size.

1.5.0: settings show only General (sorting/context menu), Display (Roles with color and DPS/HPS/none for each role, shield color, class icon, combined level/CP). roleStats migrates previous DPS/HPS preferences; aggregate flags continue to configure data collection. Hidden preferences are retained.

1.4.5 adds Update 51/API 101051 alongside 101050. Runtime API gate and manifest agree.
Reference audit: ESO 12.1.4, commit 1baf1131560c2bcd38ffd2bd070728273b25f934 (pts12.1).
Group frame methods/geometry remain compatible; new HUD editor moves native anchor containers, which sorting already preserves. Live-client verification is pending.

Small-group leader outline includes the native role icon with left padding (38 px keyboard / 58 px gamepad), plus 4 px right clearance; raid bounds stay unchanged.

1.4.4: missing DPS/HPS hides both caption and value (real zero remains visible).
No crown indentation is allowed while enabled. Ultimate strip uses overlay level 10
and independently faded fill, with no ability-ID prerequisite for received points.

1.4.3: dead members never show the added HP value. Offline members show no added
information: class/name decoration, level, rates/captions, health, Ultimate strip and
gold outline are hidden/restored to native appearance. Native name/status remain.

1.4.1: replace the group leader crown with a 2 px gold outline (RGB 1, 0.76, 0.18).
The outline has no fill, is mouse-transparent and follows native distance fading.
Remove the native crown's name indentation while enabled; preserve the five-character
raid-leader nickname limit. Small-group outline follows visible bar/name geometry.

1.4.0 supersedes the Ultimate number: a 3 px vertical strip at the right edge fills
bottom-up over 0–500 points. RGB anchors are red at 0, yellow at 175, green at 500,
linearly interpolated on each interval. A 1 px red mark represents received zero;
missing data hides the strip. Current health appears bottom-right as 25.4k / 25.4к.
All addon-owned data controls take alpha from the native health bar on refresh.

1.3.1: class icons are 16 px in both layouts. Raid leader nicknames are limited to
five Unicode characters (excluding @); other raid members retain seven characters.

## Current layout (1.2.9)

Small-group refinement (1.3.0): level/CP anchors 4 px above the health bar's right
edge, not the oversized root control. Names use 16 px. The row below health has a
10 px caption, 16 px value at x=30 and the 16 px Ultimate counter at the right edge,
both numbers at y=4. Native backgrounds, role/leader indicators and bars remain intact.

The latest user request supersedes the earlier icon presentation below: Ultimate has
no ability textures, only one 16 px readiness-colored number at the bottom right.
The 16 px DPS/HPS value shares its bottom baseline, with a 9 px caption at the left.
Name/class and numeric level stay on the upper row. The freed icon space goes to the
rate value; the counter reserves 34 px, with a 3 px right inset and 1 px bottom inset.

The ESO vanilla group frame is the design system. Preserve its dimensions, textures,
name position, HP animations, leader/role/election indicators and status messages.

- Tank: native Health gradient; healer: native Magicka; damage: native Stamina.
  Unknown roles fall back to Health. Custom colors affect tint only.
- Class: `ZO_GetClassIcon(GetUnitClassId(unitTag))`, prefixed to the native name as a 12 px icon.
  Never print a class name.
- Level/CP is right-aligned in the upper-right corner beside the name. Name width
  reserves the measured CP text width; long names truncate. Account preference applies
  to the name line. Raid names use a 16 px font, restored when disabled.
  Rates and Ultimate remain at the bottom, independently of CP.
  Raid nicknames show the first seven Unicode characters, excluding the @ prefix.
  Name width no longer loses the excessive 24 px padding previously reserved for CP.
- Statistics sit at the bottom; raid CP and statistics use the native bold font at 12 px.
- Rate typography now uses two mouse-transparent labels: a 9 px DPS/HPS caption and
  a 16 px bold numeric value. CP retains its existing size. Both hide together.
  Small groups use `ZoFontGameSmall`; Cyrillic uses ESO font fallback.
- Damage roles show DPS, healers HPS, tanks no rate label. Ultimate is independent of
  these toggles and available to every role. Each shared ability uses its actual ESO
  texture at 20 px. One shared outlined 13 px point label sits to the left of the icons
  in the lower-right area. The counter's right-center anchors to the left-center of the
  leftmost visible icon, with a 2 px gap. It transitions red-yellow-green using the best reliably
  known readiness across the displayed abilities; unknown costs produce neutral grey.
  Both distinct shared abilities appear when available; identical IDs collapse to one.
  Not-ready icons are dim/desaturated, ready icons full brightness, uncertain readiness
  neutral. Missing data hides the element; a received zero remains visible. All added
  controls are mouse-transparent and existing text yields space to the icons.
  Icon textures use DL_CONTROLS; point labels use DL_OVERLAY above them, with explicit
  24 px width, font-based height and right alignment. This avoids hiding text behind art.
- Level/CP displays digits only. Champion points are white; ordinary levels are green.
- Statistics labels: DPS/HPS (EN), ДПС/ХПС (RU). Integers below 1000, one decimal plus
  `k` for thousands, two decimals plus `m` for millions. Missing is `—`; explicit zero
  is `0`. Shared effective HPS differs from raw local fallback, as explained in settings.
- Added labels are subdued, mouse-transparent and fade outside group support range.
  Hide added lines when a nonempty native status message is visible or the unit is dead/offline.
  Empty status controls must not hide information. Label height follows GetFontHeight()
  with two pixels of padding; text uses the native text drawing layer.
- Shields use the native overlay geometry and textures. Default enhanced color is
  blue-violet at 45% opacity; both are configurable. Disabling enhancement restores
  ESO's own gradient, including its endpoint alpha differences.
- No new buttons, borders or hover decorations. Right click uses ESO's standard menu.
- English fallback and Russian translations apply to every added label, setting,
  description, menu item and compatibility message. Product name is language-neutral.

Dense raid layouts cannot guarantee fully visible long names, Ultimate icons and statistics
labels without enlarging vanilla frames. Truncation takes priority over resizing.
Review keyboard/gamepad styles, Cyrillic text and UI scaling in the client.
