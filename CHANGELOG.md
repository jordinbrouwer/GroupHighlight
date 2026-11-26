# Changelog
Written by the release pipeline from the commits; see `CONTRIBUTING.md`.

## [Unreleased](https://github.com/jordinbrouwer/GroupHighlight/compare/1.3.1...master)

## [1.3.1 (2026-11-26)](https://github.com/jordinbrouwer/GroupHighlight/releases/tag/1.3.1)

### Fixed
- Header text stays inside the window and ends with. ([18aad77](https://github.com/jordinbrouwer/GroupHighlight/commit/18aad77359d1dbb0c282031e0ff250b429854082))

## [1.3.0 (2026-11-25)](https://github.com/jordinbrouwer/GroupHighlight/releases/tag/1.3.0)

### Added
- The editor can be resized: drag the grip in the bottom right corner to change its width and height, right-click it to go back to the default size. Wide, the sections sit in two columns; narrow, in one column with a thin scroll bar.
- In a raid, Party colours lists everyone in the raid. With more than five names the list scrolls.
- A hint "or type /gh" under the button on the settings page.

### Changed
- New look for the editor, the colour picker and the settings page in GroupHighlight's own gold and grey: a header band with the logo, the name and a short description (drag it to move the window), every section (Who gets an arrow, Look, Preview, Party colours) in its own box, switches instead of check boxes, flat buttons, the addon's own tooltips and a thin outline on all texts.
- The key binding now shows a toast at the top of the screen ("Highlight: Off.") instead of a line in the chat. Click a toast to close it.
- The amber warning about dungeons and raids moved from under the title bar to the bottom of the editor.
- Reset next to each section title is now only an icon, without the word. The first click shows "Click again" in red.
- Party colours is a table with Name and Colour columns.
- The colour picker is called "Colour" and sits next to the editor at the height of the Party colours box.
- Shorter tooltips, for example on Also above your target.
- The code is split into smaller files; your settings are kept.

### Removed
- The Expressway font. The windows use the game's own fonts again.

## [1.2.0 (2026-11-19)](https://github.com/jordinbrouwer/GroupHighlight/releases/tag/1.2.0)

### Added
- A Reset link next to each section title (who gets an arrow, look, party colours) that puts only that section back to its defaults. It asks for a second click to confirm.
- Own font (Expressway) for the editor, colour picker and settings panel.
- Own flat check boxes and a new close cross in the editor title bar.

### Changed
- Friendly nameplates are no longer turned on inside dungeons, raids and scenarios, where arrows above friendly players can't be shown anyway. Your own setting comes back there.
- Lines and borders are now exactly one pixel thick at every UI scale.

### Removed
- The Defaults and Close buttons at the bottom of the editor.
- Dragging the arrow above yourself; it now always sits at its fixed spot.

## [1.1.0 (2026-11-17)](https://github.com/jordinbrouwer/GroupHighlight/releases/tag/1.1.0)

### Added
- `shell` (ShellCheck) and `smoke` checks. The `toc` check now also catches Lua files missing from the `.toc` and duplicate entries.

### Changed
- The editor title bar no longer shows the version number.
- CI runs every check as its own job, picked up automatically from `scripts/check/`.
- Tag releases run all checks before packaging and publishing.

## [1.0.0 (2026-11-11)](https://github.com/jordinbrouwer/GroupHighlight/releases/tag/1.0.0)

### Added
- Arrow above party and raid members, drawn on their nameplates.
- Modes: Off, Party and Party + Raid. The arrow above yourself is a separate option.
- Arrow shapes: a filled or outline triangle, or one to three chevrons that can fade out or stay equally bright.
- Class colors by default, with a colour per player that is remembered by name and realm.
- Own colour picker with a colour field, a hue bar, a preset for every class and a hex field.
- Arrow size and lift above the name.
- Optional arrow above your current target, for units with a nameplate. This never changes your nameplate settings.
- Editor window opened with `/gh`: movable, with a live preview and changes that show in the game world immediately.
- Amber strip under the editor title bar that says arrows don't work above friendly players inside dungeons and raids.
- The arrow above yourself can be dragged into place while the editor is open.
- Key binding to turn the arrows off and back on to the previous mode.
- Settings panel under Options > AddOns with a button that opens the editor.
- Addon icon.
- CD workflow that packages tagged releases, creates a GitHub release and publishes to CurseForge (requires the `CF_API_TOKEN` and `CF_PROJECT_ID` secrets).