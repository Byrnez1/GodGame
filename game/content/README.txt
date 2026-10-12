STORY CONTENT: EDIT FREELY
==========================

Everything the player reads lives in this folder, as plain text files.
Open any file in Notepad or VS Code, change the words, save, and run the
game again (press F5 in Godot). All the current text is a DRAFT for you
to rewrite.

Each file starts with notes explaining exactly what you can write in it.

  settings.txt                   game numbers: love, fear, faith, danger zones, casting, ranks
  cutscenes/story.txt            full-screen story moments with pictures
  prayers/act_one.txt            prayers for the early game (with the full list of settings)
  prayers/act_two.txt            the middle
  prayers/act_three.txt          the end, including the final choice
  prayers/everyday.txt           repeatable prayers, unrest, and the danger zones
  prayers/time_and_memory.txt    the villains' interference
  revelations/discoveries.txt    the decision web (stars in the Pantheon): when each appears, when its chance passes
  journal/pages.txt              the old book's pages and margin sketches
  journal/words.txt              which words become readable, and when
  characters/people.txt          people in the Known tab
  characters/gods.txt            gods in the Hall (Pantheon view), with portraits and names that change
  characters/places_and_things.txt   places and things in the Known tab
  endings/endings.txt            endings and epilogue lines

Rules that apply to every file:
  - A line starting with # is a note to yourself. The game ignores it.
  - Every entry starts with a line like:  === river_flood
  - Settings go right under that line, like:  when: 3+
  - Leave a blank line, then write the story text.
  - Choices (and notes about people) start with  >  and their settings are
    indented below them.
  - If something is written wrong, the game shows the file and line number
    instead of starting, so you can fix it.

You can add new files too. Any .txt file in these folders is read automatically.
