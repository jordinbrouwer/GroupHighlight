-- The box "Preview": the arrow with a name under it, the way it looks in the game. When the shape being edited
-- is Drawing it becomes a grid to draw on: the shape picker's member while it is open, else Look.
local GH = GroupHighlight
local UI = GH.UI
local L = GH.Loc
local GetOptions = GH.GetOptions
local LAYOUT, THEME = UI.LAYOUT, UI.THEME
local AddBorder, GetClassColor = UI.AddBorder, UI.GetClassColor
local CreateBox, FinishBox = UI.CreateBox, UI.FinishBox
local BOX_INDENT, BOX_HEADER = LAYOUT.BOX_INDENT, LAYOUT.BOX_HEADER

local GOLD_CODE = "|cffffd100"
local CELLS = GH.DRAWING_SIZE
local EDGE = 6   -- between the grid and the sides of the preview
local CELL = math.floor((LAYOUT.COLUMN - EDGE * 2) / CELLS)   -- the grid is as wide as the preview
local FOOT = 24   -- the row under the grid: the name, as under the arrow
local DRAW_HEIGHT = EDGE + CELL * CELLS + EDGE + FOOT + EDGE   -- the preview grows to this while you draw
local preview, stroke

-- What the preview draws on, and how to save it: nil while the colour picker shows a member.
local function DrawTarget()
  local look = GH.GetPickerLook and GH.GetPickerLook()
  if look then return look, GH.SetPickerOption end
  if UI.state.previewMember then return nil end
  return GetOptions(), GH.SetOption
end

-- The cell under the mouse (x, y from 0, from the top left), or nil outside the grid.
local function CellUnderCursor(canvas)
  local left, top = canvas:GetLeft(), canvas:GetTop()
  if not left then return nil end
  local x, y = GetCursorPosition()
  local scale = canvas:GetEffectiveScale()
  local cx = math.floor((x / scale - left) / CELL)
  local cy = math.floor((top - y / scale) / CELL)
  if cx >= 0 and cx < CELLS and cy >= 0 and cy < CELLS then return cx, cy end
end

-- A stroke shows at once and is saved on mouse-up, so the arrows and the picker's undo get whole strokes.
local function Paint()
  local x, y = CellUnderCursor(preview.Canvas)
  if not x then return end
  local drawing = GH.SetDrawingCell(stroke.drawing, x, y, stroke.on)
  if drawing == stroke.drawing then return end
  stroke.drawing = drawing
  preview.CanvasView.SetLook({ Shape = "drawing", Drawing = drawing })
end

local function BuildCanvas(frame)
  local canvas = CreateFrame("Frame", nil, frame)
  canvas:SetSize(CELL * CELLS, CELL * CELLS)
  canvas:SetPoint("TOP", frame, "TOP", 0, -EDGE)
  local background = canvas:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(canvas)
  background:SetColorTexture(0, 0, 0, 0.35)
  AddBorder(canvas, THEME.LINE)
  -- faint lines between the cells, over the drawing so every cell stays visible
  for index = 1, CELLS - 1 do
    local across = canvas:CreateTexture(nil, "OVERLAY")
    across:SetColorTexture(1, 1, 1, 0.07)
    across:SetPoint("TOPLEFT", canvas, "TOPLEFT", 0, -index * CELL)
    across:SetPoint("TOPRIGHT", canvas, "TOPRIGHT", 0, -index * CELL)
    UI.OnePixel(across, true)
    local down = canvas:CreateTexture(nil, "OVERLAY")
    down:SetColorTexture(1, 1, 1, 0.07)
    down:SetPoint("TOPLEFT", canvas, "TOPLEFT", index * CELL, 0)
    down:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", index * CELL, 0)
    UI.OnePixel(down, false)
  end
  preview.CanvasView = GH.CreateShapeView(canvas, "ARTWORK")
  canvas:EnableMouse(true)
  canvas:SetScript("OnMouseDown", function(_, button)
    if not preview.target then return end
    stroke = { on = button == "LeftButton", drawing = preview.target.Drawing }
    Paint()
  end)
  canvas:SetScript("OnUpdate", function() if stroke then Paint() end end)
  canvas:SetScript("OnMouseUp", function()
    if not stroke then return end
    local drawing = stroke.drawing
    stroke = nil
    -- the target can be gone when a picker opened mid-stroke
    if preview.target and drawing ~= preview.target.Drawing then preview.commit("Drawing", drawing) end
  end)
  canvas:SetScript("OnHide", function() stroke = nil end)   -- a picker that closes mid-stroke keeps its undo
  UI.AddTooltip(canvas, function()
    return GOLD_CODE .. L("drawing_label_left") .. "|r " .. L("drawing_tip_left") .. "\n"
      .. GOLD_CODE .. L("drawing_label_right") .. "|r " .. L("drawing_tip_right")
  end, L("shape_drawing"))
  preview.Canvas = canvas
