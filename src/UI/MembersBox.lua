-- The box "Members": a table with column headings and a row per group member (every second row has a faint
-- band): the name, the shape (opens the shape picker) and a swatch that opens the colour picker. It is as high as the names need, up to MEMBER_ROWS; then it scrolls.
local GH = GroupHighlight
local UI = GH.UI
local L = GH.Loc
local GetOptions = GH.GetOptions
local LAYOUT, THEME = UI.LAYOUT, UI.THEME
local GetClassColor, CreateSwatch = UI.GetClassColor, UI.CreateSwatch
local CreateBox = UI.CreateBox
local BOX_INDENT, BOX_HEADER, BOX_BOTTOM = LAYOUT.BOX_INDENT, LAYOUT.BOX_HEADER, LAYOUT.BOX_BOTTOM
local S = UI.state

local GOLD_CODE = "|cffffd100"   -- the gold of the addon, as a colour code (for tooltips)
local HEAD_H = 18        -- the column headings
local BAND_EDGE = 4        -- the bands stick out this far on both sides of the text
local LIST_WIDTH = LAYOUT.COLUMN + BAND_EDGE * 2
-- The middle of the Shape and Colour columns, from the right edge of the list: heading and icon share that middle.
local SHAPE_X, COLOUR_X = 68, 20

local box, noMembersText
local memberRows = {}
local memberList, memberScroll, updateMemberBar   -- the scrolling list

