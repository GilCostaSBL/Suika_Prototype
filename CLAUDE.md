# CLAUDE.md

Suika Game remake in Godot 4.7.2 (GDScript), with twists. Design lives in `docs/design/GDD.md`.

## Commands
Godot console binary (note: the engine folder itself is named `.exe`):
`D:\GodotProjects\Engine\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`

- Import / validate the project: `<godot> --headless --path . --import`
- Check one script for parse errors: `<godot> --headless --path . --check-only --script res://scripts/<file>.gd`
- Run the smoke test (must pass before every commit): `<godot> --headless --path . -s res://tests/smoke_test.gd`
- Run the game: `<godot> --path .`

## Layout
- `scenes/`: `.tscn` files
- `scripts/`: `.gd` files, `snake_case.gd`, one class per file, `class_name` in PascalCase
- `assets/`: art and audio
- `tests/`: headless `SceneTree` test scripts
- Core loop: `scripts/game.gd` (jar, fruit queue, merges, danger line, coins, abilities), `scripts/fruit.gd` (physics body + drawing), `scripts/fruit_data.gd` (tier table)
- Abilities: `scripts/shake_up.gd` (ultimate; rotates the view and gravity, see docs/decisions/0002), `scripts/ability_panel.gd` + `scripts/fruit_icon.gd` (panel UI)
- Help: `scripts/help_overlay.gd` ("?" button + How to Play screen on CanvasLayer 10, `PROCESS_MODE_ALWAYS`; opening it sets `get_tree().paused`). Its text reads costs from the balance config, so keep wording generic when numbers change.
- Tuning: `config/balance.tres` (`scripts/balance.gd`). Put new tunable numbers here, not in constants.
- `docs/`: Obsidian vault (ignored by Godot via `.gdignore`)

## Screen layout
Viewport 1200×1280 (window opens at 1020×1088). Jar occupies x 20–700 on the left; `UI/AbilityPanel` (x 740–1160) holds ability buttons in `AbilityButtons`.

## Input
Use the input actions from `project.godot` (`move_left`, `move_right`, `drop`, `ability_1..3`, `restart`, `debug_coins`), never raw keycodes. Mouse also aims and drops.
Debug-only actions (like `debug_coins`, F1) must be gated by `OS.is_debug_build()` so release exports ignore them.
Ability buttons must set `focus_mode = FOCUS_NONE`, or Space/arrow keys will activate and navigate the buttons instead of the game.

## Conventions
- GDScript: static typing (`var x: int`, typed function signatures), tabs for indentation, signals for decoupling.
- Trunk-based: small commits straight to `main`. Every commit must leave the project importing without errors.
- Commit messages: imperative mood, `area: summary` (e.g. `merge: award score on fruit merge`).

## Visual checks
Headless runs can't render. To see the game, render frames with a scratch driver script outside the repo:
`<godot> --path . -s <driver>.gd --write-movie <dir>/f.png --fixed-fps 60`, then read the PNGs. Tests that only check "nothing broke" can miss behaviour that looks wrong, so assert the intended effect too.

## Docs duties
- At the end of a working session, add or update `docs/devlog/YYYY-MM-DD.md` from `docs/templates/devlog.md`, including the **Claude Code observations** section.
- Record non-obvious choices as `docs/decisions/NNNN-title.md`.
- Use relative markdown links, not `[[wikilinks]]`.
