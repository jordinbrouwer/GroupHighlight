-- A color picker made for this addon, fixed to the editor: a colour field for saturation and
-- brightness, a hue bar, class presets and a hex field. Changes show in the game world
-- immediately; Cancel or Esc undoes them.
GroupHighlight = GroupHighlight or {}
local L = GroupHighlight.Loc
local UI = GroupHighlight.UI
local THEME = UI.THEME

local WINDOW_NAME = "GroupHighlightColorPicker"
local CLASS_TOKENS = {
  "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN",
  "MAGE", "WARLOCK", "MONK", "DRUID", "DEMONHUNTER", "EVOKER",
}
local LAYOUT = {
  WIDTH = 300,
  MARGIN = 14,
  TITLE = 34,
  FOOTER = 50,
  FIELD_HEIGHT = 84,
  HUE_HEIGHT = 14,
  PRESET = 22,
  PRESET_GAP = 4,
  PRESET_COLUMNS = 13,
}
LAYOUT.CONTENT_WIDTH = LAYOUT.WIDTH - LAYOUT.MARGIN * 2
local picker
local state = { h = 0, s = 0, v = 1, silent = false }
local presetButtons = {}
local controls = {}

local function GetOptions()
  return GroupHighlightDB
end

local function RGBToHSV(r, g, b)
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local delta = max - min
  local h = 0
  if delta > 0 then
    if max == r then
      h = ((g - b) / delta) % 6
    elseif max == g then
      h = (b - r) / delta + 2
    else
      h = (r - g) / delta + 4
    end
    h = h * 60
  end
  return h, max == 0 and 0 or delta / max, max
end

local function HSVToRGB(h, s, v)
  local c = v * s
  local x = c * (1 - math.abs((h / 60) % 2 - 1))
  local m = v - c
  local r, g, b
  if h < 60 then r, g, b = c, x, 0
  elseif h < 120 then r, g, b = x, c, 0
  elseif h < 180 then r, g, b = 0, c, x
  elseif h < 240 then r, g, b = 0, x, c
  elseif h < 300 then r, g, b = x, 0, c
  else r, g, b = c, 0, x end
  return r + m, g + m, b + m
end

local function ToHex(r, g, b)
  return ("%02X%02X%02X"):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

local function FromHex(text)
  local hex = (text or ""):gsub("#", "")
  if #hex ~= 6 or hex:find("%X") then return end
  return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

local function Near(a, b)
  return math.abs(a - b) < 0.006
end

local function Clamp01(value)
  return math.max(0, math.min(1, value))
end

-- Applies the current colour to the player; the class colour is stored as nothing, so the
-- player keeps following their class.
local function Apply()
  local r, g, b = HSVToRGB(state.h, state.s, state.v)
  local cr, cg, cb = UI.GetClassColor(state.unit)
  if Near(r, cr) and Near(g, cg) and Near(b, cb) then
    GroupHighlight.SetMemberColor(state.name)
  else
    GroupHighlight.SetMemberColor(state.name, r, g, b)
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
    UI.SetBorderColor(button.Border, selected and THEME.GOLD or THEME.BORDER)
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
  local width, height = LAYOUT.CONTENT_WIDTH, LAYOUT.FIELD_HEIGHT
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetSize(width, height)
  frame:SetPoint("TOPLEFT", parent, "TOPLEFT", LAYOUT.MARGIN, y)
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
  UI.AddTooltip(frame, L("picker_tip_field"))
  return field
end

local function CreateHueBar(parent, y)
  local width, height = LAYOUT.CONTENT_WIDTH, LAYOUT.HUE_HEIGHT
  local slider = CreateFrame("Slider", nil, parent)
  slider:SetPoint("TOPLEFT", parent, "TOPLEFT", LAYOUT.MARGIN, y)
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
  thumb:SetSize(6, height + 4)
  thumb:SetVertexColor(1, 1, 1)

  slider:SetScript("OnValueChanged", function(_, number)
    if state.silent then return end
    state.h = math.floor(number + 0.5)
    UpdateControls()
    Apply()
  end)
  UI.AddTooltip(slider, L("picker_tip_hue"))
  local control = {}
  control.Set = function(number) slider:SetValue(number) end
  return control
