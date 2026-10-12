extends Control
## The prototype screen. Story text comes from res://content/, rules from game_state.gd,
## pictures from backdrop.gd, the sky from star_map.gd, the meters from meters.gd.

const ContentData := preload("res://scripts/content.gd")
const GameRules := preload("res://scripts/game_state.gd")
const Backdrop := preload("res://scripts/backdrop.gd")
const StarMap := preload("res://scripts/star_map.gd")
const Meters := preload("res://scripts/meters.gd")
const Portrait := preload("res://scripts/portrait.gd")

const GOLD := "#d9b45a"
const DIM := "#8a8475"
const COLD := "#9aa7b0"
const WARN := "#d9776a"
const SKY := "#bcd4ff"
const SKY_DIM := "#8fa3cc"
const GLYPH_COLOR := "#6f6a5e"
const GLYPHS := "ᚠᚢᚦᚨᚱᚲᚷᚹᚺᚾᛁᛃᛇᛈᛉᛊᛏᛒᛖᛗᛚᛜᛟᛞ"

var content
var game
var result_text := ""
var casting := -1          ## Index of the choice being cast, or -1
var spend := 0             ## Faith poured into the current cast
var rolling := false

# Top bar
var view_btns := {}
var gen_label: Label
var rank_label: Label
var vitals
var status_label: Label
# World view
var world_view: Control
var banner
var story: RichTextLabel
var choices: VBoxContainer
var end_button: Button
var tabs: TabContainer
var known_text: RichTextLabel
var journal_text: RichTextLabel
# Pantheon view
var view := "world"
var pantheon_view: Control
var pantheon_mode := "heavens"
var mode_btns := {}
var mode_hint: Label
var heavens: Control
var star_map
var card: PanelContainer
var card_text: RichTextLabel
var card_btn: Button
var hall: Control
var hall_list: VBoxContainer
var hall_portrait
var hall_text: RichTextLabel
var hall_selected := "you"
var chronicle: Control
var chron_choices: RichTextLabel
var chron_lost: RichTextLabel
# Cutscenes
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
	view = "world"
	pantheon_mode = "heavens"
	hall_selected = "you"
	star_map.selected = ""
	star_map.game = game
	scene_panel = 0
	_refresh()


# ---------------------------------------------------------------- layout

