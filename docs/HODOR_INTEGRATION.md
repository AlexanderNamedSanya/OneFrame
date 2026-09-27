# Hodor Reflexes source investigation and consumer integration

Investigated the user's installed source, not a guessed API or remote release:

- `C:/Users/Public/Documents/Elder Scrolls Online/live/AddOns/HodorReflexes/`
  Version **2026-05-17**, manifest `HodorReflexes.addon`.
- Sibling `LibGroupCombatStats/LibGroupCombatStats.lua`, version **2026-07-26**.
  This library is a declared Hodor dependency, not vendored inside its folder.

No source files in either provider are edited or patched. Hodor is not hooked. The integration
registers normal public callbacks and a receive-only library consumer. No source is
copied into the distribution. Test code can execute the supplied encoder with fixtures.

## Ultimate source verification (1.2.0)

Hodor `modules/ult/main.lua:onULTDataReceived` consumes `ultValue`, `ult1ID`,
`ult2ID`, `ult1Cost`, `ult2Cost`. Its `list_misc.lua` resolves icons through
`GetAbilityIcon`. LGCS maps wire identifiers to actual ESO ability IDs in its existing
receiver; GroupFrame+ uses the decoded IDs directly, without a second mapping table.
LGCS obtains slotted abilities from both bars and costs via
`GetAbilityCost(id, COMBAT_MECHANIC_FLAGS_ULTIMATE, nil, "player")`.
The protocol does not send an active-bar selector. We display both distinct shared
abilities, or one when only one is available/IDs match, without inventing a selection.

Protocols 20/21 separately transmit type/cost and current points. Senders floor points
and costs divided by two; receivers multiply by two. Thus remote 173 becomes 172,
and cost 237 becomes 236. Local reader values retain their actual precision. Remote
readiness is true only at reported points >= reported cost + 2, false when points + 1
< cost, and neutral at an ambiguous boundary. There is no assumed 250-point cost.

Public player/group ULT callbacks and `GetUnitULT` expose a combined observable table.
A type-only packet advances its timestamp while points remain the default zero.
Therefore a narrowly scoped runtime `ZO_PostHook` observes the verified LGCS
ObservableTable `__newindex` after the original write. It records field receipts,
including unchanged zero, in addon-owned weak-key tables. No values are modified and
no additional broadcasts are enabled. The hook remains installed but inert on disable.
Version and metatable shape checks gate installation; missing evidence hides Ultimate.

Current account and character must match the public snapshot. Points expire after
10 seconds; type/cost receipts persist because types transmit only on changes.
Roster, activation and test transitions clear receipts; combat start does not reset
Ultimate. After enabling/resetting, remote icons may remain hidden until new type and
point packets arrive. This is conservative rather than treating cached default zero
as real data. Native frame refresh updates all Ultimate state for the current occupant.

`UI/Ultimate.lua` creates controls once, resolves textures on ability changes, and
updates points/readiness separately. DPS/HPS labels follow role; Ultimate does not.
Twelve focused tests plus real LGCS sender/receiver fixtures cover this behavior.

## Findings before implementation

1. **Origin:** LibCombat fight recaps populate LGCS local counters. LGCS's existing
   LibGroupBroadcast protocols 22 (DPS) and 23 (HPS) send/receive quantized statistics.
   Hodor is a consumer of these same library callbacks.
2. **Storage:** Hodor `core/group.lua` owns `addon.playersData`, keyed by
   `GetUnitName(tag)` (character name). `CreateOrUpdatePlayerData` adds `userId`
   (account/display name), `tag`, and a merged `lastUpdate`. The library's private
   `groupStats` is also character-keyed, with `displayName`, `name`, `tag` and independent
   observable `dps`/`hps` tables. We do not read either private storage directly.
