-- What the boxes are made of: the box (title, reset icon), a row with a switch, a row of buttons (a segment), a slider.
local GH = GroupHighlight
local UI = GH.UI
local L = GH.Loc
local GetOptions = GH.GetOptions
local LAYOUT, THEME = UI.LAYOUT, UI.THEME
local AddBorder, SetBorderColor, AddTooltip = UI.AddBorder, UI.SetBorderColor, UI.AddTooltip
local WHITE = UI.WHITE
local BOX_INDENT, BOX_BOTTOM = LAYOUT.BOX_INDENT, LAYOUT.BOX_BOTTOM

-- The reset icon on the right of a title: grey, gold under the mouse. The first click asks "Click again"
-- (3 seconds, in red); the second click resets.
local function AddReset(parent, section)
  local link = CreateFrame("Button", nil, parent)
  link:SetHeight(14)
  link.Icon = link:CreateTexture(nil, "ARTWORK")
  link.Icon:SetSize(9, 9)
  link.Icon:SetPoint("RIGHT", link, "RIGHT", 0, 0)
  link.Icon:SetTexture(GH.Media.Reset)
  link.Text = link:CreateFontString(nil, "OVERLAY", "GroupHighlightFontHighlightSmall")
  link.Text:SetPoint("RIGHT", link.Icon, "LEFT", -3, 0)
  link.Text:SetScale(0.85)   -- a little smaller than the other texts, the same as in AutomaticRoleCheck
  local armedUntil
  local function Show(text, color)
    link.Text:SetText(text)
    link.Text:SetTextColor(color[1], color[2], color[3], 1)
    link.Icon:SetVertexColor(color[1], color[2], color[3], 1)
    link:SetWidth(text ~= "" and (link.Text:GetStringWidth() * 0.85 + 16) or 16)
  end
  local function Rest()
    armedUntil = nil
    Show("", THEME.GREY)
  end
  Rest()
  local function ShowTip()
    UI.Tip.Show(link, "RIGHT", L("editor_reset"), armedUntil and L("editor_reset_confirm") or L("editor_tip_reset_" .. section))
  end
  link:SetScript("OnEnter", function()
    if not armedUntil then Show("", THEME.ACCENT) end
    ShowTip()
  end)
  link:SetScript("OnLeave", function()
    if not armedUntil then Rest() end
    UI.Tip.Hide(link)
  end)
  link:SetScript("OnClick", function()
    if armedUntil and GetTime() < armedUntil then
      GH.ResetSection(section)
      Rest()
      return
    end
    armedUntil = GetTime() + 3
    Show(L("editor_reset_confirm"), THEME.DANGER)
    if UI.Tip.owner == link then ShowTip() end
    C_Timer.After(3, function()
      if armedUntil and GetTime() >= armedUntil then Rest() end
    end)
  end)
  return link
end


-- A box: dark, a thin border, the title in the corner and the reset icon on the right. What is in it goes on the box
-- (from BOX_INDENT, -BOX_HEADER); FinishBox sets its height. Layout.lua places the box.
local function CreateBox(parent, width, titleText, resetSection)
  local box = CreateFrame("Frame", nil, parent)
  box:SetWidth(width + BOX_INDENT * 2)
  local background = box:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(box)
  background:SetColorTexture(unpack(THEME.BOX_BG))
  AddBorder(box, THEME.BOX_BORDER)
  box.Title = box:CreateFontString(nil, "OVERLAY", "GroupHighlightFontNormalSmall")
  box.Title:SetPoint("TOPLEFT", box, "TOPLEFT", LAYOUT.BOX_TITLE_X, LAYOUT.BOX_TITLE_Y)
  box.Title:SetTextColor(unpack(THEME.ACCENT))
  box.Title:SetText(titleText)
  if resetSection then
    AddReset(box, resetSection):SetPoint("TOPRIGHT", box, "TOPRIGHT", -5, -2)
  end
  return box
end

local function FinishBox(box, y)
  box:SetHeight(-y + BOX_BOTTOM)
end
local function CreateCheckboxRow(parent, x, y, width, labelText, tooltipText, onClick)
  local row = CreateFrame("Frame", nil, parent)
  row:SetSize(width, LAYOUT.ROW_H)
  row:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  -- Our own flat check box (UI.FlatSwitch), not Blizzard's template.
  local check = UI.FlatSwitch(row, function(self)
    if not UI.state.syncing then onClick(self:GetChecked() == true) end
  end)
  check:SetPoint("RIGHT", row, "RIGHT", 0, 0)
  local label = row:CreateFontString(nil, "OVERLAY", "GroupHighlightFontHighlightSmall")
  label:SetPoint("LEFT", row, "LEFT", 0, 0)
  label:SetText(labelText)
  row:EnableMouse(true)
  row:SetScript("OnMouseUp", function(_, button)
    if button == "LeftButton" then check:Click() end
  end)
  -- Hovering the label lights up the box too.
  row:HookScript("OnEnter", function() check.hover = true check:SetChecked(check.checked) end)
  row:HookScript("OnLeave", function() check.hover = false check:SetChecked(check.checked) end)
  AddTooltip(row, tooltipText, labelText)
  return check
end

