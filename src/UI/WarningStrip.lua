-- The amber band along the bottom (where the footer hint is in ARC): where the arrows do not work. As high as its text needs (it wraps when narrow).
local GH = GroupHighlight
local UI = GH.UI
local L = GH.Loc
local LAYOUT = UI.LAYOUT
local S = UI.state

local AMBER = { 1, 0.65, 0.1, 1 }
local BACKGROUND = { 0.23, 0.16, 0.03, 1 }
local TEXT_COLOR = { 1, 0.85, 0.6, 1 }

function UI.BuildWarningStrip(window)
  local strip = CreateFrame("Frame", nil, window)
  strip:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 1, 1)
  strip:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -1, 1)
  strip:SetHeight(LAYOUT.FOOTER)
  local background = strip:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(strip)
  background:SetColorTexture(unpack(BACKGROUND))
  local line = strip:CreateTexture(nil, "ARTWORK")
  line:SetColorTexture(unpack(AMBER))
  line:SetPoint("TOPLEFT", strip, "TOPLEFT", 0, 0)
  line:SetPoint("TOPRIGHT", strip, "TOPRIGHT", 0, 0)
  UI.OnePixel(line, true)
  local text = strip:CreateFontString(nil, "OVERLAY", "GroupHighlightFontHighlightSmall")
  text:SetPoint("LEFT", strip, "LEFT", 10, 0)   -- the same 10 as the hint in ARC
  text:SetPoint("RIGHT", strip, "RIGHT", -24, 0)   -- the text wraps inside the window, clear of the resize grip
  text:SetJustifyH("LEFT")
  text:SetTextColor(unpack(TEXT_COLOR))
  text:SetText(L("instance_banner"))
  strip.Text = text
  S.strip = strip
  return strip
end

-- Makes the strip as high as its text needs. Gives back its height.
function UI.FitStrip()
  local strip = S.strip
  local height = math.max(LAYOUT.FOOTER, math.ceil(strip.Text:GetStringHeight()) + 12)
  if math.abs(strip:GetHeight() - height) > 0.5 then strip:SetHeight(height) end
  return height
end
