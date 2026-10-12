STORY CONTENT: EDIT FREELY
==========================

Everything the player reads lives in this folder, as plain text files.
Open any file in Notepad or VS Code, change the words, save, and run the
game again (press F5 in Godot). All the current text is a DRAFT for you
to rewrite.

Each file starts with notes explaining exactly what you can write in it.

  settings.txt                   game numbers: length, starting people, rank thresholds
  prayers/story.txt              the main story prayers (with the full list of settings)
  prayers/everyday.txt           prayers that can repeat
  prayers/time_and_memory.txt    the villains' interference
  revelations/discoveries.txt    the decision web: Fire, Song, River Dwelling...
  journal/pages.txt              the journal pages
  journal/words.txt              which discovery makes which journal words readable
  endings/endings.txt            how the prototype can end

Rules that apply to every file:
  - A line starting with # is a note to yourself. The game ignores it.
  - Every entry starts with a line like:  === river_flood
  - Settings go right under that line, like:  cost: 3
  - Leave a blank line, then write the story text.
  - Choices start with  >  and their settings are indented below them.
  - If something is written wrong, the game shows the file and line number
    instead of starting, so you can fix it.

You can add new files too. Any .txt file in prayers/, revelations/,
journal/ or endings/ is read automatically.