-- The units whose names the list shows: everybody in the raid, or you and your party.
local function GroupUnits()
  local units = {}
  if IsInRaid and IsInRaid() then
    for index = 1, GetNumGroupMembers() do units[#units + 1] = "raid" .. index end
  else
    units = { "player", "party1", "party2", "party3", "party4" }
  end
  return units
end

-- The names in the list, each { name, unit, r, g, b }: your group (you only with "above yourself" on).
local function ListEntries(options)
  local entries = {}
  local seen = {}
  for _, unit in ipairs(GroupUnits()) do
    local name = UnitExists(unit) and GetUnitName(unit, true)
    if name and issecretvalue and issecretvalue(name) then name = nil end
    if name and UnitIsUnit(unit, "player") and not options.ShowSelf then name = nil end
    if name and not seen[name] then
      seen[name] = true
      entries[#entries + 1] = { name = name, unit = unit }
    end
  end
  return entries
end

-- One line of the list: the name in its colour and the swatch that opens the colour picker.
local function CreateMemberRow()
  local row = CreateFrame("Frame", nil, memberList)
  row:SetSize(LIST_WIDTH, LAYOUT.ROW_H)
  row.Band = row:CreateTexture(nil, "BACKGROUND")   -- every second row has a faint band, so the eye can follow a row
  row.Band:SetAllPoints(row)
  row.Label = row:CreateFontString(nil, "OVERLAY", "GroupHighlightFontHighlightSmall")
  row.Label:SetPoint("LEFT", row, "LEFT", BAND_EDGE, 0)
  row.Swatch = CreateSwatch(row)
  row.Swatch:SetSize(LAYOUT.ROW_H - 4, LAYOUT.ROW_H - 4)   -- a little smaller than the row, so the swatches do not touch
  row.Swatch:SetPoint("CENTER", row, "RIGHT", -(BAND_EDGE + COLOUR_X), 0)
  row.Swatch:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  -- the shape, in the member's colour (their own shape, or the one from Look)
  row.Shape = CreateFrame("Button", nil, row)
  row.Shape:SetSize(LAYOUT.ROW_H - 2, LAYOUT.ROW_H - 2)
  row.Shape:SetPoint("CENTER", row, "RIGHT", -(BAND_EDGE + SHAPE_X), 0)
  row.Shape.Icon = row.Shape:CreateTexture(nil, "ARTWORK")
  row.Shape.Icon:SetAllPoints(row.Shape)
  row.Shape.Border = UI.AddBorder(row.Shape, THEME.ACCENT, 0)
  row.Shape:SetScript("OnEnter", function(self) UI.SetBorderColor(self.Border, THEME.ACCENT) end)
  row.Shape:SetScript("OnLeave", function(self) UI.SetBorderColor(self.Border, THEME.ACCENT, 0) end)
  row.Shape:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  row.Shape:SetScript("OnClick", function(_, button)
    if not GetOptions() or not row.Name then return end
    if button == "RightButton" then
      GH.CloseShapePicker(true)   -- an open picker would otherwise undo the reset when it is cancelled
      GH.SetMemberShape(row.Name)
      return
    end
    GH.OpenShapePicker(row.Name, row.Unit)
  end)
  row.Label:SetPoint("RIGHT", row.Shape, "LEFT", -8, 0)
  row.Label:SetJustifyH("LEFT")
  row.Label:SetWordWrap(false)
  row.Swatch:SetScript("OnClick", function(_, button)
    if not GetOptions() or not row.Name then return end
    if button == "RightButton" then
      GH.CloseColorPicker(true)   -- an open picker would otherwise undo the reset when it is cancelled
      GH.SetMemberColor(row.Name)
      return
    end
    GH.OpenColorPicker(row.Name, row.Unit)
  end)
  -- the whole row (the name and the swatch) shows the tooltip, hanging on the row
  row:EnableMouse(true)
  local function Tip()
    return GOLD_CODE .. L("tip_label_left") .. "|r " .. L("tip_member_left") .. "\n"
      .. GOLD_CODE .. L("tip_label_right") .. "|r " .. L("tip_member_right")
  end
  UI.AddTooltip(row, Tip, function() return row.Name end)
  UI.AddTooltip(row.Swatch, Tip, function() return row.Name end, row)
  UI.AddTooltip(row.Shape, function()
    return GOLD_CODE .. L("tip_label_left") .. "|r " .. L("tip_shape_left") .. "\n"
      .. GOLD_CODE .. L("tip_label_right") .. "|r " .. L("tip_shape_right")
  end, function() return row.Name end, row)
  UI.ApplyOutline(row)
  return row
end

-- Puts one name in its row.
local function ShowMember(index, entry, options)
  local row = memberRows[index] or CreateMemberRow()
  memberRows[index] = row
  row.Name, row.Unit = entry.name, entry.unit
  row.Band:SetColorTexture(1, 1, 1, index % 2 == 1 and 0.035 or 0)
  row:ClearAllPoints()
  row:SetPoint("TOPLEFT", memberList, "TOPLEFT", 0, -(index - 1) * LAYOUT.ROW_H)
  row.Label:SetText(entry.name)
  local r, g, b = entry.r, entry.g, entry.b
  if not r then
    local color = options.MemberColors and options.MemberColors[entry.name]
    if color then r, g, b = color.r, color.g, color.b else r, g, b = GetClassColor(entry.unit) end
  end
  row.Label:SetTextColor(r, g, b)
  row.Swatch.Color:SetColorTexture(r, g, b)
  row.Shape.Icon:SetTexture(GH.GetStyleTexture(entry.name))
  row.Shape.Icon:SetVertexColor(r, g, b)
  row:Show()
end

function UI.BuildMembersBox(parent)
  local width = LAYOUT.COLUMN
  box = CreateBox(parent, width, L("editor_section_members"), "members")
  noMembersText = box:CreateFontString(nil, "OVERLAY", "GroupHighlightFontDisable")
  noMembersText:SetPoint("TOPLEFT", box, "TOPLEFT", BOX_INDENT, -(BOX_HEADER + HEAD_H + 4))
  noMembersText:SetText(L("editor_no_members"))
  -- the column headings and the line under them
  local nameHead = box:CreateFontString(nil, "OVERLAY", "GroupHighlightFontNormalSmall")
  nameHead:SetPoint("TOPLEFT", box, "TOPLEFT", BOX_INDENT, -(BOX_HEADER + 2))
  local colourHead = box:CreateFontString(nil, "OVERLAY", "GroupHighlightFontNormalSmall")
  colourHead:SetPoint("TOP", box, "TOPRIGHT", -(BOX_INDENT + COLOUR_X), -(BOX_HEADER + 2))
  local shapeHead = box:CreateFontString(nil, "OVERLAY", "GroupHighlightFontNormalSmall")
  shapeHead:SetPoint("TOP", box, "TOPRIGHT", -(BOX_INDENT + SHAPE_X), -(BOX_HEADER + 2))
  for _, head in ipairs({ nameHead, shapeHead, colourHead }) do head:SetTextColor(unpack(THEME.MUTED)) end
  nameHead:SetText(L("members_col_name"))
  shapeHead:SetText(L("members_col_look"))
  colourHead:SetText(L("members_col_colour"))
  local headLine = box:CreateTexture(nil, "ARTWORK")
  headLine:SetColorTexture(1, 1, 1, 0.1)
  headLine:SetPoint("TOPLEFT", box, "TOPLEFT", BOX_INDENT - 4, -(BOX_HEADER + HEAD_H))
  headLine:SetPoint("TOPRIGHT", box, "TOPRIGHT", -(BOX_INDENT - 4), -(BOX_HEADER + HEAD_H))
  UI.OnePixel(headLine, true)
  memberScroll = CreateFrame("ScrollFrame", nil, box)
  memberScroll:SetSize(LIST_WIDTH, LAYOUT.ROW_H)
  memberScroll:SetPoint("TOPLEFT", box, "TOPLEFT", BOX_INDENT - BAND_EDGE, -(BOX_HEADER + HEAD_H + 1))
  memberList = CreateFrame("Frame", nil, memberScroll)
  memberList:SetSize(LIST_WIDTH, LAYOUT.ROW_H)
  memberScroll:SetScrollChild(memberList)
  memberScroll:EnableMouseWheel(true)
  memberScroll:SetScript("OnMouseWheel", function(self, delta)
    self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), self:GetVerticalScroll() - delta * LAYOUT.ROW_H)))
  end)
  updateMemberBar = UI.CreateScrollBar(box, memberScroll, 1)
  box:SetHeight(BOX_HEADER + HEAD_H + 1 + LAYOUT.ROW_H + BOX_BOTTOM)
  return box
end

-- Fills the list and sets the height of the box (the window places the boxes again afterwards).
function UI.SyncMembersBox(options)
  local entries = ListEntries(options)
  for index, entry in ipairs(entries) do ShowMember(index, entry, options) end
  for index = #entries + 1, #memberRows do memberRows[index]:Hide() end
  noMembersText:SetShown(#entries == 0)
  memberList:SetHeight(math.max(1, #entries * LAYOUT.ROW_H))
  local visible = math.min(math.max(#entries, 1), LAYOUT.MEMBER_ROWS)
  memberScroll:SetHeight(visible * LAYOUT.ROW_H)
  box:SetHeight(BOX_HEADER + HEAD_H + 1 + visible * LAYOUT.ROW_H + BOX_BOTTOM)
  updateMemberBar()
  local first = entries[1]
  S.firstMember = first and { name = first.name, unit = first.unit } or nil
  if UI.Relayout then UI.Relayout() end
end
