# God Game — Design Document

*Living document. Sections marked 💡 are Claude's suggestions and are not decided yet. ❓ marks open questions.*

---

## One-sentence pitch (draft)
You wake as a god with no memory, guiding a primal people through the ages, and you piece together a torn journal of love stories about a mortal woman. Slowly you realize the journal is yours, and that to see her again you must rebuild the world she was born into.

## Fixed decisions
- **2D**, no 3D world
- **Single player**
- **PC / Steam**
- **One continuous playthrough.** No time loops in the gameplay. *(The story has past loops that happened before the game starts. See `STORY.md`.)*
- **Clues come in a single medium:** one journal
- **Faith is your power**, and it unlocks stronger options (it's more than a number on a meter)
- **The villains (Time & Memory) interfere** during the game
- **Finale:** a confrontation with Time and Memory that leads to a **final choice** (break the cycle or keep it), then a **short epilogue**, then the game ends. The consequences aren't played out. *(See `STORY.md`.)*
- 💡 The epilogue text reflects how the player treated their people (prayers answered or ignored, love vs. fear)
- **The Pantheon:** a realm of the gods where their power over each other is limited or doesn't exist
- **The journal is a love journal**, not instructions: a scattered history of the god's story with the woman
- **The journal is intact but written in her people's language**, and words become readable as the civilization discovers the concepts behind them

---

## Story (summary)
*The full story, the order of reveals, and all spoilers are in **`STORY.md`**.*

A god wakes in the Pantheon with no memory and guides a primal people through the ages. An unreadable journal of love stories about a mortal woman slowly becomes readable as his people develop language. He comes to believe his purpose is to bring her back, and later learns that the journal is his, that he loved her, that this isn't the first time, and that the God of Time and the God of Memory have been harvesting that love. This time, he wakes early enough to stop them.

---

## The journal (gameplay rules)

### ✅ The journal is intact, but written in a language that doesn't exist yet
- The journal is **whole**, but **unreadable** at the start of the game
- It's written in **the language of the woman's people**. Because time was reset, that language **hasn't developed yet**. The civilization has to grow into it
- As the civilization **discovers concepts**, the matching **words become readable** throughout the journal. Discover fire, and "fire" can be read on every page. Develop music, and "song" appears
- Early on, the people's language is so primitive that the journal is almost entirely unreadable, so it gives **no instructions** at first. As the language grows, more of each page becomes readable, and the pages start pointing the god down the right paths
- 💡 *Why he wrote in her language:* he wrote in her tongue because she taught it to him, or because the journal was written *to* her. Memory erased his knowledge of it, and Time erased the language from the world
- 💡 *The reveal moment:* the god's own name could be the last word to become readable

**What a page looks like over time:**
> Early: `𐊀𐊁𐊂 𐊃𐊄 𐊅𐊆𐊇 𐊈𐊉 𐊊𐊋 𐊌𐊍𐊎𐊏`
> After *Fire*: `𐊀𐊁𐊂 𐊃𐊄 𐊅𐊆𐊇 𐊈𐊉 **fire** 𐊌𐊍𐊎𐊏`
> After *Music*, *Weaving*, *River*: `Her mother **sang** 𐊅𐊆𐊇 by the **fire**, **weaving** 𐊌𐊍 from the **river**`
> Fully readable: `Her mother sang the old prayers by the fire, weaving reeds from the river.`

💡 **Design considerations:**
- **Chicken-and-egg problem:** the journal can only show words for concepts you've *already* discovered, so how does it guide you toward ones you haven't? 💡 Options:
  - **Context clues:** partly readable sentences hint at the missing word (*"we built the [???] from stone so the flood could not reach it"*)
  - **Sketches:** the god drew small pictures in the margins, and these are readable even when the words aren't
  - **Recurring symbols:** unknown words always use the same glyphs, so players can notice patterns and form guesses (like *Chants of Sennaar*). Optionally, players can write their own guesses next to unknown words
- **Faithfulness to her world:** 💡 a word could become readable only if your people develop that concept *the way her people did*. If your people worship the sky instead of the river, "river-prayer" stays unreadable. How much of the journal you can read then measures how close you are to rebuilding her world. It's a progress bar that's also a story
- **Pages in a scrambled order:** the pages can still be out of order or undated, so the player pieces together the timeline of the love story as more becomes readable
- **Villains and the journal:** 💡 the villains work against the journal: words go dark again, rituals are forgotten, false memories are planted. See `STORY.md` for why they fight his *awareness* rather than the love itself

---

## Gameplay

### Core idea
Decisions over time, organized as a **connected web of choices** (like a tech tree). Choosing one path unlocks new decisions and closes off others. Decisions affect the population.

### Faith as power (more than a meter)
Faith is what your people's belief gives you, and it's both a **currency** and a **level of power**.

💡 Ideas:
- **Divine tiers:** as total faith grows, you rise through ranks (e.g. *Whisper → Spirit → Deity → God*). Each tier unlocks stronger kinds of decisions and miracles, and more journal pages
- **Faith is spent** on miracles and decisions, so the player is always choosing between spending power now and saving it
- **How they worship you matters:** a god who is *feared* gains different powers (storms, punishment) than a god who is *loved* (harvests, healing). Your choices shape what kind of god you become, which gives the final confrontation different flavors
- **Faith can be lost:** ignore prayers or let disaster strike and belief fades. The villains can target it directly

### Villain interference (💡 ideas)
*Story logic:* inside the Pantheon, Time and Memory **can't touch the protagonist directly**, so they attack **through the mortal world** instead: his people, his followers, and the faith that gives him power.
- **Memory:** erases a skill your people learned (a node in the web goes dark), makes the elders forget a ritual, blanks out a journal page
- **Time:** an unnaturally long winter, a generation skipped in an instant, ages a key character early, an event that suddenly comes too soon
- Early on, these just look like **bad luck or omens**. Later, the player recognizes the villains' signature
- 💡 **Two kinds of interference** (see `STORY.md`): **herding** (events that secretly push him toward her, because the villains need the love) and **suppressing** (attacks on the journal, the language, and his awareness). After the final twist, the player sees the "attacks" in a new light

### The dark path
The player can choose darker paths (rule through fear, treat her as a tool or a sacrifice), but the game **gently nudges them back toward the lighter path**:
- 💡 The villains' herding pushes back against dark choices
- 💡 A fear-based culture develops different words, so the journal stays unreadable
- 💡 Fear-faith gives quick power but can't combine with love
- 💡 Fully committing to the dark path leads to the **"loop continues"** ending: everything resets, and the game ends where it began

### Moment-to-moment format (❓ in progress)
See "Play format options" below.

---

## Play format options (💡 for discussion)

Each option describes what a minute of play feels like. The options can be combined.

### Option 1: Prayers & Answers
Your people pray to you, and each prayer is a card: *"The hunters return empty-handed. Old Kesh kneels at the fire and asks for a sign."* You choose an answer. Big answers cost faith, and silence is an answer too. Answers have consequences, unlock future prayers, and push the civilization down paths.
- **Feel:** quick, personal, story-rich (like *Reigns*)
- **Strength:** every decision is a little story moment, so it's easy to work in clues and villains
- **Risk:** without a bigger structure, it can feel random

### Option 2: Generations (turn-based eras)
Each turn is a **generation** (or a season). Each turn you:
1. Collect faith from your worshippers
2. Answer 1–3 prayers/events (Option 1's cards)
3. Optionally grant a **Revelation** from the decision web (fire, farming, burial rites, writing…). It's permanent, opens new branches, and closes others
4. End the turn: time passes, the village changes, and a journal page may turn up

- **Feel:** thoughtful and strategic (like *Frostpunk* or *Civilization*, but smaller)
- **Strength:** clear structure, easy to build and balance, and the decision web has a natural home
- **Risk:** needs good pacing so turns don't feel repetitive

### Option 3: Speaking Through Prophets
You can't command directly. You speak through **visions sent to chosen mortals**: a shaman, a chief, a dreaming child. They **interpret** your visions, sometimes wrongly. Characters age, die, and pass on their role.
- **Feel:** mysterious and indirect, with characters you get attached to
- **Strength:** fits a god of a primal people, and makes the outcome of a choice uncertain in an interesting way
- **Risk:** more writing, and a misinterpretation can feel unfair if it's not handled carefully

### Option 4: The Matchmaker Across Generations
Steering toward a *specific birth* means certain **bloodlines** have to survive, move, and eventually meet. You follow a few family lines across generations, and the journal hints at which ones matter (*"the river-born and the mountain-born must share a fire"*).
- **Feel:** a long, slow puzzle with an emotional payoff
- **Strength:** ties directly to the story's goal, and gives every decision a hidden second purpose
- **Risk:** family tracking adds complexity, so keep it to a few lines

### Option 5: Living Village (real-time)
A small 2D village of people walking around and living their lives in real time, where you trigger miracles directly (*WorldBox / Black & White*).
- **Feel:** toy-like and alive
- **Risk:** by far the hardest to build. 💡 Not recommended for the first prototype, though some of this "aliveness" can be added later as visuals on top of another format

### 💡 Recommended combination
**Option 2 (Generations) as the structure**, with **Option 1's prayer cards** as the events, **Option 3's prophets** as recurring characters who deliver the cards, and **Option 4's bloodlines** as the hidden goal the journal points toward. The village is shown as a 2D scene that visibly changes over the eras but isn't simulated in real time.

**A sample turn:**
> *Generation 7. Faith +12.* The village scene shows huts near a river and smoke from a new fire pit.
> **Prayer:** "The river has flooded twice this season. Sana the shaman asks what we have done wrong."
> → *Calm the waters* (8 faith) · *Send a dream of high ground* (free, opens the "Migration" branch) · *Remain silent* (faith –3, fear +)
> **Revelation available:** *Burial Rites*, which unlocks ancestor worship and gives more faith over time but blocks the "Nomad" path.
> **Omen:** "The elders can't remember the words to the harvest song." *(Memory at work: your Harvest blessing weakens.)*
> **End turn** → a hunter finds a torn page in a cave: *"...she will not come where the river is forgotten..."*

---

## Reference games
- **Reigns**: decisions as cards, with a hidden overarching mystery
- **Frostpunk**: a law book of branching societal choices with moral weight
- **Crusader Kings**: dynasties and bloodlines across generations
- **Inscryption / Return of the Obra Dinn**: a hidden story that reframes everything, and piecing together fragments
- **Chants of Sennaar / Heaven's Vault**: deciphering an unknown language word by word (*very relevant to the journal*)
- **WorldBox / Black & White**: being a god over little people

---

## 💡 Production note: data-driven content
Branching games need a *lot* of written content (decisions, events, clues). We'll put that content in **simple data files**, a structured list you can edit like a spreadsheet, and keep it separate from the code. You can write and tweak decisions and clues without touching code, and Claude builds the system that reads them.

---

## First prototype (Phase 1 target)
Text and boxes only, no art:
- ~10 generations (turns)
- ~15–20 Revelations in a small decision web
- ~10 prayer cards
- Faith with 2–3 divine tiers
- 1–2 villain interference events
- 4–5 journal pages, written in glyphs, where words become readable as Revelations are discovered
- One "success" condition (the specific future) and one "failure" condition

**Questions to answer:**
1. Do the choices feel meaningful and tense, and does the player want to play "just one more generation"?
2. Is it **satisfying** when a new word appears in the journal? Does it make the player want to discover the next concept?

### ✅ Prototype v0.1 rules (as built, 2026-10-12)
*All numbers live in `game/content/settings.txt` and the content files, so they can be tuned without code.*
- **12 generations.** Each one: worship gives faith (1 per 15 people, plus discovery bonuses), the population grows (4% plus discovery bonuses), and 2 prayers arrive (prayers written for an exact generation always appear).
- **Prayers** have 2–3 choices. Choices can cost faith, gain faith, change people/love/fear, set story flags, grant or forget discoveries, or need a minimum rank. Silence is always an option and is counted.
- **Discoveries** (the decision web): one per generation, paid with faith, gated by prerequisites and rank. Some exclude others permanently ("paths not taken"). Prayers can also grant them, usually for less.
- **Ranks** come from *lifetime* faith earned: Whisper 0, Spirit 20, Deity 60, God 120. At Deity, discoveries show **glimpses** of the future.
- **Journal:** words are tied to discoveries in `journal/words.txt`. Unlisted words unlock with First Words. Unknown words show as stable rune glyphs (same word, same glyphs).
- **Memory** can make the people forget a discovery (its words go dark again). Restoring it costs half.
- **Endings** are based on the share of the journal's *key words* (words listed in words.txt) that are readable: ≥90% "Her world, almost", ≥50% "Half a story", otherwise "A stranger's world", or "Silence" if everyone dies.
- The ending screen reports prayers answered, prayers left in silence, and love vs. fear, as groundwork for the personal epilogue.

---

## Art style & interface (❓ in progress)
Look book, round one: https://claude.ai/artifact/EKpLub7YHY7z4d2sHFhSLu (copy saved at `docs/art/look-book.html`)
- Five directions mocked up: Ink & Parchment, Ochre & Charcoal, Celestial Pantheon, Silhouette & Sky, Flat Cards
- Three layouts: A. Heaven and Earth, B. The Open Book, C. The Altar
- 💡 Claude's pick: **Heaven and Earth.** The Pantheon is drawn in the Celestial style, the mortal world in Silhouette & Sky, and the journal in Ink & Parchment, using layout A

### ✅ Decided (user feedback on round one)
- **Two main views, not one:**
  - **The Pantheon view** (Celestial style): a record of decisions made so far, their effects, and **paths that were missed**
  - **The World view** (Silhouette & Sky as a starting point): the actual people of the civilization, **moving and interacting**. It should feel **alive** and like a real civilization with real consequences, not something abstract. It doesn't need much detail, but it needs movement, and the society should visibly develop over time
- **New mechanic idea (user):** as faith grows, the god can **glimpse possible future outcomes** in the Pantheon view
- **❌ No card-game feel.** Flat Cards rejected. Prayers should **not** look like physical cards (*Slay the Spire* or *Reigns* style). The game should feel as in-depth as possible. 💡 Prayers could appear inside the world itself, e.g. the camera moves toward the person praying and their words appear in the scene
- **Prototype note:** the "prayer cards" in the first prototype are just a placeholder name for prayer events

### Living world scenes, round two
Animated scene sketches: https://claude.ai/artifact/CUWWhm4T3xu1gSvL94MzYN (copy at `docs/art/living-world.html`). Scenes: The Flood (silhouette side view), Fire & Song (night close-up), The Long Walk (overhead map), Generations (pixel time-lapse), Memory's Fog (villain interference). **User feedback:** Memory's Fog, Fire & Song and The Flood are closest to the game in the user's head. ❌ Pixel art (Generations) rejected. ❌ Overhead map (The Long Walk) not working for them. Scenes mostly play out the player's choices with little interaction, so art is parked for now in favor of mechanics and a playable prototype.

---

## Prototype v0.2 plan (after the user's v0.1 playtest, 2026-10-12)

### v0.1 playtest feedback (user)
- The game works, but choices felt **meaningless** with no weight; it was boring overall
- There was **no incentive to be mean**, and decisions were too obvious (good vs. evil)
- Wants **love, fear, and faith as three interacting currencies**
- **Don't show outcomes while choosing**, so players can't min-max faith
- Wants dilemmas between **two good things or two bad things**
- The **plot didn't come through**, even for the person who wrote it. Wants **cutscenes** (text + pictures) triggered under different conditions
- More **world-building**: the god's memory loss, the Pantheon, his confusion, and his understanding that he's been tasked with ruling these people
- The journal's words **didn't lead decisions**
- **Too much story revealed at the start.** It should be completely confusing until about halfway

### v0.2 changes
**Three currencies that pull against each other**
- **Faith** is power you spend. Every generation it comes from belief, and belief has two sources:
- **Fear** produces faith *fast* (twice as efficiently as love) and never fades. But fear breeds **unrest**, which leads to revolts, heretics, and people fleeing. Fear also crowds out love: love can never go above 100 minus fear.
- **Love** produces faith *slowly* and **fades every generation** unless you tend it by answering prayers. A loving people expect you to answer, so **silence costs love**. Love calms unrest and helps the population grow.
- The temptation: her world is expensive, and fear is the quickest way to afford it.

**Choices that hide their outcomes**
- A choice shows only its words, and a faith cost if it's a miracle. Effects are revealed afterward in plain language ("Love grows. Fear spreads. Four died.")
- Some choices are **gambles** with a chance to go wrong
- Many choices have **delayed consequences**: they set a flag that brings a new event generations later (strangers return as raiders, a plague, revenge)
- Prayers are written as **dilemmas**: two goods, two bads, or a price either way

**Story told through cutscenes, gated by conditions**
- Full-screen cutscenes with pictures (drawn in code for now; real art can replace them later by dropping an image into `assets/art/`)
- The prototype now covers the **whole arc, compressed into 15 generations**: waking and confusion → finding the journal → halfway dream of her → wrong theories → the journal is his → loops and the harvest → her birth (only if her world was rebuilt) → final choice → epilogue
- **Pantheon world-building:** the hall of gods, the pool he watches his people through, the rule that gods can't touch each other there, other gods who say "welcome back", and two unnamed Voices (Time and Memory)
- The Pantheon tab gets a **"What you know"** list that grows as the god learns things

**A journal that confuses first and guides later**
- The journal isn't found until generation 3, and pages unlock over time
- "She/her" only become readable after the dream (around the halfway point), and "I/my" only after he realizes the journal is his. Before that, the pages read as unsettling fragments
- **Margin sketches** are visible from the start and hint at what to build (reeds in water, a grave facing sunrise)
- Discoveries that match words in the journal are marked: *"Something in the journal answers to this"*
- Her birth (and the ending) depends on how much of her world was rebuilt

### ✅ Added during the v0.2 build (user requests)
- **Casting the bones** (user: "like rolling a d20 in D&D, with bonuses from faith, love, and fear"): three bones (3–18, a bell curve so bonuses matter) + a bonus from love, fear, or rank, depending on the act. Before casting, the player can pour in faith (+1 each). Odds are shown as a feeling, never as a number.
- **People in the journal** (user: "characterize Time, Memory, citizens of note, and yourself, slowly recording what we learn"): the Journal tab has **Your notes** (people, including the god himself) and **The old book**. Notes unlock through conditions and stay learned.

### ✅ v0.2 playtest feedback (user, 2026-10-12)
- Got stuck at the second cutscene (a bug: the button was pushed off-screen). Fixed in v0.2.1.
- **Visuals are good.**
- Wants a **separate tab for known entities and people**, so the journal entries being transcribed aren't cluttered. Done: the **Known** tab (gods, people, places and things). The **Journal** tab is now only the old book.
- The **Pantheon screen should look like the blue-and-white astral view** from the look book. Done: the Pantheon is now a full view, with discoveries drawn as constellations on a blue-white starfield.

### ✅ v0.2.1 playtest feedback (user, 2026-10-12) → v0.3
- "It still feels like I can get anything I want. It's not clear I'm losing out on anything when I choose the good options." → discoveries appear through the story and some expire; prayers have options locked behind discoveries, shown greyed out; the Chronicle lists what was lost. Purely kind play now pays a price (see danger zones).
- "The woman needs to be introduced sooner, but not obviously as a love interest." → *the woman in the reeds*, generation 3.
- "More interference from Time and Memory, and slowly reveal their identities. Calling the time god a clock in the beginning is bad." → 8 interference events; names revealed in stages (see `STORY.md`).
- "Language in the first interaction felt modern." → the opening is rewritten.
- "The Pantheon should be where we have information on the gods, with pictures and data. The side panels are far too much to read." → the Pantheon now has three parts: the Heavens (sky plus a small card), the Hall (god portraits), and the Chronicle.
- "More visually pleasing meters for love, fear, and faith." → animated vessels with danger zones.
- "There should be ramifications for fear too high or too low, and love too low." → danger zones: terrified, fearless, forsaken.
- "Less obvious paths past what you're currently picking: a fog of war, and more options. Most should unlock during the story, and I should feel the impact of not choosing certain techs." → fog of war, 25 discoveries, story unlocks, expiring windows, missed options.
