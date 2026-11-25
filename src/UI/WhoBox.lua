-- The box "Who gets an arrow": Off, Party or Party + Raid, and above yourself and your target.
local GH = GroupHighlight
local UI = GH.UI
local L = GH.Loc
local GetOptions = GH.GetOptions
local LAYOUT = UI.LAYOUT
local CreateBox, FinishBox = UI.CreateBox, UI.FinishBox
local CreateCheckboxRow, CreateSegment = UI.CreateCheckboxRow, UI.CreateSegment
local BOX_INDENT, BOX_HEADER = LAYOUT.BOX_INDENT, LAYOUT.BOX_HEADER

local modeSegment, selfCheck, targetCheck

function UI.BuildWhoBox(parent)
  local width, x = LAYOUT.COLUMN, BOX_INDENT
  local box = CreateBox(parent, width, L("editor_section_who"), "who")
  local y = -BOX_HEADER
  local modeEntries = {}
  for _, mode in ipairs(GH.Modes) do
    modeEntries[#modeEntries + 1] = { key = mode, label = L("mode_" .. mode), tip = L("mode_tip_" .. mode) }
  end
  modeSegment = CreateSegment(box, x, y, width, 28, modeEntries, function(mode)
    if GetOptions() then GH.SetMode(mode) end
  end)
  y = y - 28 - 6
  selfCheck = CreateCheckboxRow(box, x, y, width, L("option_ShowSelf"), L("option_tip_ShowSelf"), function(value)
    GH.SetOption("ShowSelf", value)
  end)
  y = y - LAYOUT.ROW_H
  targetCheck = CreateCheckboxRow(box, x, y, width, L("option_ShowTarget"), function()
    return L("option_tip_ShowTarget") .. "\n" .. L("target_status", L("target_status_" .. GH.GetNpcPlateStatus()))
  end, function(value)
    GH.SetOption("ShowTarget", value)
  end)
  y = y - LAYOUT.ROW_H
  FinishBox(box, y)
  return box
end

-- Shows the settings in the box.
function UI.SyncWhoBox(options)
  modeSegment.SetSelected(options.Mode)
  selfCheck:SetChecked(options.ShowSelf == true)
  targetCheck:SetChecked(options.ShowTarget == true)
end
