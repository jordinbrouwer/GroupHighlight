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
  editor_tip_reset_look = "Puts only the look back to its defaults: shape, filled, chevrons, shape size and lift. Click twice.",
  editor_tip_reset_members = "Gives every party member their class colour and the shape from Look again. Click twice.",
  editor_section_who = "Who gets an arrow",
  shape_triangle = "Triangle",
  shape_chevron = "Chevron",
  shape_tip_triangle = "A triangle pointing down.",
  shape_tip_chevron = "One, two or three chevrons pointing down.",
  shape_diamond = "Diamond",
  shape_tip_diamond = "A diamond standing on its point.",
  shape_circle = "Circle",
  shape_tip_circle = "A circle. Turn Filled off for a ring.",
  shape_star = "Star",
  shape_tip_star = "A five-pointed star.",
  shape_pin = "Pin",
  shape_tip_pin = "A map pin pointing down. Turn Filled off for a round hole in it.",
  shape_shield = "Shield",
  shape_tip_shield = "A shield, like the tank icon.",
  shape_sword = "Sword",
  shape_tip_sword = "A sword pointing down, like the damage icon.",
  shape_plus = "Plus",
  shape_tip_plus = "A plus, like the healer icon.",
  shape_hint_chevron = "1–3",   -- quiet text right of Chevron in the dropdown: it is the only shape with a count
  option_Filled = "Filled",
  option_tip_Filled = "Fill the shape. Turn this off to draw only its outline.",
  option_ChevronCount = "Chevrons",
  option_tip_ChevronCount = "How many chevrons: one, two or three.",
  option_ChevronFade = "Fade out",
  option_tip_ChevronFade = "Make each extra chevron fainter than the one below it. Turn this off to draw them all equally bright.",
  chevron_count_1 = "One chevron.",
  chevron_count_2 = "Two chevrons.",
  chevron_count_3 = "Three chevrons.",
  editor_section_look = "Look",
  editor_section_preview = "Preview",
  editor_section_members = "Members",
  editor_size = "Shape size",
  editor_lift = "Lift above name",
  editor_tip_size = "Size of the shape in pixels.",
  editor_tip_lift = "How high the arrow sits, in pixels. 1 is the lowest.",
  editor_no_members = "No party members to show.",
  members_col_name = "Name",
  members_col_look = "Look",
  members_col_colour = "Colour",
  tip_label_left = "Left-click:",
  tip_label_right = "Right-click:",
  tip_member_left = "choose a colour.",
  tip_member_right = "go back to the class colour.",
  tip_shape_left = "choose a shape.",
  tip_shape_right = "go back to the shape from Look.",
  shape_picker_title = "Shape",
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