3. **Mapping:** public `reader:GetUnitStats(unitTag)` resolves the character name
   internally and returns a snapshot including both account and character. Both are
   compared against the current ESO unit. A callback's unitTag is only a refresh hint:
   library group remapping is delayed 250 ms and its observable callbacks are delayed
   10 ms, so neither callback tags nor frame indexes establish durable identity.
4. **HPS exists:** Hodor `modules/hps/main.lua:onHPSDataReceived` receives `hps` and
   `overheal` from LGCS. We use `hps` (effective outgoing healing), not `overheal`
   (raw healing rate). Hodor's HPS module must be enabled, just like its DPS module.
5. **Public interfaces:** Hodor exports `RegisterCallback`/`UnregisterCallback` and
   `HR_EVENT_*` constants. LGCS exports `RegisterAddon`, reader `GetUnitStats`,
   `RegisterForEvent`/`UnregisterForEvent` and four player/group DPS/HPS event constants.
   These are the intended consumer APIs documented in the supplied library README.
6. **Relevant files:** Hodor `HodorReflexes.lua`, `core/group.lua`, `core/events.lua`,
   `core/modules.lua`, `core/combat.lua`, `modules/dps/{main,util,list_damage}.lua`,
   `modules/hps/{main,list_hps}.lua`; LGCS `LibGroupCombatStats.lua` and its README/example.
7. **Cleaner integration:** the LGCS public reader is superior to Hodor's merged
   table/callback: it exposes per-metric timestamps and typed updates, whereas an ULT
   update can advance Hodor's generic `lastUpdate` without any DPS/HPS packet.

## Important discrepancies in the supplied version

The source code takes precedence over comments and examples:

- LGCS `updatePlayerDps` uses `floor(DPSOut / 1000)` for `dps`, in both normal and boss
  fights. `dmg` carries accumulated damage in a normal fight or boss DPS in a boss fight.
  GroupFrame+ shows **total DPS = dps × 1000** consistently, never switches to `dmg`.
- `updatePlayerHps` uses `floor(HPSOut / 1000)` for `hps` and
  `floor(OHPSOut / 1000)` for `overheal`. Thus **effective HPS = hps × 1000**.
- Hodor's `modules/hps/list_hps.lua` formats `data.hps / 10` with a `K` suffix.
  With this supplied library that is a factor-of-ten disagreement. We do not reproduce
  that display calculation; a fixture executes the real LGCS producer functions to
  verify the conversion. Other/newer version combinations require separate verification.
- Both network rate fields have protocol range 0–999, i.e. 0–999k at a 1000-unit step.
  Shared 87,200 cannot be recovered: the library has already encoded it as 87.
- README payload/precision descriptions contain outdated information. Observable
  callbacks normally receive `_data`, without timestamps. Public `GetUnitStats` builds
  the snapshot from observable objects and includes `_lastUpdated`/`_lastChanged`.
- `_lastUpdated` starts at **0** and changes on every metric field assignment.
  `_lastChanged` advances only for actual changes. Repeated zero packets update the
  former without callbacks. Therefore `0` plus timestamp 0 means no received data,
  while a fresh timestamped zero is a real available result.
- The library declares API 101046/101047 in its manifest despite version 2026-07-26;
  ESO may mark it outdated. This consumer does not rewrite its manifest or force-enable it.

## Lifecycle and freshness

Hodor emits combat start from local ESO combat state; combat end first arrives with
`confirmed=false`, then with `true` after three seconds if still out of combat. Group
changes are coalesced for 100 ms; cleanup drops missing/offline characters. Test-mode
callbacks generate synthetic Hodor table values and must not be treated as measurements.

LGCS updates local counters once/second, broadcasts changed data on a two-second
schedule and can stop transmitting when quantized values no longer change. Its
`combat.Reset` exists but has no call site in this supplied file. Hodor's own combat
reset clears its aggregate/history, not every member's LGCS measurements. Neither the
network payload nor the reader includes an encounter ID or sender combat timestamp.

Consumer policy:

