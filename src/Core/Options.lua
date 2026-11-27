-- The settings: their defaults, changing them, and tidying the saved file when the addon loads.
local GH = GroupHighlight
local GetOptions = GH.GetOptions

GH.Modes = { "off", "party", "raid" }

GH.Defaults = {
  Mode = "party",
  ShowSelf = false,
  ShowTarget = false,
  Shape = "triangle",
  Filled = true,
  ChevronCount = 2,
  ChevronFade = true,
  Drawing = GH.DEFAULT_DRAWING,   -- the shape Drawing (Core/Drawing.lua)
  MemberColors = {},
  MemberShapes = {},   -- name -> their own look (the LOOK_KEYS); a name without one follows Look
  ArrowSize = 32,
  Lift = 1,
}

-- The settings of each section of the window, so a section can be reset on its own.
GH.Sections = {
  who = { "Mode", "ShowSelf", "ShowTarget" },
  look = { "Shape", "Filled", "ChevronCount", "ChevronFade", "Drawing", "ArrowSize", "Lift" },
  members = { "MemberColors", "MemberShapes" },
}

local function CopyValue(value)
  if type(value) ~= "table" then return value end
  local copy = {}
  for key, inner in pairs(value) do
    copy[key] = CopyValue(inner)
  end
  return copy
end

-- "off", "party" or "raid".
GH.GetMode = function()
  local options = GetOptions()
  return options and options.Mode or "off"
end

GH.IsValidMode = function(mode)
  for _, value in ipairs(GH.Modes) do
    if value == mode then return true end
  end
  return false
end

-- Tells the window and the arrows that something changed.
local function NotifyChanged(key)
  if GH.RefreshWindow then GH.RefreshWindow(key) end
  if GH.Highlight_Refresh then GH.Highlight_Refresh() end
end

GH.SetOption = function(key, value)
  local options = GetOptions()
  if not options or options[key] == value then return false end
  options[key] = value
  NotifyChanged(key)
  return true
end

GH.SetMode = function(mode)
  if not GH.IsValidMode(mode) then return false end
  local options = GetOptions()
  -- Remember the mode that is being switched off, so it can come back later.
  if options and mode == "off" and options.Mode ~= "off" then options.LastMode = options.Mode end
  GH.SetOption("Mode", mode)
  return true
end

-- Key binding: Off when it is on, and back to the mode it had before (not the default) when it is off.
GH.ToggleEnabled = function()
  local options = GetOptions()
  if not options then return end
  local L = GH.Loc
  if options.Mode ~= "off" then
    GH.SetMode("off")
    GH.ShowToast(L("toggle_message"):format(L("mode_off")))
    return
  end
  local mode = options.LastMode
  if not mode or mode == "off" or not GH.IsValidMode(mode) then
    mode = GH.Defaults.Mode
  end
  GH.SetMode(mode)
  GH.ShowToast(L("toggle_message"):format(L("mode_" .. mode)))
end

-- name is the unit's full name; passing no color resets it to the class color.
GH.SetMemberColor = function(name, r, g, b)
  local options = GetOptions()
  if not options or not name then return end
  options.MemberColors = options.MemberColors or {}
  options.MemberColors[name] = r and { r = r, g = g, b = b } or nil
  NotifyChanged("MemberColors")
end

-- The settings of a look: in the options (Look) and in a member's own look.
GH.LOOK_KEYS = { "Shape", "Filled", "ChevronCount", "ChevronFade", "Drawing", "ArrowSize", "Lift" }

local function SameLook(a, b)
  return GH.GetLookTexture(a) == GH.GetLookTexture(b) and (a.Shape ~= "drawing" or a.Drawing == b.Drawing)
    and a.ArrowSize == b.ArrowSize and a.Lift == b.Lift
end