func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 16)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	# Top bar: the two views, where you are in time, and the three vessels.
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 22)
	col.add_child(top)
	var views := HBoxContainer.new()
	views.add_theme_constant_override("separation", 4)
	views.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(views)
	for v in ["World", "Pantheon"]:
		var vb := Button.new()
		vb.text = v
		vb.toggle_mode = true
		vb.custom_minimum_size = Vector2(104, 38)
		vb.pressed.connect(_on_switch_view.bind(v.to_lower()))
		views.add_child(vb)
		view_btns[v.to_lower()] = vb
	var when := VBoxContainer.new()
	when.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	when.add_theme_constant_override("separation", 0)
	top.add_child(when)
	gen_label = _label(when, 17, Color("e6dfcf"))
	rank_label = _label(when, 14, Color(DIM))
	vitals = Meters.new()
	top.add_child(vitals)
	status_label = _label(top, 15, Color(DIM))
	status_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# ---- The world: prayers on the left, your notes on the right.
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	col.add_child(body)
	world_view = body

	var world := _panel(Color("1e212a"), 0)
	world.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(world)
	var wcol := VBoxContainer.new()
	wcol.add_theme_constant_override("separation", 0)
	world.add_child(wcol)
	banner = Backdrop.new()
	banner.custom_minimum_size = Vector2(0, 200)
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
	tabs.custom_minimum_size = Vector2(430, 0)
	tabs.tab_changed.connect(_on_tab_changed)
	body.add_child(tabs)
	var kscroll := _scroll("Known")
	tabs.add_child(kscroll)
	known_text = _rich(16)
	kscroll.add_child(known_text)
	var jscroll := _scroll("Journal")
	tabs.add_child(jscroll)
	journal_text = _rich(17)
	jscroll.add_child(journal_text)

	# ---- The Pantheon: the Heavens, the Hall, and the Chronicle.
	var pv := VBoxContainer.new()
	pv.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pv.add_theme_constant_override("separation", 8)
	pv.visible = false
	col.add_child(pv)
	pantheon_view = pv
	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 4)
	pv.add_child(modes)
	for m in [["heavens", "The Heavens"], ["hall", "The Hall"], ["chronicle", "The Chronicle"]]:
		var mb := Button.new()
		mb.text = m[1]
		mb.toggle_mode = true
		mb.custom_minimum_size = Vector2(150, 34)
		mb.pressed.connect(_on_mode.bind(m[0]))
		modes.add_child(mb)
		mode_btns[m[0]] = mb
	mode_hint = _label(modes, 14, Color(SKY_DIM))
	mode_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mode_hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	# The Heavens: the sky fills the screen; a small card shows the star you picked.
	heavens = Control.new()
	heavens.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pv.add_child(heavens)
	star_map = StarMap.new()
	star_map.set_anchors_preset(Control.PRESET_FULL_RECT)
	star_map.clip_contents = true
	star_map.setup(content)
	star_map.star_clicked.connect(_on_star)
	heavens.add_child(star_map)
	card = _panel(Color(0.04, 0.07, 0.18, 0.9), 16)
	card.anchor_left = 1.0
	card.anchor_right = 1.0
	card.offset_right = -18
	card.offset_top = 52
	card.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	heavens.add_child(card)
	var ccol := VBoxContainer.new()
	ccol.add_theme_constant_override("separation", 10)
	card.add_child(ccol)
	card_text = _rich(16)
	card_text.custom_minimum_size = Vector2(360, 0)
	ccol.add_child(card_text)
	card_btn = Button.new()
	card_btn.custom_minimum_size = Vector2(0, 38)
	card_btn.pressed.connect(_on_star_grant)
	ccol.add_child(card_btn)

	# The Hall: the gods you've met, with a portrait and what you know of them.
	var hall_box := HBoxContainer.new()
	hall_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hall_box.add_theme_constant_override("separation", 16)
	pv.add_child(hall_box)
	hall = hall_box
	var list_panel := _panel(Color("0a1230"), 12)
	list_panel.custom_minimum_size = Vector2(330, 0)
	hall_box.add_child(list_panel)
	var lscroll := _scroll("Gods")
	list_panel.add_child(lscroll)
	hall_list = VBoxContainer.new()
	hall_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hall_list.add_theme_constant_override("separation", 8)
	lscroll.add_child(hall_list)
	var detail := _panel(Color("0c1638"), 24)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hall_box.add_child(detail)
	var drow := HBoxContainer.new()
	drow.add_theme_constant_override("separation", 28)
	detail.add_child(drow)
	hall_portrait = Portrait.new()
	hall_portrait.custom_minimum_size = Vector2(240, 240)
	hall_portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	drow.add_child(hall_portrait)
	var dscroll := _scroll("Detail")
	dscroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drow.add_child(dscroll)
	hall_text = _rich(17)
	dscroll.add_child(hall_text)

	# The Chronicle: what you chose, and what was lost.
	var chron := HBoxContainer.new()
	chron.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chron.add_theme_constant_override("separation", 16)
	pv.add_child(chron)
	chronicle = chron
	for side in [0, 1]:
		var cp := _panel(Color("0a1230") if side == 0 else Color("170f24"), 20)
		cp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chron.add_child(cp)
		var cs := _scroll("Chron%d" % side)
		cp.add_child(cs)
		var rt := _rich(15)
		cs.add_child(rt)
		if side == 0:
			chron_choices = rt
		else:
			chron_lost = rt

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
	overlay_pic.anchor_bottom = 0.55
	overlay.add_child(overlay_pic)
	var shade := _panel(Color(0.04, 0.04, 0.07, 0.86), 28)
	shade.anchor_left = 0.0
	shade.anchor_right = 1.0
	shade.anchor_top = 0.55
	shade.anchor_bottom = 1.0
	overlay.add_child(shade)
	var orow := VBoxContainer.new()
	orow.add_theme_constant_override("separation", 14)
	shade.add_child(orow)
	# The text scrolls if it's long, so the button below always stays on screen.
	var oscroll := _scroll("SceneText")
	oscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	orow.add_child(oscroll)
	overlay_text = _rich(20)
	oscroll.add_child(overlay_text)
	overlay_btn = Button.new()
	overlay_btn.custom_minimum_size = Vector2(200, 44)
	overlay_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	overlay_btn.pressed.connect(_on_scene_next)
	orow.add_child(overlay_btn)


