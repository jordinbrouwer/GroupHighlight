-- A thin scroll bar: a track and a thumb you can drag. It hides when everything fits.
local GH = GroupHighlight
local UI = GH.UI
local THEME = UI.THEME

-- Puts the bar on the right edge of `scroll` (`inset` pixels in: negative is inside), as a part of `parent`.
-- Gives back the function that updates the bar.
function UI.CreateScrollBar(parent, scroll, inset)
  local track = CreateFrame("Frame", nil, parent)
  track:SetWidth(3)
  track:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", inset, -2)
  track:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", inset, 2)
  local trackBackground = track:CreateTexture(nil, "BACKGROUND")
  trackBackground:SetAllPoints(track)
  trackBackground:SetColorTexture(1, 1, 1, 0.07)
  local thumb = CreateFrame("Button", nil, track)
  thumb:SetWidth(3)
  local thumbTexture = thumb:CreateTexture(nil, "ARTWORK")
  thumbTexture:SetAllPoints(thumb)
  local function Paint(color) thumbTexture:SetColorTexture(color[1], color[2], color[3], color[4] or 0.85) end
  Paint(THEME.GREY)
  local function Update()
    scroll:UpdateScrollChildRect()
    local range = scroll:GetVerticalScrollRange()
    local trackHeight = track:GetHeight()
    -- taller window or shorter content while scrolled down: go back up as far as needed
    if scroll:GetVerticalScroll() > (range or 0) then scroll:SetVerticalScroll(math.max(0, range or 0)) end
    if not range or range < 1 or not trackHeight or trackHeight <= 0 then
      scroll:SetVerticalScroll(0)
      track:Hide()
      return
    end
    track:Show()
    local viewHeight = scroll:GetHeight()
    local thumbHeight = math.max(28, trackHeight * viewHeight / (viewHeight + range))
    thumb:SetHeight(thumbHeight)
    thumb:ClearAllPoints()
    thumb:SetPoint("TOP", track, "TOP", 0, -(scroll:GetVerticalScroll() / range) * (trackHeight - thumbHeight))
  end
  local grab = 0
  thumb:SetScript("OnMouseDown", function(self)
    local _, cursorY = GetCursorPosition()
    grab = self:GetTop() * self:GetEffectiveScale() - cursorY
    Paint(THEME.ACCENT)
    self:SetScript("OnUpdate", function()
      local _, y = GetCursorPosition()
      local offset = track:GetTop() - (y + grab) / track:GetEffectiveScale()
      local free = math.max(1, track:GetHeight() - thumb:GetHeight())
      scroll:SetVerticalScroll(math.max(0, math.min(1, offset / free)) * scroll:GetVerticalScrollRange())
    end)
  end)
  thumb:SetScript("OnMouseUp", function(self)
    self:SetScript("OnUpdate", nil)
    Paint(THEME.GREY)
  end)
  thumb:SetScript("OnEnter", function() Paint(THEME.MUTED) end)
  thumb:SetScript("OnLeave", function() Paint(THEME.GREY) end)
  scroll:HookScript("OnVerticalScroll", Update)
  scroll:HookScript("OnScrollRangeChanged", Update)
  scroll:HookScript("OnSizeChanged", Update)
  return Update
end