-- name is the unit's full name; look holds the LOOK_KEYS. Passing no look, or one that looks the same as Look,
-- goes back to following Look. exact stores the look as it is (undo puts back what was there).
GH.SetMemberShape = function(name, look, exact)
  local options = GetOptions()
  if not options or not name then return end
  if look and not exact and SameLook(look, options) then look = nil end
  local copy
  if look then
    copy = {}
    for _, key in ipairs(GH.LOOK_KEYS) do copy[key] = look[key] end
  end
  options.MemberShapes = options.MemberShapes or {}
  options.MemberShapes[name] = copy
  NotifyChanged("MemberShapes")
end

-- Puts only the settings of one section ("who", "look" or "members") back to their defaults.
GH.ResetSection = function(section)
  local options = GetOptions()
  local keys = GH.Sections[section]
  if not options or not keys then return end
  for _, key in ipairs(keys) do
    options[key] = CopyValue(GH.Defaults[key])
  end
  if section == "who" then options.LastMode = nil end
  NotifyChanged("Defaults")
end

---------------------------------------------------------------- the saved file
-- DB_VERSION goes up when settings are renamed or removed; the steps run once.
local DB_VERSION = 3

-- Older versions had one Style setting; it is split into a shape and its options.
local function MigrateStyle(options)
  local style = options.Style
  if style == nil then return end
  options.Style = nil
  if options.Shape ~= nil then return end
  if style == "outline" then
    options.Shape, options.Filled = "triangle", false
  elseif style == "chevron1" then
    options.Shape, options.ChevronCount = "chevron", 1
  elseif style == "chevron" or style == "chevron2" then
    options.Shape, options.ChevronCount = "chevron", 2
  elseif style == "chevron3" then
    options.Shape, options.ChevronCount = "chevron", 3
  else
    options.Shape = "triangle"
  end
end

-- TriangleFilled became Filled when more shapes got an outline version.
local function MigrateFilled(options)
  if options.TriangleFilled == nil then return end
  if options.Filled == nil then options.Filled = options.TriangleFilled end
  options.TriangleFilled = nil
end

local function Migrate(options)
  if (options.DbVersion or 0) >= DB_VERSION then return end
  MigrateStyle(options)
  MigrateFilled(options)
  options.DbVersion = DB_VERSION
end

-- Puts a value back to its default when it is not something the addon can use.
local function Sanitize(options)
  local defaults = GH.Defaults
  if not GH.ShapeInfo[options.Shape] then options.Shape = defaults.Shape end
  if options.Lift == nil or options.Lift < 1 or options.Lift > 60 then options.Lift = defaults.Lift end
  if type(options.ArrowSize) ~= "number" then options.ArrowSize = defaults.ArrowSize end
  if not GH.IsValidDrawing(options.Drawing) then options.Drawing = defaults.Drawing end
  if type(options.MemberShapes) ~= "table" then options.MemberShapes = {} end
  for name, look in pairs(options.MemberShapes) do
    if type(look) ~= "table" or not GH.ShapeInfo[look.Shape] then
      options.MemberShapes[name] = nil
    else
      if type(look.ArrowSize) ~= "number" then look.ArrowSize = options.ArrowSize end
      if type(look.Lift) ~= "number" or look.Lift < 1 or look.Lift > 60 then look.Lift = options.Lift end
      if not GH.IsValidDrawing(look.Drawing) then look.Drawing = options.Drawing end
    end
  end
  local count = options.ChevronCount
  if type(count) ~= "number" or count < 1 or count > 3 then options.ChevronCount = defaults.ChevronCount end
  if not GH.IsValidMode(options.Mode) then options.Mode = defaults.Mode end
end

GH.On("ADDON_LOADED", function(addonName)
  if addonName ~= GH.AddonName then return end
  GroupHighlightDB = GroupHighlightDB or {}
  local options = GroupHighlightDB
  Migrate(options)
  for key, value in pairs(GH.Defaults) do
    if options[key] == nil then options[key] = CopyValue(value) end
  end
  Sanitize(options)
  if GH.Highlight_Refresh then GH.Highlight_Refresh() end
end)
