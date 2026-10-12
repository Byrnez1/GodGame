extends Control
## The Pantheon view: your people's discoveries drawn as constellations on a
## blue-white astral sky. Lit stars are discoveries your people have, pulsing
## stars can be granted, faded stars are paths you closed. Click a star.

signal star_clicked(id: String)

const STAR := Color(0.92, 0.96, 1.0)
const LINE_LIT := Color(0.78, 0.88, 1.0, 0.85)
const LINE_DIM := Color(0.55, 0.68, 1.0, 0.16)
const LABEL := Color(0.86, 0.92, 1.0)
const LABEL_DIM := Color(0.6, 0.68, 0.85, 0.45)
const TIER_X := {"whisper": 0.15, "spirit": 0.44, "deity": 0.73, "god": 0.9}

var game
var content
var selected := ""

var _t := 0.0
var _pos := {}
var _hover := ""
var _bg: Array = []
var _nebula: Array = []


func setup(c) -> void:
	content = c
	_pos.clear()
	var tiers := {}
	for id in content.revelation_order:
		var rk: String = content.revelations[id]["rank"]
		if not tiers.has(rk):
			tiers[rk] = []
		tiers[rk].append(id)
	for rk in tiers.keys():
		var ids: Array = tiers[rk]
		for i in ids.size():
			var h := float(absi(hash(ids[i])) % 1000) / 1000.0
			var x: float = TIER_X.get(rk, 0.5) + (h - 0.5) * 0.1 + (0.045 if i % 2 == 1 else -0.03)
			var y := 0.16 + (i + 0.5) / float(ids.size()) * 0.74
			_pos[ids[i]] = Vector2(x, y)
	var r := RandomNumberGenerator.new()
	r.seed = 23
	_bg.clear()
	for i in 260:
		_bg.append([r.randf(), r.randf(), r.randf_range(0.4, 1.6), r.randf() * TAU, r.randf_range(0.4, 1.8)])
	_nebula.clear()
	for i in 7:
		_nebula.append([r.randf(), r.randf_range(0.1, 0.9), r.randf_range(0.18, 0.4), r.randf() * TAU])


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_t += delta
		queue_redraw()


func _px(p: Vector2) -> Vector2:
	return Vector2(p.x * size.x, p.y * size.y)


func _draw() -> void:
	if content == null or game == null:
		return
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]),
		PackedColorArray([Color("040816"), Color("071030"), Color("0b1a44"), Color("060c24")]))
	for n in _nebula:
		var c := Vector2(n[0] * size.x + sin(_t * 0.05 + n[3]) * 20.0, n[1] * size.y)
		var rad: float = n[2] * size.y
		for k in 8:
			var f := 1.0 - k / 8.0
			draw_circle(c, rad * f, Color(0.35, 0.5, 1.0, 0.018))
	for s in _bg:
		var a: float = 0.25 + 0.35 * sin(_t * s[4] + s[3])
		draw_circle(Vector2(s[0] * size.x, s[1] * size.y), s[2] * 0.6, Color(0.85, 0.9, 1.0, maxf(a, 0.05)))
	var font := get_theme_default_font()
	for rk in TIER_X.keys():
		var used := false
		for id in content.revelation_order:
			if content.revelations[id]["rank"] == rk:
				used = true
		if used:
			draw_string(font, Vector2(TIER_X[rk] * size.x - 80, 0.07 * size.y), rk.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 160, 13, Color(0.7, 0.8, 1.0, 0.55))
	# Lines between discoveries and what they need.
	for id in content.revelation_order:
		var r: Dictionary = content.revelations[id]
		for q in r["requires"]:
			if not _pos.has(q):
				continue
			var lit: bool = game.has(id) and game.has(q)
			draw_line(_px(_pos[q]), _px(_pos[id]), LINE_LIT if lit else LINE_DIM, 2.0 if lit else 1.2, true)
		for x in r["excludes"]:
			if _pos.has(x) and id < x:
				draw_dashed_line(_px(_pos[id]), _px(_pos[x]), Color(1.0, 0.7, 0.75, 0.22), 1.0, 6.0)
	# The stars themselves.
	for id in content.revelation_order:
		var p := _px(_pos[id])
		var st: String = game.revelation_state(id)[0]
		var label_text: String = content.revelations[id]["name"]
		match st:
			"granted":
				for k in 6:
					draw_circle(p, 26.0 * (1.0 - k / 6.0), Color(0.7, 0.85, 1.0, 0.05))
				draw_circle(p, 7.0, STAR)
				_rays(p, 13.0, Color(0.95, 0.98, 1.0, 0.8))
			"available":
				var pulse := 0.5 + 0.5 * sin(_t * 2.6 + p.x)
				draw_arc(p, 11.0 + pulse * 5.0, 0.0, TAU, 40, Color(0.6, 0.9, 1.0, 0.25 + pulse * 0.45), 1.5, true)
				draw_circle(p, 5.0, Color(0.75, 0.92, 1.0))
			"forgotten":
				draw_arc(p, 6.0, 0.0, TAU, 32, Color(0.6, 0.65, 0.75, 0.7), 1.5, true)
			"closed":
				draw_circle(p, 3.0, Color(0.6, 0.6, 0.7, 0.25))
				draw_line(p + Vector2(-5, -5), p + Vector2(5, 5), Color(1.0, 0.65, 0.7, 0.35), 1.2)
				draw_line(p + Vector2(-5, 5), p + Vector2(5, -5), Color(1.0, 0.65, 0.7, 0.35), 1.2)
			_:
				draw_circle(p, 3.5, Color(0.7, 0.78, 0.95, 0.45))
		if st != "granted" and st != "closed" and game.journal_answers(id):
			var sp := 0.6 + 0.4 * sin(_t * 3.0 + p.y)
			_rays(p + Vector2(12, -12), 4.0, Color(1.0, 1.0, 1.0, sp))
		if id == selected or id == _hover:
			draw_arc(p, 18.0, 0.0, TAU, 48, Color(1, 1, 1, 0.8 if id == selected else 0.4), 1.5, true)
		var lc: Color = LABEL if st in ["granted", "available"] else LABEL_DIM
		draw_string(font, p + Vector2(-90, 28), label_text, HORIZONTAL_ALIGNMENT_CENTER, 180, 14, lc)


func _rays(p: Vector2, length: float, color: Color) -> void:
	draw_line(p + Vector2(-length, 0), p + Vector2(length, 0), color, 1.0, true)
	draw_line(p + Vector2(0, -length), p + Vector2(0, length), color, 1.0, true)


func _gui_input(event: InputEvent) -> void:
	if content == null:
		return
	if event is InputEventMouseMotion:
		var found := ""
		for id in _pos.keys():
			if _px(_pos[id]).distance_to(event.position) < 22.0:
				found = id
		_hover = found
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if found != "" else Control.CURSOR_ARROW
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _hover != "":
			selected = _hover
			star_clicked.emit(_hover)
