-- The colour of an arrow: the colour chosen for a party member, or else the class colour.
local GH = GroupHighlight
local GetOptions = GH.GetOptions

GH.DEFAULT_COLOR = { 1, 0.82, 0 }   -- when nothing else can be read
local DEFAULT_COLOR = GH.DEFAULT_COLOR

local GROUP_TOKENS = { "party1", "party2", "party3", "party4" }
for index = 1, 40 do GROUP_TOKENS[#GROUP_TOKENS + 1] = "raid" .. index end

-- The party or raid token of a unit, whose name and class can still be read when the
-- nameplate token cannot be.
local function GroupTokenFor(unit)
  for _, token in ipairs(GROUP_TOKENS) do
    if GH.IsTrue(UnitIsUnit, unit, token) then return token end
  end
end

local function ColorFor(token)
  local options = GetOptions()
  local name = GH.Safe(GetUnitName, token, true)
  if name and options and options.MemberColors then
    local color = options.MemberColors[name]
    if color then return color.r, color.g, color.b end
  end
  local ok, _, class = pcall(UnitClass, token)
  if ok and class and not GH.IsSecret(class) then
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
GH.GetColor = GetColor

-- The name (name-realm) a member's own colour and shape are kept under; read via the group token when possible.
GH.GetMemberName = function(unit)
  local name = GH.Safe(GetUnitName, GroupTokenFor(unit) or unit, true)
  if name and not GH.IsSecret(name) then return name end
end
