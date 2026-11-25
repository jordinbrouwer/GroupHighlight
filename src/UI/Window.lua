-- The editor window opened with /gh: the frame, the header, the warning strip, the scroll area with the four boxes,
-- the grip, and opening and closing.
local GH = GroupHighlight
local UI = GH.UI
local L = GH.Loc
local GetOptions = GH.GetOptions
local LAYOUT, THEME = UI.LAYOUT, UI.THEME
local S = UI.state

local WINDOW_NAME = "GroupHighlightEditor"
local GOLD_CODE = "|cffffd100"   -- the gold of the addon, as a colour code (for tooltips)

local function SavePosition()
  local options = GetOptions()
  if not options then return end
  local point, _, relativePoint, x, y = S.window:GetPoint()
  options.EditorPoint = { point, relativePoint, x, y }
  GH.RepositionColorPicker()
end

-- The frame: its size and place are the saved ones (if there are any).
local function BuildFrame()
  local frame = CreateFrame("Frame", WINDOW_NAME, UIParent)
  local saved = GetOptions() and GetOptions().EditorSize
  -- the default is wide enough for two columns of boxes; drag the grip narrower for one column
  local width = saved and math.max(LAYOUT.ONE_COLUMN, math.min(LAYOUT.MAX_WIDTH, saved[1] or LAYOUT.TWO_COLUMNS)) or LAYOUT.TWO_COLUMNS
  frame:SetSize(width, saved and math.max(LAYOUT.MIN_HEIGHT, saved[2] or 400) or 400)
  frame:SetFrameStrata("DIALOG")
  frame:SetToplevel(true)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:EnableMouse(true)
  local point = GetOptions() and GetOptions().EditorPoint
  if point then
    frame:SetPoint(point[1], UIParent, point[2], point[3], point[4])
  else
    frame:SetPoint("LEFT", UIParent, "LEFT", 60, 0)
  end
  UI.StyleWindow(frame)
  S.window = frame
  return frame
end

-- The header band: the logo, the name and the .toc description; drag it to move the window.
local function BuildHeader(frame)
  local bar = UI.CreateHeaderBand(frame, LAYOUT.HEADER - 3)
  bar:EnableMouse(true)
  bar:RegisterForDrag("LeftButton")
  bar:SetScript("OnDragStart", function() frame:StartMoving() end)
  bar:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    SavePosition()
  end)

  local logo = bar:CreateTexture(nil, "ARTWORK")
  logo:SetSize(34, 34)
  logo:SetPoint("LEFT", bar, "LEFT", 12, 0)
  logo:SetTexture(GH.Media.Logo)
  local title = bar:CreateFontString(nil, "OVERLAY", "GroupHighlightFontNormalLarge")
  title:SetTextColor(unpack(THEME.TITLE_TEXT))
  title:SetText(GH.AddonName)
  local subtitle = bar:CreateFontString(nil, "OVERLAY", "GroupHighlightFontNormalSmall")
  subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
  subtitle:SetTextColor(unpack(THEME.SUBTITLE_TEXT))
  local notes = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(GH.AddonName, "Notes"))
    or (GetAddOnMetadata and GetAddOnMetadata(GH.AddonName, "Notes"))
  subtitle:SetText(notes and notes ~= "" and notes or L("panel_description"))
  -- name and description together are centred on the logo
  title:SetPoint("LEFT", bar, "LEFT", 56, (subtitle:GetStringHeight() + 2) / 2)

  local close = UI.CreateCloseButton(bar, function() frame:Hide() end)
  close:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -9, 0)
end

-- The scroll area between the header and the band at the bottom, with the content (the boxes) in it and a thin scroll bar.
-- Gives back the function that updates the bar.
local function BuildScrollArea(frame)
  local scroll = CreateFrame("ScrollFrame", nil, frame)
  scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -LAYOUT.HEADER)
  scroll:SetPoint("BOTTOMRIGHT", S.strip, "TOPRIGHT", 1, 0)   -- down to the band at the bottom (1 pixel inside the window)
  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(frame:GetWidth(), 300)
  scroll:SetScrollChild(content)
  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel", function(self, delta)
    self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), self:GetVerticalScroll() - delta * 40)))
  end)
  scroll:SetScript("OnSizeChanged", function() UI.Relayout() end)
  S.scroll, S.content = scroll, content
  UI.BuildCanvas(content)
  return UI.CreateScrollBar(frame, scroll, -5)
