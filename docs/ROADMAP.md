# God Game — Roadmap

A living plan from "ideas only" to "published on Steam." We update this as we go.

**Guiding rule:** spend $0 and keep everything ugly until the game is proven fun. Polish only what's already working.

---

## How we work together

| You | Claude |
|---|---|
| Vision, story, design calls | Writes and explains the code |
| Run the game, playtest, report what feels wrong | Debugs, refactors, proposes mechanics |
| Recruit outside playtesters | Plans and reviews scope, keeps docs up to date |
| Final say on taste and direction | Guides you through Steam and business logistics |

**Continuity:** Claude doesn't remember past conversations on its own. The project's files are what carry the context from one session to the next:
- `ROADMAP.md`: this file, showing the current phase and next steps
- `DESIGN.md`: the game design document (mechanics, rules)
- `STORY.md`: the story bible (true story, order of reveals, characters, all spoilers)
- `CHANGELOG.md`: what changed in each version and why
- `PLAYTEST_NOTES.md`: feedback from each playtest session

Start each work session with something like *"read the roadmap and changelog, then let's continue."*

---

## Tooling (all free)

- **Engine: Godot 4.** It's free and open source, takes no royalties, and is good at both 2D and 3D. Its scripts and scene files are plain text, so Claude can read and write them directly, which matters a lot for how we work. It exports to Windows and has Steam integration through the free GodotSteam plugin.
- **Version control: Git + GitHub (private repo).** Every working version is saved, nothing is ever truly lost, and the repo doubles as an offsite backup.
- **Placeholder art and sound:** colored shapes, Kenney.nl assets (free, CC0), and the free asset packs on itch.io.
- **Project location:** `C:\Dev\GodGame` (moved out of OneDrive to avoid sync conflicts with Git). GitHub is the backup.

---

## Phases

### Phase 0: Setup and Design Foundations (Week 1–2) · $0
- [x] Git installed (already on this PC); local repo created in `C:\Dev\GodGame`
- [x] Install Godot 4 (4.7.2, installed via winget to `%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\`)
- [x] GitHub account (Byrnez1) + private repo `Byrnez1/GodGame`, first push done
- [x] Write the one-page pitch in `DESIGN.md`:
  - The game in one sentence
  - **Core loop:** what the player does every 30 seconds, every 10 minutes, and every session
  - 3–5 reference games ("X meets Y")
  - 2D or 3D, and the camera/perspective
  - What makes it different
  - Story premise (keep it short for now)
- [ ] Agree on a **scope target** for the first release: small and finishable beats big and abandoned

### Phase 1: Learn-by-Doing Prototype (Weeks 2–8) · $0
Goal: **find the fun.** Gray boxes, no story, no menus.
- [x] Get a scene running in Godot (v0.1 prototype)
- [x] Build the single most important mechanic, the one the whole game rests on (prayers + discoveries + journal words, v0.1)
- [ ] Iterate in short loops: build → you play → tweak → repeat
- [ ] Try 2–3 variations of the core mechanic, then keep the best one
- **Gate:** is the core action satisfying with zero polish? If not, rethink the mechanic before adding anything.

### Phase 2: Core Loop Prototype (Months 2–4) · $0
- [ ] Connect the core mechanics into a full loop with goals, progression, and fail/win states
- [ ] Add a rough UI and a minimal tutorial prompt
- [ ] **Outside playtests:** 3–5 friends who have never heard your pitch. Watch them play silently and take notes
- [ ] Track every version in the changelog
- **🚦 Big decision gate:** do outside players want to keep playing? If yes → commit to the project. If no → pivot or simplify. This is the cheapest point to change direction.

### Phase 3: Vertical Slice + Go Public (Months 4–7) · ~$100–$500
One short section of the game that looks and plays close to final quality.
- [ ] Choose the art direction (pick a style that's achievable, e.g. low-poly or stylized pixel art)
- [ ] Pick a working title, check that the name is available on Steam, and register a domain or socials if you want them
- [ ] **Steamworks signup:** pay the $100 Steam Direct fee (you get it back once the game earns $1,000) and fill in tax and bank info
- [ ] **Launch the "Coming Soon" store page early.** Wishlists are the #1 predictor of launch success, and they build up over time
  - Needs a capsule image (the store thumbnail). This is the one asset worth paying a professional for (~$200–800)
  - Needs a short description, tags, and 5+ screenshots (screenshots from the slice are fine at this stage)
- [ ] Start a lightweight devlog (Reddit, X/Bluesky, TikTok, or YouTube Shorts). GIFs of the game work very well

### Phase 4: Production (Months 7–15+) · budget varies
- [ ] Build out all content: levels/maps, systems, story beats, and balancing
- [ ] Swap in final art and audio: bought asset packs, commissions, or your own
- [ ] Settings menu, save/load, controller support (optional), and Windows build polish
- [ ] Steam integration: achievements, cloud saves (via GodotSteam)
- [ ] Recurring wider playtests (Steam's free Playtest feature works well here)
- [ ] **Steam Next Fest:** enter with a polished demo. It's the biggest free visibility event on Steam

### Phase 5: Launch Prep (final 2–3 months) · ~$0–$1,000
- [ ] Decide: **Early Access or full release?** (Early Access fits iterative games, but players expect frequent updates)
- [ ] Trailer (30–60s, gameplay first)
- [ ] Set the price and pick a release date (avoid big AAA launch weeks)
- [ ] Contact press, streamers, and YouTubers who cover your genre (keys via Steamworks)
- [ ] Submit the store page and build to Valve for review (allow ~1 week; the page must show "Coming Soon" for 2+ weeks before release)
- [ ] Fill in Steam's content survey, including the AI-content disclosure (check Valve's current rules at the time)
- [ ] Final bug pass on several different PCs if possible

### Phase 6: Launch & Post-Launch
- [ ] Release 🎉 Watch reviews, crash reports, and community discussions closely in week 1
- [ ] Fast patches for critical bugs
- [ ] Join seasonal sales, and plan updates or DLC if there's an audience

---

## Rough cost summary

| Item | Cost | When |
|---|---|---|
| Godot, Git, GitHub, free assets | $0 | Always |
| Steam Direct fee | $100 (recoupable) | Phase 3 |
| Capsule art (store thumbnail) | ~$200–800 | Phase 3 |
| Art/audio assets or commissions | $0–$2,000+ (your choice) | Phase 4 |
| Trailer (DIY vs hired) | $0–$1,000 | Phase 5 |
| Business entity (LLC) | Optional; you can publish as an individual | Any time |

Steam keeps 30% of sales (dropping to 25%/20% at very high revenue).

## Realistic timeline

For a first-time developer working part-time: **12–24 months** to a polished release, depending on scope and hours per week. The prototype phases are where scope gets set. Every feature we cut early saves weeks later.

---

## Current status
**Phase:** 1 (finding the fun)
**Done:** design and story docs; tools set up; art directions explored (parked for now); v0.1 playtested by the user; **prototype v0.2 is playable** (see `CHANGELOG.md`).
**Next steps:** user plays v0.2 → feedback on weight, mystery, and casting → review the draft story additions in `STORY.md` → iterate.
**Story decided:** the harvested power makes mortals love the gods; the finale is a choice (break or keep the cycle) followed by a short epilogue. Open story questions are listed at the bottom of `STORY.md`.
