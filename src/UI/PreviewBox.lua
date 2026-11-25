-- The box "Preview": the arrow with a name under it, the way it looks in the game.
local GH = GroupHighlight
local UI = GH.UI
local L = GH.Loc
local GetOptions = GH.GetOptions
local LAYOUT, THEME = UI.LAYOUT, UI.THEME
local AddBorder, GetClassColor = UI.AddBorder, UI.GetClassColor
local CreateBox, FinishBox = UI.CreateBox, UI.FinishBox
local BOX_INDENT, BOX_HEADER = LAYOUT.BOX_INDENT, LAYOUT.BOX_HEADER

local preview

function UI.BuildPreviewBox(parent)
  local width = LAYOUT.COLUMN
  local box = CreateBox(parent, width, L("editor_section_preview"))
  local frame = CreateFrame("Frame", nil, box)
  frame:SetSize(width, LAYOUT.PREVIEW_HEIGHT)
  frame:SetPoint("TOPLEFT", box, "TOPLEFT", BOX_INDENT, -BOX_HEADER)
  local background = frame:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(frame)
  background:SetColorTexture(unpack(THEME.INSET))
  AddBorder(frame, THEME.LINE)
  preview = { Frame = frame }
  preview.Name = frame:CreateFontString(nil, "OVERLAY", "GroupHighlightFontNormalLarge")
  preview.Name:SetPoint("BOTTOM", frame, "BOTTOM", 0, 14)
  preview.Arrow = frame:CreateTexture(nil, "ARTWORK")
  preview.Arrow:SetBlendMode("ADD")
  FinishBox(box, -BOX_HEADER - LAYOUT.PREVIEW_HEIGHT)
  return box
end

-- Shows the member being edited in the colour picker, else the first name in the list, else yourself.
function UI.UpdatePreview()
  local options = GetOptions()
  if not options or not preview then return end
  local member = UI.state.previewMember or UI.state.firstMember
  local r, g, b, name
  if member then
    local color = options.MemberColors and options.MemberColors[member.name]
    if color then r, g, b = color.r, color.g, color.b else r, g, b = GetClassColor(member.unit) end
    name = member.name
  else
    -- Nobody in the list: yourself, the same way the list would show you.
    r, g, b = GH.GetColor("player")
    name = GetUnitName("player", true) or UnitName("player") or ""
  end
  preview.Name:SetText(name)
  preview.Name:SetTextColor(r, g, b)
  local size = options.ArrowSize or 32
  local offset = (options.Lift or 1) + 3
  local scale = math.min(1, 84 / (size + offset))
  preview.Arrow:SetTexture(GH.GetStyleTexture())
  preview.Arrow:SetVertexColor(r, g, b)
  preview.Arrow:SetSize(size * scale, size * scale)
  preview.Arrow:ClearAllPoints()
  preview.Arrow:SetPoint("BOTTOM", preview.Name, "TOP", 0, offset * scale)
end

-- Called by the colour picker: show this member in the preview, or yourself again with no name.
GH.SetPreviewMember = function(name, unit)
  UI.state.previewMember = name and { name = name, unit = unit } or nil
  UI.UpdatePreview()
end
