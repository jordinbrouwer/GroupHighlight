GroupHighlight = GroupHighlight or {}
local L = GroupHighlight.Loc

local TEXTURE_PATH = "Interface\\AddOns\\GroupHighlight\\Media\\"
local TEXTURES = {
  triangle_filled = TEXTURE_PATH .. "Arrow",
  triangle_outline = TEXTURE_PATH .. "Outline",
  chevron1 = TEXTURE_PATH .. "Chevron1",
  chevron2_fade = TEXTURE_PATH .. "Chevron2Fade",
  chevron2_solid = TEXTURE_PATH .. "Chevron2Solid",
  chevron3_fade = TEXTURE_PATH .. "Chevron3Fade",
  chevron3_solid = TEXTURE_PATH .. "Chevron3Solid",
}
GroupHighlight.StyleTextures = TEXTURES

-- The texture that belongs to the chosen shape and its options.
GroupHighlight.GetStyleTexture = function()
  local options = GroupHighlightDB
  if options and options.Shape == "chevron" then
    local count = options.ChevronCount
    if count == 1 then return TEXTURES.chevron1 end
    return TEXTURES[(count == 3 and "chevron3" or "chevron2") .. (options.ChevronFade == false and "_solid" or "_fade")]
  end
  return options and options.TriangleFilled == false and TEXTURES.triangle_outline or TEXTURES.triangle_filled
end

-- Lift 1 is the lowest position; every step moves the arrow up one pixel. There is no fixed offset.
GroupHighlight.GetLiftOffset = function()
  local options = GroupHighlightDB
  return options and options.Lift or 1
end

local SELF_BASE_HEIGHT = 2400
local DEFAULT_COLOR = { 1, 0.82, 0 }

local arrows = {} -- nameplate frame -> arrow frame
local pool = {}
local selfArrow
local pendingCVars = false
local eventFrame = CreateFrame("Frame")

-- Nameplates are the only thing an addon can attach to a unit in the world. Arrows above group
-- members need these CVars; arrows above a target use whatever nameplates the player already has.
local PLAYER_CVARS = { "nameplateShowFriends", "nameplateShowFriendlyPlayers", "nameplateShowAll" }
local NPC_CVARS = { "nameplateShowFriendlyNPCs", "nameplateShowFriendlyNpcs" }

local function GetOptions()
  return GroupHighlightDB
end

local function GetMode()
  local options = GetOptions()
  return options and options.Mode or "off"
end

-- Inside dungeons and raids the game hides some unit information from addons ("secret values").
-- A secret value cannot be tested or used as a table key, so every lookup below checks for it.
local function IsSecret(value)
  return issecretvalue ~= nil and issecretvalue(value)
end

-- First result of fn when the call worked and the result is readable.
local function Safe(fn, ...)
  local ok, value = pcall(fn, ...)
  if ok and not IsSecret(value) then return value end
end

local function IsTrue(fn, ...)
  return Safe(fn, ...) == true
end

