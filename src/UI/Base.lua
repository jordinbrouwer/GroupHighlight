-- The look and the shared parts of the windows. Every UI file takes its tools from the UI table.
-- Colours and sizes live here only, as in AutomaticRoleCheck, in GroupHighlight's own colours (gold and grey).
GroupHighlight = GroupHighlight or {}
local UI = {}
GroupHighlight.UI = UI

-- Values that change while the editor lives (set in one file, read in another).
UI.state = {
  syncing = false,       -- the window is filling its controls, so they must not react
  window = nil,          -- the editor window, its scroll area, its content and its warning strip
  scroll = nil,
  content = nil,
  strip = nil,
  boxes = nil,           -- { who, look, preview, members }
  firstMember = nil,     -- { name, unit } of the first name in the members list (the preview shows it)
  previewMember = nil,   -- the member being edited in the colour or shape picker
}

UI.WHITE = "Interface\\Buttons\\WHITE8X8"

UI.THEME = {
  ACCENT = { 1, 0.82, 0, 1 },             -- gold: GroupHighlight's own colour
  WINDOW = { 0.06, 0.06, 0.07, 0.96 },
  HEADER = { 0.11, 0.11, 0.12, 1 },       -- the band at the top
  TITLE_TEXT = { 1, 0.82, 0, 1 },
  SUBTITLE_TEXT = { 0.62, 0.62, 0.66, 1 },
  BORDER = { 0.32, 0.32, 0.35, 1 },
  LINE = { 0.25, 0.25, 0.28, 1 },
  INSET = { 0.1, 0.1, 0.11, 1 },
  BOX_BG = { 0.1, 0.1, 0.1, 0.6 },        -- the boxes round the sections (as in AutomaticRoleCheck)
  BOX_BORDER = { 0.4, 0.4, 0.4, 0.8 },
  BUTTON = { 0.14, 0.14, 0.16, 0.95 },
  BUTTON_HOVER = { 0.24, 0.24, 0.28, 0.98 },
  BUTTON_ON = { 0.26, 0.2, 0.04, 0.95 },  -- a chosen button
  ON_TEXT = { 1, 0.82, 0, 1 },            -- text of a chosen button
  TRACK = { 0.2, 0.2, 0.23, 1 },
  MUTED = { 0.62, 0.62, 0.66, 1 },        -- quiet text and icons at rest
  BRIGHT = { 0.95, 0.95, 0.97, 1 },       -- the same under the mouse
  GREY = { 0.5, 0.52, 0.58, 1 },
  DANGER = { 1, 0.42, 0.42, 1 },
  TIP_BG = { 0.06, 0.06, 0.07, 0.98 },
}

-- The sizes of the editor window (pixels). A box holds one section; the boxes go in one or two columns.
UI.LAYOUT = {
  MARGIN = 16,
  COLUMN = 300,       -- the width of what is in a box
  HEADER = 47,         -- the gold line (3) and the header band (44)
  ROW_H = 20,           -- a row with a switch (the same as in AutomaticRoleCheck)
  PREVIEW_HEIGHT = 122,
  FOOTER = 24,   -- the band with the warning at the bottom
  OUTER = 10,         -- between the window edge and the boxes (the same as in AutomaticRoleCheck)
  TOP = 10,           -- between the strip and the first box
  COLUMN_GAP = 8,     -- between the two columns of boxes
  MIN_HEIGHT = 220,
  MAX_WIDTH = 760,
  BOX_INDENT = 8,        -- between the sides of a box and what is in it (the same as the title)
  BOX_BOTTOM = 8,     -- between the last row and the bottom edge
  BOX_GAP = 4,        -- between two boxes under each other
  BOX_HEADER = 26,    -- the title row of a box (the title, and some air before the first row)
  BOX_TITLE_X = 8,    -- where the title sits (from the top left corner)
  BOX_TITLE_Y = -6,
  MEMBER_ROWS = 5,    -- how many names the members list shows at most; more names scroll
}
local LAYOUT = UI.LAYOUT
LAYOUT.BOX_WIDTH = LAYOUT.COLUMN + LAYOUT.BOX_INDENT * 2
LAYOUT.ONE_COLUMN = LAYOUT.BOX_WIDTH + LAYOUT.OUTER * 2                               -- the narrowest window
LAYOUT.TWO_COLUMNS = LAYOUT.BOX_WIDTH * 2 + LAYOUT.COLUMN_GAP + LAYOUT.OUTER * 2    -- wide enough for two columns
LAYOUT.TWO_COLUMNS_FROM = LAYOUT.TWO_COLUMNS - 12   -- from this width on the boxes are in two columns (a little less than
                                                      -- the default width, so rounding never decides)
