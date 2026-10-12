STORY CONTENT: EDIT FREELY
==========================

Everything the player reads lives in this folder, as plain text files.
Open any file in Notepad or VS Code, change the words, save, and run the game.

Folders:
  journal/      the journal pages (one file per page)
  prayers/      prayers and events, and the choices the player can make
  revelations/  the decision web: discoveries like Fire, Music, Weaving
  characters/   shamans, chiefs, gods
  endings/      the final choice and the epilogues

Rules that apply to every file:
  - A line starting with #  is a note to yourself. The game ignores it.
  - Blank lines are fine. Use them to keep things readable.
  - If something is written wrong, the game will tell you the file and line number.

Example of a prayer (the exact format will be finalized when we build the prototype):

    === river_flood
    speaker: Sana the shaman

    The river has flooded twice this season. Sana kneels in the mud
    and asks what the people have done wrong.

    > Calm the waters
      cost: 8 faith
    > Send a dream of high ground
      unlocks: migration
    > Remain silent
      faith: -3