end

-- The grip in the bottom right corner: drag to change width and height, right-click for the default size.
local function BuildGrip(frame)
  frame:SetResizable(true)
  local grip = CreateFrame("Button", nil, frame)
  grip:SetSize(14, 14)
  grip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
  grip:SetFrameLevel(frame:GetFrameLevel() + 20)
  local icon = grip:CreateTexture(nil, "OVERLAY")
  icon:SetAllPoints(grip)
  icon:SetTexture(GH.Media.Grip)
  local function Paint(color) icon:SetVertexColor(color[1], color[2], color[3], 1) end
  Paint(THEME.MUTED)
  grip:SetScript("OnEnter", function(self)
    Paint(THEME.BRIGHT)
    UI.Tip.Show(self, "LEFT", L("grip_title"),
      GOLD_CODE .. L("grip_label_drag") .. "|r " .. L("grip_tip_drag"),
      GOLD_CODE .. L("grip_label_right") .. "|r " .. L("grip_tip_reset"))
  end)
  grip:SetScript("OnLeave", function() Paint(THEME.MUTED) UI.Tip.Hide() end)
  grip:SetScript("OnMouseDown", function(_, mouseButton)
    if mouseButton ~= "LeftButton" then return end
    -- sizing from the top left corner: the window is anchored there first
    local left, top = frame:GetLeft(), frame:GetTop()
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    frame.sizing = true
    frame:StartSizing("BOTTOMRIGHT")
  end)
  grip:SetScript("OnMouseUp", function(_, mouseButton)
    local options = GetOptions()
    if mouseButton == "RightButton" then
      if options then options.EditorSize = nil end
      frame:SetWidth(LAYOUT.TWO_COLUMNS)
      UI.Relayout()
      return
    end
    frame:StopMovingOrSizing()
    frame.sizing = false
    if options then options.EditorSize = { math.floor(frame:GetWidth() + 0.5), math.floor(frame:GetHeight() + 0.5) } end
    SavePosition()
    UI.Relayout()
  end)
end

-- Showing: the boxes are filled and placed now and once more a moment later (sizes are known after showing).
-- Escape closes it.
local function SetupShowing(frame, updateScrollBar)
  frame:SetScript("OnShow", function()
    UI.SyncEditor()
    UI.Relayout()
    updateScrollBar()
    C_Timer.After(0, function() UI.Relayout() updateScrollBar() end)
  end)
  frame:SetScript("OnHide", function()
    GH.CloseColorPicker()
    UI.Tip.Hide()
  end)
  frame:RegisterEvent("GROUP_ROSTER_UPDATE")
  frame:RegisterEvent("PLAYER_TARGET_CHANGED")
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:SetScript("OnEvent", function()
    if frame:IsShown() then UI.SyncEditor() end
  end)
  tinsert(UISpecialFrames, WINDOW_NAME)
end

local function BuildWindow()
  local frame = BuildFrame()
  BuildHeader(frame)
  UI.BuildWarningStrip(frame)
  local updateScrollBar = BuildScrollArea(frame)
  BuildGrip(frame)
  SetupShowing(frame, updateScrollBar)
  UI.ApplyOutline(frame)
  frame:Hide()
end

function GH.OpenOptions()
  if not GetOptions() then return end
  if not S.window then BuildWindow() end
  S.window:Show()
end

function GH.ToggleOptions()
  if S.window and S.window:IsShown() then
    S.window:Hide()
  else
    GH.OpenOptions()
  end
end

GH.RefreshWindow = function()
  if S.window and S.window:IsShown() then UI.SyncEditor() end
end
