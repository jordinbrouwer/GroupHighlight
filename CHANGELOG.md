# Changelog
All notable changes to this project will be documented in this file.

## [Unreleased](https://github.com/jordinbrouwer/GroupHighlight/compare/1.0.0...main)

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