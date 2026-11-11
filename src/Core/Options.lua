GroupHighlight = GroupHighlight or {}
GroupHighlight.AddonName = ...

GroupHighlight.Modes = { "off", "party", "raid" }
GroupHighlight.Shapes = { "triangle", "chevron" }

GroupHighlight.Defaults = {
  Mode = "party",
  ShowSelf = false,
  ShowTarget = false,
  Shape = "triangle",
  TriangleFilled = true,
  ChevronCount = 2,
  ChevronFade = true,
  MemberColors = {},
  ArrowSize = 32,
  Lift = 1,
  SelfX = 0,
  SelfY = 0,
}

local function GetOptions()
  return GroupHighlightDB
end

local function CopyValue(value)
  if type(value) ~= "table" then return value end
  local copy = {}
  for key, inner in pairs(value) do
    copy[key] = CopyValue(inner)
  end
  return copy
end

GroupHighlight.IsValidMode = function(mode)
  for _, value in ipairs(GroupHighlight.Modes) do
    if value == mode then return true end
  end
  return false
end

-- Older versions had one Style option; it is split into a shape and its options.
GroupHighlight.MigrateStyle = function(options)
  local style = options.Style
  if style == nil then return end
  options.Style = nil
  if options.Shape ~= nil then return end
  if style == "outline" then
    options.Shape, options.TriangleFilled = "triangle", false
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

local function NotifyChanged(key)
  if GroupHighlight.Editor_OnOptionsChanged then
    GroupHighlight.Editor_OnOptionsChanged(key)
  end
  if GroupHighlight.Highlight_Refresh then
    GroupHighlight.Highlight_Refresh()
  end
end

GroupHighlight.SetOption = function(key, value)
  local options = GetOptions()
  if not options or options[key] == value then return false end
  options[key] = value
  NotifyChanged(key)
  return true
end

GroupHighlight.SetMode = function(mode)
  if not GroupHighlight.IsValidMode(mode) then return false end
  local options = GetOptions()
  -- Remember the mode that is being switched off, so it can come back later.
  if options and mode == "off" and options.Mode ~= "off" then options.LastMode = options.Mode end
  GroupHighlight.SetOption("Mode", mode)
  return true
end

-- Key binding: Off when it is on, and back to the mode it had before (not the default) when it is off.
GroupHighlight.ToggleEnabled = function()
  local options = GetOptions()
  if not options then return end
  local L = GroupHighlight.Loc
  if options.Mode ~= "off" then
    GroupHighlight.SetMode("off")
    print(L("toggle_message"):format(L("mode_off")))
    return
  end
  local mode = options.LastMode
  if not mode or mode == "off" or not GroupHighlight.IsValidMode(mode) then
    mode = GroupHighlight.Defaults.Mode
  end
  GroupHighlight.SetMode(mode)
  print(L("toggle_message"):format(L("mode_" .. mode)))
end

-- name is the unit's full name; passing no color resets it to the class color.
GroupHighlight.SetMemberColor = function(name, r, g, b)
  local options = GetOptions()
  if not options or not name then return end
  options.MemberColors = options.MemberColors or {}
  options.MemberColors[name] = r and { r = r, g = g, b = b } or nil
  NotifyChanged("MemberColors")
end

GroupHighlight.ResetOptions = function()
  local options = GetOptions()
  if not options then return end
  for key, value in pairs(GroupHighlight.Defaults) do
    options[key] = CopyValue(value)
  end
  options.LastMode = nil
  NotifyChanged("Defaults")
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, _, arg1)
  if arg1 ~= GroupHighlight.AddonName then return end
  GroupHighlightDB = GroupHighlightDB or {}
  GroupHighlight.MigrateStyle(GroupHighlightDB)
  for key, value in pairs(GroupHighlight.Defaults) do
    if GroupHighlightDB[key] == nil then
      GroupHighlightDB[key] = CopyValue(value)
    end
  end
  if GroupHighlightDB.Shape ~= "triangle" and GroupHighlightDB.Shape ~= "chevron" then GroupHighlightDB.Shape = GroupHighlight.Defaults.Shape end
  if type(GroupHighlightDB.ChevronCount) ~= "number" or GroupHighlightDB.ChevronCount < 1 or GroupHighlightDB.ChevronCount > 3 then GroupHighlightDB.ChevronCount = GroupHighlight.Defaults.ChevronCount end
  if GroupHighlightDB.Lift == nil or GroupHighlightDB.Lift < 1 or GroupHighlightDB.Lift > 60 then GroupHighlightDB.Lift = GroupHighlight.Defaults.Lift end
  if not GroupHighlight.IsValidMode(GroupHighlightDB.Mode) then
    GroupHighlightDB.Mode = GroupHighlight.Defaults.Mode
  end
  if GroupHighlight.Highlight_Refresh then
    GroupHighlight.Highlight_Refresh()
  end
  eventFrame:UnregisterEvent("ADDON_LOADED")
end)

SLASH_GROUPHIGHLIGHT1 = "/gh"
SLASH_GROUPHIGHLIGHT2 = "/grouphighlight"