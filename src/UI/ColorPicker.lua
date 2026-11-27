-- The colour picker, fixed to the editor: a colour field, a hue bar, class presets and a hex field.
-- Changes show in the game at once; Cancel or Esc undoes them.
local GH = GroupHighlight
local L = GH.Loc
local UI = GH.UI
local S = UI.state
local THEME = UI.THEME
local GetOptions = GH.GetOptions
local RGBToHSV, HSVToRGB, ToHex, FromHex, Near, Clamp01 = UI.RGBToHSV, UI.HSVToRGB, UI.ToHex, UI.FromHex, UI.Near, UI.Clamp01

local WINDOW_NAME = "GroupHighlightColorPicker"
local CLASS_TOKENS = {
  "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN",
  "MAGE", "WARLOCK", "MONK", "DRUID", "DEMONHUNTER", "EVOKER",
}
local PICKER = {
  WIDTH = 300,
  MARGIN = 10,
  TITLE = 30,
  FOOTER = 36,
  FIELD_HEIGHT = 64,
  HUE_HEIGHT = 10,
  PRESET = 16,
  PRESET_GAP = 3,
  PRESET_COLUMNS = 13,
}
PICKER.CONTENT_WIDTH = PICKER.WIDTH - PICKER.MARGIN * 2
local picker
local state = { h = 0, s = 0, v = 1, silent = false }
local presetButtons = {}
local controls = {}

-- Applies the current colour to the player; the class colour is stored as nothing, so the
-- player keeps following their class.
local function Apply()
  local r, g, b = HSVToRGB(state.h, state.s, state.v)
  local cr, cg, cb = UI.GetClassColor(state.unit)
  if Near(r, cr) and Near(g, cg) and Near(b, cb) then
    GH.SetMemberColor(state.name)
  else
    GH.SetMemberColor(state.name, r, g, b)
  end
end

local function UpdateControls(keepHex)
  local r, g, b = HSVToRGB(state.h, state.s, state.v)
  state.silent = true
  controls.hue.Set(state.h)
  state.silent = false
  controls.field.Set(state.h, state.s, state.v)
  controls.new.Color:SetColorTexture(r, g, b)
  if not keepHex then controls.hex:SetText(ToHex(r, g, b)) end
  for _, button in ipairs(presetButtons) do
    local selected = Near(button.r, r) and Near(button.g, g) and Near(button.b, b)
    UI.SetBorderColor(button.Border, selected and THEME.ACCENT or THEME.BORDER)
  end
end

-- user is true when the change comes from the player, which applies it.
local function SetColor(r, g, b, user, keepHex)
  state.h, state.s, state.v = RGBToHSV(r, g, b)
  UpdateControls(keepHex)
  if user then Apply() end
end

-- The square: saturation grows to the right, brightness grows upwards.
local function CreateField(parent, y)
  local width, height = PICKER.CONTENT_WIDTH, PICKER.FIELD_HEIGHT
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetSize(width, height)
  frame:SetPoint("TOPLEFT", parent, "TOPLEFT", PICKER.MARGIN, y)
  frame:EnableMouse(true)

  local base = frame:CreateTexture(nil, "BACKGROUND")
  base:SetAllPoints(frame)
  base:SetColorTexture(1, 1, 1, 1)
  local shade = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
  shade:SetAllPoints(frame)
  shade:SetColorTexture(1, 1, 1, 1)
  shade:SetGradient("VERTICAL", CreateColor(0, 0, 0, 1), CreateColor(0, 0, 0, 0))
  UI.AddBorder(frame, THEME.BORDER)

  local cursor = CreateFrame("Frame", nil, frame)
  cursor:SetSize(12, 12)
  UI.AddBorder(cursor, { 0, 0, 0, 1 })
  local ring = CreateFrame("Frame", nil, cursor)
  ring:SetPoint("TOPLEFT", cursor, "TOPLEFT", 1, -1)
  ring:SetPoint("BOTTOMRIGHT", cursor, "BOTTOMRIGHT", -1, 1)
  UI.AddBorder(ring, { 1, 1, 1, 1 })

  local field = {}
  function field.Set(h, s, v)
    local r, g, b = HSVToRGB(h, 1, 1)
    base:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 1), CreateColor(r, g, b, 1))
    cursor:ClearAllPoints()
    cursor:SetPoint("CENTER", frame, "TOPLEFT", s * width, -(1 - v) * height)
  end

  local dragging = false
  local function Pick()
    local left, top = frame:GetLeft(), frame:GetTop()
    if not left then return end
    local scale = frame:GetEffectiveScale()
    local cursorX, cursorY = GetCursorPosition()
    state.s = Clamp01((cursorX / scale - left) / width)
    state.v = 1 - Clamp01((top - cursorY / scale) / height)
    UpdateControls()
    Apply()
  end
  frame:SetScript("OnMouseDown", function(_, button)
    if button ~= "LeftButton" then return end
    dragging = true
    Pick()
  end)
  frame:SetScript("OnMouseUp", function() dragging = false end)
  frame:SetScript("OnHide", function() dragging = false end)
  frame:SetScript("OnUpdate", function()
    if not dragging then return end
    if IsMouseButtonDown("LeftButton") then Pick() else dragging = false end
  end)
  UI.AddTooltip(frame, L("picker_tip_field"), L("picker_name_field"))
  return field
