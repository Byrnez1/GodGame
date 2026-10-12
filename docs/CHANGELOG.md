# Changelog

## v0.3: Things you can lose (2026-10-12)

Rebuilt after the v0.2.1 playtest ("I can kind of get anything I want", "the side panel is far too much to read").

**Choosing one thing costs you another**
- **25 discoveries** (up from 14). Most appear **through the story**: Spear Hunting when a hunter finds a fire-hardened stick, Song and Healing Herbs when Sana chooses a student, Stone Shaping when Teo starts stacking stones.
- **Chances pass.** Some discoveries have a window. Miss it and the moment is gone for good ("The reed beds silted up. The art of weaving was never found.").
- **Prayers show what you're missing.** Many prayers have an option that only works if your people have the right discovery: reed boats in the flood, fever-leaf in the sickness, the wall against raiders, the keepers of stories against Memory's fog. Without the discovery, the option is greyed out with the reason ("Your people would need Reed Boats").
- New exclusive paths: Reed Weaving or Fish Weirs. New dark paths: Carved Faces, the Priesthood, Blood Rites.

**Danger zones for love and fear**
- **Terrified** (too much fear): every generation some of your people flee into the hills.
- **Fearless** (too little fear, from generation 5): the offerings dry up and you lose faith. Young men climb the high rocks to see if anything's there, and a man named Haro says he's the god now.
- **Forsaken** (too little love): fewer children, more bitterness, and your people build an altar to a different spirit.
- Each zone brings its own prayers. You're warned the moment your people slip into one.

**New meters**
- Faith is a glowing orb, and love and fear are animated vessels. Each vessel marks its danger zones and glows red when you're in one. The hatched end of the love vessel shows how much love fear has crowded out. Hover over a vessel to read what it does.

**The Pantheon, in three parts**
- **The Heavens:** the star map, now hidden in **fog of war**. You only see what your people have, what they could have next, and a "?" for anything right beside what you know. Reading the Stars lets you see further. Clicking a star shows a small card, not a wall of text.
- **The Hall:** portraits of the gods you've met (you, the two Voices, the god with golden eyes), with what you know about them, when you first saw them, and how often you've felt their hand in your world.
- **The Chronicle:** your choices, and *what was lost*: chances that passed, paths you closed, and options that were out of reach.

**Story**
- **The woman in the reeds:** she appears in generation 3, as an eerie figure standing in the river at dusk, not as a love interest.
- **More interference from Time and Memory** (8 events, up from 3), aimed at what you remember. Their identities are revealed slowly: *the tall Voice* becomes *the Voice that Counts*, then **Time**.
- **The opening is rewritten** in an older voice. The clock and the modern phrasing are gone.
- Gods moved from the Known tab to the Hall. The Known tab is now people and places.

**Behind the scenes**
- Four test players now (random, kind, wise, cruel). Balance at the time of writing: a purely kind ruler is "fearless" all game and breaks the cycle with love 19% of the time; a "wise" ruler who keeps a little fear does it 63% of the time; a cruel ruler reaches God rank but terror empties the land.
- `tests/trace.gd` prints one whole game step by step, for balancing.


## v0.2.1: Fixes from the first v0.2 playtest (2026-10-12)
- **Fixed:** long cutscene panels pushed the Continue button off-screen (the player got stuck after "So that we cannot hurt each other"). Cutscene text now has more room and scrolls if needed, and the button always stays visible. **Enter** or **Space** also advances cutscenes.
- **New "Known" tab** for people and entities, grouped into Gods and Powers, People, and Places and Things (the Pantheon, your pool, the small room, the flat rock, the old book). The **Journal** tab now holds only the old book, and it appears once the book is found.
- **New Pantheon view** (button at top left): a blue-and-white astral sky where your discoveries are constellations. Bright stars are discoveries your people have, pulsing stars can be granted now, crossed stars are closed paths, and a white spark means the old book answers to it. Click a star for details and to grant it. The side panel shows paths not taken and your full record. This replaces the old Discoveries and Pantheon tabs.


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
