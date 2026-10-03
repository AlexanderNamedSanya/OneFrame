# OneFrame 1.2

Changes compared with the latest local release archive, dist/OneFrame-1.0.zip, dated September 30, 2026. No release tags are available in this repository.

- Added Leave Group to your own frame's context menu, using ESO's standard confirmation dialog.
- Added Promote to Leader for online group members when you are the leader. Permissions and player identity are checked again before the action runs, preventing stale menus from acting on a different player.
- Coalesced health and roster events into 50 ms refresh queues, reducing repeated statistics updates and collector reconfiguration. Full frame refreshes absorb pending statistics refreshes.
- Reduced redundant name and statistics updates during native frame refreshes while preserving immediate updates for player changes, name updates and offline members.
- Refined the leader border with a lighter gold color, a one-pixel thickness and a one-pixel inset.
- Updated the addon manifest, runtime version and README to version 1.2.

The built-in group DPS feature was already included in the comparison archive.

Validation: automated Lua syntax, manifest, native identifier, behavior, shared statistics, Ultimate, group combat and refresh queue checks passed before the version-only update. Git whitespace validation passed after the update. In-game ESO validation has not been performed.

Installation: extract the OneFrame folder into Documents/Elder Scrolls Online/live/AddOns/ and reload the UI. LibAddonMenu-2.0 is required.