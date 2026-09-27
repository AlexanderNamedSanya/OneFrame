# Architecture

## Boundary

`GroupFramePlus/` is the complete deployable addon. Lua files load in manifest order.
Required dependency: LibAddonMenu-2.0. Optional: HodorReflexes and LibGroupCombatStats.
Account-wide saved variables use schema version 1; new `hodor` preference defaults true.
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
| Ultimate | Two reusable native ability textures and point labels; role-independent visibility |
| ShieldOverlay | Appearance-only extension of the native power-shield module |
| RoleSorting | Snapshot/restore native anchors and assign visual slots, without changing identity |
| CombatStats | Shared-first values with per-metric local fallback and local encounter counters |
| Integrations/HodorReflexes | Optional provider validation, public LGCS reader/callbacks, identity/freshness checks |
| Interaction | Chain native mouse handlers; validated member-specific native menu actions |
| Settings | LAM sections, independent toggles, color pickers and opacity |

## Native lifecycle

Source baseline is pinned in API_VERIFICATION.md. `UNIT_FRAMES:GetFrame(unitTag)`
selects native objects. Group and raid objects are distinct and may be hidden/reused.
The adapter checks styles, caches by object identity and refreshes after native methods.
All children are created once per object. Stale/disabled objects' additions are hidden.
Member identities are queried at refresh/click time, never fixed when a control is created.
Native name/status refresh also updates statistics synchronously, so recycled controls
cannot keep the previous occupant's text during the deferred layout pass.

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
Travel passes the validated display/account name; raw character names remain identity
checks only. Native leader refresh calls SetTextIndented, which exposes an empty status
label. PlayerInfo suppresses additions only for a visible nonempty status message.

## Work scheduling

No addon render-frame polling or tree searches. Event bursts use one pending 50 ms
refresh; sort work is separately dirty-flagged. Combat callbacks perform table lookup
and addition; only enabled local statistics listen to combat events. One 500 ms timer
exists while measuring combat. Native hooks remain installed but become inactive after
disable; restoration runs through the same refresh path.

Shared statistics use four DPS/HPS and two Ultimate LGCS callbacks coalesced to 50 ms label updates, Hodor
lifecycle callbacks and a 1000 ms sweep while enabled/grouped. LGCS silently updates
`_lastUpdated` for unchanged packets, making this sweep necessary. Each metric expires
after 10000 ms. Reset cutoffs reject previous-combat/roster/zone records. For local data,
`_lastChanged` and confirmed-end limits prevent idle writes reviving previous results.

The public reader is acquired once via `RegisterAddon(name, {})`, which does not enable
broadcasts. Disable removes callbacks/timers, keeping only the inert getter object:
LGCS has no unregister-addon method. All provider names and fields stay inside
Integrations/HodorReflexes.lua. CombatStats consumes `SharedStats:Values/Configure/Reset`;
UI consumes CombatStats only. Exact provider version checks and protected calls fail
closed for statistics alone. No cached frame-index/player associations.

Ultimate uses the same public reader and identity validation. A version-gated runtime
post-hook on LGCS ObservableTable.__newindex records individual field receipts in
addon-owned weak-key tables. This distinguishes a real received zero from the default
zero following a type-only packet. Original writes always execute unchanged. The hook
remains inert while disabled; provider source files are never edited. Points expire
after 10 seconds; roster/activation resets clear receipts, combat start preserves them.
Both distinct shared bar abilities are displayed because the protocol has no active-bar
field. Remote cost/points have two-point precision; ambiguous readiness stays neutral.

## Compatibility policy

API mismatch fails closed. Missing UI support retries at player activation and logs at
most once. Additions never target player/reticle/boss/companion frames. Replacing addons
and hostile handler replacement after attachment are not supported. Any future source
revision requires API/geometry review and client acceptance, not merely a manifest bump.
