-- /gh (or /grouphighlight) opens the window.
local GH = GroupHighlight
SLASH_GROUPHIGHLIGHT1 = "/gh"
SLASH_GROUPHIGHLIGHT2 = "/grouphighlight"

SlashCmdList.GROUPHIGHLIGHT = function()
  GH.ToggleOptions()
end