end

function UI.BuildPreviewBox(parent)
  local width = LAYOUT.COLUMN
  -- the reset icon empties the drawing; it only shows while you draw
  local box = CreateBox(parent, width, L("editor_section_preview"), "preview", function()
    if preview.target then preview.commit("Drawing", GH.EMPTY_DRAWING) end
  end)
  local frame = CreateFrame("Frame", nil, box)
  frame:SetSize(width, LAYOUT.PREVIEW_HEIGHT)
  frame:SetPoint("TOPLEFT", box, "TOPLEFT", BOX_INDENT, -BOX_HEADER)
  local background = frame:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(frame)
  background:SetColorTexture(unpack(THEME.INSET))
  AddBorder(frame, THEME.LINE)
  preview = { Frame = frame, Box = box }
  preview.Name = frame:CreateFontString(nil, "OVERLAY", "GroupHighlightFontNormalLarge")
  preview.Name:SetPoint("BOTTOM", frame, "BOTTOM", 0, 14)
  preview.Arrow = CreateFrame("Frame", nil, frame)
  preview.ArrowView = GH.CreateShapeView(preview.Arrow, "ARTWORK")
  BuildCanvas(frame)
  FinishBox(box, -BOX_HEADER - LAYOUT.PREVIEW_HEIGHT)
  return box
end

-- Shows the member being edited in the colour or shape picker, else the first name in the list, else yourself.
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
  local target, commit = DrawTarget()
  local drawing = target and target.Shape == "drawing"
  preview.target, preview.commit = drawing and target or nil, commit
  preview.Canvas:SetShown(drawing)
  preview.Box.Reset:SetShown(drawing)
  local height = drawing and DRAW_HEIGHT or LAYOUT.PREVIEW_HEIGHT
  if preview.Frame:GetHeight() ~= height then
    preview.Frame:SetHeight(height)
    FinishBox(preview.Box, -BOX_HEADER - height)
    if UI.Relayout then UI.Relayout() end
  end
  preview.Arrow:SetShown(not drawing)
  preview.Name:SetText(name)
  preview.Name:SetTextColor(r, g, b)
  if drawing then
    if not stroke then preview.CanvasView.SetLook(target) end
    preview.CanvasView.SetColor(r, g, b)
    return
  end
  local shown = member and member.name or GH.GetMemberName("player")
  local size, lift = GH.GetMemberSize(shown)
  local offset = lift + 3
  local scale = math.min(1, 84 / (size + offset))
  preview.ArrowView.SetLook(GH.GetShownLook(shown))
  preview.ArrowView.SetColor(r, g, b)
  preview.Arrow:SetSize(size * scale, size * scale)
  preview.Arrow:ClearAllPoints()
  preview.Arrow:SetPoint("BOTTOM", preview.Name, "TOP", 0, offset * scale)
end

-- Called by the colour picker: show this member in the preview, or yourself again with no name.
GH.SetPreviewMember = function(name, unit)
  UI.state.previewMember = name and { name = name, unit = unit } or nil
  UI.UpdatePreview()
end