LAYOUT.MAX_WIDTH = LAYOUT.TWO_COLUMNS   -- the window cannot be made wider than its default width

-- The fonts GroupHighlightFont<Name>: copies of the game fonts (GameFont<Name>), e.g. "GroupHighlightFontHighlight".
for _, suffix in ipairs({ "Normal", "Highlight", "NormalSmall", "HighlightSmall", "NormalLarge", "NormalHuge", "Disable" }) do
  local template = _G["GameFont" .. suffix]
  if template then
    local font = CreateFont("GroupHighlightFont" .. suffix)
    font:CopyFontObject(template)
  end
end

-- Makes a line exactly one screen pixel thick, whatever the UI scale. A plain height or
-- width of 1 can render as 0, 1 or 2 pixels, so lines looked uneven and corners didn't meet.
function UI.OnePixel(line, horizontal)
  line:SetTexelSnappingBias(0)
  line:SetSnapToPixelGrid(false)
  if PixelUtil then
    if horizontal then PixelUtil.SetHeight(line, 1, 1) else PixelUtil.SetWidth(line, 1, 1) end
  else
    if horizontal then line:SetHeight(1) else line:SetWidth(1) end
  end
end

-- A thin border of one-pixel lines: top and bottom full width, the sides in between (no doubled corners).
-- color = { r, g, b, a }; alpha replaces its alpha when given. Gives back the lines (for UI.SetBorderColor).
function UI.AddBorder(frame, color, alpha)
  local top, bottom, left, right = frame:CreateTexture(nil, "BORDER"), frame:CreateTexture(nil, "BORDER"),
    frame:CreateTexture(nil, "BORDER"), frame:CreateTexture(nil, "BORDER")
  top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);              top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
  bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0);     bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
  left:SetPoint("TOPLEFT", top, "BOTTOMLEFT", 0, 0);            left:SetPoint("BOTTOMLEFT", bottom, "TOPLEFT", 0, 0)
  right:SetPoint("TOPRIGHT", top, "BOTTOMRIGHT", 0, 0);         right:SetPoint("BOTTOMRIGHT", bottom, "TOPRIGHT", 0, 0)
  UI.OnePixel(top, true); UI.OnePixel(bottom, true); UI.OnePixel(left, false); UI.OnePixel(right, false)
  local lines = { top, bottom, left, right }
  UI.SetBorderColor(lines, color, alpha)
  return lines
end

function UI.SetBorderColor(lines, color, alpha)
  for _, line in ipairs(lines) do line:SetColorTexture(color[1], color[2], color[3], alpha or color[4] or 1) end
end
-- Gives every text in a frame (and in everything inside it) a thin outline.
function UI.ApplyOutline(frame)
  for _, region in ipairs({ frame:GetRegions() }) do
    if region.GetObjectType and region:GetObjectType() == "FontString" then
      local path, size = region:GetFont()
      if path then region:SetFont(path, size, "OUTLINE") end
    end
  end
  for _, child in ipairs({ frame:GetChildren() }) do UI.ApplyOutline(child) end
end
