-- Settings > AddOns > GroupHighlight: a short page with the icon, the description and a button for the editor.
local GH = GroupHighlight
local L = GH.Loc
local UI = GH.UI
local THEME = UI.THEME

local function BuildPanel()
  if not (Settings and Settings.RegisterCanvasLayoutCategory) then return end
  local panel = CreateFrame("Frame")
  panel.name = L("settings_category")

  local icon = panel:CreateTexture(nil, "ARTWORK")
  icon:SetSize(44, 44)
  icon:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -24)
  icon:SetTexture(GH.Media.Logo)

  local title = panel:CreateFontString(nil, "OVERLAY", "GroupHighlightFontNormalHuge")
  title:SetPoint("LEFT", icon, "RIGHT", 12, 0)
  title:SetText("GroupHighlight")

  local desc = panel:CreateFontString(nil, "OVERLAY", "GroupHighlightFontHighlight")
  desc:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -14)
  desc:SetPoint("RIGHT", panel, "RIGHT", -24, 0)
  desc:SetJustifyH("LEFT")
  desc:SetText(L("panel_description"))

  local open = UI.FlatChip(panel, L("panel_button_open"), 280, false, function()
    if SettingsPanel and HideUIPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
    GH.OpenOptions()
  end)
  open:SetHeight(30)
  open:SetPoint("CENTER", panel, "CENTER", 0, 0)

  local hint = panel:CreateFontString(nil, "OVERLAY", "GroupHighlightFontNormalSmall")
  hint:SetPoint("TOP", open, "BOTTOM", 0, -10)
  hint:SetTextColor(unpack(THEME.MUTED))
  hint:SetText(L("panel_hint"))
  UI.ApplyOutline(panel)

  local category = Settings.RegisterCanvasLayoutCategory(panel, L("settings_category"))
  Settings.RegisterAddOnCategory(category)
end

BuildPanel()