# God Game — Project Map

## Play the prototype

1. Double-click **God Game (Godot)** on your desktop. The Godot editor opens.
2. Press **F5**, or click the ▶ button at the top right. The game starts in its own window.
3. Close that window to stop playing.

After changing any story file, press F5 again to see the change.

## Folders

```
GodGame/
├── README.md            ← you are here
├── CLAUDE.md            instructions Claude reads at the start of each session
│
├── docs/                📋 PLANNING
│   ├── ROADMAP.md       the plan, phases, and current status
│   ├── DESIGN.md        how the game plays
│   ├── STORY.md         the full story and every spoiler
│   ├── CHANGELOG.md     what changed in each version
│   └── art/             look books and scene sketches
│
└── game/                🎮 THE GAME (Godot project)
    ├── project.godot    open this file with Godot
    │
    ├── content/         ✏️ STORY TEXT: edit freely (see content/README.txt)
    │   ├── settings.txt game numbers
    │   ├── prayers/     prayers and the player's choices
    │   ├── revelations/ the decision web (fire, song, weaving…)
    │   ├── journal/     the journal pages and which words unlock when
    │   ├── characters/  (not used yet)
    │   └── endings/     how the game can end
    │
    ├── scenes/          screens (Claude's area)
    ├── scripts/         code (Claude's area)
    ├── tests/           automated checks (Claude's area)
    └── assets/          art, fonts, sounds (empty for now)
```

## Where to edit what

| I want to… | Go to |
|---|---|
| Change story, prayer, or journal text | `game/content/` |
| Change game numbers (length, costs, ranks) | `game/content/settings.txt` and `revelations/discoveries.txt` |
| Change the plan or the story bible | `docs/` |
| Change how something works | Ask Claude |

If you make a mistake in a story file, the game shows which file and line to fix instead of starting.
