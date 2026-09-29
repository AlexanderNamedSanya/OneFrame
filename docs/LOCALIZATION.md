# OneFrame localization

English base: OneFrame/Lang/en.lua (ZO_CreateStringId, ONEFRAME_*).
Overrides: OneFrame/Lang/$(language).lua (SafeAddString, version 1).
Russian is ru.lua. English remains the fallback. New languages need only a matching
language file with overrides; core code uses GetString and contains no locale branches.
Native API pattern verified in ESO API 101051 reference localization source and OneDungeon.
Internal OneFrame addon/folder/SavedVariables names remain for safe upgrades.
Visible title is OneFrame; author is oneDOK. Debug command /oneframedebug remains compatible.
