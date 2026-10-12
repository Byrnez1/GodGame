extends Control
## The prototype screen. Story text comes from res://content/, rules from game_state.gd,
## pictures from backdrop.gd.

const ContentData := preload("res://scripts/content.gd")
const GameRules := preload("res://scripts/game_state.gd")
const Backdrop := preload("res://scripts/backdrop.gd")

const GOLD := "#d9b45a"
const DIM := "#8a8475"
const COLD := "#9aa7b0"
const GLYPH_COLOR := "#6f6a5e"
const GLYPHS := "ᚠᚢᚦᚨᚱᚲᚷᚹᚺᚾᛁᛃᛇᛈᛉᛊᛏᛒᛖᛗᛚᛜᛟᛞ"

var content
var game
var result_text := ""
var casting := -1          ## Index of the choice being cast, or -1
var spend := 0             ## Faith poured into the current cast
var rolling := false
var journal_view := "notes"

var bar := {}
var love_bar: ProgressBar
var fear_bar: ProgressBar
var banner
var story: RichTextLabel
var choices: VBoxContainer
var end_button: Button
var tabs: TabContainer
var rev_box: VBoxContainer
var journal_text: RichTextLabel
var notes_btn: Button
var book_btn: Button
var history: RichTextLabel
var overlay: Control
var overlay_pic
var overlay_text: RichTextLabel
var overlay_btn: Button
var scene_panel := 0


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
	_dev_preview()


func _new_game() -> void:
	game = GameRules.new()
	game.start(content)
	result_text = ""
	casting = -1
	journal_view = "notes"
	scene_panel = 0
	_refresh()


# ---------------------------------------------------------------- layout

func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 18)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	margin.add_child(col)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 26)
	col.add_child(top)
	for key in ["generation", "faith"]:
		bar[key] = _label(top)
	love_bar = _meter(top, "Love", Color("e0915a"))
	fear_bar = _meter(top, "Fear", Color("9a4a5a"))
	for key in ["people", "mood", "rank"]:
		bar[key] = _label(top)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	col.add_child(body)

	var world := _panel(Color("1e212a"), 0)
	world.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(world)
	var wcol := VBoxContainer.new()
	wcol.add_theme_constant_override("separation", 0)
	world.add_child(wcol)
	banner = Backdrop.new()
	banner.custom_minimum_size = Vector2(0, 210)
	wcol.add_child(banner)
	var pad := MarginContainer.new()
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		pad.add_theme_constant_override(side, 18)
	wcol.add_child(pad)
	var inner_col := VBoxContainer.new()
	inner_col.add_theme_constant_override("separation", 12)
	pad.add_child(inner_col)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inner_col.add_child(scroll)
	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 16)
	scroll.add_child(inner)
	story = _rich(19)
	inner.add_child(story)
	choices = VBoxContainer.new()
	choices.add_theme_constant_override("separation", 8)
	inner.add_child(choices)
	end_button = Button.new()
	end_button.custom_minimum_size = Vector2(0, 46)
	end_button.pressed.connect(_on_end)
	inner_col.add_child(end_button)

	tabs = TabContainer.new()
	tabs.custom_minimum_size = Vector2(440, 0)
	body.add_child(tabs)

	var jcol := VBoxContainer.new()
	jcol.name = "Journal"
	jcol.add_theme_constant_override("separation", 10)
	tabs.add_child(jcol)
	var jrow := HBoxContainer.new()
	jcol.add_child(jrow)
	notes_btn = Button.new()
	notes_btn.text = "Your notes"
	notes_btn.toggle_mode = true
	notes_btn.pressed.connect(_on_view.bind("notes"))
	jrow.add_child(notes_btn)
	book_btn = Button.new()
	book_btn.text = "The old book"
	book_btn.toggle_mode = true
	book_btn.pressed.connect(_on_view.bind("book"))
	jrow.add_child(book_btn)
	var jscroll := _scroll("JournalScroll")
	jscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	jcol.add_child(jscroll)
	journal_text = _rich(17)
	jscroll.add_child(journal_text)

	var rscroll := _scroll("Discoveries")
	tabs.add_child(rscroll)
	rev_box = VBoxContainer.new()
	rev_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rev_box.add_theme_constant_override("separation", 8)
	rscroll.add_child(rev_box)

	var hscroll := _scroll("Pantheon")
	tabs.add_child(hscroll)
	history = _rich(15)
	hscroll.add_child(history)

	# Cutscene overlay, on top of everything.
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	add_child(overlay)
	var overlay_bg := ColorRect.new()
	overlay_bg.color = Color("0a0a10")
	overlay_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(overlay_bg)
	overlay_pic = Backdrop.new()
	overlay_pic.anchor_right = 1.0
	overlay_pic.anchor_bottom = 0.64
	overlay.add_child(overlay_pic)
	var shade := _panel(Color(0.04, 0.04, 0.07, 0.86), 28)
	shade.anchor_left = 0.0
	shade.anchor_right = 1.0
	shade.anchor_top = 0.64
	shade.anchor_bottom = 1.0
	overlay.add_child(shade)
	var orow := VBoxContainer.new()
	orow.add_theme_constant_override("separation", 14)
	shade.add_child(orow)
	overlay_text = _rich(22)
	overlay_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	orow.add_child(overlay_text)
	overlay_btn = Button.new()
	overlay_btn.custom_minimum_size = Vector2(200, 44)
	overlay_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	overlay_btn.pressed.connect(_on_scene_next)
	orow.add_child(overlay_btn)


