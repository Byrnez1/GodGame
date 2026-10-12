# God Game

A 2D, single-player, narrative decision game for PC (Steam), built in **Godot 4** with GDScript. It's a long-term collaboration: the user leads the vision and story, and Claude writes the code, guides publishing logistics, and helps playtest and iterate.

## Start every session by reading
- `docs/ROADMAP.md`: the current phase and next steps (see "Current status" at the bottom)
- `docs/DESIGN.md`: gameplay design
- `docs/STORY.md`: story bible (true story, order of reveals, open questions, all spoilers)
- `docs/CHANGELOG.md` / `docs/PLAYTEST_NOTES.md` once they exist

## Folder layout (keep it organized; the user cares about this)
- `docs/`: planning documents (Markdown)
- `game/`: the Godot project (open `game/project.godot`)
  - `game/content/`: **all player-facing story text**, as plain `.txt` files the user edits directly. Never hard-code story text in scripts or scenes
  - `game/scenes/`, `game/scripts/`: screens and code (Claude's area)
  - `game/assets/`: art, fonts, audio
- `README.md` at the root is the user's map of the project. Update it if the layout changes.

## Working with the user
- The user is **new to game development**. Explain engine, Git, and Steam concepts in plain language, one step at a time.
- The user owns the creative direction. Mark Claude's suggestions with 💡 and open questions with ❓ in the docs. Record decisions only after the user agrees.
- Keep costs near $0 until the core loop has been proven fun (see the gates in the roadmap).
- Keep the docs up to date as decisions are made. They're the project's memory between sessions.

## Conventions
- Content files must be forgiving and readable in Notepad: no JSON, no code syntax. The game's loader should report mistakes in plain language (file, line, what's wrong).
- `.txt` content isn't imported by Godot, so the Windows export preset must include `content/*.txt` in its non-resource include filter.
- Git: GitHub remote `Byrnez1/GodGame` (private), branch `main`. Commit working states often, with clear messages.
- Godot 4.7.2 is installed via winget at `%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\` (use `Godot_v4.7.2-stable_win64_console.exe` for headless runs).

## Testing
- Run `godot --headless --path game --script res://tests/run_tests.gd` (use the `_console.exe` Godot) after any rules or content change. It validates content and plays 900 games with random, kind, and cruel players.
- Screenshots: `godot --path game --write-movie <out.png> --fixed-fps 10 --quit-after 12 -- --preview=MODE` where MODE is main, cast, known, pantheon, or scene:<cutscene_id>:<panel>. No flag shows the opening cutscene. Check long cutscene panels this way after writing them.
