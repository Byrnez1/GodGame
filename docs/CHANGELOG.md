# Changelog

## v0.2: Weight, mystery, and the whole arc (2026-10-12)

Rebuilt after the v0.1 playtest ("choosing felt meaningless", "the plot didn't come through").

**Three currencies that pull against each other**
- **Fear** pays out faith quickly and lingers, but breeds unrest (revolts, doubters, people fleeing) and crowds out love.
- **Love** pays slowly, fades every generation unless tended, calms unrest, grows the population. Ignoring a loving people costs love.
- Top bar shows love and fear as bars and your people's mood. There are no exact numbers to optimize.

**Choices with weight**
- Outcomes are hidden until after you choose, then described in words ("Love grows. Fear spreads. Four are gone.").
- Prayers rewritten as dilemmas: save the children or the winter stores, accept Oren's sacrifice to end the drought, which of Sana's two students to teach.
- Delayed consequences: strangers you drive away come back as raiders; strangers you welcome bring sickness; a blood feud returns.
- **Casting the bones**: some choices roll three bones (3–18) plus a bonus from love, fear, or your rank. You can pour in faith (+1 each, up to 3) before casting. Odds are shown as a feeling ("Likely", "Even", "Hard", "Desperate").

**Story told on screen**
- 15 full-screen cutscenes with pictures: waking in the Pantheon, the two Voices, the rule that gods can't touch, finding the old book, "welcome back", the dream, three inks, the matching handwriting, the harvest, her birth.
- The prototype now covers the **whole arc** in 15 generations, ending in a final choice and an epilogue that reflects how you ruled.
- Story beats are gated by conditions (generation, journal progress, flags), so it stays confusing until about halfway.

**The journal**
- **Your notes**: the god's notes on people (himself, the Voice that Counts, the Voice that Keeps, Sana, Ama, Teo, Oren, Ina, a god with golden eyes, the girl). Entries fill in as you learn things.
- **The old book**: found in generation 3. Margin sketches guide early decisions. "She/her" stay unreadable until the dream, "I/my" until you realize it's your handwriting. Discoveries that match its words are marked.
- Her birth (and the best endings) depend on how much of her world you rebuilt.

**Under the hood**
- Pictures are drawn in code for now. An image at `game/assets/art/<name>.png` replaces the drawn one.
- New content folders: `cutscenes/` and `characters/`. New conditions: `after`, `mood`, `journal`, `rank`, `silence`.
- Tests play 900 games with random, kind, and cruel players.

**Balance at v0.2** (automated players)
- Kind (love, rebuild her world): best ending in ~62% of games, the rest loop again.
- Cruel (fear): ~4× the faith of kind play, but populations collapse into revolt; ~48% end in Silence.
- Random: mostly "Again" (the cycle continues).


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
