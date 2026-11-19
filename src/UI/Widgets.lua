-- Small flat widgets shared by the editor and the color picker.
GroupHighlight = GroupHighlight or {}

local UI = {}
GroupHighlight.UI = UI

UI.WHITE = "Interface\\Buttons\\WHITE8X8"

UI.THEME = {
  GOLD = { 1, 0.82, 0, 1 },
  WINDOW = { 0.06, 0.06, 0.07, 0.96 },
  TITLE = { 0.11, 0.11, 0.12, 1 },
  BORDER = { 0.32, 0.32, 0.35, 1 },
  LINE = { 0.25, 0.25, 0.28, 1 },
  INSET = { 0.1, 0.1, 0.11, 1 },
  BUTTON = { 0.14, 0.14, 0.16, 0.95 },
  BUTTON_ON = { 0.26, 0.2, 0.04, 0.95 },
  TRACK = { 0.2, 0.2, 0.23, 1 },
}
local THEME = UI.THEME

-- GroupHighlight's own fonts: Expressway (in Media), with the size, colour and shadow of the
-- game font each one replaces. Use them by name, e.g. CreateFontString(nil, "OVERLAY",
-- "GroupHighlightFontHighlight") instead of the game's GameFontHighlight.
UI.FONT = "Interface\\AddOns\\GroupHighlight\\Media\\Expressway.ttf"
for _, suffix in ipairs({ "Normal", "Highlight", "NormalSmall", "HighlightSmall", "NormalLarge", "NormalHuge", "Disable" }) do
  local template = _G["GameFont" .. suffix]
  if template then
    local font = CreateFont("GroupHighlightFont" .. suffix)
    font:CopyFontObject(template)
    local _, size, flags = template:GetFont()
    if not font:SetFont(UI.FONT, size or 12, flags or "") then
      font:CopyFontObject(template) -- the file is missing: keep the game font
    end
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

function UI.AddBorder(frame, color)
  local function Edge(p1, p2, horizontal)
    local line = frame:CreateTexture(nil, "BORDER")
    line:SetColorTexture(unpack(color))
    line:SetPoint(p1, frame, p1, 0, 0)
    line:SetPoint(p2, frame, p2, 0, 0)
    UI.OnePixel(line, horizontal)
    return line
  end
  return {
    Edge("TOPLEFT", "TOPRIGHT", true),
    Edge("BOTTOMLEFT", "BOTTOMRIGHT", true),
    Edge("TOPLEFT", "BOTTOMLEFT", false),
    Edge("TOPRIGHT", "BOTTOMRIGHT", false),
  }
end

-- A flat check box of our own (not Blizzard's): a dark square with a border and a gold
-- tick drawn from two bars. Works like a CheckButton: SetChecked, GetChecked, Click.
function UI.CreateCheckbox(parent, onClick)
  local box = CreateFrame("Button", nil, parent)
  box:SetSize(16, 16)
  box.Back = box:CreateTexture(nil, "BACKGROUND")
  box.Back:SetAllPoints(box)
  box.Back:SetColorTexture(unpack(THEME.INSET))
  box.Border = UI.AddBorder(box, THEME.BORDER)
  -- The tick: a short bar down-right and a long bar up-right, meeting at the bottom.
  box.Short = box:CreateTexture(nil, "ARTWORK")
  box.Short:SetColorTexture(unpack(THEME.GOLD))
  box.Short:SetSize(5, 2)
  box.Short:SetPoint("CENTER", box, "CENTER", -3, -1)
  box.Short:SetRotation(math.rad(-45))
  box.Long = box:CreateTexture(nil, "ARTWORK")
  box.Long:SetColorTexture(unpack(THEME.GOLD))
  box.Long:SetSize(10, 2)
  box.Long:SetPoint("CENTER", box, "CENTER", 1.5, 0.5)
  box.Long:SetRotation(math.rad(45))
  function box:SetChecked(on)
    self.checked = on and true or false
    self.Short:SetShown(self.checked)
    self.Long:SetShown(self.checked)
    UI.SetBorderColor(self.Border, (self.checked or self.hover) and THEME.GOLD or THEME.BORDER)
  end
  function box:GetChecked() return self.checked end
  box:SetScript("OnEnter", function(self) self.hover = true self:SetChecked(self.checked) end)
  box:SetScript("OnLeave", function(self) self.hover = false self:SetChecked(self.checked) end)
  box:SetScript("OnClick", function(self)
    self:SetChecked(not self.checked)
    if onClick then onClick(self) end
  end)
  box:SetChecked(false)
  return box
end

function UI.SetBorderColor(lines, color)
  for _, line in ipairs(lines) do
    line:SetColorTexture(unpack(color))
  end
end

-- text can be a string or a function that returns one.
function UI.AddTooltip(frame, text)
  frame:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(type(text) == "function" and text() or text, nil, nil, nil, nil, true)
    GameTooltip:Show()
  end)
  frame:HookScript("OnLeave", GameTooltip_Hide)
end

-- A flat button; primary buttons get a gold edge.
function UI.CreateButton(parent, text, width, primary, onClick, tooltipText)
  local button = CreateFrame("Button", nil, parent)
  button:SetSize(width, 28)
  button.Background = button:CreateTexture(nil, "BACKGROUND")
  button.Background:SetAllPoints(button)
  button.Border = UI.AddBorder(button, primary and THEME.GOLD or THEME.BORDER)
  button.Label = button:CreateFontString(nil, "OVERLAY", "GroupHighlightFontHighlight")
  button.Label:SetPoint("CENTER", button, "CENTER", 0, 0)
  button.Label:SetText(text)
  local function Rest()
    button.Background:SetColorTexture(unpack(primary and THEME.BUTTON_ON or THEME.BUTTON))
    if primary then button.Label:SetTextColor(unpack(THEME.GOLD)) else button.Label:SetTextColor(1, 1, 1, 1) end
  end
  Rest()
  button:SetScript("OnEnter", function()
    button.Background:SetColorTexture(0.24, 0.24, 0.28, 0.98)
    UI.SetBorderColor(button.Border, THEME.GOLD)
  end)
  button:SetScript("OnLeave", function()
    Rest()
    UI.SetBorderColor(button.Border, primary and THEME.GOLD or THEME.BORDER)
  end)
  button:SetScript("OnMouseDown", function() button.Label:SetPoint("CENTER", button, "CENTER", 0, -1) end)
  button:SetScript("OnMouseUp", function() button.Label:SetPoint("CENTER", button, "CENTER", 0, 0) end)
  button:SetScript("OnClick", onClick)
  if tooltipText then UI.AddTooltip(button, tooltipText) end
  return button
end

function UI.CreateSwatch(parent, tooltipText)
  local swatch = CreateFrame("Button", nil, parent)
  swatch:SetSize(22, 22)
  local border = swatch:CreateTexture(nil, "BACKGROUND")
  border:SetAllPoints(swatch)
  border:SetColorTexture(0.8, 0.8, 0.8, 1)
  swatch.Color = swatch:CreateTexture(nil, "ARTWORK")
  swatch.Color:SetPoint("TOPLEFT", swatch, "TOPLEFT", 2, -2)
  swatch.Color:SetPoint("BOTTOMRIGHT", swatch, "BOTTOMRIGHT", -2, 2)
  if tooltipText then UI.AddTooltip(swatch, tooltipText) end
  return swatch
end

function UI.GetClassColor(unit)
  local _, class = UnitClass(unit)
  if issecretvalue and issecretvalue(class) then class = nil end
  local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  if color then return color.r, color.g, color.b end
  return 1, 0.82, 0
end