- Read only the exact verified Hodor/LGCS versions, initialized Hodor (`internal` is
  removed at the successful end of initialization), and enabled, non-test modules.
  This small lifecycle/module inspection is isolated entirely inside the adapter.
- Accept metric values only with finite nonnegative numbers and valid timestamps;
  independently expire each metric after **10 seconds** without updates.
- Reset a cutoff at combat start, zone/activation, roster changes, group-unit creation/
  destruction and test-mode transitions. Old/default records are rejected, including
  equal-millisecond timestamps. A group change conservatively invalidates all metrics
  until refreshed rather than allowing a departed/rejoined character's result to linger.
- Local LGCS updates can continually rewrite the previous result while idle; require
  a recent `_lastChanged` after the cutoff and cap local shared data at 10 seconds after
  confirmed combat end. The independent local fallback can still show its last encounter.
- Fresh remote packets can remain usable while the local player is out of combat.
- Public callbacks schedule a coalesced 50 ms label refresh. One **1000 ms** sweep while
  enabled/grouped covers expiry and unchanged packets that produce no callback.

There is no reliable way to identify an old in-flight packet arriving after a new
encounter without an encounter ID. Receive timestamps limit retention but cannot solve
that protocol ambiguity. Similarly, unchanged valid rates can expire conservatively;
this is intentional rather than displaying an unbounded stale number.
The payload also does not identify the sender's library version; peers using a
different rate encoding cannot be identified from these fields alone.

## Consumer behavior and isolation

`RegisterAddon("GroupFramePlusHodorReader", {})` was checked against the implementation:
an empty `neededStats` array skips every broadcast-enabling branch. There is no new
protocol, no transmission request and no change to the providers' sharing preferences.
The reader exposes all getters/events irrespective of that empty array.

Disabling integration unregisters all consumer callbacks/timers. The library offers
no unregister-addon method, so only its inert reader object is retained for re-enable;
registering twice under the same name would otherwise fail. Provider errors are caught
and disable this integration for the session. No guessed API fallback is attempted.

`CombatStats:Values` prefers shared data per metric, including valid zero. Only the
local player can use existing raw-event counters as fallback; remote absence is `nil`,
rendered `—`. Before any local measurement, local absence also renders `—`.
Shared effective HPS and raw local fallback have different semantics, explained in settings.

## Changed addon files

- **New:** `Integrations/HodorReflexes.lua` — every Hodor/LGCS-specific detail.
- `Data/CombatStats.lua` — shared-first per-metric selection and configuration/reset bridge.
- `Core.lua` — load/activation/roster lifecycle routing through CombatStats.
- `UI/PlayerInfo.lua` — million formatting; existing mouse-transparent labels retained.
- `UI/VanillaFrames.lua` — synchronous statistic refresh when native controls are reused.
- `Defaults.lua`, `Settings/Settings.lua` — independent Hodor toggle, default on.
- `Lang/en.lua`, `Lang/ru.lua` — settings/help, DPS/HPS and ДПС/ХПС, number formatting.
- `UI/Ultimate.lua` — reusable native ability icons and separate point labels.
- `GroupFramePlus.txt`, `Namespace.lua` — 1.2.0, adapter/UI load order, optional dependencies.

`OptionalDependsOn` is verified both in Hodor's supplied manifest and the ESO source's
`esoui/libraries/libraries.txt`. LibAddonMenu remains the only required dependency.

## Verification

Lua 5.1 syntax, manifest paths, native/provider identifier audit, 13 previous regression
tests and 15 new shared-statistics tests pass. Actual LGCS encoder functions are tested
unchanged for total/boss DPS, effective HPS and zeros. External Hodor file hashes are
compared before/after work. The actual library registration function is also executed
with an empty stat request and proves it does not enable any broadcaster. All 86 Hodor files are
unchanged. Runtime UI/network validation still requires ESO; no live
client was available in this environment.
