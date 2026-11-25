-- Our own tooltip: a dark box with a gold edge, a gold title and white text. One for the whole addon.
local GH = GroupHighlight
local UI = GH.UI
local THEME = UI.THEME

-- UI.Tip.Show(owner, anchor, title, paragraph, ...)   anchor: "RIGHT" or "LEFT";  UI.Tip.Hide(owner)
local Tip = {}
UI.Tip = Tip
do
  local MAX_W, PAD = 260, 10
  local frame = CreateFrame("Frame", "GroupHighlightTip", UIParent)
  frame:SetFrameStrata("TOOLTIP")
  frame:SetClampedToScreen(true)
  frame:Hide()
  local background = frame:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(frame)
  background:SetColorTexture(unpack(THEME.TIP_BG))
  UI.AddBorder(frame, THEME.ACCENT)
  local title = frame:CreateFontString(nil, "OVERLAY", "GroupHighlightFontNormal")
  title:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -PAD)
  title:SetJustifyH("LEFT")
  title:SetTextColor(unpack(THEME.ACCENT))
  local body = frame:CreateFontString(nil, "OVERLAY", "GroupHighlightFontHighlight")
  body:SetJustifyH("LEFT")
  body:SetTextColor(1, 1, 1)
  body:SetSpacing(2)
  UI.ApplyOutline(frame)

  function Tip.Show(owner, anchor, titleText, ...)
    if not owner then return end
    local bodyText = table.concat({ ... }, "\n")
    local hasTitle = titleText ~= nil and titleText ~= ""
    local hasBody = bodyText ~= ""
    frame.owner = owner
    local width, height = 0, PAD * 2
    title:SetShown(hasTitle)
    if hasTitle then
      title:SetWidth(0)
      title:SetText(titleText)
      width = title:GetStringWidth()
      height = height + title:GetStringHeight()
    end
    body:SetShown(hasBody)
    body:ClearAllPoints()
    if hasBody then
      body:SetWidth(0)
      body:SetText(bodyText)
      local bodyWidth = math.min(MAX_W, body:GetStringWidth())
      body:SetWidth(math.ceil(bodyWidth) + 1)
      width = math.max(width, bodyWidth)
      height = height + body:GetStringHeight() + (hasTitle and 4 or 0)
      if hasTitle then
        body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
      else
        body:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -PAD)
      end
    end
    frame:SetSize(math.ceil(width) + PAD * 2, math.ceil(height))
    frame:ClearAllPoints()
    if anchor == "LEFT" then
      frame:SetPoint("BOTTOMRIGHT", owner, "TOPLEFT", -2, 2)
    else
      frame:SetPoint("BOTTOMLEFT", owner, "TOPRIGHT", 2, 2)
    end
    frame:Show()
  end

  function Tip.Hide(owner)
    if not owner or frame.owner == owner then
      frame:Hide()
      frame.owner = nil
    end
  end
end

-- text and title: a string or a function that returns one (the title is optional). The tooltip hangs on `owner`
-- (default: the frame): give a row and what is in it the same owner, so it does not jump.
function UI.AddTooltip(frame, text, title, owner)
  local function Resolve(value) if type(value) == "function" then return value() end return value end
  frame:HookScript("OnEnter", function(self)
    Tip.Show(owner or self, "RIGHT", Resolve(title), Resolve(text))
  end)
  frame:HookScript("OnLeave", function(self) Tip.Hide(owner or self) end)
end
