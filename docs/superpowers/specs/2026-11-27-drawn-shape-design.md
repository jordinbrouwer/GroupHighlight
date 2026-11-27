# Drawn shape: draw your own icon in the Preview

## Why
Players want an icon of their own next to the built-in shapes, for Look and per member.

## Goals
- A shape "Drawing" in the shape dropdown (Look and the shape picker).
- You draw it in the Preview box: a 16×16 grid, left-drag draws, right-drag erases, the reset icon of Preview empties it (click twice).
- Look has one drawing; every member with their own look has their own drawing.

## Non-goals
- A library of named drawings (approach B).
- Colours inside a drawing, soft glow, or import/export of drawings.

## Approaches
- **A (picked): the drawing is part of the look.** One more look setting, `Drawing`. Member looks copy it like the
  other settings, so Okay/Cancel, reset and "right-click = back to Look" work as they do now.
- B: a library of named drawings that looks point at. Needs a whole management UI; not asked for.

## Design
- `Drawing` is a string of 64 hex digits: 16 rows of 4 digits, the highest bit is the leftmost cell. A string is
  copied by value, so copying a look never shares a drawing. The default is a down arrow.
- WoW cannot make textures at run time, so a drawing is drawn as stripes: one texture per run of set cells in a row.
  One "shape view" (a frame with a texture, or the stripes for a drawing) is used by the arrows in the world, the
  preview, the Look column in Members and the shape picker header.
- What you draw on: the shape picker's member while it is open, else Look. While the colour picker is open the
  preview only shows the member. With no picker open and Look on Drawing, the preview shows Look's drawing.
- A stroke is shown at once in the preview and saved on mouse-up (one change per stroke, so the arrows in the world
  and the picker's undo see whole strokes).
- The dropdown shows a pencil icon for Drawing. It has no options row.
- Saved data: an invalid `Drawing` goes back to the default (Look) or to Look's drawing (a member).

## Left to the builder
Exact sizes in the preview, the stripe layering, wording of the tooltip.
