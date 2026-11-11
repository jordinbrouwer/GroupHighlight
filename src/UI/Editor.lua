-- The editor window opened with /gh: movable, with live results in the game world.
GroupHighlight = GroupHighlight or {}
local L = GroupHighlight.Loc

local WINDOW_NAME = "GroupHighlightEditor"
local ICON_PATH = "Interface\\AddOns\\GroupHighlight\\GroupHighlight"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local MEMBER_UNITS = { "player", "party1", "party2", "party3", "party4" }

local LAYOUT = {
  MARGIN = 16,
  COLUMN = 300,
  GAP = 16,
  TITLE = 38,
  FOOTER = 64,
  ROW = 24,
  SECTION = 28,
  PREVIEW_HEIGHT = 122,
}
LAYOUT.WIDTH = LAYOUT.MARGIN * 2 + LAYOUT.COLUMN * 2 + LAYOUT.GAP
LAYOUT.CONTENT = 352
LAYOUT.STRIP = 26
LAYOUT.HEIGHT = LAYOUT.TITLE + LAYOUT.STRIP + LAYOUT.CONTENT + LAYOUT.FOOTER

local UI = GroupHighlight.UI
local THEME = UI.THEME
local AddBorder, SetBorderColor, AddTooltip = UI.AddBorder, UI.SetBorderColor, UI.AddTooltip
local CreateButton, CreateSwatch, GetClassColor = UI.CreateButton, UI.CreateSwatch, UI.GetClassColor

local window
local syncing = false
local modeSegment, shapeSegment, countSegment, filledCheck, fadeCheck, targetCheck, selfCheck
local sizeSlider, liftSlider, noPartyText, preview
local content, strip
local memberRows = {}

local AMBER = { 1, 0.65, 0.1, 1 }

-- The amber strip under the title bar is always shown: it tells where highlights do not work.
local function BuildInstanceStrip()
  strip = CreateFrame("Frame", nil, window)
  strip:SetPoint("TOPLEFT", window, "TOPLEFT", 1, -LAYOUT.TITLE)
  strip:SetPoint("TOPRIGHT", window, "TOPRIGHT", -1, -LAYOUT.TITLE)
  strip:SetHeight(LAYOUT.STRIP)
  local background = strip:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(strip)
  background:SetColorTexture(0.23, 0.16, 0.03, 1)
  local line = strip:CreateTexture(nil, "ARTWORK")
  line:SetColorTexture(unpack(AMBER))
  line:SetPoint("BOTTOMLEFT", strip, "BOTTOMLEFT", 0, 0)
  line:SetPoint("BOTTOMRIGHT", strip, "BOTTOMRIGHT", 0, 0)
  line:SetHeight(1)
  local dot = strip:CreateTexture(nil, "OVERLAY")
  dot:SetSize(8, 8)
  dot:SetColorTexture(unpack(AMBER))
  dot:SetPoint("LEFT", strip, "LEFT", LAYOUT.MARGIN, 0)
  local text = strip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  text:SetPoint("LEFT", dot, "RIGHT", 8, 0)
  text:SetTextColor(1, 0.85, 0.6, 1)
  text:SetText(L("instance_banner"))
end

local function GetOptions()
  return GroupHighlightDB
end

local function CreateSection(parent, x, y, width, text)
  local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  title:SetTextColor(unpack(THEME.GOLD))
  title:SetText(text)
  local line = parent:CreateTexture(nil, "ARTWORK")
  line:SetColorTexture(unpack(THEME.LINE))
  line:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 18)
  line:SetSize(width, 1)
end