func _label(parent: Control) -> Label:
	var l := Label.new()
	parent.add_child(l)
	return l


func _meter(parent: Control, title: String, color: Color) -> ProgressBar:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	parent.add_child(box)
	var l := Label.new()
	l.text = title
	box.add_child(l)
	var pb := ProgressBar.new()
	pb.custom_minimum_size = Vector2(110, 14)
	pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pb.max_value = 100
	pb.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	var back := StyleBoxFlat.new()
	back.bg_color = Color("2a2e38")
	back.set_corner_radius_all(3)
	pb.add_theme_stylebox_override("fill", fill)
	pb.add_theme_stylebox_override("background", back)
	box.add_child(pb)
	return pb


func _panel(color: Color, margin: int) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(margin)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _scroll(node_name: String) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.name = node_name
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	return sc


func _rich(font_size: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for k in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size"]:
		r.add_theme_font_size_override(k, font_size)
	return r


func _add_button(label: String, action: Callable, disabled := false) -> Button:
	var b := Button.new()
	b.text = label
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(0, 42)
	b.disabled = disabled
	b.pressed.connect(action)
	choices.add_child(b)
	return b


func _esc(t: String) -> String:
	return t.replace("[", "[lb]")


# ---------------------------------------------------------------- refresh

func _refresh() -> void:
	bar["generation"].text = "Generation %d of %d" % [game.generation, game.s("generations")]
	bar["faith"].text = "Faith %d" % game.faith
	love_bar.value = game.love
	fear_bar.value = game.fear
	bar["people"].text = "People %d" % game.people
	var mood_words := {"loved": "Your people adore you", "feared": "Your people fear you", "restless": "Your people are restless", "calm": "Your people are unsure of you"}
	bar["mood"].text = mood_words[game.mood()]
	bar["mood"].add_theme_color_override("font_color", Color("c46a5a") if game.is_restless() else Color(DIM))
	bar["rank"].text = "Rank: %s" % GameRules.RANK_NAMES[game.rank()]
	tabs.set_tab_title(0, "Journal" + (" •" if not game.new_notes.is_empty() else ""))
	_refresh_story()
	_refresh_revelations()
	_refresh_journal()
	_refresh_history()
	_maybe_show_scene()


func _maybe_show_scene() -> void:
	if game.over or game.scenes.is_empty():
		overlay.visible = false
		return
	var cs: Dictionary = game.scenes[0]
	var panels: Array = cs["panels"]
	scene_panel = clampi(scene_panel, 0, panels.size() - 1)
	var pnl: Dictionary = panels[scene_panel]
	overlay_pic.picture = pnl["picture"]
	overlay_text.text = _esc(pnl["text"])
	overlay_btn.text = "Continue" if scene_panel < panels.size() - 1 else "Return to your people"
	overlay.visible = true


func _refresh_story() -> void:
	for ch in choices.get_children():
		ch.queue_free()
	banner.tint = game.mood()
	if game.over:
		banner.picture = "pantheon"
		_show_ending()
		return
	if result_text != "":
		story.text = result_text
		_add_button("Continue", _on_continue)
		_end_btn(false, "…")
		return
	var p: Dictionary = game.current_prayer()
	if p.is_empty():
		banner.picture = "village"
		story.text = "[color=%s]The prayers have gone quiet for now.[/color]\n\nYou could grant a discovery, read your journal, or let time pass." % DIM
		if game.generation < game.s("generations"):
			_end_btn(true, "Let a generation pass")
		else:
			_end_btn(true, "See what became of them")
		return
	var pic: String = p["picture"]
	if pic == "":
		pic = "fog" if p["kind"] == "villain" else "village"
	banner.picture = pic
	if casting >= 0:
		_show_cast(p)
		return
	var t := ""
	if p["kind"] == "villain":
		t += "[color=%s]Something is wrong.[/color]\n\n" % COLD
	if p["speaker"] != "":
		t += "[color=%s]%s[/color]\n\n" % [GOLD, _esc(p["speaker"])]
	t += _esc(p["text"])
	story.text = t
	for i in p["choices"].size():
		var ch: Dictionary = p["choices"][i]
		var label: String = ch["text"]
		if ch["cost"] > 0:
			label += "   · %d faith" % ch["cost"]
		if not ch["test"].is_empty():
			label += "   · cast the bones"
		var why: String = game.choice_check(ch)
		if why != "":
			label += "   · " + why
		_add_button(label, _on_choice.bind(i), why != "")
	_end_btn(false, "Answer your people first (%d waiting)" % game.queue.size())


func _end_btn(enabled: bool, text: String) -> void:
	end_button.disabled = not enabled
	end_button.text = text


func _show_cast(p: Dictionary) -> void:
	var ch: Dictionary = p["choices"][casting]
	var stat: String = ch["test"]["stat"]
	var bonus: int = game.cast_bonus(stat)
	var guide := {"love": "Your people's love", "fear": "Your people's fear", "faith": "Your own strength as a %s" % GameRules.RANK_NAMES[game.rank()]}
	var t := "[color=%s]CAST THE BONES[/color]\n\n[b]%s[/b]\n\n" % [GOLD, _esc(ch["text"])]
	t += "%s guides the bones: [b]+%d[/b]\n" % [guide[stat], bonus]
	t += "Faith poured in: [b]+%d[/b]   [color=%s](1 faith for each +1)[/color]\n\n" % [spend, DIM]
	t += "The odds feel: [b]%s[/b]" % game.odds_word(ch, spend)
	story.text = t
	var mx: int = game.max_spend(ch)
	_add_button("Pour in more faith (+1)", _on_spend.bind(1), spend >= mx)
	_add_button("Take some faith back (−1)", _on_spend.bind(-1), spend <= 0)
	_add_button("Cast", _on_cast)
	_add_button("Choose something else", _on_cancel_cast)
	_end_btn(false, "The bones are in your hand")


func _refresh_revelations() -> void:
	for ch in rev_box.get_children():
		ch.queue_free()
	var intro := _rich(15)
	intro.text = "[color=%s]Grant one discovery per generation. Each changes how your people live, and some close other paths for good.[/color]" % DIM
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
		var box := _panel(Color("232733"), 14)
		rev_box.add_child(box)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 6)
		box.add_child(v)
		var status := ""
		match st[0]:
			"granted":
				status = "[color=#7fc28a]Granted[/color]"
			"forgotten":
				status = "[color=%s]Forgotten · restore for %d faith[/color]" % [COLD, game.grant_cost(id)]
			"closed":
				status = "[color=#a06a6a]Path closed[/color]"
			"available":
				status = "[color=%s]%d faith[/color]" % [GOLD, game.grant_cost(id)]
			_:
				status = "[color=%s]%d faith · %s[/color]" % [DIM, game.grant_cost(id), st[1]]
		var title := _rich(17)
		title.text = "[b]%s[/b]   %s" % [_esc(r["name"]), status]
		v.add_child(title)
		if r["text"] != "" and st[0] != "closed":
			var desc := _rich(15)
			desc.text = "[color=#b8b2a4]%s[/color]" % _esc(r["text"])
			v.add_child(desc)
		if st[0] != "granted" and st[0] != "closed" and game.journal_answers(id):
			var hint := _rich(15)
			hint.text = "[color=%s]✦ Something in the old book answers to this.[/color]" % GOLD
			v.add_child(hint)
		if r["glimpse"] != "" and st[0] in ["available", "locked"] and game.rank_at_least("deity"):
			var gl := _rich(15)
			gl.text = "[i][color=%s]A glimpse of what could be: %s[/color][/i]" % [GOLD, _esc(r["glimpse"])]
			v.add_child(gl)
		if st[0] == "available" or (st[0] == "forgotten" and st[1] == ""):
			var b := Button.new()
			b.text = "Restore" if st[0] == "forgotten" else "Grant %s" % r["name"]
			b.pressed.connect(_on_grant.bind(id))
			v.add_child(b)


