-- The base: the shared table, the pictures, and the one place that listens to game events.
-- The rest: Options (settings), Highlight (the arrows), Command (/gh), UI/ (the windows), Locale/ (texts).
GroupHighlight = GroupHighlight or {}
local GH = GroupHighlight
GH.AddonName = ...

-- Pictures (our own .tga files in the Media folder).
local MEDIA_DIR = "Interface\\AddOns\\" .. GH.AddonName .. "\\Media\\"
GH.Media = {
  Logo = MEDIA_DIR .. "Logo",                -- the addon icon (settings page, header of the window)
  Reset = MEDIA_DIR .. "Reset",
  Grip = MEDIA_DIR .. "Grip",
  Arrow = MEDIA_DIR .. "Arrow",              -- the arrows themselves
  Outline = MEDIA_DIR .. "Outline",
  Chevron1 = MEDIA_DIR .. "Chevron1",
  Chevron2Fade = MEDIA_DIR .. "Chevron2Fade",
  Chevron2Solid = MEDIA_DIR .. "Chevron2Solid",
  Chevron3Fade = MEDIA_DIR .. "Chevron3Fade",
  Chevron3Solid = MEDIA_DIR .. "Chevron3Solid",
  Diamond = MEDIA_DIR .. "Diamond",
  DiamondOutline = MEDIA_DIR .. "DiamondOutline",
  Circle = MEDIA_DIR .. "Circle",
  Ring = MEDIA_DIR .. "Ring",
  Star = MEDIA_DIR .. "Star",
  StarOutline = MEDIA_DIR .. "StarOutline",
  Pin = MEDIA_DIR .. "Pin",
  PinHole = MEDIA_DIR .. "PinHole",
  Shield = MEDIA_DIR .. "Shield",
  ShieldOutline = MEDIA_DIR .. "ShieldOutline",
  Sword = MEDIA_DIR .. "Sword",
  SwordOutline = MEDIA_DIR .. "SwordOutline",
  Plus = MEDIA_DIR .. "Plus",
  PlusOutline = MEDIA_DIR .. "PlusOutline",
}

-- The saved settings (nil until the game has loaded them).
GH.GetOptions = function()
  return GroupHighlightDB
end

-- Game events: GH.On("EVENT", fn). One frame listens for all of them.
local handlers = {}
local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(_, event, ...)
  for _, handler in ipairs(handlers[event]) do handler(...) end
end)

GH.On = function(event, handler)
  if not handlers[event] then
    handlers[event] = {}
    eventFrame:RegisterEvent(event)
  end
  table.insert(handlers[event], handler)
end
