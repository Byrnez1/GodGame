extends Control
## Prototype screen: plain boxes and text, no art yet.
## All story text comes from res://content/. The rules live in game_state.gd.

const ContentData := preload("res://scripts/content.gd")
const GameRules := preload("res://scripts/game_state.gd")

const GOLD := "#d9b45a"
const DIM := "#8a8475"
const GLYPH_COLOR := "#6f6a5e"
const GLYPHS := "ᚠᚢᚦᚨᚱᚲᚷᚹᚺᚾᛁᛃᛇᛈᛉᛊᛏᛒᛖᛗᛚᛜᛟᛞ"

var content
var game
var result_text := ""
var bar := {}
var story: RichTextLabel
var choices: VBoxContainer
var end_button: Button
var rev_box: VBoxContainer
var journal_info: Label
var journal: RichTextLabel
var history: RichTextLabel
var tabs: TabContainer


func _ready() -> void:
	var th := Theme.new()
	th.default_font_size = 17
	theme = th
	var bg := ColorRect.new()
	bg.color = Color("15171d")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	content = ContentData.new()
	content.load_all()
	if not content.errors.is_empty():
		_show_errors()
		return
	_build()
	_new_game()
	# Developer aid for screenshots: run with "-- --preview" to skip the intro,
	# grant First Words and Fire, and open the Journal tab.
	if "--preview" in OS.get_cmdline_user_args():
		game.faith = 20
		game.grant("speech")
		game.granted_this_gen = false
		game.grant("fire")
		result_text = ""
		tabs.current_tab = 1
		_refresh()


func _new_game() -> void:
	game = GameRules.new()
	game.start(content)
	result_text = "[color=%s]Generation 1[/color]\n\n[color=%s]How to play: answer your people's prayers, grant them discoveries in the Revelations tab, and watch the Journal tab as its words come back. Each generation, your people's worship gives you faith to spend.[/color]" % [GOLD, DIM]
	_refresh()


# ---------------------------------------------------------------- layout

func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 20)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	margin.add_child(col)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 34)
	col.add_child(top)
	for key in ["generation", "faith", "rank", "people", "worship"]:
		var l := Label.new()
		top.add_child(l)
		bar[key] = l

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	col.add_child(body)

	# The World: prayers, choices, and what happened.
	var world := _panel(Color("1e212a"))
	world.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(world)
	var wcol := VBoxContainer.new()
	wcol.add_theme_constant_override("separation", 14)
	world.add_child(wcol)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	wcol.add_child(scroll)
	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 18)
	scroll.add_child(inner)
	story = _rich()
	story.add_theme_font_size_override("normal_font_size", 19)
	story.add_theme_font_size_override("bold_font_size", 19)
	story.add_theme_font_size_override("italics_font_size", 19)
	inner.add_child(story)
	choices = VBoxContainer.new()
	choices.add_theme_constant_override("separation", 8)
	inner.add_child(choices)
	end_button = Button.new()
	end_button.custom_minimum_size = Vector2(0, 46)
	end_button.pressed.connect(_on_end)
	wcol.add_child(end_button)

	# Side tabs: Revelations, Journal, Pantheon.
	tabs = TabContainer.new()
	tabs.custom_minimum_size = Vector2(430, 0)
	body.add_child(tabs)

	var rscroll := _scroll("Revelations")
	tabs.add_child(rscroll)
	rev_box = VBoxContainer.new()
	rev_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rev_box.add_theme_constant_override("separation", 8)
	rscroll.add_child(rev_box)

	var jcol := VBoxContainer.new()
	jcol.name = "Journal"
	jcol.add_theme_constant_override("separation", 10)
	tabs.add_child(jcol)
	journal_info = Label.new()
	journal_info.add_theme_color_override("font_color", Color(GOLD))
	jcol.add_child(journal_info)
	var jscroll := _scroll("JournalScroll")
	jscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	jcol.add_child(jscroll)
	journal = _rich()
	jscroll.add_child(journal)

	var hscroll := _scroll("Pantheon")
	tabs.add_child(hscroll)
	history = _rich()
	history.add_theme_font_size_override("normal_font_size", 15)
	hscroll.add_child(history)


