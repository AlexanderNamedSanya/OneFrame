# Verification

## Automated

`python tests/run.py` needs Python package `lupa`; runtime is explicitly Lua 5.1.
It compiles all shipped modules, checks manifest paths, optionally audits native names
against the pinned ESO source, and runs tests/behavior.lua.

Behavior tests exercise real addon logic with mocked native boundaries: role fallback;
local-only damage/healing, timing/reset/event teardown; visual-only sorting/restoration
including native relative chains; companion/combat/scene guards; context-menu actions,
permission loss, vote-required groups, self target, A→B reuse and stale callbacks;
native handler preservation, drag cancellation, outside/left clicks, existing menu
precedence, settings toggles; shield tint restoration without altering status children.

The mocks do not prove ESO rendering, server permissions, combat-result semantics,
load order or third-party compatibility. Syntax/API-name existence is not runtime proof.

## Required client acceptance — not yet performed

1. Load with LAM on EN and RU clients/API 101050; verify settings and saved values after reload.
2. Join 2/4/12-member groups, leave/rejoin, zone/instance transition, reload while grouped.
   Change roles and leader. Verify names, assignment/leader/ready-check icons and native fades.
3. Switch keyboard/gamepad appearance and UI scales; verify added text does not cover
   native status/election indicators, respects Cyrillic fonts and truncates acceptably.
4. Enable sorting; compare frame identity/name/health and menu target. Change roster/roles;
   disable sorting and confirm original anchors. Check cursor HUD and group-management
   scenes, combat transitions and companions. Validate no anchor drift after repeated cycles.
5. Apply shields at low/full HP, above missing HP and above max HP; change max HP; test
   rapid stacking/removal, death/resurrection, disconnect and range changes. Confirm
   native trauma/no-healing remains visible and shield-off restores vanilla appearance.
6. Test role colors with shields active; disable addon and confirm original gradients.
7. Measure local direct/DoT/HoT/critical events; confirm remote values stay unavailable,
   out-of-combat final values freeze and next combat/zone resets. Test pets/companions
   are excluded and statistics-off removes the addon combat timer/listeners.
8. Right-click every visible portion of small/raid frames in cursor mode. Confirm vanilla
   handlers and context menus work, added text does not intercept clicks, and cancelled
   drags/left releases/outside releases never open the addon menu.
9. Open menu on A, remove A externally, fill slot with B, execute old menu item: no action.
   Open new menu: all actions target B. Repeat with same account on a different character,
   shifted unit tags, role sorting and a transition from small to raid frames.
10. Verify native whisper input, travel success/failure, leader-only direct kick,
    permission loss while a menu is open, no self kick and no direct kick in vote groups.
11. Disable interaction/context-menu/addon while a menu is open; pending actions do nothing.
12. Profile an active 12-player fight: no addon per-frame scan or repeated control creation;
    one coalesced refresh per native event burst and at most two statistic updates/second.

Record client version, group composition, UI mode/scale and addon list with failures.
Do not raise the manifest API version without reviewing source changes and rerunning this list.
