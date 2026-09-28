# Project context

1.5.0: settings show only General (sorting/context menu), Display (Roles with color and DPS/HPS/none for each role, shield color, class icon, combined level/CP). roleStats migrates previous DPS/HPS preferences; aggregate flags continue to configure data collection. Hidden preferences are retained.

1.4.5 adds Update 51/API 101051 alongside 101050. Runtime API gate and manifest agree.
Reference audit: ESO 12.1.4, commit 1baf1131560c2bcd38ffd2bd070728273b25f934 (pts12.1).
Group frame methods/geometry remain compatible; new HUD editor moves native anchor containers, which sorting already preserves. Live-client verification is pending.

Small-group leader outline includes the native role icon with left padding (38 px keyboard / 58 px gamepad), plus 4 px right clearance; raid bounds stay unchanged.

Version 1.4.4: Ultimate strip accepts fresh point receipts without ability-type packets;
fill no longer inherits the dim track's parentage and draws above native overlays.
Unavailable DPS/HPS values/captions hide. Native SetTextIndented(true) is post-hooked
to undo crown spacing while active. Sorting reuses native container anchors directly
and no longer restores vanilla order on combat entry. Client confirmation pending.

Version 1.4.3 explicitly hides HP on death and all additions while offline, including
class markup and leader outline. Tests cover death, disconnect and restored online state.

Version 1.4.2 addresses repeated frame motion: avoid restore/reapply of unchanged
sorting, repeated restores and full layout refreshes on every health update. Avoid
repeated leader indentation resets. Regression verifies unchanged passes write no anchors.
The user identified another member zoning as a possible trigger. Hidden member frames
now retain their sort slots; incomplete frame sets defer sorting before restoring anything.
Unrelated unit creation/destruction no longer schedules group sorting.

Version 1.4.1 replaces the leader crown with a thin gold frame outline, including
distance fading, leadership transfer and native restoration on disable.

Version 1.4.0 replaces Ultimate text with the requested thin vertical red/yellow/green
strip (0/175/500), adds current HP in tenths of thousands at bottom-right, and mirrors
native health-bar fading on all added data. Tests cover color anchors, fill, missing
data, real zero, HP formatting and propagated alpha. Client visual verification pending.

Version 1.3.1 enlarges class icons from 12 to 16 px and limits raid leader nicknames
to five characters. EVENT_LEADER_UPDATE refreshes names after leadership changes.

Version 1.3.0 refines the small-group layout: CP above the bar's right edge, consistent
16 px names, aligned rate/Ultimate numbers below health, and a more readable caption.
The screenshot's far-right CP came from anchoring to the oversized native root.

Version 1.2.9 implements the user's latest screenshot feedback: Ultimate icons removed,
one colored number retained at bottom right, and DPS/HPS aligned on the same baseline.
Earlier requirements for visible ability artwork are superseded by this explicit request.

## Goal

Create GroupFrame+ for ESO: extend vanilla upper-left group/raid frames with role
colors, optional member information, shield appearance, stable visual sorting,
honest combat statistics, EN/RU settings and native right-click member actions.
Preserving native functionality is the highest priority.

## Current state

Initial modular implementation complete; source-verified against ESO 12.0.8/API 101050.
The repository was initially empty. Architecture/design/context documents were created
as part of the implementation. Deployable folder: `GroupFramePlus`.

Implemented context-menu update: Whisper, Travel, permission-checked Remove. Preserves
native mouse handlers, rejects cancelled drags, detects intervening native menus,
validates recycled frames and stale menu callbacks. Independent interaction/menu settings.

Version 1.1.0 adds optional Hodor Reflexes shared statistics. Supplied source pair:
Hodor 2026-05-17 + LGCS 2026-07-26. Both DPS and effective HPS are available. Public
library reader/callbacks, no new broadcasts, no Hodor modifications. Account/character
matching, per-metric timestamps, reset cutoffs and 10-second expiry reject stale values.
See HODOR_INTEGRATION.md for the HPS scale discrepancy and protocol limitations.