func _refresh_journal() -> void:
	var found: bool = game.journal_found()
	book_btn.visible = found
	if not found:
		journal_view = "notes"
	notes_btn.button_pressed = journal_view == "notes"
	book_btn.button_pressed = journal_view == "book"
	journal_text.text = _notes_text() if journal_view == "notes" else _book_text()
	if journal_view == "notes" and tabs.current_tab == 0:
		game.new_notes.clear()


func _notes_text() -> String:
	var t := "[color=%s]What you have learned about the people in your world, including yourself.[/color]\n\n" % DIM
	for person in content.characters:
		if not person["id"] in game.met:
			continue
		var learned: Array = person["notes"].filter(func(n): return n["key"] in game.notes)
		if learned.is_empty() and person["intro"] == "":
			continue
		var heading := "[b]%s[/b]" % _esc(person["name"])
		if person["title"] != "":
			heading += "   [color=%s]%s[/color]" % [DIM, _esc(person["title"])]
		t += heading + "\n"
		if person["intro"] != "":
			t += "[color=#b8b2a4]%s[/color]\n" % _esc(person["intro"])
		for n in person["notes"]:
			if n["key"] in game.notes:
				if n["key"] in game.new_notes:
					t += "[color=%s]• %s[/color]\n" % [GOLD, _esc(n["text"])]
				else:
					t += "• %s\n" % _esc(n["text"])
		t += "\n"
	return t.strip_edges()


