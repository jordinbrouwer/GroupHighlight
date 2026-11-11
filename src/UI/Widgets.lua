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

function UI.AddBorder(frame, color)
  local function Edge(p1, p2, x1, y1, x2, y2)
    local line = frame:CreateTexture(nil, "BORDER")
    line:SetColorTexture(unpack(color))
    line:SetPoint(p1, frame, p1, x1, y1)
    line:SetPoint(p2, frame, p2, x2, y2)
    return line
  end
  return {
    Edge("TOPLEFT", "TOPRIGHT", 0, 0, 0, -1),
    Edge("BOTTOMLEFT", "BOTTOMRIGHT", 0, 1, 0, 0),
    Edge("TOPLEFT", "BOTTOMLEFT", 0, 0, 1, 0),
    Edge("TOPRIGHT", "BOTTOMRIGHT", -1, 0, 0, 0),
  }
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
  button.Label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
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