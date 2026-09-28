# Architecture

1.4.5 adds Update 51/API 101051 alongside 101050. Runtime API gate and manifest agree.
Reference audit: ESO 12.1.4, commit 1baf1131560c2bcd38ffd2bd070728273b25f934 (pts12.1).
Group frame methods/geometry remain compatible; new HUD editor moves native anchor containers, which sorting already preserves. Live-client verification is pending.

Small-group leader outline includes the native role icon with left padding (38 px keyboard / 58 px gamepad), plus 4 px right clearance; raid bounds stay unchanged.

1.4.4 supersedes the combat sorting restriction: native container-relative anchor
tuples define sorted slots without screen-coordinate measurement or a restore pass.
Only cross-member anchor chains use the legacy snapshot/restore fallback. Ultimate
point-only records are valid without ability metadata; both textures fade independently.

Offline data refresh exits after synchronously hiding all owned data controls and
restoring the undecorated native name. Leader outline eligibility requires online state.
Normal reconnect refresh repopulates controls; no player identity is cached in visibility.

1.4.2: sorting skips unchanged roster/role/frame/native-anchor signatures. Restore is
idempotent when no sorted layout is active. Native SetAnchor hooks ignore addon writes.
Health power events update data controls directly, not the full frame layout. Leader
indentation is changed only when leader decoration state transitions.
Incomplete rosters/frame sets defer sorting while a member zones; hidden controls
still contribute their original slots. Non-group unit lifecycle events are ignored.

Leader presentation: four reusable edge textures per highlighted frame, validated
against current unit ownership. Native crown visibility calls are post-hooked to
suppress its alpha while active; the prior alpha and name indentation restore on
disable. Existing EVENT_LEADER_UPDATE refresh transfers the border to the new leader.

1.4.0: UltimateUI owns a narrow track/fill texture pair and no numeric control.
PlayerInfo owns a current-health label using GetUnitPower(HEALTH). Group health power
events queue coalesced refreshes. Native DoAlphaUpdate hooks refresh all added labels
and the Ultimate strip with the actual native health-bar alpha. Class markup inherits
the native name label's own fading. Ultimate color is point-based, not cost-based.

Leader changes queue a normal refresh via EVENT_LEADER_UPDATE so the leader-specific
nickname limit follows the current unit rather than remaining attached to a frame.

Small-group metadata anchors to the visible health bar, rather than the larger native
root. Raid and small-group layouts use separate caption widths and lower-row offsets.

Current Ultimate UI (1.2.9): creates one mouse-transparent numeric label, no icon
controls or texture lookups. Ability IDs and costs remain in the provider adapter
for readiness calculations. The counter and rate value share the lower baseline.

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
PlayerInfo now decorates the current native name with the class icon. It remembers the
undecorated text/font, avoids duplicate prefixes, accepts new native text on reuse and
restores the original text/font/width on disable. Native name anchors remain unchanged.
The upper-right CP label reserves its measured text width in the name row; Ultimate
only reserves bottom-row statistic width and does not resize CP.
Ultimate now owns one shared point label plus two icon controls. Its reserved width
includes the counter, which hides alongside all icons. Adapter progress uses only
validated costs and conservative remote quantization; the UI combines visible abilities.
Rate caption and numeric value are separate reusable labels with shared visibility;
the width calculation reserves both the caption and Ultimate cluster.
The manual /gfpdebug command reports provider state, timestamps, identity agreement and
accepted DPS by unitTag, without names or a polling loop, for live-client diagnosis.

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