func _label(parent: Control, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


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


func _person(id: String) -> Dictionary:
	for p in content.characters:
		if p["id"] == id:
			return p
	return {}


# ---------------------------------------------------------------- refresh

func _refresh() -> void:
	gen_label.text = "Generation %d of %d" % [game.generation, game.s("generations")]
	rank_label.text = "%s  ·  %d people" % [GameRules.RANK_NAMES[game.rank()], game.people]
	vitals.set_values(game)
	if game.is_restless():
		status_label.text = "Your people are restless"
		status_label.add_theme_color_override("font_color", Color(WARN))
	else:
		var mood_words := {"loved": "Your people love you", "feared": "Your people fear you", "calm": "Your people are unsure of you", "restless": ""}
		status_label.text = mood_words[game.mood()]
		status_label.add_theme_color_override("font_color", Color(DIM))
	world_view.visible = view == "world"
	pantheon_view.visible = view == "pantheon"
	for k in view_btns.keys():
		view_btns[k].button_pressed = k == view
	var sky_news: bool = not game.new_stars.is_empty() or not _new_notes_in("gods").is_empty()
	view_btns["pantheon"].text = "Pantheon •" if sky_news else "Pantheon"
	_refresh_story()
	_refresh_known()
	_refresh_journal()
	_refresh_pantheon()
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
		story.text = "[color=%s]The prayers have gone quiet for now.[/color]\n\nYou could look to the heavens and grant a discovery, read your journal, or let time pass." % DIM
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
	if p["kind"] == "villain" and p["speaker"] == "":
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


## Notes learned since last looked at, for people in these groups.
func _new_notes_in(group: String) -> Array:
	return game.new_notes.filter(func(k): return _person(k.get_slice(":", 0)).get("group", "") == group)


func _refresh_known() -> void:
	var groups := [["people", "PEOPLE"], ["places", "PLACES AND THINGS"]]
	var t := "[color=%s]Everyone and everything you have come to know. (The gods are in the Hall, in the Pantheon.)[/color]\n" % DIM
	for g in groups:
		var section := ""
		for person in content.characters:
			if person["group"] != g[0] or not person["id"] in game.met:
				continue
			var learned: Array = person["notes"].filter(func(n): return n["key"] in game.notes)
			if learned.is_empty() and person["intro"] == "":
				continue
			section += "[b]%s[/b]" % _esc(game.display_name(person))
			if person["title"] != "":
				section += "   [color=%s]%s[/color]" % [DIM, _esc(person["title"])]
			section += "\n"
			if person["intro"] != "":
				section += "[color=#b8b2a4]%s[/color]\n" % _esc(person["intro"])
			for n in learned:
				if n["key"] in game.new_notes:
					section += "[color=%s]• %s[/color]\n" % [GOLD, _esc(n["text"])]
				else:
					section += "• %s\n" % _esc(n["text"])
			section += "\n"
		if section != "":
			t += "\n[color=%s]%s[/color]\n%s" % [GOLD, g[1], section]
	known_text.text = t.strip_edges()
	var fresh_known := _new_notes_in("people") + _new_notes_in("places")
	tabs.set_tab_title(0, "Known" + (" •" if not fresh_known.is_empty() else ""))
	if tabs.current_tab == 0 and view == "world":
		for k in fresh_known:
			game.new_notes.erase(k)


func _refresh_journal() -> void:
	var found: bool = game.journal_found()
	tabs.set_tab_hidden(1, not found)
	if found:
		journal_text.text = _book_text()


func _book_text() -> String:
	var t := "[color=%s]The old book. You are slowly learning to read it.[/color]\n" % DIM
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


func _refresh_pantheon() -> void:
	for k in mode_btns.keys():
		mode_btns[k].button_pressed = k == pantheon_mode
	mode_btns["heavens"].text = "The Heavens" + (" •" if not game.new_stars.is_empty() else "")
	mode_btns["hall"].text = "The Hall" + (" •" if not _new_notes_in("gods").is_empty() else "")
	heavens.visible = pantheon_mode == "heavens"
	hall.visible = pantheon_mode == "hall"
	chronicle.visible = pantheon_mode == "chronicle"
	var hints := {"heavens": "Your people's discoveries. Click a star.", "hall": "The gods you have met.", "chronicle": "What you chose, and what was lost."}
	mode_hint.text = hints[pantheon_mode]
	star_map.game = game
	_refresh_card()
	_refresh_hall()
	_refresh_chronicle()
	if view == "pantheon":
		if pantheon_mode == "heavens":
			game.new_stars.clear()
		elif pantheon_mode == "hall":
			for k in _new_notes_in("gods"):
				game.new_notes.erase(k)


func _refresh_card() -> void:
	var id: String = star_map.selected
	card_btn.visible = false
	if id == "" or not content.revelations.has(id):
		card.visible = false
		return
	card.visible = true
	var r: Dictionary = content.revelations[id]
	if game.star_visibility(id) == "faint":
		var t := "[color=%s][b]%s[/b][/color]\n" % [SKY, "Something in the fog" if game.sight() < 2 else _esc(r["name"])]
		t += "[color=%s]Your people aren't ready to see it yet. It's near something you know.[/color]" % SKY_DIM
		card_text.text = t
		return
	var st: Array = game.revelation_state(id)
	var states := {"granted": "Your people have this.", "forgotten": "Your people have forgotten this.", "closed": "This path closed forever.",
		"lost": "Its moment passed. It is lost forever.", "available": "You could grant this now.", "locked": st[1]}
	var t := "[color=%s][b]%s[/b][/color]\n[color=%s]%s  ·  %s[/color]\n\n" % [SKY, _esc(r["name"]), SKY_DIM, GameRules.RANK_NAMES[r["rank"]], states[st[0]]]
	t += _esc(r["text"])
	if st[0] in ["available", "locked"]:
		if not r["excludes"].is_empty():
			var ex := PackedStringArray()
			for q in r["excludes"]:
				ex.append(content.revelations[q]["name"])
			t += "\n\n[color=#d8a0a8]Granting this closes %s forever.[/color]" % _esc(", ".join(ex))
		if r["until"] > 0:
			var left: int = r["until"] - game.generation
			t += "\n[color=#d8a0a8]%s[/color]" % ("This is its last generation." if left <= 0 else "Its moment will pass after generation %d." % r["until"])
		if game.journal_answers(id):
			t += "\n\n[color=#ffffff]✦ Something in the old book answers to this.[/color]"
		if r["glimpse"] != "" and game.rank_at_least("deity"):
			t += "\n\n[i][color=%s]A glimpse: %s[/color][/i]" % [SKY, _esc(r["glimpse"])]
	if st[0] == "lost" and r["lost"] != "":
		t += "\n\n[i][color=#d8a0a8]%s[/color][/i]" % _esc(r["lost"])
	card_text.text = t
	if st[0] == "available" or (st[0] == "forgotten" and st[1] == ""):
		card_btn.visible = true
		card_btn.text = ("Restore it (%d faith)" if st[0] == "forgotten" else "Grant it to your people (%d faith)") % game.grant_cost(id)


func _refresh_hall() -> void:
	for ch in hall_list.get_children():
		ch.queue_free()
	var gods: Array = content.characters.filter(func(p): return p["group"] == "gods" and p["id"] in game.met)
	if gods.is_empty():
		return
	if not gods.any(func(p): return p["id"] == hall_selected):
		hall_selected = gods[0]["id"]
	for person in gods:
		var b := Button.new()
		b.toggle_mode = true
		b.button_pressed = person["id"] == hall_selected
		b.custom_minimum_size = Vector2(0, 84)
		b.pressed.connect(_on_hall_pick.bind(person["id"]))
		hall_list.add_child(b)
		var row := HBoxContainer.new()
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 8
		row.add_theme_constant_override("separation", 12)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(row)
		var pic = Portrait.new()
		pic.custom_minimum_size = Vector2(70, 70)
		pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pic.style = person["portrait"]
		row.add_child(pic)
		var names := VBoxContainer.new()
		names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		names.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(names)
		var fresh: bool = person["notes"].any(func(n): return n["key"] in game.new_notes)
		var nl := _label(names, 17, Color(GOLD) if fresh else Color("e6eefc"))
		nl.text = game.display_name(person) + ("  •" if fresh else "")
		var tl := _label(names, 13, Color(SKY_DIM))
		tl.text = person["title"]
	var sel := _person(hall_selected)
	hall_portrait.style = sel["portrait"]
	var t := "[font_size=28][color=%s]%s[/color][/font_size]\n[color=%s]%s[/color]\n\n" % [SKY, _esc(game.display_name(sel)), SKY_DIM, _esc(sel["title"])]
	var facts := PackedStringArray()
	if sel["id"] == "you":
		facts.append("Rank: %s   ·   Lifetime faith: %d" % [GameRules.RANK_NAMES[game.rank()], game.faith_earned])
		facts.append("Prayers answered: %d   ·   Left in silence: %d" % [game.answered, game.unanswered])
	else:
		facts.append("First seen: generation %d" % game.met_gen.get(sel["id"], 1))
		if game.display_name(sel) != sel["name"]:
			facts.append("Times you have felt their hand in your world: %d" % game.interference.get(sel["id"], 0))
		else:
			facts.append("Who they truly are: [color=%s]unknown[/color]" % DIM)
	t += "[color=%s]%s[/color]\n\n" % ["#c9d6f0", "\n".join(facts)]
	for n in sel["notes"]:
		if n["key"] in game.notes:
			var colr: String = GOLD if n["key"] in game.new_notes else "#dfe6f5"
			t += "[color=%s]• %s[/color]\n" % [colr, _esc(n["text"])]
	hall_text.text = t.strip_edges()


func _refresh_chronicle() -> void:
	var t := "[color=%s]YOUR CHOICES[/color]\n" % SKY
	var last_gen := -1
	for i in range(game.log_entries.size() - 1, -1, -1):
		var e: Dictionary = game.log_entries[i]
		if e["gen"] != last_gen:
			last_gen = e["gen"]
			t += "\n[color=%s]Generation %d[/color]\n" % [SKY_DIM, last_gen]
		t += "• %s\n" % _esc(e["text"])
	chron_choices.text = t.strip_edges()
	var l := "[color=#e0a0b0]WHAT WAS LOST[/color]\n[color=%s]Every road taken closes others.[/color]\n" % SKY_DIM
	var lost_seen: Array = game.lost.filter(func(id): return id in game.seen_stars)
	var closed_seen: Array = game.closed.filter(func(id): return id in game.seen_stars)
	if lost_seen.is_empty() and closed_seen.is_empty() and game.missed.is_empty():
		l += "\n[color=%s]Nothing yet.[/color]" % DIM
	if not lost_seen.is_empty():
		l += "\n[color=#e0a0b0]Chances that passed[/color]\n"
		for id in lost_seen:
			var r: Dictionary = content.revelations[id]
			l += "• [b]%s[/b]. %s\n" % [_esc(r["name"]), _esc(r["lost"])]
	if not closed_seen.is_empty():
		var names := PackedStringArray()
		for id in closed_seen:
			names.append(content.revelations[id]["name"])
		l += "\n[color=#e0a0b0]Paths you closed[/color]\n%s\n" % _esc(", ".join(names))
	if not game.missed.is_empty():
		l += "\n[color=#e0a0b0]Out of reach[/color]\n"
		for i in range(game.missed.size() - 1, -1, -1):
			var m: Dictionary = game.missed[i]
			l += "• [color=%s]Generation %d.[/color] %s\n" % [SKY_DIM, m["gen"], _esc(m["text"])]
	chron_lost.text = l.strip_edges()


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
	t += "\n\n[color=%s]Her world rebuilt: %d%%   ·   Prayers answered: %d   ·   Left in silence: %d   ·   Discoveries: %d[/color]" % [DIM, game.readable_percent(), game.answered, game.unanswered, game.granted.size()]
	t += "\n\n[color=%s]End of prototype v0.3. The Chronicle in the Pantheon shows everything you chose, and everything you lost.[/color]" % DIM
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
		"words": game.journal_counts().x, "rank": game.rank(), "unrest": game.is_restless(),
		"zones": game.extremes(), "stars": game.seen_stars.size()}


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
		t += "\n[color=%s]Something is stirring among your people. They are restless.[/color]" % WARN
	var warnings := {
		"terrified": "Your people are beginning to live in terror of you. If it lasts, they will flee.",
		"fearless": "Your people have stopped fearing you. If it lasts, the offerings will dry up.",
		"forsaken": "Your people feel forsaken. If it lasts, fewer children will be born.",
	}
	for z in game.extremes():
		if not z in before["zones"]:
			t += "\n[color=%s]%s[/color]" % [WARN, warnings[z]]
	if game.seen_stars.size() > before["stars"]:
		var names := PackedStringArray()
		for id in game.seen_stars.slice(before["stars"]):
			names.append(content.revelations[id]["name"])
		t += "\n[color=%s]A new star appears in the heavens: %s.[/color]" % [SKY, ", ".join(names)]
	if not game.new_notes.is_empty() and game.new_notes.size() > 0:
		t += "\n[color=%s]You have learned something new.[/color]" % GOLD
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
	var closes: Array = r["excludes"].filter(func(x): return x in game.closed)
	if not closes.is_empty():
		var names := PackedStringArray()
		for x in closes:
			names.append(content.revelations[x]["name"])
		result_text += "\n\n[color=#d8a0a8]The path of %s closes forever.[/color]" % _esc(", ".join(names))
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
		for line in game.gen_report:
			t += "\n\n[color=%s]%s[/color]" % [WARN, _esc(line)]
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


