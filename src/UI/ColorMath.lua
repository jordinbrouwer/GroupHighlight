-- Colour arithmetic for the colour picker: red/green/blue <-> hue/saturation/brightness and hex codes.
local GH = GroupHighlight
local UI = GH.UI

local function RGBToHSV(r, g, b)
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local delta = max - min
  local h = 0
  if delta > 0 then
    if max == r then
      h = ((g - b) / delta) % 6
    elseif max == g then
      h = (b - r) / delta + 2
    else
      h = (r - g) / delta + 4
    end
    h = h * 60
  end
  return h, max == 0 and 0 or delta / max, max
end

local function HSVToRGB(h, s, v)
  local c = v * s
  local x = c * (1 - math.abs((h / 60) % 2 - 1))
  local m = v - c
  local r, g, b
  if h < 60 then r, g, b = c, x, 0
  elseif h < 120 then r, g, b = x, c, 0
  elseif h < 180 then r, g, b = 0, c, x
  elseif h < 240 then r, g, b = 0, x, c
  elseif h < 300 then r, g, b = x, 0, c
  else r, g, b = c, 0, x end
  return r + m, g + m, b + m
end

local function ToHex(r, g, b)
  return ("%02X%02X%02X"):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

local function FromHex(text)
  local hex = (text or ""):gsub("#", "")
  if #hex ~= 6 or hex:find("%X") then return end
  return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

local function Near(a, b)
  return math.abs(a - b) < 0.006
end

local function Clamp01(value)
  return math.max(0, math.min(1, value))
end

UI.RGBToHSV, UI.HSVToRGB, UI.ToHex, UI.FromHex, UI.Near, UI.Clamp01 = RGBToHSV, HSVToRGB, ToHex, FromHex, Near, Clamp01
