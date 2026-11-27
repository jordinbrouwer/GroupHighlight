-- Checks the drawing helpers outside the game. Run from the repo root: lua5.1 tests/drawing_test.lua
GroupHighlight = {}
dofile("src/Core/Drawing.lua")
local GH = GroupHighlight

assert(GH.IsValidDrawing(GH.DEFAULT_DRAWING))
assert(GH.IsValidDrawing(GH.EMPTY_DRAWING))
assert(not GH.IsValidDrawing("00"))
assert(not GH.IsValidDrawing(string.rep("g", 64)))

-- set and clear the corners; nothing else changes
local d = GH.EMPTY_DRAWING
d = GH.SetDrawingCell(d, 0, 0, true)
d = GH.SetDrawingCell(d, 15, 15, true)
assert(d:sub(1, 4) == "8000" and d:sub(61, 64) == "0001", d)
assert(GH.GetDrawingCell(d, 0, 0) and GH.GetDrawingCell(d, 15, 15) and not GH.GetDrawingCell(d, 1, 0))
assert(GH.SetDrawingCell(d, 0, 0, true) == d)   -- setting a set cell changes nothing
assert(GH.SetDrawingCell(GH.SetDrawingCell(d, 0, 0, false), 15, 15, false) == GH.EMPTY_DRAWING)
assert(GH.IsValidDrawing(d))

-- runs: the default arrow's shaft is one run of 4 per row, the head row one run of 12
local runs = GH.DrawingRuns(GH.DEFAULT_DRAWING)
assert(#runs == 13, #runs)
assert(runs[1][1] == 6 and runs[1][2] == 1 and runs[1][3] == 4)
assert(runs[8][1] == 2 and runs[8][2] == 8 and runs[8][3] == 12)
-- a gap splits a row, and a run can end at the right edge
local split = GH.SetDrawingCell(GH.SetDrawingCell(GH.SetDrawingCell(GH.EMPTY_DRAWING, 0, 3, true), 2, 3, true), 15, 3, true)
runs = GH.DrawingRuns(split)
assert(#runs == 3 and runs[3][1] == 15 and runs[3][3] == 1)
print("drawing_test: ok")
