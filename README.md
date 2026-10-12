# God Game — Project Map

```
GodGame/
├── README.md            ← you are here
├── CLAUDE.md            instructions Claude reads at the start of each session
│
├── docs/                📋 PLANNING
│   ├── ROADMAP.md       the plan, phases, and current status
│   ├── DESIGN.md        how the game plays
│   └── STORY.md         the full story and every spoiler
│
└── game/                🎮 THE GAME (Godot project)
    ├── project.godot    open this file with Godot
    │
    ├── content/         ✏️ STORY TEXT: edit freely
    │   ├── journal/     the journal pages
    │   ├── prayers/     prayers and events, and the player's choices
    │   ├── revelations/ the decision web (fire, music, weaving…)
    │   ├── characters/  shamans, chiefs, gods
    │   └── endings/     the final choice and epilogues
    │
    ├── scenes/          screens and UI (Claude's area)
    ├── scripts/         code (Claude's area)
    └── assets/          art, fonts, sounds
```

## Where to edit what

| I want to… | Go to |
|---|---|
| Change story, dialogue, or journal text | `game/content/` |
| Change the plan or the story bible | `docs/` |
| Change how something works | Ask Claude |

Everything in `game/content/` is plain text. Open it in Notepad or VS Code, change the words, save, and run the game. If you make a mistake in a file, the game will tell you which file and line to fix.