end

local function CreateHexBox(parent)
  local box = CreateFrame("EditBox", nil, parent)
  box:SetSize(76, 22)
  box:SetFontObject("GameFontHighlight")
  box:SetAutoFocus(false)
  box:SetMaxLetters(7)
  box:SetTextInsets(7, 7, 0, 0)
  local background = box:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(box)
  background:SetColorTexture(unpack(THEME.INSET))
  local border = UI.AddBorder(box, THEME.BORDER)
  box:SetScript("OnEditFocusGained", function() UI.SetBorderColor(border, THEME.GOLD) end)
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
  UI.AddTooltip(box, L("picker_tip_hex"))
  return box
end

local function CreatePreset(parent, token, index)
  local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
  if not color then return end
  local column = (index - 1) % LAYOUT.PRESET_COLUMNS
  local row = math.floor((index - 1) / LAYOUT.PRESET_COLUMNS)
  local button = CreateFrame("Button", nil, parent)
  button:SetSize(LAYOUT.PRESET, LAYOUT.PRESET)
  button:SetPoint("TOPLEFT", parent, "TOPLEFT",
    LAYOUT.MARGIN + column * (LAYOUT.PRESET + LAYOUT.PRESET_GAP),
    parent.PresetTop - row * (LAYOUT.PRESET + LAYOUT.PRESET_GAP))
  button.r, button.g, button.b = color.r, color.g, color.b
  button.Fill = button:CreateTexture(nil, "ARTWORK")
  button.Fill:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
  button.Fill:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
  button.Fill:SetColorTexture(color.r, color.g, color.b)
  button.Border = UI.AddBorder(button, THEME.BORDER)
  button:SetScript("OnClick", function() SetColor(button.r, button.g, button.b, true) end)
  local names = LOCALIZED_CLASS_NAMES_MALE or {}
  UI.AddTooltip(button, L("picker_tip_preset"):format(names[token] or token))
  presetButtons[#presetButtons + 1] = button
end

local function BuildTitleBar()
  local bar = CreateFrame("Frame", nil, picker)
  bar:SetPoint("TOPLEFT", picker, "TOPLEFT", 1, -1)
  bar:SetPoint("TOPRIGHT", picker, "TOPRIGHT", -1, -1)
  bar:SetHeight(LAYOUT.TITLE - 1)
  local background = bar:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(bar)
  background:SetColorTexture(unpack(THEME.TITLE))
  local line = bar:CreateTexture(nil, "ARTWORK")
  line:SetColorTexture(THEME.GOLD[1], THEME.GOLD[2], THEME.GOLD[3], 0.55)
  line:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
  line:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
  line:SetHeight(1)
  controls.title = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  controls.title:SetPoint("LEFT", bar, "LEFT", 12, 0)
  controls.title:SetTextColor(unpack(THEME.GOLD))
  controls.title:SetText(L("picker_title"))

  -- The new colour and its hex code sit on the right of the title bar.
  controls.hex = CreateHexBox(bar)
  controls.hex:SetPoint("RIGHT", bar, "RIGHT", -8, 0)
  controls.new = UI.CreateSwatch(bar)
  controls.new:SetSize(20, 20)
  controls.new:SetPoint("RIGHT", controls.hex, "LEFT", -6, 0)
  controls.new:EnableMouse(false)
end

local function Build()
  -- The window is exactly as wide as one row with every class colour.
  local total = 0
  for _, token in ipairs(CLASS_TOKENS) do
    if RAID_CLASS_COLORS and RAID_CLASS_COLORS[token] then total = total + 1 end
  end
  LAYOUT.PRESET_COLUMNS = math.max(total, 1)
  LAYOUT.CONTENT_WIDTH = LAYOUT.PRESET_COLUMNS * LAYOUT.PRESET + (LAYOUT.PRESET_COLUMNS - 1) * LAYOUT.PRESET_GAP
  LAYOUT.WIDTH = LAYOUT.CONTENT_WIDTH + LAYOUT.MARGIN * 2

  picker = CreateFrame("Frame", WINDOW_NAME, UIParent)
  picker:SetSize(LAYOUT.WIDTH, 300)
  picker:SetFrameStrata("DIALOG")
  picker:SetToplevel(true)
  picker:EnableMouse(true)
  local background = picker:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(picker)
  background:SetColorTexture(unpack(THEME.WINDOW))
  UI.AddBorder(picker, THEME.BORDER)
  BuildTitleBar()

  local y = -(LAYOUT.TITLE + 12)
  controls.field = CreateField(picker, y)
  y = y - LAYOUT.FIELD_HEIGHT - 8
  controls.hue = CreateHueBar(picker, y)
  y = y - LAYOUT.HUE_HEIGHT - 10

  picker.PresetTop = y
  local index = 0
  for _, token in ipairs(CLASS_TOKENS) do
    if RAID_CLASS_COLORS and RAID_CLASS_COLORS[token] then
      index = index + 1
      CreatePreset(picker, token, index)
    end
  end
  local rows = math.ceil(index / LAYOUT.PRESET_COLUMNS)
  y = y - rows * (LAYOUT.PRESET + LAYOUT.PRESET_GAP) - 6

  picker:SetHeight(-y + LAYOUT.FOOTER)
  local footer = picker:CreateTexture(nil, "ARTWORK")
  footer:SetColorTexture(unpack(THEME.LINE))
  footer:SetPoint("BOTTOMLEFT", picker, "BOTTOMLEFT", LAYOUT.MARGIN, LAYOUT.FOOTER)
  footer:SetPoint("BOTTOMRIGHT", picker, "BOTTOMRIGHT", -LAYOUT.MARGIN, LAYOUT.FOOTER)
  footer:SetHeight(1)
  local cancel = UI.CreateButton(picker, L("picker_cancel"), 100, false, function() picker:Hide() end)
  cancel:SetPoint("BOTTOMLEFT", picker, "BOTTOMLEFT", LAYOUT.MARGIN, 11)
  local okay = UI.CreateButton(picker, L("picker_okay"), 100, true, function()
    state.accepted = true
    picker:Hide()
  end)
  okay:SetPoint("BOTTOMRIGHT", picker, "BOTTOMRIGHT", -LAYOUT.MARGIN, 11)

  -- Closing in any way other than Okay puts back what the player had.
  picker:SetScript("OnHide", function()
    if not state.accepted and state.name then
      local original = state.original
      if original then
        GroupHighlight.SetMemberColor(state.name, original.r, original.g, original.b)
      else
        GroupHighlight.SetMemberColor(state.name)
      end
    end
    GroupHighlight.SetPreviewMember(nil)
  end)
  tinsert(UISpecialFrames, WINDOW_NAME)
  picker:Hide()
end

-- The picker is fixed to the editor, on its right side or, when there is no room, its left side.
function GroupHighlight.RepositionColorPicker()
  if not picker then return end
  local editor = _G.GroupHighlightEditor
  picker:ClearAllPoints()
  if not editor then
    picker:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  elseif (editor:GetRight() or 0) + LAYOUT.WIDTH + 8 > (UIParent:GetRight() or 0) then
    picker:SetPoint("TOPRIGHT", editor, "TOPLEFT", -8, 0)
  else
    picker:SetPoint("TOPLEFT", editor, "TOPRIGHT", 8, 0)
  end
end
function GroupHighlight.OpenColorPicker(name, unit)
  local options = GetOptions()
  if not options or not name then return end
  if not picker then Build() end
  if picker:IsShown() then
    state.accepted = true
    picker:Hide()
  end
  state.name, state.unit, state.accepted = name, unit, false
  local stored = options.MemberColors and options.MemberColors[name]
  state.original = stored and { r = stored.r, g = stored.g, b = stored.b } or nil
  local r, g, b
  if stored then r, g, b = stored.r, stored.g, stored.b else r, g, b = UI.GetClassColor(unit) end
  GroupHighlight.SetPreviewMember(name, unit)
  SetColor(r, g, b, false)
  GroupHighlight.RepositionColorPicker()
  picker:Show()
end

function GroupHighlight.CloseColorPicker()
  if picker and picker:IsShown() then picker:Hide() end
end