func _panel(color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(16)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _scroll(node_name: String) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.name = node_name
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	return sc


func _rich() -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return r


func _add_button(label: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(0, 42)
	b.pressed.connect(action)
	choices.add_child(b)
	return b


func _esc(t: String) -> String:
	return t.replace("[", "[lb]")


# ---------------------------------------------------------------- refresh

func _refresh() -> void:
	bar["generation"].text = "Generation %d of %d" % [game.generation, game.s("generations")]
	bar["faith"].text = "Faith %d   (+%d next generation)" % [game.faith, game.income()]
	var rank_text := "Rank: %s" % GameRules.RANK_NAMES[game.rank()]
	var nr: Array = game.next_rank()
	if not nr.is_empty():
		rank_text += "   (%s at %d faith earned, you have %d)" % [GameRules.RANK_NAMES[nr[0]], nr[1], game.faith_earned]
	bar["rank"].text = rank_text
	bar["people"].text = "People %d" % game.people
	bar["worship"].text = "Love %d · Fear %d" % [game.love, game.fear]
	_refresh_story()
	_refresh_revelations()
	_refresh_journal()
	_refresh_history()


func _refresh_story() -> void:
	for ch in choices.get_children():
		ch.queue_free()
	if game.over:
		_show_ending()
		return
	if result_text != "":
		story.text = result_text
		_add_button("Continue", _on_continue)
		end_button.disabled = true
		end_button.text = "…"
		return
	var p: Dictionary = game.current_prayer()
	if p.is_empty():
		story.text = "[color=%s]The prayers have gone quiet for now.[/color]\n\nGrant a revelation from the panel on the right, read the journal, or let time pass." % DIM
		end_button.disabled = false
		if game.generation < game.s("generations"):
			end_button.text = "End generation %d" % game.generation
		else:
			end_button.text = "See what became of them"
		return
	var t := ""
	if p["kind"] == "villain":
		t += "[color=#9aa7b0]Something is wrong.[/color]\n\n"
	if p["speaker"] != "":
		t += "[color=%s]%s[/color]\n\n" % [GOLD, _esc(p["speaker"])]
	t += _esc(p["text"])
	story.text = t
	for i in p["choices"].size():
		var ch: Dictionary = p["choices"][i]
		var label: String = ch["text"]
		if ch["cost"] > 0:
			label += "   (%d faith)" % ch["cost"]
		var why: String = game.choice_check(ch)
		if why != "":
			label += "   · " + why
		var b := _add_button(label, _on_choice.bind(i))
		b.disabled = why != ""
	end_button.disabled = true
	var waiting: int = game.queue.size()
	end_button.text = "Answer the prayer first (%d waiting)" % waiting


func _refresh_revelations() -> void:
	for ch in rev_box.get_children():
		ch.queue_free()
	var intro := _rich()
	intro.text = "[color=%s]Grant one discovery per generation. Each one changes how your people live, and may close other paths for good.[/color]" % DIM
	rev_box.add_child(intro)
	var last_rank := ""
	for id in content.revelation_order:
		var r: Dictionary = content.revelations[id]
		if r["rank"] != last_rank:
			last_rank = r["rank"]
			var h := Label.new()
			h.text = GameRules.RANK_NAMES[last_rank].to_upper()
			h.add_theme_color_override("font_color", Color(GOLD))
			rev_box.add_child(h)
		var st: Array = game.revelation_state(id)
		var box := _panel(Color("232733"))
		rev_box.add_child(box)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 6)
		box.add_child(v)
		var status := ""
		match st[0]:
			"granted":
				status = "[color=#7fc28a]Granted[/color]"
			"forgotten":
				status = "[color=#9aa7b0]Forgotten · restore for %d faith[/color]" % game.grant_cost(id)
			"closed":
				status = "[color=#a06a6a]Path closed[/color]"
			"available":
				status = "[color=%s]%d faith[/color]" % [GOLD, game.grant_cost(id)]
			_:
				status = "[color=%s]%d faith · %s[/color]" % [DIM, game.grant_cost(id), st[1]]
		var title := _rich()
		title.text = "[b]%s[/b]   %s" % [_esc(r["name"]), status]
		v.add_child(title)
		if r["text"] != "" and st[0] != "closed":
			var desc := _rich()
			desc.add_theme_font_size_override("normal_font_size", 15)
			desc.text = "[color=#b8b2a4]%s[/color]" % _esc(r["text"])
			v.add_child(desc)
		if r["glimpse"] != "" and st[0] in ["available", "locked"] and game.rank_at_least("deity"):
			var gl := _rich()
			gl.add_theme_font_size_override("italics_font_size", 15)
			gl.text = "[i][color=%s]A glimpse of what could be: %s[/color][/i]" % [GOLD, _esc(r["glimpse"])]
			v.add_child(gl)
		var can_act: bool = (st[0] == "available") or (st[0] == "forgotten" and st[1] == "")
		if can_act:
			var b := Button.new()
			b.text = "Restore" if st[0] == "forgotten" else "Grant %s" % r["name"]
			b.pressed.connect(_on_grant.bind(id))
			v.add_child(b)


func _refresh_journal() -> void:
	var counts: Vector2i = game.journal_counts()
	var keys: Vector2i = game.key_counts()
	journal_info.text = "Her world: %d of %d key words (%d%%)   ·   All words: %d of %d" % [keys.x, keys.y, game.readable_percent(), counts.x, counts.y]
	var t := ""
	for page in content.pages:
		var title: String = page["title"] if page["title"] != "" else "A page"
		t += "[color=%s]%s[/color]\n" % [DIM, _esc(title)]
		for tok in game.tokens(page["text"]):
			if not tok["is_word"]:
				t += _esc(tok["text"])
				continue
			var w: String = tok["text"]
			if game.readable(w):
				if game.concept_of(w) in game.fresh:
					t += "[color=%s]%s[/color]" % [GOLD, w]
				else:
					t += w
			else:
				t += "[color=%s]%s[/color]" % [GLYPH_COLOR, _glyph(w)]
		t += "\n\n"
	journal.text = t.strip_edges()


func _refresh_history() -> void:
	var t := ""
	if not game.closed.is_empty():
		var names := PackedStringArray()
		for id in game.closed:
			names.append(content.revelations[id]["name"])
		t += "[color=%s]PATHS NOT TAKEN[/color]\n%s\n\n" % [GOLD, _esc(", ".join(names))]
	var last_gen := -1
	for i in range(game.log_entries.size() - 1, -1, -1):
		var e: Dictionary = game.log_entries[i]
		if e["gen"] != last_gen:
			last_gen = e["gen"]
			t += "[color=%s]GENERATION %d[/color]\n" % [GOLD, last_gen]
		t += "• %s\n" % _esc(e["text"])
	history.text = t.strip_edges()


## Same word, same glyphs, every time, so players can learn to recognize them.
func _glyph(w: String) -> String:
	var lw := w.to_lower()
	var out := ""
	var h := 7
	for i in lw.length():
		h = (h * 31 + lw.unicode_at(i)) % 9973
		out += GLYPHS[h % GLYPHS.length()]
	return out


func _show_ending() -> void:
	var e: Dictionary = game.ending
	var worship := "Worshipped in love and fear alike"
	if game.love > game.fear:
		worship = "Worshipped mostly in love"
	elif game.fear > game.love:
		worship = "Worshipped mostly in fear"
	var heading: String = e.get("title", "")
	if heading == "":
		heading = "The first age ends"
	var t := "[font_size=28]%s[/font_size]\n\n" % _esc(heading)
	t += _esc(e.get("text", "")) + "\n\n"
	t += "[color=%s]Her world rebuilt: %d%% of the journal's key words   ·   Prayers answered: %d   ·   Left in silence: %d   ·   %s[/color]" % [DIM, game.readable_percent(), game.answered, game.unanswered, worship]
	t += "\n\n[color=%s]This is the end of prototype v0.1, roughly the first act of the game.[/color]" % DIM
	story.text = t
	_add_button("Play again", _new_game)
	end_button.disabled = true
	end_button.text = "The end"


func _show_errors() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 32)
	add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var r := _rich()
	var t := "[font_size=26]Some story files need fixing[/font_size]\n\n"
	t += "[color=%s]The game can't start until these are fixed. Open the file, go to the line number, fix it, save, and run the game again.[/color]\n\n" % DIM
	for e in content.errors:
		t += "• %s\n\n" % _esc(e)
	r.text = t
	scroll.add_child(r)


