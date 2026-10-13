# Plan: a longer game where your choices steer the story

*Status: **draft for the user to approve.** Nothing here is built yet.*
*Map of the idea: `docs/mockups/story-web.html` (tab "A story with paths").*

## The goal
1. **Longer:** 36 generations in 6 eras (today: 15 generations), so investments in love, fear, and faith have time to grow into something.
2. **Your people become something:** love, fear, and silence add up, era by era, into a culture that changes what happens and what's possible.
3. **The player steers the story:** four turning points set paths that later cutscenes, prayers, Time and Memory, and the endings all respond to.
4. **Choices come back:** almost every choice should matter again later. Today, 36 of 63 story flags are never checked again.

## How the influence of choices works

Choices will influence the game on four layers, from fastest to slowest:

| Layer | What it is | How long it lasts | Example |
|---|---|---|---|
| **Right away** | Love, fear, faith, people (as today) | A few generations (love fades, fear lingers) | Saving the children: love grows, the stores are lost |
| **Echoes** | A choice sets a flag, and a prayer or scene brings it back later | 3 to 15 generations | Strangers you drove off return as raiders. Oren's grandchildren remember he was spared |
| **Culture** | Your love and fear over a whole era decide who your people become | Eras (can shift slowly) | Six generations of fear: a people of the knife |
| **Paths** | The answer at a turning point | The rest of the game | You told the Voices about the small room: they "help" you from then on |

### Culture (new)
- At the end of each era, the game looks at the **average love and fear over that era**, and how often you were silent.
  - Love clearly ahead: **a singing people**
  - Fear ahead: **a people of the knife**
  - Neither, or lots of silence: **a people who doubt**
- **Momentum:** the previous culture counts for part of the score, so a culture can shift, but slowly. One kind generation doesn't undo six cruel ones.
- **Each culture changes the rules a little** (draft numbers, to tune by testing):
  - Singing: love fades more slowly (20% → 12% per generation).
  - Knife: fear pays more faith, but the terror line comes sooner.
  - Doubt: less faith, but no danger-zone penalties for being fearless.
- **Each culture has its own prayers:** festivals and weddings, or punishments and offerings, or rival altars and doubters.
- **Institutions act on their own.** From era 4, temples and priesthoods you built make choices without you, for good or bad, depending on the culture.
- **Legacy for the finale:** the final cast draws on your **lifetime** love or fear, not just the last few prayers. Thirty generations of love is a strong bond.

### Paths (the four turning points)
1. **Era 1, gen 5. The Voices ask what you remember.** Trust them, hide from them, or defy them. This sets how Time and Memory treat you all game: guiding you, hunting what you know, or striking at your people.
2. **Era 2, gen 12. Why must you find her?** A sacrifice, a prophecy, or an acolyte. Your culture makes one path easier. Choosing against it costs faith and causes unrest for a generation or two.
3. **Era 4, gen 24. What do you do with the truth?** Tell your people, keep it from them, bargain, or wake another god.
4. **Era 6, gens 34 to 36. The finale.** Options appear based on your paths and culture. The shooting-star throw decides whether the attempt holds.

### Quiet generations (new)
A longer game shouldn't mean more clicking. When nothing pressing is waiting, you can **let several generations pass at once**. The game then shows a short summary of what your investments did, for example: *"Three generations pass. Your temple grows. Fear of you has become law. 40 more people."*

## What changes in the engine
All of it stays readable and editable in the `content/` text files.

1. **Eras and length:**
   - `generations: 36` and `era_length: 6` in `settings.txt`.
   - A new condition, `era: 3` or `era: 2+`, for any prayer or cutscene.
   - An era card when each era begins: "Era 2: Roots", with your people's new culture.
2. **Culture tracking:**
   - Love and fear are recorded every generation, and the culture is set at each era's end.
   - A new condition, `culture: singing / knife / doubt`.
   - Culture rule changes in `settings.txt`.
3. **Legacy:** lifetime love and fear are tracked and used for the final cast bonus.
4. **Paths:** nothing new is needed. Turning-point prayers set flags (`path_trust`, `path_sacrifice`…), and content checks them with `requires` and `blocks`, as today.
5. **Quiet generations:** a "Let several generations pass" button, which stops early if something important is due, plus the summary screen.
6. **Story health check:** the test run reports any story flag that nothing ever checks again, and the ending share for each path and culture. The story map is rebuilt from the files after each phase.

## What changes in the content (the biggest part)
I draft everything, and you rewrite whatever you like. It's your story.

| | Today | Planned |
|---|---|---|
| Prayers | 48 | about 90 to 100: existing ones spread across the eras, plus culture prayers (~18), path prayers (~35), and echoes (~15) |
| Cutscenes | 16 | about 30: versions per path, such as three ways to hear the truth about the harvest |
| Endings | 6 | 8, adding **The Keeper** and **The Waking** |
| Epilogue lines | 6 | about 15, covering culture, path, and echoes |
| Choices that are never brought up again | 36 of 63 flags | under 10 |

## Build order
Each phase ends with a playable game, passing tests, and a playtest by you before the next phase starts.

1. **Foundations.** Eras, 36 generations, culture tracking, legacy, quiet generations. Today's story is stretched across the longer game, so you can feel the pacing and the culture forming before any new story is written. *I'll rebalance with the test players so a game takes about 60 to 90 minutes.*
2. **Eras 1 to 3.** Turning points 1 and 2, the six paths, culture prayers, and Time and Memory's responses for each stance.
3. **Eras 4 to 6.** The book beats in their path versions, turning point 3, the finale options, and the two new endings.
4. **Echoes.** Wire up the choices that are never brought up again, using the map's list.
5. **The shooting star.** The Throw replaces casting the bones, and the Reading is used for granting discoveries.

## Decisions for you before we start
1. Is **36 generations** the right length? (The other option I considered is 30, in 5 eras of 6.)
2. **Culture names:** a singing people, a people of the knife, a people who doubt. Keep them, or rename them?
3. Can the player **leave a path** once chosen (at a cost), or are paths locked in?
4. Are the four turning points and their options right? (See the map.)
5. Do you want the two new endings, The Keeper and The Waking?