local GROUP_TOKENS = { "party1", "party2", "party3", "party4" }
for index = 1, 40 do GROUP_TOKENS[#GROUP_TOKENS + 1] = "raid" .. index end

-- The party or raid token of a unit, whose name and class can still be read when the
-- nameplate token cannot be.
local function GroupTokenFor(unit)
  for _, token in ipairs(GROUP_TOKENS) do
    if IsTrue(UnitIsUnit, unit, token) then return token end
  end
end

-- Party covers everyone in your party except yourself; yourself is a separate option.
local function ShouldHighlight(unit)
  local options = GetOptions()
  if not unit then return false end
  if options and options.ShowTarget and IsTrue(UnitIsUnit, unit, "target") then return true end
  if GetMode() == "off" then return false end
  if not IsTrue(UnitIsPlayer, unit) then return false end
  if IsTrue(UnitIsUnit, unit, "player") then return false end
  if IsTrue(UnitInParty, unit) then return true end
  return GetMode() == "raid" and Safe(UnitInRaid, unit) ~= nil
end

local function ColorFor(token)
  local options = GetOptions()
  local name = Safe(GetUnitName, token, true)
  if name and options and options.MemberColors then
    local color = options.MemberColors[name]
    if color then return color.r, color.g, color.b end
  end
  local ok, _, class = pcall(UnitClass, token)
  if ok and class and not IsSecret(class) then
    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if color then return color.r, color.g, color.b end
  end
end

-- Class color by default; a color chosen for a party member is remembered by name-realm.
local function GetColor(unit)
  local token = GroupTokenFor(unit)
  local r, g, b = ColorFor(token or unit)
  if not r and token then r, g, b = ColorFor(unit) end
  if r then return r, g, b end
  return DEFAULT_COLOR[1], DEFAULT_COLOR[2], DEFAULT_COLOR[3]
end
GroupHighlight.GetColor = GetColor

local function CreateArrow(parent)
  local frame = CreateFrame("Frame", nil, parent)
  -- Nameplates fade with range; the arrow should stay visible.
  if frame.SetIgnoreParentAlpha then frame:SetIgnoreParentAlpha(true) end
  frame.Texture = frame:CreateTexture(nil, "OVERLAY")
  frame.Texture:SetAllPoints(frame)
  frame.Texture:SetBlendMode("ADD")
  return frame
end

local function ApplyTexture(frame)
  local path = GroupHighlight.GetStyleTexture()
  if frame.TexturePath ~= path then
    frame.TexturePath = path
    frame.Texture:SetTexture(path)
  end
end

local function AcquireArrow(plate)
  local arrow = tremove(pool) or CreateArrow(plate)
  local options = GetOptions()
  local size = options and options.ArrowSize or 32
  arrow:SetParent(plate)
  ApplyTexture(arrow)
  arrow:ClearAllPoints()
  arrow:SetSize(size, size)
  arrow:SetPoint("BOTTOM", plate, "CENTER", 0, GroupHighlight.GetLiftOffset())
  arrow:Show()
  return arrow
end

local function ReleaseArrow(plate)
  local arrow = arrows[plate]
  if not arrow then return end
  arrow:Hide()
  arrow:SetParent(nil)
  arrows[plate] = nil
  tinsert(pool, arrow)
end

local function UpdatePlate(plate, unit)
  if not plate or (plate.IsForbidden and plate:IsForbidden()) then return end
  local ok, show = pcall(ShouldHighlight, unit)
  if ok and show then
    local arrow = arrows[plate]
    if not arrow then
      arrow = AcquireArrow(plate)
      arrows[plate] = arrow
    end
    local colored, r, g, b = pcall(GetColor, unit)
    if not colored then r, g, b = DEFAULT_COLOR[1], DEFAULT_COLOR[2], DEFAULT_COLOR[3] end
    arrow.Texture:SetVertexColor(r, g, b)
  else
    ReleaseArrow(plate)
  end
end

-- The player has no nameplate, so the arrow on yourself sits at the screen
-- center above the character and scales with the camera zoom.
local function UpdateSelfArrow()
  local options = GetOptions()
  if not selfArrow then return end
  if not options or not options.ShowSelf or options.Mode == "off" then
    selfArrow:Hide()
    return
  end
  local zoom = GetCameraZoom and GetCameraZoom() or 10
  local size = options.ArrowSize or 32
  ApplyTexture(selfArrow)
  selfArrow:SetSize(size, size)
  selfArrow:ClearAllPoints()
  selfArrow:SetPoint("BOTTOM", UIParent, "CENTER", options.SelfX or 0,
    SELF_BASE_HEIGHT / math.max(zoom, 2) / 2 + GroupHighlight.GetLiftOffset() - 20 + (options.SelfY or 0))
  selfArrow.Texture:SetVertexColor(GetColor("player"))
  selfArrow:Show()
end

-- While the editor is open the arrow above yourself can be dragged; the offset is
-- saved. Right-click puts it back.
local editing = false

local function GetCursor()
  local x, y = GetCursorPosition()
  local scale = UIParent:GetEffectiveScale()
  return x / scale, y / scale
end

local function SetupSelfDrag(arrow)
  local drag
  arrow:SetScript("OnMouseDown", function(_, button)
    local options = GetOptions()
    if button ~= "LeftButton" or not editing or not options then return end
    local x, y = GetCursor()
    drag = { x = x, y = y, offsetX = options.SelfX or 0, offsetY = options.SelfY or 0 }
  end)
  arrow:SetScript("OnMouseUp", function(_, button)
    local options = GetOptions()
    drag = nil
    if button == "RightButton" and editing and options then
      options.SelfX, options.SelfY = 0, 0
    end
  end)
  arrow:SetScript("OnUpdate", function()
    local options = GetOptions()
    if not drag or not options then return end
    local x, y = GetCursor()
    options.SelfX = math.floor(drag.offsetX + x - drag.x + 0.5)
    options.SelfY = math.floor(drag.offsetY + y - drag.y + 0.5)
  end)
  arrow:SetScript("OnEnter", function(self)
    if not editing then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L("editor_tip_drag"), nil, nil, nil, nil, true)
    GameTooltip:Show()
  end)
  arrow:SetScript("OnLeave", GameTooltip_Hide)
