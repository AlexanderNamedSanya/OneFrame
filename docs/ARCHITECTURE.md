# Architecture

## Boundary

`GroupFramePlus/` is the complete deployable addon. Lua files load in manifest order.
Only dependency: LibAddonMenu-2.0. Account-wide saved variables use schema version 1.
There is no replacement frame, XML template, custom texture asset or network protocol.

`Namespace.lua` owns the shared namespace. `Lang/en.lua` establishes fallback strings;
`Lang/ru.lua` overrides them when `language.2 == ru`. `Defaults.lua` resolves native
resource gradients rather than approximating their colors.

## Modules

| Module | Responsibility |
| --- | --- |
| Core | Initialization, delayed activation retry, compatibility gate, events, 50 ms coalescing |
| GroupData | Current group roster and supported native frame identification |
| VanillaFrames | Cached frame objects, idempotent child creation, native post-hooks, role colors |
| PlayerInfo | Mouse-transparent information/statistics labels; native class texture markup |
| ShieldOverlay | Appearance-only extension of the native power-shield module |
| RoleSorting | Snapshot/restore native anchors and assign visual slots, without changing identity |
| CombatStats | Local-only event counters, encounter lifecycle, 500 ms display updates |
| Interaction | Chain native mouse handlers; validated member-specific native menu actions |
| Settings | LAM sections, independent toggles, color pickers and opacity |

## Native lifecycle

Source baseline is pinned in API_VERIFICATION.md. `UNIT_FRAMES:GetFrame(unitTag)`
selects native objects. Group and raid objects are distinct and may be hidden/reused.
The adapter checks styles, caches by object identity and refreshes after native methods.
All children are created once per object. Stale/disabled objects' additions are hidden.
Member identities are queried at refresh/click time, never fixed when a control is created.

`ZO_UnitFrameObject:SetAnchor` post-hook captures native anchors before scheduled sorting.
Before measuring slots, sorting restores original relationships, preventing cumulative
drift and cycles. It then anchors current member controls to original parent-relative
positions. No changes to `unitTag`, `m_unitTag`, manager lookup tables or native offsets.
Sorting is limited to HUD/hudui, out of combat, with no companions. Native leader/election
controls stay attached to their original member frames.

The native shield module already processes attribute-visual events and computes
health/shield/trauma geometry. Post-hooks recolor the actual overlay and its health
layer. The addon never hides that hierarchy, which would also hide essential statuses.
The shield checkbox restores native rendering when off; it is not a global suppression toggle.

Interaction pre-hook records cursor/menu state and always allows the original handler.
Post-hook opens a menu only for an inside right release with no prior drag or intervening
menu action. Native menu-function revisions detect even equal-sized replacement menus.
Selection callbacks revalidate control ownership, account AND character identity,
membership, settings and kick permissions. Vote-required groups never expose direct kick.

## Work scheduling

No addon render-frame polling or tree searches. Event bursts use one pending 50 ms
refresh; sort work is separately dirty-flagged. Combat callbacks perform table lookup
and addition; only enabled local statistics listen to combat events. One 500 ms timer
exists while measuring combat. Native hooks remain installed but become inactive after
disable; restoration runs through the same refresh path.

## Compatibility policy

API mismatch fails closed. Missing UI support retries at player activation and logs at
most once. Additions never target player/reticle/boss/companion frames. Replacing addons
and hostile handler replacement after attachment are not supported. Any future source
revision requires API/geometry review and client acceptance, not merely a manifest bump.
