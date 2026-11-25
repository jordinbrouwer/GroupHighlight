-- Where the boxes go and how high the window is. Wide enough: two columns of boxes; narrower: one column.
-- The window is never taller than its content.
local GH = GroupHighlight
local UI = GH.UI
local GetOptions = GH.GetOptions
local LAYOUT = UI.LAYOUT
local S = UI.state
local BOX_GAP = LAYOUT.BOX_GAP

-- Puts a box at (x, y) of the content and gives back the y under it.
local function Place(box, x, y)
  box:ClearAllPoints()
  box:SetPoint("TOPLEFT", S.content, "TOPLEFT", x, y)
  return y - box:GetHeight() - BOX_GAP
end

-- Places the boxes; gives back the height of the content.
local function PlaceBoxes(width)
  local boxes = S.boxes
  local x1 = LAYOUT.OUTER
  local endY
  if width >= LAYOUT.TWO_COLUMNS_FROM then
    local x2 = x1 + LAYOUT.BOX_WIDTH + LAYOUT.COLUMN_GAP
    local y1 = Place(boxes.look, x1, Place(boxes.who, x1, -LAYOUT.TOP))
    local y2 = Place(boxes.party, x2, Place(boxes.preview, x2, -LAYOUT.TOP))
    endY = math.min(y1, y2)
  else
    endY = -LAYOUT.TOP
    for _, name in ipairs({ "who", "look", "preview", "party" }) do endY = Place(boxes[name], x1, endY) end
  end
  return -endY - BOX_GAP + LAYOUT.TOP
end

-- The height and the limits of the window: never taller than its content needs.
local function FitWindow(contentHeight, stripHeight)
  local window = S.window
  local fit = math.floor(math.min(UIParent:GetHeight(), LAYOUT.HEADER + contentHeight + stripHeight + 1) + 0.5)
  if window.SetResizeBounds then
    window:SetResizeBounds(LAYOUT.ONE_COLUMN, math.min(LAYOUT.MIN_HEIGHT, fit), math.min(LAYOUT.MAX_WIDTH, UIParent:GetWidth()), fit)
  end
  local options = GetOptions()
  if options and options.EditorSize then
    if window:GetHeight() > fit + 0.5 and not window.sizing then
      window:SetHeight(fit)
      options.EditorSize[2] = fit
    end
  else
    window:SetHeight(math.min(fit, math.floor(UIParent:GetHeight() * 0.92)))
  end
end

function UI.Relayout()
  if not (S.content and S.boxes) then return end
  local stripHeight = UI.FitStrip()
  local width = S.scroll:GetWidth() or LAYOUT.ONE_COLUMN
  local contentHeight = PlaceBoxes(width)
  S.content:SetWidth(width)
  S.content:SetHeight(contentHeight)
  FitWindow(contentHeight, stripHeight)
end
