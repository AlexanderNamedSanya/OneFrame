# ESO API and native source verification

Checked 2026-09-27 against [esoui/esoui live](https://github.com/esoui/esoui),
commit `f76cf16c4e5be7b234d15dc7f676febffa64c5bb`, released 2026-08-10,
ESO 12.0.8 / **API 101050**. Reference source is not distributed with the addon.

## Authoritative reference paths

All paths below refer to the pinned source commit:

- [API documentation](https://github.com/esoui/esoui/blob/f76cf16c4e5be7b234d15dc7f676febffa64c5bb/ESOUIDocumentation.txt)
- [Native unit-frame objects and manager](https://github.com/esoui/esoui/blob/f76cf16c4e5be7b234d15dc7f676febffa64c5bb/esoui/ingame/unitframes/unitframes.lua)
- [Native unit-frame templates/mouse handlers](https://github.com/esoui/esoui/blob/f76cf16c4e5be7b234d15dc7f676febffa64c5bb/esoui/ingame/unitframes/unitframes.xml)
- [Native shield module](https://github.com/esoui/esoui/blob/f76cf16c4e5be7b234d15dc7f676febffa64c5bb/esoui/ingame/unitattributevisualizer/modules/powershield.lua)
- [Native group-list context menu](https://github.com/esoui/esoui/blob/f76cf16c4e5be7b234d15dc7f676febffa64c5bb/esoui/ingame/group/keyboard/zo_grouplist_keyboard.lua)

| Requirement | Verified interface |
| --- | --- |
| Frame identity | `UNIT_FRAMES:GetFrame(tag)`, `frame.unitTag`, `frame.frame.m_unitTag` |
| Existing health | `frame.healthBar.barControls`, `ZO_UnitFrameBar:SetColor` |
| Refresh hooks | `ZO_UnitFrameObject` methods SetAnchor, ApplyVisualStyle, UpdateName, UpdateLevel, UpdateStatus, UpdateAssignment, DoAlphaUpdate; global ZO_UnitFrames_UpdateWindow |
| Roles | GetGroupMemberSelectedRole; LFG_ROLE_TANK, LFG_ROLE_HEAL, LFG_ROLE_DPS |
| Resource colors | ZO_POWER_BAR_GRADIENT_COLORS keyed by COMBAT_MECHANIC_FLAGS_*; derives from GetInterfaceColor POWER_START/END |
| Class | GetUnitClassId; ZO_GetClassIcon in publicallingames/globals/sharedtextures.lua |
| Names/progression | GetUnitDisplayName, GetRawUnitName, GetUnitLevel, IsUnitChampion, GetUnitChampionPoints |
| Health scale | GetUnitPower returns current, max, effectiveMax; native frame uses its own current/max bar values |
| Shield source | GetUnitAttributeVisualizerEffectInfo(tag, ATTRIBUTE_VISUAL_POWER_SHIELDING, STAT_MITIGATION, ATTRIBUTE_HEALTH, COMBAT_MECHANIC_FLAGS_HEALTH) returns value, maxValue, sequenceId (nilable) |
| Shield updates | Native visualizer handles EVENT_UNIT_ATTRIBUTE_VISUAL_ADDED/UPDATED/REMOVED and their deltas |
| Shield appearance | ZO_UnitVisualizer_PowerShieldModule, attributeInfo[ATTRIBUTE_HEALTH].overlayControls; fakeHealthBar child |
| Anchors | GetAnchor is zero-indexed, returns valid, point, relativeTo, relativePoint, x, y, constraints |
| Mouse | Template OnMouseUp calls UnitFrame_HandleMouseUp; native handler handles dragged cursor content; template mouseEnabled=true |
| Menu | ClearMenu, AddMenuItem, ShowMenu; ZO_PreHookHandler / ZO_PostHookHandler |
| Whisper | StartChatInput("", CHAT_CHANNEL_WHISPER, account); also used by native friends list |
| Travel | JumpToGroupMember(characterOrDisplayName), used by native group list |
| Remove | IsUnitGroupLeader("player"), IsGroupModificationAvailable(), DoesGroupModificationRequireVote(), GroupKick(unitTag) |

The native group-list row menu assumes scroll-list row data and cannot be attached
directly to a unit frame. Reuse its supported menu/actions and permission predicates,
with additional identity validation, instead of fabricating scroll-list state.

## Combat-event contract and limits

API 101050 documents EVENT_COMBAT_EVENT arguments as result, isError, abilityName,
abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType,
hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId, overflow.
The addon uses only result/isError/sourceType/hitValue and filters local-player sources.

The API reference lists the callback but does not promise a complete remote stream.
[ZOS developer explanation of combat-event filtering](https://www.esoui.com/forums/printthread.php?t=6955)
documents that full information is available for events involving the local player/pet;
unrelated events lose attribution, with further PvP restrictions. This explanation is
historical (2017), not a newly measured server guarantee. The current exported API and
native source offer no verified complete remote outgoing-statistics feed. Consequently
the raw-event fallback exposes no remote DPS/HPS. Optional shared data now comes from
the separately verified Hodor/LGCS integration (see HODOR_INTEGRATION.md). Incoming healing from a
particular player cannot establish that player's overall HPS.

Local statistics intentionally sum only the result whitelist in CombatStats.lua.
Raw hitValue is not adjusted using undocumented overflow assumptions. Pets, companions,
absorbed damage and other event categories are not silently treated as player damage.
No client encounter-log parsing or new cooperative broadcast protocol is implemented;
the optional integration consumes the provider's existing protocol.

## Library contract

LibAddonMenu-2.0 uses the `LibAddonMenu2` global, RegisterAddonPanel and
RegisterOptionControls, with panel/checkbox/colorpicker/slider/header/description/button
controls, verified against its [maintainer's examples](https://github.com/sirinsidiator/ESO-LibAddonMenu/blob/master/LibAddonMenu-2.0/exampleoptions.lua)
and registration implementation. It is declared as a required dependency and is not vendored.
# Ultimate API evidence (1.2.0)

1.2.1: `JumpToGroupMember(characterOrDisplayName)` accepts account names. Raw names
are retained only for stale-target validation. Native `SetTextIndented` calls
`LayoutUnitFrameStatus`, which sets hidden=false when statusData exists, even with
empty text. `UpdateLeaderIndicator` invokes this for raid members. Therefore
IsHidden alone cannot determine whether a status message should suppress additions.
Label `GetFontHeight()` is documented and used by native button/tree templates.

Native source/API audit includes `DoesAbilityExist`, `GetAbilityIcon`,
`ZO_NO_TEXTURE_FILE`, texture `SetDesaturation`, and `ZO_PostHook`.
Hodor `modules/ult/list_misc.lua` uses `GetAbilityIcon` on decoded Ultimate IDs.
LGCS obtains actual slot costs with `GetAbilityCost` and transmits both bars; see
HODOR_INTEGRATION.md for source names, precision and the guarded field-receipt hook.
