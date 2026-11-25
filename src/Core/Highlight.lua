-- The arrows: which units get one, where it sits and its picture. They hang on nameplates; yours sits at the screen centre.
local GH = GroupHighlight
local GetOptions = GH.GetOptions
local Safe, IsTrue, GetMode = GH.Safe, GH.IsTrue, GH.GetMode
local GetColor, DEFAULT_COLOR = GH.GetColor, GH.DEFAULT_COLOR

local MEDIA = GH.Media
local TEXTURES = {
  triangle_filled = MEDIA.Arrow,
  triangle_outline = MEDIA.Outline,
  chevron1 = MEDIA.Chevron1,
  chevron2_fade = MEDIA.Chevron2Fade,
  chevron2_solid = MEDIA.Chevron2Solid,
  chevron3_fade = MEDIA.Chevron3Fade,
  chevron3_solid = MEDIA.Chevron3Solid,
}
GH.StyleTextures = TEXTURES
-- The texture that belongs to the chosen shape and its options.
GH.GetStyleTexture = function()
  local options = GetOptions()
  if options and options.Shape == "chevron" then
    local count = options.ChevronCount
    if count == 1 then return TEXTURES.chevron1 end
    return TEXTURES[(count == 3 and "chevron3" or "chevron2") .. (options.ChevronFade == false and "_solid" or "_fade")]
  end
  return options and options.TriangleFilled == false and TEXTURES.triangle_outline or TEXTURES.triangle_filled
end

-- Lift 1 is the lowest position; every step moves the arrow up one pixel. There is no fixed offset.
GH.GetLiftOffset = function()
  local options = GetOptions()
  return options and options.Lift or 1
end

local SELF_BASE_HEIGHT = 2400

local arrows = {} -- nameplate frame -> arrow frame
local pool = {}
local selfArrow

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
  local path = GH.GetStyleTexture()
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
  arrow:SetPoint("BOTTOM", plate, "CENTER", 0, GH.GetLiftOffset())
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
  selfArrow:SetPoint("BOTTOM", UIParent, "CENTER", 0,
    SELF_BASE_HEIGHT / math.max(zoom, 2) / 2 + GH.GetLiftOffset() - 20)
  selfArrow.Texture:SetVertexColor(GetColor("player"))
  selfArrow:Show()
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

GH.Highlight_Refresh = function()
  if not (C_NamePlate and C_NamePlate.GetNamePlates) then return end
  if not selfArrow then
    selfArrow = CreateArrow(UIParent)
    selfArrow:SetFrameStrata("BACKGROUND")
    selfArrow:Hide()
    selfArrow:EnableMouse(false)
  end
  for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
    ReleaseArrow(plate)
    UpdatePlate(plate, plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit))
  end
  GH.ApplyFriendlyPlates()
  UpdateSelfArrow()
end

-- Runs on a frame that is always shown, because a hidden frame gets no OnUpdate.
local elapsed = 0
CreateFrame("Frame"):SetScript("OnUpdate", function(_, delta)
  elapsed = elapsed + delta
  if elapsed < 0.05 then return end
  elapsed = 0
  UpdateSelfArrow()
end)

GH.On("NAME_PLATE_UNIT_ADDED", function(unit)
  UpdatePlate(C_NamePlate.GetNamePlateForUnit(unit), unit)
end)
GH.On("NAME_PLATE_UNIT_REMOVED", function(unit)
  ReleaseArrow(C_NamePlate.GetNamePlateForUnit(unit))
end)
GH.On("PLAYER_ENTERING_WORLD", function()   -- also fires on entering and leaving an instance
  C_Timer.After(0.5, function()
    GH.Highlight_Refresh()
    ScanPlates()
  end)
end)
GH.On("GROUP_ROSTER_UPDATE", function() GH.Highlight_Refresh() end)
GH.On("PLAYER_TARGET_CHANGED", function() GH.Highlight_Refresh() end)
