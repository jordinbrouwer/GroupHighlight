# Contributing

Contributions are welcome and appreciated.

## Development guidelines

- Create feature branches. Do not work directly on `main`.
- Keep each change focused on one feature or fix.
- Keep commits meaningful and history clean.
- Follow the existing code style in this repository.
- Keep changes simple and avoid unnecessary complexity.
- Everything that ships with the addon lives in `src/`: the `.toc`, `Bindings.xml`, the icon, the Lua code in `Core/` and `UI/`, and the arrow textures in `Media/`. The release zip is built from that folder only.
- Keep the `.toc` file list in load order.
- To test in game, link `src/` into your AddOns folder as `GroupHighlight` (for example `Interface/AddOns/GroupHighlight -> <repo>/src`).
- Tooltips and descriptions end with a period. Usage explanations belong in `README.md`, not in the `.toc` or the settings panel.
- Document intentional behavior changes in `README.md`, `CHANGELOG.md`, or this file.

## Run checks locally

Use these before opening a PR (`luacheck` is required for lint, `zip` for the release dry-run):

- Fast structural pass:
  - `bash ./scripts/check.sh quick`
- Full check suite:
  - `bash ./scripts/check.sh all`
- Individual modes:
  - `bash ./scripts/check.sh --help`
