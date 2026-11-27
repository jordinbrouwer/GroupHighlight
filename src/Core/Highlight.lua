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
  diamond_filled = MEDIA.Diamond,
  diamond_outline = MEDIA.DiamondOutline,
  circle_filled = MEDIA.Circle,
  circle_outline = MEDIA.Ring,
  star_filled = MEDIA.Star,
  star_outline = MEDIA.StarOutline,
  pin_filled = MEDIA.Pin,
  pin_outline = MEDIA.PinHole,        -- not filled: the pin keeps its shape, with a round hole
  shield_filled = MEDIA.Shield,
  shield_outline = MEDIA.ShieldOutline,
  sword_filled = MEDIA.Sword,
  sword_outline = MEDIA.SwordOutline,
  plus_filled = MEDIA.Plus,
  plus_outline = MEDIA.PlusOutline,
}
GH.StyleTextures = TEXTURES
-- The shapes in the order of the list in the editor. outline: the shape can be drawn as an outline too (option Filled).
GH.Shapes = {
  { key = "triangle", outline = true },
  { key = "chevron" },
  { key = "diamond", outline = true },
  { key = "circle", outline = true },
  { key = "star", outline = true },
  { key = "pin", outline = true },
  { key = "shield", outline = true },
  { key = "sword", outline = true },
  { key = "plus", outline = true },
}
GH.ShapeInfo = {}
for _, shape in ipairs(GH.Shapes) do GH.ShapeInfo[shape.key] = shape end

-- The texture of a look: a table with Shape, Filled, ChevronCount and ChevronFade (the options, or a member's own look).
local function TextureFor(look)
  local shape = GH.ShapeInfo[look.Shape] and look.Shape or "triangle"
  if shape == "chevron" then
    local count = look.ChevronCount
    if count == 1 then return TEXTURES.chevron1 end
    return TEXTURES[(count == 3 and "chevron3" or "chevron2") .. (look.ChevronFade == false and "_solid" or "_fade")]
  end
  local outline = GH.ShapeInfo[shape].outline and look.Filled == false
  return TEXTURES[shape .. (outline and "_outline" or "_filled")]
end
GH.GetLookTexture = TextureFor

-- The look of a member (by name): their own, or else the one chosen in Look. nil before the settings are loaded.
GH.GetMemberLook = function(name)
  local options = GetOptions()
  if not options then return nil end
  return name and options.MemberShapes and options.MemberShapes[name] or options
end

-- The texture of a member's look.
GH.GetStyleTexture = function(name)
  local look = GH.GetMemberLook(name)
  return look and TextureFor(look) or TEXTURES.triangle_filled
end

-- The size of a member's shape and how high it sits above the name (Lift 1 is the lowest; every step is a pixel).
GH.GetMemberSize = function(name)
  local look = GH.GetMemberLook(name)
  return look and look.ArrowSize or 32, look and look.Lift or 1
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
  frame.Texture:SetBlendMode("BLEND")   -- not ADD: that mixes in the ground, so the colour changed with the background
  return frame
end

-- The member's texture and size; gives back how high the shape sits above its anchor.
local function ApplyLook(frame, unit)
  local name = GH.GetMemberName(unit)
  local path = GH.GetStyleTexture(name)
  if frame.TexturePath ~= path then
    frame.TexturePath = path
    frame.Texture:SetTexture(path)
  end
  local size, lift = GH.GetMemberSize(name)
  frame:SetSize(size, size)
  return lift
end

local function AcquireArrow(plate)
  local arrow = tremove(pool) or CreateArrow(plate)
  arrow:SetParent(plate)
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
    local lift = ApplyLook(arrow, unit)
    arrow:ClearAllPoints()
    arrow:SetPoint("BOTTOM", plate, "CENTER", 0, lift)
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
  local lift = ApplyLook(selfArrow, "player")
  selfArrow:ClearAllPoints()
  selfArrow:SetPoint("BOTTOM", UIParent, "CENTER", 0,
    SELF_BASE_HEIGHT / math.max(zoom, 2) / 2 + lift - 20)
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