# ---------------------------------------------------------------- actions

func _on_choice(i: int) -> void:
	var before: int = game.journal_counts().x
	var rank_before: String = game.rank()
	var res: String = game.choose(i)
	result_text = "[i]%s[/i]" % _esc(res) if res != "" else "[i]It is done.[/i]"
	result_text += _news(before, rank_before)
	_refresh()


func _on_grant(id: String) -> void:
	var before: int = game.journal_counts().x
	var rank_before: String = game.rank()
	var was_forgotten: bool = id in game.forgotten
	if not game.grant(id):
		return
	var r: Dictionary = content.revelations[id]
	if was_forgotten:
		result_text = "You return [b]%s[/b] to your people." % _esc(r["name"])
	else:
		result_text = "You grant [b]%s[/b] to your people.\n\n[i]%s[/i]" % [_esc(r["name"]), _esc(r["text"])]
	result_text += _news(before, rank_before)
	_refresh()


func _news(words_before: int, rank_before: String) -> String:
	var t := ""
	var gained: int = game.journal_counts().x - words_before
	if gained > 0:
		t += "\n\n[color=%s]%d new %s readable in the journal.[/color]" % [GOLD, gained, "word is" if gained == 1 else "words are"]
	elif gained < 0:
		t += "\n\n[color=#9aa7b0]%d %s in the journal went dark.[/color]" % [-gained, "word" if gained == -1 else "words"]
	if game.rank() != rank_before:
		t += "\n\n[color=%s]Your people's faith has made you stronger. You are now a %s.[/color]" % [GOLD, GameRules.RANK_NAMES[game.rank()]]
	return t


func _on_continue() -> void:
	result_text = ""
	_refresh()


func _on_end() -> void:
	var gen_before: int = game.generation
	game.end_generation()
	if not game.over and game.generation != gen_before:
		var last: Dictionary = game.log_entries.back()
		result_text = "[color=%s]Generation %d[/color]\n\n%s" % [GOLD, game.generation, _esc(last["text"])]
		var rank_line := ""
		for e in game.log_entries:
			if e["gen"] == game.generation and e["text"].begins_with("Your people's faith"):
				rank_line = e["text"]
		if rank_line != "":
			result_text += "\n\n[color=%s]%s[/color]" % [GOLD, _esc(rank_line)]
	_refresh()