end

local function CreateHueBar(parent, y)
  local width, height = PICKER.CONTENT_WIDTH, PICKER.HUE_HEIGHT
  local slider = CreateFrame("Slider", nil, parent)
  slider:SetPoint("TOPLEFT", parent, "TOPLEFT", PICKER.MARGIN, y)
  slider:SetSize(width, height)
  slider:SetOrientation("HORIZONTAL")
  slider:SetMinMaxValues(0, 360)
  slider:SetValueStep(1)
  if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end

  local segments = 36
  for index = 0, segments - 1 do
    local piece = slider:CreateTexture(nil, "BACKGROUND")
    piece:SetColorTexture(HSVToRGB(index * 360 / segments, 1, 1))
    piece:SetSize(width / segments + 0.5, height)
    piece:SetPoint("LEFT", slider, "LEFT", index * width / segments, 0)
  end
  slider:SetThumbTexture(UI.WHITE)
  local thumb = slider:GetThumbTexture()
  thumb:SetSize(4, height + 4)
  thumb:SetVertexColor(1, 1, 1)

  slider:SetScript("OnValueChanged", function(_, number)
    if state.silent then return end
    state.h = math.floor(number + 0.5)
    UpdateControls()
    Apply()
  end)
  UI.AddTooltip(slider, L("picker_tip_hue"), L("picker_name_hue"))
  local control = {}
  control.Set = function(number) slider:SetValue(number) end
  return control
end

local function CreateHexBox(parent)
  local box = CreateFrame("EditBox", nil, parent)
  box:SetSize(66, 20)
  box:SetFontObject("GroupHighlightFontHighlightSmall")
  box:SetAutoFocus(false)
  box:SetMaxLetters(7)
  box:SetTextInsets(7, 7, 0, 0)
  local background = box:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(box)
  background:SetColorTexture(unpack(THEME.INSET))
  local border = UI.AddBorder(box, THEME.BORDER)
  box:SetScript("OnEditFocusGained", function() UI.SetBorderColor(border, THEME.ACCENT) end)
  box:SetScript("OnEditFocusLost", function(self)
    UI.SetBorderColor(border, THEME.BORDER)
    local r, g, b = FromHex(self:GetText())
    if r then SetColor(r, g, b, true) else UpdateControls() end
  end)
  box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  box:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    UpdateControls()
  end)
  box:SetScript("OnTextChanged", function(self, byUser)
    if not byUser then return end
    local r, g, b = FromHex(self:GetText())
    if r then SetColor(r, g, b, true, true) end
  end)
  UI.AddTooltip(box, L("picker_tip_hex"), L("picker_name_hex"))
  return box
end