func _book_text() -> String:
	var t := ""
	if game.flags.has("dreamed_of_her"):
		t += "[color=%s]Her world, rebuilt: %d%%[/color]\n\n" % [GOLD, game.readable_percent()]
	else:
		var counts: Vector2i = game.journal_counts()
		t += "[color=%s]Words you can read: %d of %d[/color]\n\n" % [GOLD, counts.x, counts.y]
	for page in game.visible_pages():
		var title: String = page["title"] if page["title"] != "" else "A page"
		t += "[color=%s]%s[/color]" % [DIM, _esc(title)]
		if page["ink"] != "":
			t += "   [color=%s](%s)[/color]" % [DIM, _esc(page["ink"])]
		t += "\n"
		if page["sketch"] != "":
			t += "[i][color=#a39a86]In the margin, a sketch: %s[/color][/i]\n" % _esc(page["sketch"])
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
	return t.strip_edges()


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
	var heading: String = e.get("title", "")
	if heading == "":
		heading = "The age ends"
	var t := "[font_size=28]%s[/font_size]\n\n" % _esc(heading)
	t += _esc(e.get("text", ""))
	for line in game.epilogue_lines:
		t += "\n\n" + _esc(line)
	t += "\n\n[color=%s]Her world rebuilt: %d%%   ·   Prayers answered: %d   ·   Left in silence: %d[/color]" % [DIM, game.readable_percent(), game.answered, game.unanswered]
	t += "\n\n[color=%s]End of prototype v0.2.[/color]" % DIM
	story.text = t
	_add_button("Play again", _new_game)
	_end_btn(false, "The end")


