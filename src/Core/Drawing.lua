-- A drawn shape: 16 by 16 cells, kept as a string of 64 hex digits, 4 per row (top row first). The highest bit of
-- a row is its leftmost cell. A string is copied by value, so copying a look never shares a drawing.
local GH = GroupHighlight

local SIZE = 16
GH.DRAWING_SIZE = SIZE

-- A down arrow, so the shape Drawing shows something before you draw.
GH.DEFAULT_DRAWING = table.concat({
  "0000", "03C0", "03C0", "03C0", "03C0", "03C0", "03C0", "03C0",
  "3FFC", "1FF8", "0FF0", "07E0", "03C0", "0180", "0000", "0000",
})
GH.EMPTY_DRAWING = string.rep("0", SIZE * 4)

GH.IsValidDrawing = function(drawing)
  return type(drawing) == "string" and #drawing == SIZE * 4 and not drawing:find("[^0-9A-F]")
end

-- x and y count from 0, from the top left.
local function Row(drawing, y)
  return tonumber(drawing:sub(y * 4 + 1, y * 4 + 4), 16)
end

GH.GetDrawingCell = function(drawing, x, y)
  return math.floor(Row(drawing, y) / 2 ^ (SIZE - 1 - x)) % 2 == 1
end

-- Gives back the drawing with one cell set (on true) or cleared.
GH.SetDrawingCell = function(drawing, x, y, on)
  if GH.GetDrawingCell(drawing, x, y) == on then return drawing end
  local bit = 2 ^ (SIZE - 1 - x)
  local row = Row(drawing, y) + (on and bit or -bit)
  return drawing:sub(1, y * 4) .. string.format("%04X", row) .. drawing:sub(y * 4 + 5)
end

-- The runs of set cells next to each other in a row, each { x, y, length }: one texture each on screen.
GH.DrawingRuns = function(drawing)
  local runs = {}
  for y = 0, SIZE - 1 do
    local start
    for x = 0, SIZE do
      local on = x < SIZE and GH.GetDrawingCell(drawing, x, y)
      if on and not start then
        start = x
      elseif not on and start then
        runs[#runs + 1] = { start, y, x - start }
        start = nil
      end
    end
  end
  return runs
end