local function CreateCheck(parent, x, y, width, labelText, tooltipText, onClick)
  local row = CreateFrame("Frame", nil, parent)
  row:SetSize(width, LAYOUT.ROW)
  row:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
  check:SetSize(24, 24)
  check:SetPoint("LEFT", row, "LEFT", 0, 0)
  local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  label:SetPoint("LEFT", check, "RIGHT", 4, 0)
  label:SetText(labelText)
  row:EnableMouse(true)
  row:SetScript("OnMouseUp", function(_, button)
    if button == "LeftButton" then check:Click() end
  end)
  AddTooltip(row, tooltipText)
  check:SetScript("OnClick", function(self)
    if not syncing then onClick(self:GetChecked() == true) end
  end)
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
    button.Label = button:CreateFontString(nil, "OVERLAY", labelFont or "GameFontHighlight")
    if entry.icon and inline then
      button.Label:SetPoint("CENTER", button, "CENTER", 14, 0)
      button.Icon = button:CreateTexture(nil, "ARTWORK")
      button.Icon:SetSize(24, 24)
      button.Icon:SetPoint("RIGHT", button.Label, "LEFT", -6, 0)
      button.Icon:SetTexture(entry.icon)
      button.Icon:SetVertexColor(unpack(THEME.GOLD))
    elseif entry.icon then
      button.Icon = button:CreateTexture(nil, "ARTWORK")
      button.Icon:SetSize(30, 30)
      button.Icon:SetPoint("TOP", button, "TOP", 0, -6)
      button.Icon:SetTexture(entry.icon)
      button.Icon:SetVertexColor(unpack(THEME.GOLD))
      button.Label:SetPoint("BOTTOM", button, "BOTTOM", 0, 5)
    else
      button.Label:SetPoint("CENTER", button, "CENTER", 0, 0)
    end
    button.Label:SetText(entry.label)
    button.Key = entry.key
    button:SetScript("OnClick", function()
      if not syncing then onSelect(entry.key) end
    end)
    button:SetScript("OnEnter", function(self)
      if not self.Selected then self.Background:SetColorTexture(0.2, 0.2, 0.23, 0.95) end
    end)
    button:SetScript("OnLeave", function(self)
      if not self.Selected then self.Background:SetColorTexture(unpack(THEME.BUTTON)) end
    end)
    AddTooltip(button, entry.tip)
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
      SetBorderColor(button.Border, selected and THEME.GOLD or THEME.BORDER)
      if selected then button.Label:SetTextColor(unpack(THEME.GOLD)) else button.Label:SetTextColor(1, 1, 1, 1) end
    end
  end
  return segment
end

local function CreateSlider(parent, x, y, width, key, minValue, maxValue, labelKey, tipKey)
  local holder = CreateFrame("Frame", nil, parent)
  holder:SetSize(width, 40)
  holder:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  local label = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  label:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
  label:SetText(L(labelKey))
  local valueText = holder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  valueText:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, 0)

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
  fill:SetColorTexture(THEME.GOLD[1], THEME.GOLD[2], THEME.GOLD[3], 0.75)
  fill:SetPoint("LEFT", slider, "LEFT", 0, 0)
  fill:SetHeight(4)
  slider:SetThumbTexture(WHITE)
  local thumb = slider:GetThumbTexture()
  thumb:SetSize(8, 16)
  thumb:SetVertexColor(unpack(THEME.GOLD))

  local function Show(value)
    valueText:SetText(tostring(value))
    fill:SetWidth(math.max(1, (value - minValue) / (maxValue - minValue) * (width - 8) + 4))
  end
  slider:SetScript("OnValueChanged", function(_, value)
    value = math.floor(value + 0.5)
    Show(value)
    if not syncing and GetOptions() and GetOptions()[key] ~= value then
      GroupHighlight.SetOption(key, value)
    end
  end)
  AddTooltip(slider, L(tipKey))
  slider.Display = Show
  return slider
end

-- The party member whose colour is being edited in the colour picker; nil shows the first
-- name in the party colours list.
local previewMember

local function UpdatePreview()
  local options = GetOptions()
  if not options or not preview then return end
  local member = previewMember
  local first = memberRows[1]
  if not member and first and first:IsShown() and first.Name then
    member = { name = first.Name, unit = first.Unit }
  end
  local r, g, b, name
  if member then
    local color = options.MemberColors and options.MemberColors[member.name]
    if color then r, g, b = color.r, color.g, color.b else r, g, b = GetClassColor(member.unit) end
    name = member.name
  else
    -- Nobody in the list: yourself, the same way the list would show you.
    r, g, b = GroupHighlight.GetColor("player")
    name = GetUnitName("player", true) or UnitName("player") or ""
  end
  preview.Name:SetText(name)
  preview.Name:SetTextColor(r, g, b)
  local size = options.ArrowSize or 32
  local offset = (options.Lift or 1) + 3
  local scale = math.min(1, 84 / (size + offset))
  preview.Arrow:SetTexture(GroupHighlight.GetStyleTexture())
  preview.Arrow:SetVertexColor(r, g, b)
  preview.Arrow:SetSize(size * scale, size * scale)
  preview.Arrow:ClearAllPoints()
  preview.Arrow:SetPoint("BOTTOM", preview.Name, "TOP", 0, offset * scale)
