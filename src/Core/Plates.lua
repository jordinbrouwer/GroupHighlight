-- The friendly nameplates the arrows hang on: the game settings they need, and putting your own back.
local GH = GroupHighlight
local GetOptions = GH.GetOptions

local pendingCVars = false   -- true while we wait for combat to end to change a setting

-- Nameplates are the only thing an addon can attach to a unit in the world. Arrows above group
-- members need these CVars; arrows above a target use whatever nameplates the player already has.
local PLAYER_CVARS = { "nameplateShowFriends", "nameplateShowFriendlyPlayers", "nameplateShowAll" }
local NPC_CVARS = { "nameplateShowFriendlyNPCs", "nameplateShowFriendlyNpcs" }

local function GetMode()
  local options = GetOptions()
  return options and options.Mode or "off"
end

-- Party covers everyone in your party except yourself; yourself is a separate option.

-- Inside dungeons, raids and scenarios arrows above friendly players are not allowed, so we do not switch
-- friendly nameplates on there (your own setting comes back on entering, ours on leaving).
local NO_ARROW_INSTANCES = { party = true, raid = true, scenario = true }
local function InNoArrowInstance()
  local inInstance, kind = IsInInstance()
  return inInstance and NO_ARROW_INSTANCES[kind] or false
end

-- The game only shows these nameplates with these CVars. Originals are saved and
-- restored when the option that needed them is switched off (or in a dungeon or raid).
GH.ApplyFriendlyPlates = function()
  local options = GetOptions()
  if not options or not C_CVar or not C_CVar.GetCVar then return end
  if InCombatLockdown() then
    pendingCVars = true
    return
  end
  pendingCVars = false
  options.CVarRestore = options.CVarRestore or {}
  local wanted = {}
  if GetMode() ~= "off" and not InNoArrowInstance() then
    for _, name in ipairs(PLAYER_CVARS) do wanted[name] = true end
  end
  -- The target option never touches NPC nameplates. NPC_CVARS is only here to put back a value an older
  -- version of this addon changed: it is never wanted, so a saved original is restored.
  local function Apply(name)
    local current = C_CVar.GetCVar(name)
    if current == nil then return end
    if wanted[name] then
      if current ~= "1" then
        if options.CVarRestore[name] == nil then options.CVarRestore[name] = current end
        pcall(C_CVar.SetCVar, name, "1")
      end
    elseif options.CVarRestore[name] ~= nil then
      pcall(C_CVar.SetCVar, name, options.CVarRestore[name])
      options.CVarRestore[name] = nil
    end
  end
  for _, name in ipairs(PLAYER_CVARS) do Apply(name) end
  for _, name in ipairs(NPC_CVARS) do Apply(name) end
end
-- Whether friendly NPCs can get an arrow: "on", "off" or "unavailable" when this version of
-- the game has no CVar for friendly NPC nameplates.
GH.GetNpcPlateStatus = function()
  if not C_CVar or not C_CVar.GetCVar then return "unavailable" end
  for _, name in ipairs(NPC_CVARS) do
    local value = C_CVar.GetCVar(name)
    if value ~= nil then return value == "1" and "on" or "off" end
  end
  return "unavailable"
end

GH.On("PLAYER_REGEN_ENABLED", function()
  if pendingCVars then GH.Highlight_Refresh() end
end)
GH.On("ZONE_CHANGED_NEW_AREA", function()
  GH.ApplyFriendlyPlates()
end)
