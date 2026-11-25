-- The small flat parts: window frame, header band, close cross, switch, button and colour swatch.
local GH = GroupHighlight
local UI = GH.UI
local THEME = UI.THEME

-- A window frame: flat dark, a thin border and the blue line along the top.
function UI.StyleWindow(frame)
  local background = frame:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(frame)
  background:SetColorTexture(unpack(THEME.WINDOW))
  UI.AddBorder(frame, THEME.BORDER)
  local accent = frame:CreateTexture(nil, "ARTWORK")
  accent:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
  accent:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
  accent:SetHeight(2)
  accent:SetColorTexture(unpack(THEME.ACCENT))
end

-- The dark blue header band under the blue line (3 pixels from the top of the window).
function UI.CreateHeaderBand(parent, height)
  local bar = CreateFrame("Frame", nil, parent)
  bar:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, -3)
  bar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -1, -3)
  bar:SetHeight(height)
  local background = bar:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(bar)
  background:SetColorTexture(unpack(THEME.HEADER))
  return bar
end

-- A drawn cross: muted, bright under the mouse.
function UI.CreateCloseButton(parent, onClick)
  local close = CreateFrame("Button", nil, parent)
  close:SetSize(24, 22)
  local bars = {}
  for _, angle in ipairs({ 45, -45 }) do
    local bar = close:CreateTexture(nil, "ARTWORK")
    bar:SetSize(11, 1.5)
    bar:SetPoint("CENTER", close, "CENTER", 0, 0)
    bar:SetRotation(math.rad(angle))
    bars[#bars + 1] = bar
  end
  local function Paint(color)
    for _, bar in ipairs(bars) do bar:SetColorTexture(color[1], color[2], color[3], 1) end
  end
  close:SetScript("OnEnter", function() Paint(THEME.BRIGHT) end)
  close:SetScript("OnLeave", function() Paint(THEME.MUTED) end)
  close:SetScript("OnClick", onClick)
  Paint(THEME.MUTED)
  return close
end

---------------------------------------------------------------- switch, button, swatch
-- A small on/off switch (a pill with a knob). Works like a CheckButton: SetChecked, GetChecked, Click.
function UI.FlatSwitch(parent, onClick)
  local box = CreateFrame("Button", nil, parent)
  box:SetSize(26, 14)
  box.Track = box:CreateTexture(nil, "BACKGROUND")
  box.Track:SetAllPoints(box)
  box.Knob = box:CreateTexture(nil, "ARTWORK")
  box.Knob:SetSize(10, 10)
  function box:SetChecked(on)
    self.checked = on and true or false
    local c = self.checked and THEME.ACCENT or THEME.TRACK
    local lift = self.hover and 0.08 or 0
    self.Track:SetColorTexture(math.min(1, c[1] + lift), math.min(1, c[2] + lift), math.min(1, c[3] + lift), 1)
    self.Knob:ClearAllPoints()
    local side = self.checked and "RIGHT" or "LEFT"
    self.Knob:SetPoint(side, self, side, self.checked and -2 or 2, 0)
    if self.checked then self.Knob:SetColorTexture(0.08, 0.08, 0.1, 1) else self.Knob:SetColorTexture(0.72, 0.74, 0.8, 1) end
  end
  function box:GetChecked() return self.checked end
  box:SetScript("OnEnter", function(self) self.hover = true self:SetChecked(self.checked) end)
  box:SetScript("OnLeave", function(self) self.hover = false self:SetChecked(self.checked) end)
  box:SetScript("OnClick", function(self)
    self:SetChecked(not self.checked)
    if onClick then onClick(self) end
  end)
  box:SetChecked(false)
  return box
end

-- A flat button; a primary button has a blue edge and blue text.
function UI.FlatChip(parent, text, width, primary, onClick, tooltipText)
  local button = CreateFrame("Button", nil, parent)
  button:SetSize(width, 28)
  button.Background = button:CreateTexture(nil, "BACKGROUND")
  button.Background:SetAllPoints(button)
  button.Border = UI.AddBorder(button, primary and THEME.ACCENT or THEME.BORDER)
  button.Label = button:CreateFontString(nil, "OVERLAY", "GroupHighlightFontHighlightSmall")
  button.Label:SetPoint("CENTER", button, "CENTER", 0, 0)
  button.Label:SetText(text)
  local function Rest()
    button.Background:SetColorTexture(unpack(primary and THEME.BUTTON_ON or THEME.BUTTON))
    button.Label:SetTextColor(unpack(primary and THEME.ON_TEXT or { 1, 1, 1, 1 }))
  end
  Rest()
  button:SetScript("OnEnter", function()
    button.Background:SetColorTexture(unpack(THEME.BUTTON_HOVER))
    UI.SetBorderColor(button.Border, THEME.ACCENT)
  end)
  button:SetScript("OnLeave", function()
    Rest()
    UI.SetBorderColor(button.Border, primary and THEME.ACCENT or THEME.BORDER)
  end)
  button:SetScript("OnMouseDown", function() button.Label:SetPoint("CENTER", button, "CENTER", 0, -1) end)
  button:SetScript("OnMouseUp", function() button.Label:SetPoint("CENTER", button, "CENTER", 0, 0) end)
  button:SetScript("OnClick", onClick)
  if tooltipText then UI.AddTooltip(button, tooltipText, text) end
  return button
end

function UI.CreateSwatch(parent, tooltipText)
  local swatch = CreateFrame("Button", nil, parent)
  swatch:SetSize(22, 22)
  swatch.Edge = swatch:CreateTexture(nil, "BACKGROUND")
  swatch.Edge:SetAllPoints(swatch)
  swatch.Edge:SetColorTexture(unpack(THEME.GREY))
  swatch.Color = swatch:CreateTexture(nil, "ARTWORK")
  swatch.Color:SetPoint("TOPLEFT", swatch, "TOPLEFT", 2, -2)
  swatch.Color:SetPoint("BOTTOMRIGHT", swatch, "BOTTOMRIGHT", -2, 2)
  swatch:SetScript("OnEnter", function(self) self.Edge:SetColorTexture(unpack(THEME.ACCENT)) end)
  swatch:SetScript("OnLeave", function(self) self.Edge:SetColorTexture(unpack(THEME.GREY)) end)
  if tooltipText then UI.AddTooltip(swatch, tooltipText) end
  return swatch
end

function UI.GetClassColor(unit)
  local _, class = UnitClass(unit)
  if issecretvalue and issecretvalue(class) then class = nil end
  local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  if color then return color.r, color.g, color.b end
  return 1, 0.82, 0
end