end

-- You only appear in the list when the arrow above yourself is on. The rows are
-- filled from the top, so there are no gaps.
local function UpdateMembers()
  local options = GetOptions()
  if not options then return end
  local shown = 0
  for _, unit in ipairs(MEMBER_UNITS) do
    local name = UnitExists(unit) and (unit ~= "player" or options.ShowSelf) and GetUnitName(unit, true)
    if name and issecretvalue and issecretvalue(name) then name = nil end
    if name then
      shown = shown + 1
      local row = memberRows[shown]
      row.Name = name
      row.Unit = unit
      row.Label:SetText(name)
      local color = options.MemberColors and options.MemberColors[name]
      local r, g, b
      if color then r, g, b = color.r, color.g, color.b else r, g, b = GetClassColor(unit) end
      row.Label:SetTextColor(r, g, b)
      row.Swatch.Color:SetColorTexture(r, g, b)
      row:Show()
    end
  end
  for index = shown + 1, #memberRows do
    memberRows[index]:Hide()
  end
  noPartyText:SetShown(shown == 0)
end
local function Sync()
  local options = GetOptions()
  if not options or not window then return end
  syncing = true
  modeSegment.SetSelected(options.Mode)
  shapeSegment.SetSelected(options.Shape)
  countSegment.SetSelected(options.ChevronCount)
  local isChevron = options.Shape == "chevron"
  countSegment.SetShown(isChevron)
  fadeCheck:GetParent():SetShown(isChevron)
  filledCheck:GetParent():SetShown(not isChevron)
  filledCheck:SetChecked(options.TriangleFilled ~= false)
  fadeCheck:SetChecked(options.ChevronFade ~= false)
  selfCheck:SetChecked(options.ShowSelf == true)
  targetCheck:SetChecked(options.ShowTarget == true)
  sizeSlider:SetValue(options.ArrowSize or 32)
  sizeSlider.Display(options.ArrowSize or 32)
  liftSlider:SetValue(options.Lift or 1)
  liftSlider.Display(options.Lift or 1)
  syncing = false
  -- The list first: the preview shows its first name.
  UpdateMembers()
  UpdatePreview()
end

