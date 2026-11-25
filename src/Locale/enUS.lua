-- All texts of the addon (English).
GroupHighlight = GroupHighlight or {}

local enUS = {
  settings_category = "GroupHighlight",
  binding_toggle = "Turn the arrows on or off",
  toggle_message = "Highlight: %s.",
  panel_description = "An arrow above your party and raid members.",
  grip_title = "Resize window",
  grip_label_drag = "Drag:",
  grip_label_right = "Right-click:",
  grip_tip_drag = "change the width and height of the window.",
  grip_tip_reset = "go back to the default size.",
  panel_hint = "or type /gh",
  panel_button_open = "Open GroupHighlight",
  editor_reset_confirm = "Click again",
  editor_reset = "Reset",
  editor_tip_reset_who = "Puts only these options back to their defaults: who gets an arrow, above yourself, above your target. Click twice.",
  editor_tip_reset_look = "Puts only the look back to its defaults: shape, filled, chevrons, arrow size and lift. Click twice.",
  editor_tip_reset_colours = "Gives every party member their class colour again. Click twice.",
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
  party_col_name = "Name",
  party_col_colour = "Colour",
  tip_label_left = "Left-click:",
  tip_label_right = "Right-click:",
  tip_member_left = "choose a colour.",
  tip_member_right = "go back to the class colour.",
  picker_title = "Colour",
  picker_okay = "Okay",
  picker_cancel = "Cancel",
  picker_name_field = "Shade",
  picker_name_hue = "Hue",
  picker_name_hex = "Hex code",
  picker_tip_preset = "Use this class colour.",
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
  option_tip_ShowTarget = "Also show the arrow above your target. It works on players, enemies and, with friendly nameplates on, friendly NPCs.",
  target_status = "Friendly NPC nameplates: %s",
  target_status_on = "on, so friendly NPCs get an arrow.",
  target_status_off = "off in the game settings, so friendly NPCs get none.",
  target_status_unavailable = "not in this game version, so friendly NPCs get none.",
}

-- GH.Loc("key") gives the text (or the key itself when it is missing); GH.Loc("key", a, b) fills in the %s parts.
-- Other languages go in `locales`, with only the keys they change.
local locales = { enUS = enUS }

GroupHighlight.Loc = function(key, ...)
  local strings = locales[GetLocale()] or enUS
  local text = strings[key] or enUS[key] or key
  if select("#", ...) > 0 then
    local ok, result = pcall(string.format, text, ...)
    return ok and result or text
  end
  return text
end

-- Names in the key bindings screen (Options > Keybindings > AddOns).
BINDING_HEADER_GROUPHIGHLIGHT = "GroupHighlight"
BINDING_NAME_GROUPHIGHLIGHT_TOGGLE = GroupHighlight.Loc("binding_toggle")