## Developer aid for screenshots. Run with "-- --preview=MODE":
##   main      the journal found and open      cast       a cast in progress
##   known     the Known tab                   heavens    the Heavens (Pantheon)
##   hall      the Hall of gods                chronicle  the Chronicle
##   danger    the meters in danger zones      scene:ID:N panel N of cutscene ID
##   prayer:ID   a particular prayer
func _dev_preview() -> void:
	var mode := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--preview="):
			mode = a.substr(10)
	if mode == "":
		return
	if mode.begins_with("scene:"):
		var bits := mode.split(":")
		for cs in content.cutscenes:
			if cs["id"] == bits[1]:
				game.scenes = [cs]
				scene_panel = bits[2].to_int() if bits.size() > 2 else 0
		_refresh()
		return
	game.scenes.clear()
	game.faith = 30
	game.flags["journal_found"] = 1
	game.grant("speech")
	game.granted_this_gen = false
	game.grant("fire")
	game.love = 18
	game.fear = 9
	game.generation = 6
	for f in ["voices_met", "rule_learned", "sana_met", "sana_heard", "welcome_back", "reed_woman_seen", "reed_woman_omen", "lost_spring", "question_asked", "memory_noticed", "spear_found"]:
		game.flags[f] = 1
	game.update_notes()
	if mode == "main":
		tabs.current_tab = 1
	elif mode == "known":
		tabs.current_tab = 0
	elif mode == "danger":
		game.fear = 44
		game.love = 4
	elif mode in ["heavens", "hall", "chronicle"]:
		game.generation = 8
		game.granted_this_gen = false
		game.grant("river")
		game.lost.append("herding")
		game.seen_stars.append("herding")
		game.faith_earned = 25
		game.missed.append({"gen": 5, "text": "The healers: \"Brew the fever-leaf\" was out of reach without Healing Herbs."})
		game.update_notes()
		view = "pantheon"
		pantheon_mode = mode
		star_map.selected = "song" if mode == "heavens" else ""
		hall_selected = "memory"
	elif mode == "cast":
		for p in content.prayers:
			if p["id"] == "cold_nights":
				game.queue = [p]
		casting = 1
	elif mode.begins_with("prayer:"):
		for p in content.prayers:
			if p["id"] == mode.substr(7):
				game.queue = [p]
	_refresh()


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


func _on_switch_view(v: String) -> void:
	view = v
	_refresh()


func _on_mode(m: String) -> void:
	pantheon_mode = m
	_refresh()


func _on_tab_changed(_i: int) -> void:
	if game != null:
		_refresh()


func _on_hall_pick(id: String) -> void:
	hall_selected = id
	_refresh()


func _on_star(_id: String) -> void:
	_refresh()


func _on_star_grant() -> void:
	if star_map.selected != "":
		view = "world"
		_on_grant(star_map.selected)


## Enter or Space also advances a cutscene.
func _unhandled_input(event: InputEvent) -> void:
	if overlay != null and overlay.visible and event.is_action_pressed("ui_accept"):
		_on_scene_next()
		get_viewport().set_input_as_handled()
