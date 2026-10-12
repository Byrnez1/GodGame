# Changelog

## v0.1: First playable prototype (2026-10-12)

Text and boxes only. It covers roughly the first act: 12 generations.

**What you can do**
- Answer prayers from your people. Each has 2–3 choices that cost or gain faith, change your population, and shift whether you're worshipped in love or fear. Staying silent is always an option.
- Grant **discoveries** from the decision web (one per generation). Some close other paths for good: River Dwelling vs. the Wandering Path, Burial Facing Sunrise vs. Sky Burial.
- Watch the **journal**: three love-journal pages written in rune glyphs. Words become readable as your people discover the concepts behind them.
- Rise through **ranks** (Whisper → Spirit → Deity → God) as lifetime faith grows. Higher ranks unlock stronger choices and discoveries.
- At Deity rank, discoveries show **glimpses** of possible futures.
- Time and Memory interfere: Memory's fog can make your people forget Song, and its words go dark in the journal until you restore it. Time can steal a generation.
- The **Pantheon** tab records every decision and the paths not taken.
- Four endings, based on how much of her world you rebuilt.

**Under the hood**
- All story text lives in `game/content/` as plain text you can edit.
- Mistakes in story files show on screen with the file and line number.
- `game/tests/run_tests.gd` checks the content and plays 600 automated games (random and focused).

**Balance at v0.1** (from the automated games)
- Random play: mostly the middle ending ("Half a story"), avg 64% of her world rebuilt.
- Focused play: "Her world, almost" in about 28% of games, avg 88%.