func _show_errors() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 32)
	add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var r := _rich(17)
	var t := "[font_size=26]Some story files need fixing[/font_size]\n\n"
	t += "[color=%s]The game can't start until these are fixed. Open the file, go to the line number, fix it, save, and run the game again.[/color]\n\n" % DIM
	for e in content.errors:
		t += "• %s\n\n" % _esc(e)
	r.text = t
	scroll.add_child(r)


# ---------------------------------------------------------------- actions

func _snapshot() -> Dictionary:
	return {"love": game.love, "fear": game.fear, "people": game.people, "faith": game.faith,
		"words": game.journal_counts().x, "rank": game.rank(), "unrest": game.is_restless()}


## Describes what changed, in plain words rather than exact numbers for love and fear.
func _news(before: Dictionary) -> String:
	var bits := PackedStringArray()
	var dl: int = game.love - before["love"]
	var df: int = game.fear - before["fear"]
	if dl >= 5:
		bits.append("Love swells.")
	elif dl > 0:
		bits.append("Love grows.")
	elif dl <= -5:
		bits.append("Love falls away.")
	elif dl < 0:
		bits.append("Love cools.")
	if df >= 5:
		bits.append("Terror spreads.")
	elif df > 0:
		bits.append("Fear spreads.")
	elif df < 0:
		bits.append("Fear eases.")
	var dp: int = game.people - before["people"]
	if dp < 0:
		bits.append("%d %s." % [-dp, "died" if dp == -1 else "are gone"])
	elif dp > 0:
		bits.append("%d more %s." % [dp, "soul" if dp == 1 else "souls"])
	var dfa: int = game.faith - before["faith"]
	if dfa > 0:
		bits.append("+%d faith." % dfa)
	var t := ""
	if not bits.is_empty():
		t += "\n\n[color=%s]%s[/color]" % [DIM, " ".join(bits)]
	var gained: int = game.journal_counts().x - before["words"]
	if gained > 0:
		t += "\n[color=%s]The old book stirs: %d %s readable.[/color]" % [GOLD, gained, "word is" if gained == 1 else "words are"]
	elif gained < 0:
		t += "\n[color=%s]%d %s in the old book went dark.[/color]" % [COLD, -gained, "word" if gained == -1 else "words"]
	if game.rank() != before["rank"]:
		t += "\n[color=%s]Your people's faith has made you stronger. You are now a %s.[/color]" % [GOLD, GameRules.RANK_NAMES[game.rank()]]
	if game.is_restless() and not before["unrest"]:
		t += "\n[color=#c46a5a]Something is stirring among your people. They are restless.[/color]"
	if not game.new_notes.is_empty():
		t += "\n[color=%s]Your journal has new notes.[/color]" % GOLD
	return t


func _on_choice(i: int) -> void:
	var p: Dictionary = game.current_prayer()
	if not p["choices"][i]["test"].is_empty():
		casting = i
		spend = 0
		_refresh()
		return
	var before := _snapshot()
	var res: Dictionary = game.choose(i)
	_show_result(res, before, "")