local function BuildLeft(parent, x, y)
  local width = LAYOUT.COLUMN
  CreateSection(parent, x, y, width, L("editor_section_who"))
  y = y - LAYOUT.SECTION - 4
  local modeEntries = {}
  for _, mode in ipairs(GroupHighlight.Modes) do
    modeEntries[#modeEntries + 1] = { key = mode, label = L("mode_" .. mode), tip = L("mode_tip_" .. mode) }
  end
  modeSegment = CreateSegment(parent, x, y, width, 28, modeEntries, function(mode)
    if GetOptions() then GroupHighlight.SetMode(mode) end
  end)
  y = y - 28 - 6
  selfCheck = CreateCheck(parent, x, y, width, L("option_ShowSelf"), L("option_tip_ShowSelf"), function(value)
    GroupHighlight.SetOption("ShowSelf", value)
  end)
  y = y - LAYOUT.ROW
  targetCheck = CreateCheck(parent, x, y, width, L("option_ShowTarget"), function()
    return L("option_tip_ShowTarget") .. "\n\n" .. L("target_status"):format(L("target_status_" .. GroupHighlight.GetNpcPlateStatus()))
  end, function(value)
    GroupHighlight.SetOption("ShowTarget", value)
  end)
  y = y - LAYOUT.ROW
  y = y - 14

  CreateSection(parent, x, y, width, L("editor_section_look"))
  y = y - LAYOUT.SECTION - 4
  shapeSegment = CreateSegment(parent, x, y, width, 38, {
    { key = "triangle", label = L("shape_triangle"), tip = L("shape_tip_triangle"), icon = GroupHighlight.StyleTextures.triangle_filled },
    { key = "chevron", label = L("shape_chevron"), tip = L("shape_tip_chevron"), icon = GroupHighlight.StyleTextures.chevron2_fade },
  }, function(shape)
    GroupHighlight.SetOption("Shape", shape)
  end, nil, true)
  y = y - 38 - 8
  -- Triangle and chevron share one row; the row shows the options of the chosen shape.
  filledCheck = CreateCheck(parent, x, y, width, L("option_TriangleFilled"), L("option_tip_TriangleFilled"), function(value)
    GroupHighlight.SetOption("TriangleFilled", value)
  end)
  countSegment = CreateSegment(parent, x, y, 120, 24, {
    { key = 1, label = "1", tip = L("chevron_count_1") },
    { key = 2, label = "2", tip = L("chevron_count_2") },
    { key = 3, label = "3", tip = L("chevron_count_3") },
  }, function(count)
    GroupHighlight.SetOption("ChevronCount", count)
  end)
  fadeCheck = CreateCheck(parent, x + 136, y, width - 136, L("option_ChevronFade"), L("option_tip_ChevronFade"), function(value)
    GroupHighlight.SetOption("ChevronFade", value)
  end)
  y = y - LAYOUT.ROW - 8
  sizeSlider = CreateSlider(parent, x, y, width, "ArrowSize", 16, 96, "editor_size", "editor_tip_size")
  y = y - 44
  liftSlider = CreateSlider(parent, x, y, width, "Lift", 1, 50, "editor_lift", "editor_tip_lift")
end

local function BuildRight(parent, x, y)
  local width = LAYOUT.COLUMN
  CreateSection(parent, x, y, width, L("editor_section_preview"))
  y = y - LAYOUT.SECTION - 4
  local box = CreateFrame("Frame", nil, parent)
  box:SetSize(width, LAYOUT.PREVIEW_HEIGHT)
  box:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  local background = box:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(box)
  background:SetColorTexture(unpack(THEME.INSET))
  AddBorder(box, THEME.LINE)
  preview = { Frame = box }
  preview.Name = box:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  preview.Name:SetPoint("BOTTOM", box, "BOTTOM", 0, 14)
  preview.Arrow = box:CreateTexture(nil, "ARTWORK")
  preview.Arrow:SetBlendMode("ADD")
  y = y - LAYOUT.PREVIEW_HEIGHT - 14

  CreateSection(parent, x, y, width, L("editor_section_party"))
  y = y - LAYOUT.SECTION - 2
  noPartyText = parent:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  noPartyText:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 2, y - 4)
  noPartyText:SetText(L("editor_no_party"))
  for index = 1, #MEMBER_UNITS do
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(width, LAYOUT.ROW)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    row.Label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.Label:SetPoint("LEFT", row, "LEFT", 2, 0)
    row.Swatch = CreateSwatch(row, L("editor_tip_member"))
    row.Swatch:SetPoint("RIGHT", row, "RIGHT", -2, 0)
    row.Swatch:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row.Swatch:SetScript("OnClick", function(_, button)
      local options = GetOptions()
      if not options or not row.Name then return end
      if button == "RightButton" then
        GroupHighlight.SetMemberColor(row.Name)
        return
      end
      GroupHighlight.OpenColorPicker(row.Name, row.Unit)
    end)
    row:Hide()
    memberRows[index] = row
    y = y - LAYOUT.ROW
  end
end

local function SavePosition()
  local options = GetOptions()
  if not options then return end
  local point, _, relativePoint, x, y = window:GetPoint()
  options.EditorPoint = { point, relativePoint, x, y }
  GroupHighlight.RepositionColorPicker()
end

local function BuildTitleBar()
  local bar = CreateFrame("Frame", nil, window)
  bar:SetPoint("TOPLEFT", window, "TOPLEFT", 1, -1)
  bar:SetPoint("TOPRIGHT", window, "TOPRIGHT", -1, -1)
  bar:SetHeight(LAYOUT.TITLE - 1)
  bar:EnableMouse(true)
  bar:RegisterForDrag("LeftButton")
  bar:SetScript("OnDragStart", function() window:StartMoving() end)
  bar:SetScript("OnDragStop", function()
    window:StopMovingOrSizing()
    SavePosition()
  end)
  local background = bar:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(bar)
  background:SetColorTexture(unpack(THEME.TITLE))
  local line = bar:CreateTexture(nil, "ARTWORK")
  line:SetColorTexture(THEME.GOLD[1], THEME.GOLD[2], THEME.GOLD[3], 0.55)
  line:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
  line:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
  line:SetHeight(1)

  local icon = bar:CreateTexture(nil, "ARTWORK")
  icon:SetSize(26, 26)
  icon:SetPoint("LEFT", bar, "LEFT", 12, 0)
  icon:SetTexture(ICON_PATH)
  local title = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("LEFT", icon, "RIGHT", 8, 0)
  title:SetText("GroupHighlight")
  local version = bar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  version:SetPoint("LEFT", title, "RIGHT", 8, -1)
  local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  local text = getMeta and getMeta(GroupHighlight.AddonName or "GroupHighlight", "Version") or ""
  version:SetText(text:find("@", 1, true) and "" or text)

  local close = CreateFrame("Button", nil, bar)
  close:SetSize(28, 28)
  close:SetPoint("RIGHT", bar, "RIGHT", -6, 0)
  local mark = close:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  mark:SetPoint("CENTER", close, "CENTER", 0, 1)
  mark:SetText("x")
  mark:SetTextColor(0.7, 0.7, 0.7, 1)
  close:SetScript("OnEnter", function() mark:SetTextColor(unpack(THEME.GOLD)) end)
  close:SetScript("OnLeave", function() mark:SetTextColor(0.7, 0.7, 0.7, 1) end)
  close:SetScript("OnClick", function() window:Hide() end)