-- A row of buttons where exactly one is selected.
local function CreateSegment(parent, x, y, width, height, entries, onSelect, labelFont, inline)
  local segment = { buttons = {} }
  local gap = 4
  local buttonWidth = (width - gap * (#entries - 1)) / #entries
  for index, entry in ipairs(entries) do
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(buttonWidth, height)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x + (index - 1) * (buttonWidth + gap), y)
    button.Background = button:CreateTexture(nil, "BACKGROUND")
    button.Background:SetAllPoints(button)
    button.Border = AddBorder(button, THEME.BORDER)
    button.Label = button:CreateFontString(nil, "OVERLAY", labelFont or "GroupHighlightFontHighlightSmall")
    if entry.icon and inline then
      button.Label:SetPoint("CENTER", button, "CENTER", 14, 0)
      button.Icon = button:CreateTexture(nil, "ARTWORK")
      button.Icon:SetSize(24, 24)
      button.Icon:SetPoint("RIGHT", button.Label, "LEFT", -6, 0)
      button.Icon:SetTexture(entry.icon)
      button.Icon:SetVertexColor(unpack(THEME.ACCENT))
    elseif entry.icon then
      button.Icon = button:CreateTexture(nil, "ARTWORK")
      button.Icon:SetSize(30, 30)
      button.Icon:SetPoint("TOP", button, "TOP", 0, -6)
      button.Icon:SetTexture(entry.icon)
      button.Icon:SetVertexColor(unpack(THEME.ACCENT))
      button.Label:SetPoint("BOTTOM", button, "BOTTOM", 0, 5)
    else
      button.Label:SetPoint("CENTER", button, "CENTER", 0, 0)
    end
    button.Label:SetText(entry.label)
    button.Key = entry.key
    button:SetScript("OnClick", function()
      if not UI.state.syncing then onSelect(entry.key) end
    end)
    button:SetScript("OnEnter", function(self)
      if not self.Selected then self.Background:SetColorTexture(unpack(THEME.BUTTON_HOVER)) SetBorderColor(self.Border, THEME.ACCENT) end
    end)
    button:SetScript("OnLeave", function(self)
      if not self.Selected then self.Background:SetColorTexture(unpack(THEME.BUTTON)) SetBorderColor(self.Border, THEME.BORDER) end
    end)
    AddTooltip(button, entry.tip, entry.title or entry.label)
    button.Background:SetColorTexture(unpack(THEME.BUTTON))
    segment.buttons[index] = button
  end
  function segment.SetShown(shown)
    for _, button in ipairs(segment.buttons) do button:SetShown(shown) end
  end
  function segment.SetSelected(key)
    for _, button in ipairs(segment.buttons) do
      local selected = button.Key == key
      button.Selected = selected
      button.Background:SetColorTexture(unpack(selected and THEME.BUTTON_ON or THEME.BUTTON))
      SetBorderColor(button.Border, selected and THEME.ACCENT or THEME.BORDER)
      if selected then button.Label:SetTextColor(unpack(THEME.ON_TEXT)) else button.Label:SetTextColor(1, 1, 1, 1) end
    end
  end
  return segment
end

local function CreateSlider(parent, x, y, width, key, minValue, maxValue, labelKey, tipKey)
  local holder = CreateFrame("Frame", nil, parent)
  holder:SetSize(width, 40)
  holder:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  local label = holder:CreateFontString(nil, "OVERLAY", "GroupHighlightFontHighlightSmall")
  label:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
  label:SetText(L(labelKey))
  local valueText = holder:CreateFontString(nil, "OVERLAY", "GroupHighlightFontNormalSmall")
  valueText:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, 0)
  valueText:SetTextColor(unpack(THEME.ACCENT))

  local slider = CreateFrame("Slider", nil, holder)
  slider:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -20)
  slider:SetSize(width, 16)
  slider:SetOrientation("HORIZONTAL")
  slider:SetMinMaxValues(minValue, maxValue)
  slider:SetValueStep(1)
  if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end

  local track = slider:CreateTexture(nil, "BACKGROUND")
  track:SetColorTexture(unpack(THEME.TRACK))
  track:SetPoint("LEFT", slider, "LEFT", 0, 0)
  track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
  track:SetHeight(4)
  local fill = slider:CreateTexture(nil, "ARTWORK")
  fill:SetColorTexture(THEME.ACCENT[1], THEME.ACCENT[2], THEME.ACCENT[3], 0.85)
  fill:SetPoint("LEFT", slider, "LEFT", 0, 0)
  fill:SetHeight(4)
  slider:SetThumbTexture(WHITE)
  local thumb = slider:GetThumbTexture()
  thumb:SetSize(8, 16)
  thumb:SetVertexColor(unpack(THEME.ACCENT))

  local function Show(value)
    valueText:SetText(tostring(value))
    fill:SetWidth(math.max(1, (value - minValue) / (maxValue - minValue) * (width - 8) + 4))
  end
  slider:SetScript("OnValueChanged", function(_, value)
    value = math.floor(value + 0.5)
    Show(value)
    if not UI.state.syncing and GetOptions() and GetOptions()[key] ~= value then
      GH.SetOption(key, value)
    end
  end)
  -- the whole row (the name, the value and the bar) shows the tooltip, hanging on the row
  holder:EnableMouse(true)
  AddTooltip(holder, L(tipKey), L(labelKey))
  AddTooltip(slider, L(tipKey), L(labelKey), holder)
  slider.Display = Show
  return slider
end

UI.CreateBox, UI.FinishBox, UI.CreateCheckboxRow, UI.CreateSegment, UI.CreateSlider = CreateBox, FinishBox, CreateCheckboxRow, CreateSegment, CreateSlider