func _on_cast() -> void:
	if rolling:
		return
	rolling = true
	for k in choices.get_children():
		k.disabled = true
	var r := RandomNumberGenerator.new()
	r.randomize()
	for frame in 12:
		story.text = "[color=%s]CAST THE BONES[/color]\n\n[font_size=40]%d   %d   %d[/font_size]" % [GOLD, r.randi_range(1, 6), r.randi_range(1, 6), r.randi_range(1, 6)]
		await get_tree().create_timer(0.06 + frame * 0.01).timeout
	var before := _snapshot()
	var idx := casting
	var amount := spend
	casting = -1
	spend = 0
	rolling = false
	var res: Dictionary = game.choose(idx, amount)
	var cast: Dictionary = res.get("cast", {})
	var head := ""
	if not cast.is_empty():
		var bones: Array = cast["bones"]
		head = "[color=%s]THE BONES LAND[/color]\n\n[font_size=40]%d   %d   %d[/font_size]\n" % [GOLD, bones[0], bones[1], bones[2]]
		head += "[color=%s]%d from the bones + %d from %s + %d faith = %d. You needed %d.[/color]\n" % [DIM, bones[0] + bones[1] + bones[2], cast["bonus"], cast["stat"], cast["spend"], cast["total"], cast["target"]]
		head += ("[color=#c46a5a][b]It fails.[/b][/color]\n\n" if res["failed"] else "[color=#7fc28a][b]It holds.[/b][/color]\n\n")
	_show_result(res, before, head)


func _show_result(res: Dictionary, before: Dictionary, head: String) -> void:
	var text: String = res.get("result", "")
	result_text = head + ("[i]%s[/i]" % _esc(text) if text != "" else "[i]It is done.[/i]")
	result_text += _news(before)
	_refresh()


func _on_grant(id: String) -> void:
	var before := _snapshot()
	var was_forgotten: bool = id in game.forgotten
	if not game.grant(id):
		return
	var r: Dictionary = content.revelations[id]
	if was_forgotten:
		result_text = "You return [b]%s[/b] to your people." % _esc(r["name"])
	else:
		result_text = "You grant [b]%s[/b] to your people.\n\n[i]%s[/i]" % [_esc(r["name"]), _esc(r["text"])]
	result_text += _news(before)
	_refresh()


func _on_continue() -> void:
	result_text = ""
	_refresh()


func _on_end() -> void:
	var before := _snapshot()
	var gen_before: int = game.generation
	game.end_generation()
	if not game.over and game.generation != gen_before:
		var li: Dictionary = game.last_income
		var t := "[color=%s]Generation %d[/color]\n\n" % [GOLD, game.generation]
		t += "Time passes below you. Children are born; the old die.\n"
		t += "[color=%s]Faith from love: %d   ·   Faith from fear: %d[/color]" % [DIM, li["love"], li["fear"] + li.get("bonus", 0)]
		result_text = t + _news(before)
	_refresh()


func _on_scene_next() -> void:
	if game.scenes.is_empty():
		overlay.visible = false
		return
	var cs: Dictionary = game.scenes[0]
	if scene_panel < cs["panels"].size() - 1:
		scene_panel += 1
	else:
		game.scene_seen(cs)
		scene_panel = 0
	_refresh()


## Developer aid for screenshots: run with "-- --preview=main" to skip ahead to
## generation 4 with the journal found and open, or "--preview=cast" to open a cast.
func _dev_preview() -> void:
	var mode := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--preview="):
			mode = a.substr(10)
	if mode == "":
		return
	game.scenes.clear()
	game.faith = 30
	game.flags["journal_found"] = 1
	game.grant("speech")
	game.granted_this_gen = false
	game.grant("fire")
	game.love = 18
	game.fear = 9
	game.update_notes()
	if mode == "main":
		tabs.current_tab = 0
		journal_view = "book"
	elif mode == "cast":
		for p in content.prayers:
			if p["id"] == "cold_nights":
				game.queue = [p]
		casting = 1
	_refresh()


func _on_view(view: String) -> void:
	journal_view = view
	_refresh_journal()


func _on_spend(delta: int) -> void:
	var p: Dictionary = game.current_prayer()
	if p.is_empty() or casting < 0:
		return
	spend = clampi(spend + delta, 0, game.max_spend(p["choices"][casting]))
	_refresh()


func _on_cancel_cast() -> void:
	casting = -1
	spend = 0
	_refresh()