end

local function BuildFooter()
  local line = window:CreateTexture(nil, "ARTWORK")
  line:SetColorTexture(unpack(THEME.LINE))
  line:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", LAYOUT.MARGIN, LAYOUT.FOOTER)
  line:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -LAYOUT.MARGIN, LAYOUT.FOOTER)
  line:SetHeight(1)

  local defaults = CreateButton(window, L("editor_defaults"), 120, false, function()
    GroupHighlight.ResetOptions()
  end, L("editor_tip_defaults"))
  defaults:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", LAYOUT.MARGIN, 18)

  local close = CreateButton(window, L("editor_close"), 120, true, function() window:Hide() end)
  close:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -LAYOUT.MARGIN, 18)
end
local function BuildWindow()
  window = CreateFrame("Frame", WINDOW_NAME, UIParent)
  window:SetSize(LAYOUT.WIDTH, LAYOUT.HEIGHT)
  window:SetFrameStrata("DIALOG")
  window:SetToplevel(true)
  window:SetMovable(true)
  window:SetClampedToScreen(true)
  window:EnableMouse(true)
  local saved = GetOptions() and GetOptions().EditorPoint
  if saved then
    window:SetPoint(saved[1], UIParent, saved[2], saved[3], saved[4])
  else
    window:SetPoint("LEFT", UIParent, "LEFT", 60, 0)
  end

  local background = window:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(window)
  background:SetColorTexture(unpack(THEME.WINDOW))
  AddBorder(window, THEME.BORDER)

  BuildTitleBar()
  BuildInstanceStrip()
  content = CreateFrame("Frame", nil, window)
  content:SetPoint("TOPLEFT", window, "TOPLEFT", 0, -(LAYOUT.TITLE + LAYOUT.STRIP))
  content:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", 0, LAYOUT.FOOTER)
  BuildLeft(content, LAYOUT.MARGIN, -14)
  BuildRight(content, LAYOUT.MARGIN + LAYOUT.COLUMN + LAYOUT.GAP, -14)
  BuildFooter()

  window:SetScript("OnShow", function()
    GroupHighlight.SetEditing(true)
    Sync()
  end)
  window:SetScript("OnHide", function()
    GroupHighlight.CloseColorPicker()
    GroupHighlight.SetEditing(false)
  end)
  window:RegisterEvent("GROUP_ROSTER_UPDATE")
  window:RegisterEvent("PLAYER_TARGET_CHANGED")
  window:RegisterEvent("PLAYER_ENTERING_WORLD")
  window:SetScript("OnEvent", function()
    if window:IsShown() then Sync() end
  end)
  tinsert(UISpecialFrames, WINDOW_NAME)
  window:Hide()
end

function GroupHighlight.OpenEditor()
  if not GetOptions() then return end
  if not window then BuildWindow() end
  window:Show()
end

function GroupHighlight.ToggleEditor()
  if window and window:IsShown() then
    window:Hide()
  else
    GroupHighlight.OpenEditor()
  end
end

-- Called by the colour picker: show this member in the preview, or yourself again with no name.
GroupHighlight.SetPreviewMember = function(name, unit)
  previewMember = name and { name = name, unit = unit } or nil
  UpdatePreview()
end

GroupHighlight.Editor_OnOptionsChanged = function()
  if window and window:IsShown() then Sync() end
end