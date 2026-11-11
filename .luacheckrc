std = "lua51"
max_line_length = false
exclude_files = { ".git/**" }

globals = { "BINDING_HEADER_GROUPHIGHLIGHT", "BINDING_NAME_GROUPHIGHLIGHT_TOGGLE", "GroupHighlight", "GroupHighlightDB", "SLASH_GROUPHIGHLIGHT1", "SLASH_GROUPHIGHLIGHT2", "SlashCmdList" }

read_globals = {
  "C_AddOns", "C_CVar", "C_NamePlate", "C_Timer", "CreateColor", "IsMouseButtonDown", "LOCALIZED_CLASS_NAMES_MALE", "_G", "CreateFrame", "GameTooltip",
  "GameTooltip_Hide", "GetAddOnMetadata", "GetCameraZoom", "GetCursorPosition", "GetLocale", "GetUnitName",
  "HideUIPanel", "InCombatLockdown", "issecretvalue", "RAID_CLASS_COLORS", "Settings", "SettingsPanel", "UIParent",
  "UISpecialFrames", "UnitClass", "UnitExists", "UnitInParty", "UnitInRaid", "UnitIsPlayer", "UnitIsUnit",
  "UnitName", "tinsert", "tremove", "unpack",
}
