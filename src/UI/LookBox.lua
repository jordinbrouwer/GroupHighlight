-- The box "Look": the shape (a dropdown), its options, and the size and height of the shape.
local GH = GroupHighlight
local UI = GH.UI
local L = GH.Loc
local LAYOUT = UI.LAYOUT
local CreateBox, FinishBox = UI.CreateBox, UI.FinishBox
local CreateCheckboxRow, CreateSegment, CreateDropdown, CreateSlider = UI.CreateCheckboxRow, UI.CreateSegment, UI.CreateDropdown, UI.CreateSlider
local BOX_INDENT, BOX_HEADER = LAYOUT.BOX_INDENT, LAYOUT.BOX_HEADER

local shapeControls

local SEGMENT_W = 98   -- the 1 2 3 buttons of the chevron count

-- The shape dropdown with, under it, the options of the chosen shape: Filled, or for a chevron the count and Fade out
-- (each on its own row, so it fits a narrow picker too), and the sliders Shape size and Lift above name.
-- Used by Look and by the shape picker. onChange(key, value) gets one of GH.LOOK_KEYS.
-- Gives back { frame, Sync(look) }: the frame holds everything and is as high as the chosen shape needs.
function UI.CreateShapeControls(parent, x, y, width, onChange)
  local area = CreateFrame("Frame", nil, parent)
  area:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  area:SetWidth(width)
  local entries = {}
  for _, shape in ipairs(GH.Shapes) do
    local key = shape.key
    entries[#entries + 1] = {
      key = key, label = L("shape_" .. key), tip = L("shape_tip_" .. key),
      hint = key == "chevron" and L("shape_hint_chevron") or nil,   -- the other shapes only have Filled, which speaks for itself
      -- the outline where a shape has one: the list then reads as shapes, not as the choice Filled
      icon = GH.StyleTextures[key == "chevron" and "chevron2_fade" or key .. (shape.outline and "_outline" or "_filled")],
    }
  end
  local dropdown = CreateDropdown(area, 0, 0, width, 38, entries, function(shape) onChange("Shape", shape) end)
  local rowY = -38 - 8
  local filledCheck = CreateCheckboxRow(area, 0, rowY, width, L("option_Filled"), L("option_tip_Filled"), function(value)
    onChange("Filled", value)
  end)
  -- a chevron: the count on the first row, Fade out on the second
  local countRow = CreateFrame("Frame", nil, area)
  countRow:SetSize(width - SEGMENT_W - 8, LAYOUT.ROW_H)
  countRow:SetPoint("TOPLEFT", area, "TOPLEFT", 0, rowY)
  local countLabel = countRow:CreateFontString(nil, "OVERLAY", "GroupHighlightFontHighlightSmall")
  countLabel:SetPoint("LEFT", countRow, "LEFT", 0, 0)
  countLabel:SetText(L("option_ChevronCount"))
  countRow:EnableMouse(true)
  UI.AddTooltip(countRow, L("option_tip_ChevronCount"), L("option_ChevronCount"))
  local countSegment = CreateSegment(area, width - SEGMENT_W, rowY + 1, SEGMENT_W, 22, {
    { key = 1, label = "1", title = L("shape_chevron"), tip = L("chevron_count_1") },
    { key = 2, label = "2", title = L("shape_chevron"), tip = L("chevron_count_2") },
    { key = 3, label = "3", title = L("shape_chevron"), tip = L("chevron_count_3") },
  }, function(count) onChange("ChevronCount", count) end)
  local fadeCheck = CreateCheckboxRow(area, 0, rowY - LAYOUT.ROW_H - 6, width, L("option_ChevronFade"), L("option_tip_ChevronFade"), function(value)
    onChange("ChevronFade", value)
  end)
  -- the size and the height hang under the options of the shape, which are higher for a chevron
  local options = CreateFrame("Frame", nil, area)
  options:SetSize(width, 1)
  local sizeSlider = CreateSlider(area, 0, 0, width, "ArrowSize", 16, 96, "editor_size", "editor_tip_size", onChange)
  sizeSlider:GetParent():ClearAllPoints()
  sizeSlider:GetParent():SetPoint("TOPLEFT", options, "BOTTOMLEFT", 0, -8)
  local liftSlider = CreateSlider(area, 0, 0, width, "Lift", 1, 50, "editor_lift", "editor_tip_lift", onChange)
  liftSlider:GetParent():ClearAllPoints()
  liftSlider:GetParent():SetPoint("TOPLEFT", sizeSlider:GetParent(), "TOPLEFT", 0, -44)
  local controls = { frame = area }
  -- Shows a look; the controls must not answer it as if the player changed them (SetValue fires OnValueChanged).
  function controls.Sync(look)
    local wasSyncing = UI.state.syncing
    UI.state.syncing = true
    dropdown.SetSelected(look.Shape)
    countSegment.SetSelected(look.ChevronCount)
    local isChevron = look.Shape == "chevron"
    countRow:SetShown(isChevron)
    countSegment.SetShown(isChevron)
    fadeCheck:GetParent():SetShown(isChevron)
    local info = GH.ShapeInfo[look.Shape]
    filledCheck:GetParent():SetShown(info and info.outline or false)
    filledCheck:SetChecked(look.Filled ~= false)
    fadeCheck:SetChecked(look.ChevronFade ~= false)
    sizeSlider:SetValue(look.ArrowSize or 32)
    sizeSlider.Display(look.ArrowSize or 32)
    liftSlider:SetValue(look.Lift or 1)
    liftSlider.Display(look.Lift or 1)
    -- a drawing has no options: the sliders come right under the dropdown
    local optionsH = look.Shape == "drawing" and -rowY - 8 or -rowY + LAYOUT.ROW_H + (isChevron and LAYOUT.ROW_H + 6 or 0)
    options:SetPoint("TOPLEFT", area, "TOPLEFT", 0, -optionsH + 1)
    area:SetHeight(optionsH + 8 + 44 + 40)
    UI.state.syncing = wasSyncing
  end
  return controls
end

local lookBox

function UI.BuildLookBox(parent)
  lookBox = CreateBox(parent, LAYOUT.COLUMN, L("editor_section_look"), "look")
  shapeControls = UI.CreateShapeControls(lookBox, BOX_INDENT, -BOX_HEADER, LAYOUT.COLUMN, GH.SetOption)
  shapeControls.Sync(GH.Defaults)
  FinishBox(lookBox, -(BOX_HEADER + shapeControls.frame:GetHeight()))
  return lookBox
end

-- Shows the settings in the box.
function UI.SyncLookBox(options)
  shapeControls.Sync(options)
  FinishBox(lookBox, -(BOX_HEADER + shapeControls.frame:GetHeight()))
end
