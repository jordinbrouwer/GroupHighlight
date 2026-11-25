-- Toasts: messages at the top of the screen. A band with the logo and name, the text, and a bar that runs out.
-- Click to close; the bar waits while the mouse is over it. GH.ShowToast(text)
local GH = GroupHighlight
local UI = GH.UI
local THEME = UI.THEME

local WIDTH, PAD, HEADER_H, BAR_H = 290, 10, 24, 3
local GAP = 6                -- between two toasts
local TOP_OFFSET = 140       -- from the top of the screen
local MAX_TOASTS = 4
local SECONDS = 5

local pool, active = {}, {}

local function Layout()
  local y = -TOP_OFFSET
  for _, toast in ipairs(active) do
    toast:ClearAllPoints()
    toast:SetPoint("TOP", UIParent, "TOP", 0, y)
    y = y - toast:GetHeight() - GAP
  end
end

local function Release(toast)
  toast:Hide()
  toast:SetScript("OnUpdate", nil)
  for i, t in ipairs(active) do
    if t == toast then table.remove(active, i) break end
  end
  pool[#pool + 1] = toast
  Layout()
end

local function Create()
  local toast = CreateFrame("Button", nil, UIParent)
  toast:SetWidth(WIDTH)
  toast:SetFrameStrata("FULLSCREEN_DIALOG")
  local background = toast:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(toast)
  background:SetColorTexture(unpack(THEME.TIP_BG))
  UI.AddBorder(toast, THEME.BORDER)

  local band = toast:CreateTexture(nil, "ARTWORK")
  band:SetPoint("TOPLEFT", 1, -1)
  band:SetPoint("TOPRIGHT", -1, -1)
  band:SetHeight(HEADER_H)
  band:SetColorTexture(unpack(THEME.HEADER))
  local logo = toast:CreateTexture(nil, "OVERLAY")
  logo:SetSize(16, 16)
  logo:SetPoint("LEFT", band, "LEFT", 8, 0)
  logo:SetTexture(GH.Media.Logo)
  local title = toast:CreateFontString(nil, "OVERLAY", "GroupHighlightFontNormalSmall")
  title:SetPoint("LEFT", logo, "RIGHT", 6, 0)
  title:SetTextColor(unpack(THEME.TITLE_TEXT))
  title:SetText("GroupHighlight")

  toast.body = toast:CreateFontString(nil, "OVERLAY", "GroupHighlightFontHighlight")
  toast.body:SetPoint("TOPLEFT", toast, "TOPLEFT", PAD, -(HEADER_H + 9))
  toast.body:SetWidth(WIDTH - 2 * PAD)
  toast.body:SetJustifyH("LEFT")
  toast.body:SetTextColor(1, 1, 1)

  local track = toast:CreateTexture(nil, "ARTWORK")
  track:SetPoint("BOTTOMLEFT", 1, 1)
  track:SetPoint("BOTTOMRIGHT", -1, 1)
  track:SetHeight(BAR_H)
  track:SetColorTexture(0.14, 0.15, 0.17, 1)
  toast.bar = toast:CreateTexture(nil, "OVERLAY")
  toast.bar:SetPoint("BOTTOMLEFT", 1, 1)
  toast.bar:SetHeight(BAR_H)
  toast.bar:SetColorTexture(unpack(THEME.ACCENT))

  toast:RegisterForClicks("AnyUp")
  toast:SetScript("OnClick", Release)
  toast:SetScript("OnEnter", function(self) self.hover = true end)
  toast:SetScript("OnLeave", function(self) self.hover = false end)
  UI.ApplyOutline(toast)
  return toast
end

GH.ShowToast = function(text)
  if #active >= MAX_TOASTS then Release(active[1]) end
  local toast = table.remove(pool) or Create()
  toast.body:SetText(text)
  toast:SetHeight(HEADER_H + 9 + math.ceil(toast.body:GetStringHeight()) + 9 + BAR_H + 1)
  toast.hover = false
  toast.left = SECONDS
  toast.bar:SetWidth(WIDTH - 2)
  toast:SetScript("OnUpdate", function(self, elapsed)
    if self.hover then return end
    self.left = self.left - elapsed
    if self.left <= 0 then
      Release(self)
    else
      self.bar:SetWidth(math.max(1, (WIDTH - 2) * self.left / SECONDS))
    end
  end)
  active[#active + 1] = toast
  toast:Show()
  Layout()
end