Version 1.2.0 adds actual shared Ultimate ability icons and current points for all roles.
Both distinct transmitted bar abilities are shown: the verified protocol does not
identify the active bar. Real zero is distinguished using individual LGCS field receipts;
missing data is hidden. Remote readiness is conservative around two-point quantization.
Rate labels now follow selected role (damage DPS, healer HPS, tank neither).

Version 1.2.1 addresses the user's raid screenshot and "character not found" travel
failure. Travel now uses the verified account identity, accepted by JumpToGroupMember.
Native leader layout exposes empty status controls; these no longer suppress all
information and Ultimate. Text height uses actual font metrics. Three new regressions
cover suffixed character names, empty statuses and font sizing (43 behavior tests total).
Client confirmation of the fix is pending.

Version 1.2.2 responds to the next client screenshot: information is now visible but
overlaps, and Ultimate textures cover their numbers. Class moves before the native
name, raid names become compact, CP occupies its own line, and Ultimate point labels
draw above icons with explicit dimensions. Name restoration/reuse is tested.
The user reports missing DPS even while Hodor displays it in combat. The cause is not
yet confirmed; /gfpdebug provides live adapter rejection evidence. Do not claim that
the DPS issue is fixed until this output and in-game verification are available.

Version 1.2.3 moves CP to the upper-right beside the name at the user's request.
Name width is reserved for CP and restored when disabled. DPS diagnosis remains pending.

Version 1.2.4 increases raid names to 16 px, CP/rates to 12 px bold white and Ultimate
points to 13 px. CP stays upper-right to avoid the Ultimate icons. The latest user
screenshot shows numeric DPS/HPS and Ultimate points; remaining concern is readability.

Version 1.2.5 removes CP/level prefixes, uses green for ordinary levels, and replaces
per-icon point labels with one counter to the left of both icons at the bottom right.
Counter color moves red-yellow-green towards the first reliably ready shared ability;
unknown costs remain neutral. Individual icon readiness remains independent.

Version 1.2.6 separates DPS/HPS captions (9 px) from values (16 px bold), as requested.
Both controls follow role, status, settings and frame lifecycle together.

Version 1.2.7 vertically centers the shared Ultimate counter beside the icons,
anchoring it to the leftmost visible icon rather than the health-bar bottom.

Version 1.2.8 expands raid nickname space and shows seven Unicode characters, excluding
the account prefix. Original full native names remain available for restoration.

## Deliberate deviations

1. Remote DPS/HPS require fresh compatible shared data; otherwise display unavailable.
2. Local raw-event counters remain an independent per-metric fallback, not full raid logs.
3. Shield off means restoring vanilla; hiding the native shield parent would also break
   trauma/no-healing indicators. No replacement renderer was introduced.
4. Sorting suspends during combat, outside HUD/hudui and with companions.
5. No replacement UI or expanded frames; compact raid text can truncate.
6. Unverified ESO API versions disable enhancements rather than risking native frames.

## Verification

Automated Lua 5.1 syntax, manifest validation, native-identifier existence audit,
and behavior tests cover local statistics, role defaults, anchor restoration, menu
actions/permissions/recycling, native mouse preservation and shield-color restoration.
An additional 15 integration tests cover absence/incompatibility, units, zero/no-data,
expiry/reset/identity, provider exceptions, toggles, local fallback and synchronous
reused-frame refresh. The supplied LGCS encoder functions are also executed unchanged
with fixtures to verify actual DPS/HPS scaling, boss-field separation and zero values.
Twelve additional Ultimate tests cover receipt validity, expiry, identity recycling,
readiness, role independence and reusable mouse-transparent controls. Actual LGCS
Ultimate sender/receiver functions verify ability IDs and point/cost quantization.
See tests/run.py and docs/TESTING.md. These are mocked logic tests, not an ESO UI emulator.
No ESO client execution or rendered in-game verification has occurred. A production
release still requires the in-game checklist, especially scaling, shield animation,
4↔12-player transitions, remote membership churn and interactions with other addons.

## Collaboration conventions

Read ARCHITECTURE.md, DESIGN_SYSTEM.md and PROJECT_CONTEXT.md before subsequent work.
Update them when behavior or design decisions change. Commit code changes. Reports
should remain concise and distinguish verified facts from client validation still needed.
