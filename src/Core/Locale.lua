GroupHighlight = GroupHighlight or {}

local enUS = {
  settings_category = "GroupHighlight",
  binding_toggle = "Turn the arrows on or off",
  toggle_message = "GroupHighlight: %s.",
  panel_description = "An arrow above your party and raid members.",
  panel_button_open = "Open GroupHighlight",
  editor_close = "Close",
  editor_defaults = "Defaults",
  editor_tip_defaults = "Reset all options to their defaults.",
  editor_tip_drag = "Drag to move the arrow above yourself. Right-click to put it back.",
  editor_section_who = "Who gets an arrow",
  shape_triangle = "Triangle",
  shape_chevron = "Chevron",
  shape_tip_triangle = "A triangle pointing down.",
  shape_tip_chevron = "One, two or three chevrons pointing down.",
  option_TriangleFilled = "Filled",
  option_tip_TriangleFilled = "Fill the triangle. Turn this off to draw only its outline.",
  option_ChevronFade = "Fade out",
  option_tip_ChevronFade = "Make each extra chevron fainter than the one below it. Turn this off to draw them all equally bright.",
  chevron_count_1 = "One chevron.",
  chevron_count_2 = "Two chevrons.",
  chevron_count_3 = "Three chevrons.",
  editor_section_look = "Look",
  editor_section_preview = "Preview",
  editor_section_party = "Party colours",
  editor_size = "Arrow size",
  editor_lift = "Lift above name",
  editor_tip_size = "Size of the arrow in pixels.",
  editor_tip_lift = "How high the arrow sits, in pixels. 1 is the lowest.",
  editor_no_party = "No party members to show.",
  editor_tip_member = "Left-click to choose a colour. Right-click to go back to the class colour.",
  picker_title = "Choose a colour",
  picker_okay = "Okay",
  picker_cancel = "Cancel",
  picker_tip_preset = "Use the %s colour.",
  picker_tip_hex = "Type a colour as six hex digits, for example FF8800.",
  picker_tip_hue = "The basic colour.",
  picker_tip_field = "Click or drag to choose how strong and how light the colour is. Left is closer to white, the bottom is closer to black.",
  mode_off = "Off",
  mode_party = "Party",
  mode_raid = "Party + Raid",
  mode_tip_off = "No arrows.",
  mode_tip_party = "Arrow above every party member, except yourself.",
  mode_tip_raid = "Arrow above every party and raid member, except yourself.",
  instance_banner = "Inside dungeons and raids, arrows don't work above friendly players.",
  option_ShowSelf = "Also above yourself",
  option_tip_ShowSelf = "Show the arrow above your own character as well.",
  option_ShowTarget = "Also above your target",
  option_tip_ShowTarget = "Show the arrow above your current target as well. The arrow is attached to the nameplate, so it works on players and enemies, and on friendly NPCs when you have friendly NPC nameplates turned on in the game's nameplate settings. It does not work on units without a nameplate, like objects or units out of range. Your nameplate settings are never changed for this.",
  target_status = "Friendly NPC nameplates: %s",
  target_status_on = "on in your game settings, so friendly NPCs get an arrow.",
  target_status_off = "off in your game settings, so friendly NPCs get no arrow. Turn them on in the game's nameplate settings if you want that.",
  target_status_unavailable = "not available in this version of the game, so friendly NPCs get no arrow.",
}

local locales = { enUS = enUS }

GroupHighlight.Loc = function(key)
  local strings = locales[GetLocale()] or enUS
  return strings[key] or enUS[key] or key
end

-- Names in the key bindings screen (Options > Keybindings > AddOns).
BINDING_HEADER_GROUPHIGHLIGHT = "GroupHighlight"
BINDING_NAME_GROUPHIGHLIGHT_TOGGLE = GroupHighlight.Loc("binding_toggle")