end

GroupHighlight.SetEditing = function(enabled)
  editing = enabled and true or false
  if selfArrow then
    selfArrow:EnableMouse(editing)
    selfArrow:SetFrameStrata(editing and "MEDIUM" or "BACKGROUND")
  end
end

-- The game only shows these nameplates with these CVars. Originals are saved and
-- restored when the option that needed them is switched off.
GroupHighlight.ApplyFriendlyPlates = function()
  local options = GetOptions()
  if not options or not C_CVar or not C_CVar.GetCVar then return end
  if InCombatLockdown() then
    pendingCVars = true
    return
  end
  pendingCVars = false
  options.CVarRestore = options.CVarRestore or {}
  local wanted = {}
  if GetMode() ~= "off" then
    for _, name in ipairs(PLAYER_CVARS) do wanted[name] = true end
  end
  -- The target option never touches NPC nameplates. NPC_CVARS is only here to put back a value an older
  -- version of this addon changed: it is never wanted, so a saved original is restored.
  local function Apply(name)
    local current = C_CVar.GetCVar(name)
    if current == nil then return end
    if wanted[name] then
      if current ~= "1" then
        if options.CVarRestore[name] == nil then options.CVarRestore[name] = current end
        pcall(C_CVar.SetCVar, name, "1")
      end
    elseif options.CVarRestore[name] ~= nil then
      pcall(C_CVar.SetCVar, name, options.CVarRestore[name])
      options.CVarRestore[name] = nil
    end
  end
  for _, name in ipairs(PLAYER_CVARS) do Apply(name) end
  for _, name in ipairs(NPC_CVARS) do Apply(name) end
end
-- Whether friendly NPCs can get an arrow: "on", "off" or "unavailable" when this version of
-- the game has no CVar for friendly NPC nameplates.
GroupHighlight.GetNpcPlateStatus = function()
  if not C_CVar or not C_CVar.GetCVar then return "unavailable" end
  for _, name in ipairs(NPC_CVARS) do
    local value = C_CVar.GetCVar(name)
    if value ~= nil then return value == "1" and "on" or "off" end
  end
  return "unavailable"
end

-- Plates that already exist after a reload do not fire NAME_PLATE_UNIT_ADDED.
local function ScanPlates()
  if not C_NamePlate then return end
  for index = 1, 40 do
    local unit = "nameplate" .. index
    if IsTrue(UnitExists, unit) then
      UpdatePlate(C_NamePlate.GetNamePlateForUnit(unit), unit)
    end
  end
end

GroupHighlight.Highlight_Refresh = function()
  if not (C_NamePlate and C_NamePlate.GetNamePlates) then return end
  if not selfArrow then
    selfArrow = CreateArrow(UIParent)
    selfArrow:SetFrameStrata("BACKGROUND")
    selfArrow:Hide()
    SetupSelfDrag(selfArrow)
    GroupHighlight.SetEditing(editing)
  end
  for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
    ReleaseArrow(plate)
    UpdatePlate(plate, plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit))
  end
  GroupHighlight.ApplyFriendlyPlates()
  UpdateSelfArrow()
end

-- Runs on the always-shown event frame, because a hidden frame gets no OnUpdate.
local elapsed = 0
eventFrame:SetScript("OnUpdate", function(_, delta)
  elapsed = elapsed + delta
  if elapsed < 0.05 then return end
  elapsed = 0
  UpdateSelfArrow()
end)

eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
eventFrame:SetScript("OnEvent", function(_, event, unit)
  if event == "NAME_PLATE_UNIT_ADDED" then
    UpdatePlate(C_NamePlate.GetNamePlateForUnit(unit), unit)
  elseif event == "NAME_PLATE_UNIT_REMOVED" then
    ReleaseArrow(C_NamePlate.GetNamePlateForUnit(unit))
  elseif event == "PLAYER_REGEN_ENABLED" then
    if pendingCVars then GroupHighlight.Highlight_Refresh() end
  elseif event == "PLAYER_ENTERING_WORLD" then
    C_Timer.After(0.5, function()
      GroupHighlight.Highlight_Refresh()
      ScanPlates()
    end)
  else
    GroupHighlight.Highlight_Refresh()
  end
end)