local function CreatePreset(parent, token, index)
  local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
  if not color then return end
  local column = (index - 1) % PICKER.PRESET_COLUMNS
  local row = math.floor((index - 1) / PICKER.PRESET_COLUMNS)
  local button = CreateFrame("Button", nil, parent)
  button:SetSize(PICKER.PRESET, PICKER.PRESET)
  button:SetPoint("TOPLEFT", parent, "TOPLEFT",
    PICKER.MARGIN + column * (PICKER.PRESET + PICKER.PRESET_GAP),
    parent.PresetTop - row * (PICKER.PRESET + PICKER.PRESET_GAP))
  button.r, button.g, button.b = color.r, color.g, color.b
  button.Fill = button:CreateTexture(nil, "ARTWORK")
  button.Fill:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
  button.Fill:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
  button.Fill:SetColorTexture(color.r, color.g, color.b)
  button.Border = UI.AddBorder(button, THEME.BORDER)
  button:SetScript("OnClick", function() SetColor(button.r, button.g, button.b, true) end)
  local names = LOCALIZED_CLASS_NAMES_MALE or {}
  UI.AddTooltip(button, L("picker_tip_preset"), names[token] or token)
  presetButtons[#presetButtons + 1] = button
end

local function BuildTitleBar()
  local bar = UI.CreateHeaderBand(picker, PICKER.TITLE - 3)
  controls.title = bar:CreateFontString(nil, "OVERLAY", "GroupHighlightFontNormal")
  controls.title:SetPoint("LEFT", bar, "LEFT", 12, 0)
  controls.title:SetTextColor(unpack(THEME.TITLE_TEXT))
  controls.title:SetText(L("picker_title"))

  -- The hex code and the new colour sit on the right of the header band; the colour at the far right, like the
  -- chosen shape in the shape picker.
  controls.new = UI.CreateSwatch(bar)
  controls.new:SetSize(18, 18)
  controls.new:SetPoint("RIGHT", bar, "RIGHT", -8, 0)
  controls.new:EnableMouse(false)
  controls.hex = CreateHexBox(bar)
  controls.hex:SetPoint("RIGHT", controls.new, "LEFT", -6, 0)
end
local function Build()
  -- The window is exactly as wide as one row with every class colour.
  local total = 0
  for _, token in ipairs(CLASS_TOKENS) do
    if RAID_CLASS_COLORS and RAID_CLASS_COLORS[token] then total = total + 1 end
  end
  PICKER.PRESET_COLUMNS = math.max(total, 1)
  PICKER.CONTENT_WIDTH = PICKER.PRESET_COLUMNS * PICKER.PRESET + (PICKER.PRESET_COLUMNS - 1) * PICKER.PRESET_GAP
  PICKER.WIDTH = PICKER.CONTENT_WIDTH + PICKER.MARGIN * 2

  picker = CreateFrame("Frame", WINDOW_NAME, UIParent)
  picker:SetSize(PICKER.WIDTH, 300)
  picker:SetFrameStrata("DIALOG")
  picker:SetToplevel(true)
  picker:EnableMouse(true)
  UI.StyleWindow(picker)
  BuildTitleBar()

  local y = -(PICKER.TITLE + 8)
  controls.field = CreateField(picker, y)
  y = y - PICKER.FIELD_HEIGHT - 6
  controls.hue = CreateHueBar(picker, y)
  y = y - PICKER.HUE_HEIGHT - 8

  -- the class colours sit on a faint band, like a row of the members table
  local band = picker:CreateTexture(nil, "BACKGROUND")
  band:SetColorTexture(1, 1, 1, 0.035)
  band:SetPoint("TOPLEFT", picker, "TOPLEFT", PICKER.MARGIN - 4, y + 3)
  band:SetPoint("TOPRIGHT", picker, "TOPRIGHT", -(PICKER.MARGIN - 4), y + 3)
  band:SetHeight(PICKER.PRESET + 6)

  picker.PresetTop = y
  local index = 0
  for _, token in ipairs(CLASS_TOKENS) do
    if RAID_CLASS_COLORS and RAID_CLASS_COLORS[token] then
      index = index + 1
      CreatePreset(picker, token, index)
    end
  end
  local rows = math.ceil(index / PICKER.PRESET_COLUMNS)
  y = y - rows * (PICKER.PRESET + PICKER.PRESET_GAP) - 2

  picker:SetHeight(-y + PICKER.FOOTER)
  local footer = picker:CreateTexture(nil, "ARTWORK")
  footer:SetColorTexture(unpack(THEME.LINE))
  footer:SetPoint("BOTTOMLEFT", picker, "BOTTOMLEFT", PICKER.MARGIN, PICKER.FOOTER)
  footer:SetPoint("BOTTOMRIGHT", picker, "BOTTOMRIGHT", -PICKER.MARGIN, PICKER.FOOTER)
  UI.OnePixel(footer, true)
  local cancel = UI.FlatChip(picker, L("picker_cancel"), 80, false, function() picker:Hide() end)
  cancel:SetPoint("BOTTOMLEFT", picker, "BOTTOMLEFT", PICKER.MARGIN, 7)
  cancel:SetHeight(22)
  local okay = UI.FlatChip(picker, L("picker_okay"), 80, true, function()
    state.accepted = true
    picker:Hide()
  end)
  okay:SetPoint("BOTTOMRIGHT", picker, "BOTTOMRIGHT", -PICKER.MARGIN, 7)
  okay:SetHeight(22)

  -- Closing in any way other than Okay puts back what the player had.
  picker:SetScript("OnHide", function()
    if not state.accepted and state.name then
      local original = state.original
      if original then
        GH.SetMemberColor(state.name, original.r, original.g, original.b)
      else
        GH.SetMemberColor(state.name)
      end
    end
    GH.SetPreviewMember(nil)
  end)
  tinsert(UISpecialFrames, WINDOW_NAME)
  UI.ApplyOutline(picker)
  picker:Hide()
end

-- A picker (colour or shape) is fixed to the editor, on its right side or, when there is no room, its left side. Its bottom
-- is level with the bottom of the members table (kept inside the editor), so it sits next to the table.
function UI.PlaceBesideEditor(frame)
  local editor = _G.GroupHighlightEditor
  frame:ClearAllPoints()
  if not editor then
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    return
  end
  local members = S.boxes and S.boxes.members
  local lift = 0
  if members and members:GetBottom() and editor:GetBottom() then
    lift = math.max(0, members:GetBottom() - editor:GetBottom())
  end
  lift = math.min(lift, math.max(0, (UIParent:GetTop() or 0) - (editor:GetBottom() or 0) - frame:GetHeight()))
  if (editor:GetRight() or 0) + frame:GetWidth() + 8 > (UIParent:GetRight() or 0) then
    frame:SetPoint("BOTTOMRIGHT", editor, "BOTTOMLEFT", -8, lift)
  else
    frame:SetPoint("BOTTOMLEFT", editor, "BOTTOMRIGHT", 8, lift)
  end
end

function GH.RepositionColorPicker()
  if picker then UI.PlaceBesideEditor(picker) end
  if GH.RepositionShapePicker then GH.RepositionShapePicker() end
end
function GH.OpenColorPicker(name, unit)
  local options = GetOptions()
  if not options or not name then return end
  if not picker then Build() end
  GH.CloseShapePicker(true)
  if picker:IsShown() then
    state.accepted = true
    picker:Hide()
  end
  state.name, state.unit, state.accepted = name, unit, false
  local stored = options.MemberColors and options.MemberColors[name]
  state.original = stored and { r = stored.r, g = stored.g, b = stored.b } or nil
  local r, g, b
  if stored then r, g, b = stored.r, stored.g, stored.b else r, g, b = UI.GetClassColor(unit) end
  GH.SetPreviewMember(name, unit)
  SetColor(r, g, b, false)
  GH.RepositionColorPicker()
  picker:Show()
end

-- keep: true keeps the changes (the shape picker opens instead), else they are undone like with Cancel.
function GH.CloseColorPicker(keep)
  if picker and picker:IsShown() then
    state.accepted = keep or state.accepted
    picker:Hide()
  end
end
