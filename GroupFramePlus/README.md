# GroupFrame+ 1.0.0

Enhances ESO's vanilla group and raid frames without replacing their controls,
textures, health animations, names, leader icons, ready checks or status indicators.
Supports English and Russian; other client languages use English.

## Installation / Установка

1. Install **LibAddonMenu-2.0**, including dependencies declared by that library,
   through your addon manager or [ESOUI](https://www.esoui.com/downloads/info7-LibAddonMenu.html).
2. Copy the **GroupFramePlus** folder to
   `Documents/Elder Scrolls Online/live/AddOns/` (use your actual ESO documents folder).
3. Confirm `AddOns/GroupFramePlus/GroupFramePlus.txt` exists, enable the addon,
   and reload the UI. Open **Settings → Addons → GroupFrame+**.

Скопируйте папку **GroupFramePlus** в `Documents/Elder Scrolls Online/live/AddOns/`,
установите **LibAddonMenu-2.0**, включите аддон и выполните `/reloadui`.
Настройки: **Настройки → Дополнения → GroupFrame+**. Настройки общие для аккаунта.

## Features and settings

- General: enable/disable; optional visual sorting (tank → healer → damage → unknown).
- Interaction: enable/disable frame interaction and the right-click menu independently.
  Whisper opens native chat input; Travel calls native group travel. Remove appears
  only for a leader with direct removal permission, never for oneself or in a vote-kick group.
- Player information: independent account name, native class icon, level and CP toggles.
  CP replaces level for Champion characters. Long account names truncate in compact frames.
- Role colors: vanilla Health/Magicka/Stamina gradients by default; independent custom
  colors and a button to restore native resource gradients. Unknown roles use Health.
- Combat statistics: optional DPS/HPS, updated twice per second during local combat.
- Damage shields: recolor the **existing shield overlay over the health bar**, including
  opacity. No second shield bar and no extra health polling are introduced.

Sort, account name and combat statistics are off initially. Other enhancements
are enabled. Disabling the addon in its settings restores native colors/anchors,
hides added text, disables menu actions and unregisters combat collection.

## Compatibility and deliberate limits

This release is source-verified for **API 101050 (ESO 12.0.8)**. Other API versions
leave frames unchanged and show one localized message. No live-client validation
has yet been performed; use the repository's acceptance checklist before release.
Other addons replacing group frames are outside the compatibility scope.

**DPS/HPS are local-player-only measurements.** Remote members display `—`, not zero.
The normal combat API does not provide a complete attributable stream of every other
member's outgoing damage/healing. No health-change estimates, combat-name matching,
group data transmission or fabricated values are used.

The local meter sums reported outgoing damage/critical/DoT/blocked-damage events and
heal/critical/HoT events from `COMBAT_UNIT_TYPE_PLAYER`. It divides by time since local
combat began, with a one-second minimum. HPS uses raw event `hitValue`, not an estimate
of effective healing. Pet/companion contributions, shield absorption and unlisted
result categories are excluded. These values are **not full encounter-log DPS/HPS**.
The last result remains after combat, resets at the next local combat, activation/zone
transition, reload, or when collection is disabled. Enabling statistics mid-fight
measures only the period after enabling them.

**Shield checkbox:** disabling enhancement restores ESO's native shield rendering;
it does not suppress vanilla shields. This is intentional: native overlay children
also render trauma and healing restrictions. Native code owns shield values, clipping,
overflow, death/offline behavior and animations. Shield amounts above maximum health
saturate the native bar; this is not a numeric shield counter. Very small shields use
ESO's native visibility threshold. Role colors also apply to the native fake-health
layer used underneath shields so the HP color does not revert during shielding.

**Sorting:** changes anchors only, never unit tags or manager tables. Same-role order
uses account names as a deterministic stable key. Native positioning is restored
during combat, outside HUD/cursor HUD scenes and whenever companions are present.
Sorting resumes after those conditions clear. These restrictions preserve native
companion layout and group management behavior. No sorting runs on a render-frame loop.

**Interaction:** native handlers always execute. A right click that cancels a drag
does not open a menu. An existing menu created during that click takes precedence.
Actions validate the current frame, current membership and account/character identity
again when selected; outdated menus become no-ops. Travel failures use ESO's native
feedback. The addon adds no visible interaction controls. Mouse operation is intended
for PC keyboard/mouse, including cursor mode; gamepad-only navigation is not added.

**Layout:** added text stays compact and yields to death/offline/status messages.
Raid text is deliberately small and can truncate, particularly with long Russian
labels. Frame sizes and native label positions are unchanged. No class names are shown.

Ограничения: УВС/ЛВС рассчитываются только для своего персонажа; у союзников — «—».
Выключение щитов возвращает стандартный вид ESO, сохраняя щиты и состояния лечения.
Сортировка временно отключается в бою, при наличии спутников и вне игрового HUD.
Перед публикацией нужна проверка внутри игры; автоматические тесты её не заменяют.
