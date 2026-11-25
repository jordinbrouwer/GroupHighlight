-- Small helpers for reading units safely.
local GH = GroupHighlight

-- Inside dungeons and raids the game hides some unit information from addons ("secret values").
-- A secret value cannot be tested or used as a table key, so every lookup below checks for it.
GH.IsSecret = function(value)
  return issecretvalue ~= nil and issecretvalue(value)
end

-- First result of fn when the call worked and the result is readable.
GH.Safe = function(fn, ...)
  local ok, value = pcall(fn, ...)
  if ok and not GH.IsSecret(value) then return value end
end

GH.IsTrue = function(fn, ...)
  return GH.Safe(fn, ...) == true
end
