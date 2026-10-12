# God Game

A 2D, single-player, narrative decision game for PC (Steam), built in **Godot 4** with GDScript. It's a long-term collaboration: the user leads the vision and story, and Claude writes the code, guides publishing logistics, and helps playtest and iterate.

## Start every session by reading
- `ROADMAP.md`: the current phase and next steps (see "Current status" at the bottom)
- `DESIGN.md`: gameplay design
- `STORY.md`: story bible (true story, order of reveals, open questions, all spoilers)
- `CHANGELOG.md` / `PLAYTEST_NOTES.md` once they exist

## Working with the user
- The user is **new to game development**. Explain engine, Git, and Steam concepts in plain language, one step at a time.
- The user owns the creative direction. Mark Claude's suggestions with 💡 and open questions with ❓ in the docs. Record decisions only after the user agrees.
- Keep costs near $0 until the core loop has been proven fun (see the gates in the roadmap).
- Keep the docs up to date as decisions are made. They're the project's memory between sessions.

## Conventions
- Game content (prayers, revelations, journal pages, words) lives in **data files**, separate from the code, so the user can edit it without programming.
- Commit working states to Git often, with clear messages.
