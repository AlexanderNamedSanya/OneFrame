# Design system

The ESO vanilla group frame is the design system. Preserve its dimensions, textures,
name position, HP animations, leader/role/election indicators and status messages.

- Tank: native Health gradient; healer: native Magicka; damage: native Stamina.
  Unknown roles fall back to Health. Custom colors affect tint only.
- Class: `ZO_GetClassIcon(GetUnitClassId(unitTag))`, embedded as a 12 px native icon.
  Never print a class name.
- Extra information occupies a short line above the small-group name or the raid's
  middle line. Icon and level/CP precede optional, truncatable account names.
- Statistics sit at the bottom; narrow raid frames use the native medium font at 10 px.
  Small groups use `ZoFontGameSmall`; Cyrillic uses ESO font fallback.
- Statistics labels: DPS/HPS (EN), ДПС/ХПС (RU). Integers below 1000, one decimal plus
  `k` for thousands, two decimals plus `m` for millions. Missing is `—`; explicit zero
  is `0`. Shared effective HPS differs from raw local fallback, as explained in settings.
- Added labels are subdued, mouse-transparent and fade outside group support range.
  Hide both added lines when the native status label is visible or the unit is dead/offline.
- Shields use the native overlay geometry and textures. Default enhanced color is
  blue-violet at 45% opacity; both are configurable. Disabling enhancement restores
  ESO's own gradient, including its endpoint alpha differences.
- No new buttons, borders or hover decorations. Right click uses ESO's standard menu.
- English fallback and Russian translations apply to every added label, setting,
  description, menu item and compatibility message. Product name is language-neutral.

Dense raid layouts cannot guarantee fully visible long names and both long statistics
labels without enlarging vanilla frames. Truncation takes priority over resizing.
Review keyboard/gamepad styles, Cyrillic text and UI scaling in the client.
