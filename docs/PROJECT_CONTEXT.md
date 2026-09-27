# Project context

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

## Deliberate deviations

1. No remote DPS/HPS: unavailable marker instead of invented statistics.
2. Local counters are explicitly limited raw outgoing-event rates, not full raid logs.
3. Shield off means restoring vanilla; hiding the native shield parent would also break
   trauma/no-healing indicators. No replacement renderer was introduced.
4. Sorting suspends during combat, outside HUD/hudui and with companions.
5. No replacement UI or expanded frames; compact raid text can truncate.
6. Unverified ESO API versions disable enhancements rather than risking native frames.

## Verification

Automated Lua 5.1 syntax, manifest validation, native-identifier existence audit,
and behavior tests cover local statistics, role defaults, anchor restoration, menu
actions/permissions/recycling, native mouse preservation and shield-color restoration.
See tests/run.py and docs/TESTING.md. These are mocked logic tests, not an ESO UI emulator.
No ESO client execution or rendered in-game verification has occurred. A production
release still requires the in-game checklist, especially scaling, shield animation,
4↔12-player transitions, remote membership churn and interactions with other addons.

## Collaboration conventions

Read ARCHITECTURE.md, DESIGN_SYSTEM.md and PROJECT_CONTEXT.md before subsequent work.
Update them when behavior or design decisions change. Commit code changes. Reports
should remain concise and distinguish verified facts from client validation still needed.
