-- The box "Look": triangle or chevron, its options, and the size and height of the arrow.
local GH = GroupHighlight
local UI = GH.UI
local L = GH.Loc
local LAYOUT = UI.LAYOUT
local CreateBox, FinishBox = UI.CreateBox, UI.FinishBox
local CreateCheckboxRow, CreateSegment, CreateSlider = UI.CreateCheckboxRow, UI.CreateSegment, UI.CreateSlider
local BOX_INDENT, BOX_HEADER = LAYOUT.BOX_INDENT, LAYOUT.BOX_HEADER

local shapeSegment, countSegment, filledCheck, fadeCheck, sizeSlider, liftSlider

function UI.BuildLookBox(parent)
  local width, x = LAYOUT.COLUMN, BOX_INDENT
  local box = CreateBox(parent, width, L("editor_section_look"), "look")
  local y = -BOX_HEADER
  shapeSegment = CreateSegment(box, x, y, width, 38, {
    { key = "triangle", label = L("shape_triangle"), tip = L("shape_tip_triangle"), icon = GH.StyleTextures.triangle_filled },
    { key = "chevron", label = L("shape_chevron"), tip = L("shape_tip_chevron"), icon = GH.StyleTextures.chevron2_fade },
  }, function(shape)
    GH.SetOption("Shape", shape)
  end, nil, true)
  y = y - 38 - 8
  -- Triangle and chevron share one row; the row shows the options of the chosen shape.
  filledCheck = CreateCheckboxRow(box, x, y, width, L("option_TriangleFilled"), L("option_tip_TriangleFilled"), function(value)
    GH.SetOption("TriangleFilled", value)
  end)
  countSegment = CreateSegment(box, x, y, 120, 24, {
    { key = 1, label = "1", title = L("shape_chevron"), tip = L("chevron_count_1") },
    { key = 2, label = "2", title = L("shape_chevron"), tip = L("chevron_count_2") },
    { key = 3, label = "3", title = L("shape_chevron"), tip = L("chevron_count_3") },
  }, function(count)
    GH.SetOption("ChevronCount", count)
  end)
  fadeCheck = CreateCheckboxRow(box, x + 136, y, width - 136, L("option_ChevronFade"), L("option_tip_ChevronFade"), function(value)
    GH.SetOption("ChevronFade", value)
  end)
  y = y - LAYOUT.ROW_H - 8
  sizeSlider = CreateSlider(box, x, y, width, "ArrowSize", 16, 96, "editor_size", "editor_tip_size")
  y = y - 44
  liftSlider = CreateSlider(box, x, y, width, "Lift", 1, 50, "editor_lift", "editor_tip_lift")
  y = y - 40
  FinishBox(box, y)
  return box
end

-- Shows the settings in the box.
function UI.SyncLookBox(options)
  shapeSegment.SetSelected(options.Shape)
  countSegment.SetSelected(options.ChevronCount)
  local isChevron = options.Shape == "chevron"
  countSegment.SetShown(isChevron)
  fadeCheck:GetParent():SetShown(isChevron)
  filledCheck:GetParent():SetShown(not isChevron)
  filledCheck:SetChecked(options.TriangleFilled ~= false)
  fadeCheck:SetChecked(options.ChevronFade ~= false)
  sizeSlider:SetValue(options.ArrowSize or 32)
  sizeSlider.Display(options.ArrowSize or 32)
  liftSlider:SetValue(options.Lift or 1)
  liftSlider.Display(options.Lift or 1)
end
