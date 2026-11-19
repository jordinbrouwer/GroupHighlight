# Changelog
Written by the release pipeline from the commits; see `CONTRIBUTING.md`.

## [Unreleased](https://github.com/jordinbrouwer/GroupHighlight/compare/1.2.0...master)

## [1.2.0 (2026-11-19)](https://github.com/jordinbrouwer/GroupHighlight/releases/tag/1.2.0)

### Added
- A Reset link next to each section title (who gets an arrow, look, party colours) that puts only that section back to its defaults. It asks for a second click to confirm.
- Own font (Expressway) for the editor, colour picker and settings panel.
- Own flat check boxes and a new close cross in the editor title bar.

- Per-section reset, own font and refreshed screenshots. ([76f0267](https://github.com/jordinbrouwer/GroupHighlight/commit/76f02674fbbbb7098d5c7f22141d30bf559a57b1))

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