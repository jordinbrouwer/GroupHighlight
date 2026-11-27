-- The shape picker, fixed to the editor like the colour picker: the shape of one party member, with the same
-- dropdown and options as Look. Changes show in the game at once; Cancel or Esc undoes them.
local GH = GroupHighlight
local L = GH.Loc
local UI = GH.UI
local THEME = UI.THEME
local GetOptions = GH.GetOptions

local WINDOW_NAME = "GroupHighlightShapePicker"
local PICKER = {
  MARGIN = 10,
  TITLE = 30,
  FOOTER = 36,
  CONTENT_WIDTH = 220,
}
PICKER.WIDTH = PICKER.CONTENT_WIDTH + PICKER.MARGIN * 2
local picker, controls, current
local state = {}

-- The look being edited: the member's own look, or else a copy of Look.
local function CopyLook(look)
  local copy = {}
  for _, key in ipairs(GH.LOOK_KEYS) do copy[key] = look[key] end
  return copy
end

local function Show()
  controls.Sync(state.look)
  picker:SetHeight(PICKER.TITLE + 10 + controls.frame:GetHeight() + 10 + PICKER.FOOTER)
  -- a chevron makes it higher: place it again, so it stays on the screen
  if picker:IsShown() then UI.PlaceBesideEditor(picker) end
  current.SetLook(state.look)
end

local function Change(key, value)
  state.look[key] = value
  GH.SetMemberShape(state.name, state.look)
  Show()
end

local function Build()
  picker = CreateFrame("Frame", WINDOW_NAME, UIParent)
  picker:SetFrameStrata("DIALOG")
  picker:SetToplevel(true)
  picker:EnableMouse(true)
  UI.StyleWindow(picker)

  -- The header band: the title, and the chosen shape in the member's colour on the right.
  local bar = UI.CreateHeaderBand(picker, PICKER.TITLE - 3)
  local title = bar:CreateFontString(nil, "OVERLAY", "GroupHighlightFontNormal")
  title:SetPoint("LEFT", bar, "LEFT", 12, 0)
  title:SetTextColor(unpack(THEME.TITLE_TEXT))
  title:SetText(L("shape_picker_title"))
  local frame = CreateFrame("Frame", nil, bar)
  frame:SetSize(20, 20)
  frame:SetPoint("RIGHT", bar, "RIGHT", -8, 0)
  local background = frame:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(frame)
  background:SetColorTexture(unpack(THEME.INSET))
  UI.AddBorder(frame, THEME.BORDER)
  local inner = CreateFrame("Frame", nil, frame)
  inner:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
  inner:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
  current = GH.CreateShapeView(inner, "ARTWORK")

  controls = UI.CreateShapeControls(picker, PICKER.MARGIN, -(PICKER.TITLE + 10), PICKER.CONTENT_WIDTH, Change)
  picker:SetWidth(PICKER.WIDTH)   -- the height follows the chosen shape (Show)
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

  -- Closing in any way other than Okay puts back what the member had.
  picker:SetScript("OnHide", function()
    UI.CloseMenu()
    if not state.accepted and state.name then GH.SetMemberShape(state.name, state.original, true) end
    GH.SetPreviewMember(nil)
  end)
  tinsert(UISpecialFrames, WINDOW_NAME)
  UI.ApplyOutline(picker)
  picker:Hide()
end

function GH.OpenShapePicker(name, unit)
  local options = GetOptions()
  if not options or not name then return end
  if not picker then Build() end
  GH.CloseColorPicker(true)
  if picker:IsShown() then
    state.accepted = true
    picker:Hide()
  end
  local own = options.MemberShapes and options.MemberShapes[name]
  state.name, state.accepted = name, false
  state.original = own and CopyLook(own) or nil
  state.look = CopyLook(own or options)
  current.SetColor(GH.GetColor(unit))
  GH.SetPreviewMember(name, unit)
  Show()
  UI.PlaceBesideEditor(picker)
  picker:Show()
end

-- The look being edited while the picker is open (the preview draws on it), and how to change it.
function GH.GetPickerLook()
  return picker and picker:IsShown() and state.look or nil
end
GH.SetPickerOption = function(key, value) Change(key, value) end

function GH.RepositionShapePicker()
  if picker and picker:IsShown() then UI.PlaceBesideEditor(picker) end
end

-- keep: true keeps the changes (the colour picker opens instead), else they are undone like with Cancel.
function GH.CloseShapePicker(keep)
  if picker and picker:IsShown() then
    state.accepted = keep or state.accepted
    picker:Hide()
  end
end
