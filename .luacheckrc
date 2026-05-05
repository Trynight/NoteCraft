std = "lua51"
max_line_length = 140
exclude_files = { "Libs/**", ".release/**" }

ignore = {
  "212",  -- unused argument
  "213",  -- unused loop variable
  "311",  -- value assigned to a local variable is unused
  "631",  -- line is too long
}

globals = {
  -- WoW namespaces / API tables
  "C_Timer", "C_ChallengeMode", "C_Map", "C_LFGList", "C_ChatInfo",
  "Enum", "Settings", "Menu", "TooltipDataProcessor",

  -- WoW unit / group / realm
  "GetNumGroupMembers", "IsInGroup", "IsInRaid",
  "UnitName", "UnitFullName", "UnitGUID", "UnitClass", "UnitClassBase",
  "UnitGroupRolesAssigned", "UnitExists", "UnitIsPlayer", "UnitIsUnit",
  "GetNormalizedRealmName", "GetRealmName",

  -- WoW frames / UI
  "GameTooltip", "ItemRefTooltip", "UIParent", "CreateFrame",
  "InCombatLockdown", "hooksecurefunc", "SetItemRef",
  "InterfaceOptions_AddCategory",

  -- WoW LFG
  "LFGListFrame", "LFGListApplicantViewer_UpdateApplicant",

  -- Misc
  "GetBuildInfo", "GetTime", "time", "date",
  "wipe", "select", "strsplit", "strjoin", "format",
  "BackdropTemplateMixin",

  -- Color tables
  "RAID_CLASS_COLORS",

  -- LibStub & libraries
  "LibStub",

  -- Addon globals
  "NoteCraft", "NoteCraftDB",
  "SLASH_NOTECRAFT1", "SLASH_NOTECRAFT2", "SLASH_NC1",

  -- Addon namespaces
  "BINDING_HEADER_NOTECRAFT",
}

read_globals = {
  "string", "table", "math", "ipairs", "pairs", "type", "tostring", "tonumber",
  "next", "rawget", "rawset", "rawequal", "setmetatable", "getmetatable",
  "unpack", "error", "assert", "pcall", "xpcall",
}
