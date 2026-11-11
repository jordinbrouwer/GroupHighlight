-- Settings > AddOns > GroupHighlight: icon, description and a button for the editor.
GroupHighlight = GroupHighlight or {}
local L = GroupHighlight.Loc

function GroupHighlight.BuildPanel()
  if not (Settings and Settings.RegisterCanvasLayoutCategory) then return end
  local panel = CreateFrame("Frame")
  panel.name = L("settings_category")

  local icon = panel:CreateTexture(nil, "ARTWORK")
  icon:SetSize(40, 40)
  icon:SetPoint("TOPLEFT", 16, -16)
  icon:SetTexture("Interface\\AddOns\\GroupHighlight\\GroupHighlight")

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
  title:SetPoint("LEFT", icon, "RIGHT", 10, 0)
  title:SetText("GroupHighlight")

  local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  desc:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -16)
  desc:SetText(L("panel_description"))
  desc:SetJustifyH("LEFT")

  local open = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  open:SetSize(240, 32)
  open:SetPoint("CENTER", panel, "CENTER", 0, 0)
  open:SetText(L("panel_button_open"))
  open:SetScript("OnClick", function()
    if SettingsPanel and HideUIPanel then HideUIPanel(SettingsPanel) end
    GroupHighlight.OpenEditor()
  end)

  local category = Settings.RegisterCanvasLayoutCategory(panel, L("settings_category"))
  Settings.RegisterAddOnCategory(category)
end

GroupHighlight.BuildPanel()