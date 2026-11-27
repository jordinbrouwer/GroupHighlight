# Contributing

Contributions are welcome.

## How to contribute

1. Fork the repository and create a branch from `master`.
2. Make one feature or fix per pull request, and follow the existing code style.
3. Run the checks (see below).
4. Open a pull request against `master`. The checks run on it automatically.

## Guidelines

- Write commits as [Conventional Commits](https://www.conventionalcommits.org/): `feat: ...`, `fix: ...`, `docs: ...`. Write the description for players, because it becomes the changelog line. A commit that adds its own lines to `CHANGELOG.md` gets no extra line.
- Don't change version numbers; that happens automatically when a release is made.
- Everything that ships with the addon lives in `src/`: the `.toc`, `Bindings.xml`, the icon, the texts in `Locale/`, the Lua code in `Core/` and `UI/`, and the textures in `Media/`. Keep the `.toc` file list in load order.
- To test in game, link `src/` into your AddOns folder as `GroupHighlight` (for example `Interface/AddOns/GroupHighlight -> <repo>/src`).
- Tooltips and descriptions end with a period. Usage explanations belong in `README.md`, not in the `.toc` or the settings panel.

## Code layout

The load order is the file list in `src/GroupHighlight.toc`.

- `src/Locale/enUS.lua`: all texts the player sees. Use `L("key")` (`GroupHighlight.Loc`); a missing key shows the key itself.
- `src/Core/`: the addon without windows.
  - `Core.lua`: the shared `GroupHighlight` table, the picture paths (`GroupHighlight.Media`), `GetOptions` and `On("EVENT", fn)`, the one place that listens to game events.
  - `Util.lua`: reading units safely (`Safe`, `IsTrue`).
  - `Drawing.lua`: the shape Drawing: 16×16 cells kept as 64 hex digits, and the runs of cells it is drawn with.
  - `Options.lua`: defaults, `SetOption`, resetting a section, and tidying the saved settings once (`Migrate`, `DB_VERSION`).
  - `Color.lua`: the colour of an arrow (the chosen colour, or the class colour).
  - `Plates.lua`: the friendly nameplates the arrows hang on, and the game settings (CVars) they need.
  - `Highlight.lua`: the arrows: which units get one, where it sits and its picture. `CreateShapeView` draws a look (a texture, or the stripes of a drawing) everywhere a shape shows.
  - `Command.lua`: `/gh` and `/grouphighlight`.
- `src/UI/`: the windows. Every file takes its tools from the `UI` table.
  - `Base.lua`: the `UI` table, shared state, colours (`THEME`), sizes (`LAYOUT`), fonts and line helpers.
  - `Widgets.lua`, `Tooltip.lua`, `Toast.lua`, `Controls.lua`, `Scroll.lua`: the building blocks (window frame, header band, switch, button, swatch, tooltip, toasts, box, segment, slider, reset icon, scroll bar).
  - `WhoBox.lua`, `LookBox.lua`, `PreviewBox.lua`, `MembersBox.lua`, `WarningStrip.lua`: one file per box of the editor, and the amber warning band.
  - `Canvas.lua` builds the boxes and fills them from the settings; `Layout.lua` places them in one or two columns and sets the window height.
  - `ColorMath.lua` and `ColorPicker.lua`: the colour picker. `ShapePicker.lua`: the shape picker per party member (it reuses the shape controls of `LookBox.lua`).
  - `Window.lua`: the editor window (frame, header, scroll area, grip, opening and closing). `SettingsPage.lua`: the page under Settings > AddOns.
- `src/Media/`: the addon's own `.tga` pictures.

Rules of thumb:

- Colours and sizes live in `UI/Base.lua`, texts in `Locale/enUS.lua`, picture paths in `Core/Core.lua`.
- A new setting goes in `Core/Options.lua` (its default and the section it belongs to), in the box where it shows (`UI/WhoBox.lua` or `UI/LookBox.lua`, in both the build and the sync function) and in the locale.
- A new shape needs its picture in `Media/` (128×128, 32-bit TGA, white with a soft glow; an `...Outline` version when it can be an outline), an entry in `GH.Media` (`Core/Core.lua`), in `TEXTURES` and `GH.Shapes` (`Core/Highlight.lua`), and `shape_<key>` and `shape_tip_<key>` in the locale. The dropdown in Look picks it up by itself.
- Renamed or removed settings are handled in `Migrate` in `Core/Options.lua`; raise `DB_VERSION` with them.

## Checks

The checks live in [wow-addon-ci](https://github.com/jordinbrouwer/wow-addon-ci). Clone it next to this repository; it needs Python 3 and `luacheck`. From this repository's root:

- `python3 ../wow-addon-ci/scripts/checks/run.py quick`: fast structural checks.
- `python3 ../wow-addon-ci/scripts/checks/run.py`: everything CI runs.

## Releases (maintainers)

A `feat`, `fix` or breaking commit in `src/` on `master` releases automatically: the pipeline writes the changelog, tags the version and publishes it to GitHub and CurseForge. **Actions > Pipeline > Run workflow** on `master` can force a `patch`, `minor` or `major` release.

Descriptions, website and images on GitHub and CurseForge can only be changed on their websites. The pipeline compares them with the code and, when they differ, shows a warning and a summary with what to paste.

Repository setup:

- Secrets `CF_API_TOKEN` and `CF_PROJECT_ID` for the CurseForge upload.
- `github-actions` must be allowed to push to `master` (for the release commit and the README release block).
