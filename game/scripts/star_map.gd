extends Control
## The Heavens: your people's discoveries drawn as constellations on a blue-white
## astral sky. Most of the sky is hidden in fog until the story reveals it.
##   bright stars      discoveries your people have
##   pulsing stars     discoveries you could grant now
##   ? in the fog      something is there, next to what you know
##   grey stars        paths closed forever, or chances that passed
## Click a star to select it. Click empty sky to clear the selection.

signal star_clicked(id: String)

const STAR := Color(0.92, 0.96, 1.0)
const LINE_LIT := Color(0.78, 0.88, 1.0, 0.85)
const LINE_DIM := Color(0.55, 0.68, 1.0, 0.2)
const LABEL := Color(0.86, 0.92, 1.0)
const LABEL_DIM := Color(0.6, 0.68, 0.85, 0.55)
const LOST := Color(0.85, 0.6, 0.65, 0.55)
const TIER_X := {"whisper": 0.09, "spirit": 0.35, "deity": 0.62, "god": 0.87}
const TIER_NAMES := {"whisper": "WHISPER", "spirit": "SPIRIT", "deity": "DEITY", "god": "GOD"}

var game
var content
var selected := ""

var _t := 0.0
var _pos := {}
var _hover := ""
var _bg: Array = []
var _nebula: Array = []
var _puffs := {}  ## star -> fog puffs around it


func setup(c) -> void:
	content = c
	_pos.clear()
	# Lay out each rank as a column. Stars sit near the stars they need, so lines don't tangle.
	var y_of := {}
	for rk in TIER_X.keys():
		var ids: Array = content.revelation_order.filter(func(id): return content.revelations[id]["rank"] == rk)
		var want := {}
		for i in ids.size():
			var id: String = ids[i]
			var reqs: Array = content.revelations[id]["requires"].filter(func(q): return y_of.has(q))
			if reqs.is_empty():
				want[id] = (i + 0.5) / float(ids.size())
			else:
				var sum := 0.0
				for q in reqs:
					sum += y_of[q]
				want[id] = sum / reqs.size() + i * 0.001
		ids.sort_custom(func(a, b): return want[a] < want[b])
		for i in ids.size():
			var y := 0.15 + (i + 0.5) / float(ids.size()) * 0.72
			y_of[ids[i]] = y
			var x: float = TIER_X[rk] + (0.035 if i % 2 == 1 else -0.02)
			_pos[ids[i]] = Vector2(x, y)
	var r := RandomNumberGenerator.new()
	r.seed = 23
	_bg.clear()
	for i in 260:
		_bg.append([r.randf(), r.randf(), r.randf_range(0.4, 1.6), r.randf() * TAU, r.randf_range(0.4, 1.8)])
	_nebula.clear()
	for i in 7:
		_nebula.append([r.randf(), r.randf_range(0.1, 0.9), r.randf_range(0.18, 0.4), r.randf() * TAU])
	_puffs.clear()
	for id in _pos.keys():
		var list: Array = []
		for k in 7:
			list.append([r.randf_range(-0.07, 0.07), r.randf_range(-0.06, 0.06), r.randf_range(40.0, 80.0), r.randf() * TAU])
		_puffs[id] = list


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_t += delta
		queue_redraw()


func _px(p: Vector2) -> Vector2:
	return Vector2(p.x * size.x, p.y * size.y)


func _vis(id: String) -> String:
	return game.star_visibility(id)


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
		var reached: bool = game.rank_at_least(rk)
		draw_string(font, Vector2(TIER_X[rk] * size.x - 80, 0.07 * size.y), TIER_NAMES[rk], HORIZONTAL_ALIGNMENT_CENTER, 160, 13, Color(0.7, 0.8, 1.0, 0.6 if reached else 0.25))
	var vis := {}
	for id in content.revelation_order:
		vis[id] = _vis(id)
	# The fog, over everything you can't see clearly yet.
	for id in content.revelation_order:
		if vis[id] == "shown":
			continue
		var base := _px(_pos[id])
		var thick := 0.045 if vis[id] == "hidden" else 0.025
		for p in _puffs[id]:
			var drift := Vector2(sin(_t * 0.07 + p[3]) * 14.0, cos(_t * 0.05 + p[3]) * 6.0)
			var pc := base + Vector2(p[0] * size.x, p[1] * size.y) + drift
			for k in 9:
				draw_circle(pc, p[2] * (1.0 - k / 9.0), Color(0.72, 0.8, 0.98, thick * 0.22))
	# Lines between discoveries and what they need.
	for id in content.revelation_order:
		if vis[id] == "hidden":
			continue
		for q in content.revelations[id]["requires"]:
			if not _pos.has(q) or vis[q] == "hidden":
				continue
			var a := _px(_pos[q])
			var b := _px(_pos[id])
			if vis[id] == "faint" or vis[q] == "faint":
				draw_dashed_line(a, b, Color(0.6, 0.72, 1.0, 0.18), 1.0, 4.0)
			else:
				var lit: bool = game.has(id) and game.has(q)
				draw_line(a, b, LINE_LIT if lit else LINE_DIM, 2.0 if lit else 1.2, true)
		for x in content.revelations[id]["excludes"]:
			if _pos.has(x) and id < x and vis[id] == "shown" and vis.get(x, "hidden") == "shown":
				draw_dashed_line(_px(_pos[id]), _px(_pos[x]), Color(1.0, 0.7, 0.75, 0.25), 1.0, 6.0)
	# The stars themselves.
	var clear_sight: bool = game.sight() >= 2
	for id in content.revelation_order:
		if vis[id] == "hidden":
			continue
		var p := _px(_pos[id])
		var label_text: String = content.revelations[id]["name"]
		var lc := LABEL_DIM
		if vis[id] == "faint":
			var tw := 0.35 + 0.25 * sin(_t * 1.3 + p.x)
			draw_circle(p, 3.0, Color(0.8, 0.86, 1.0, tw))
			if not clear_sight:
				label_text = "?"
			lc = Color(0.7, 0.78, 0.95, 0.4)
		else:
			var st: String = game.revelation_state(id)[0]
			match st:
				"granted":
					for k in 6:
						draw_circle(p, 26.0 * (1.0 - k / 6.0), Color(0.7, 0.85, 1.0, 0.05))
					draw_circle(p, 7.0, STAR)
					_rays(p, 13.0, Color(0.95, 0.98, 1.0, 0.8))
					lc = LABEL
				"available":
					var pulse := 0.5 + 0.5 * sin(_t * 2.6 + p.x)
					draw_arc(p, 11.0 + pulse * 5.0, 0.0, TAU, 40, Color(0.6, 0.9, 1.0, 0.25 + pulse * 0.45), 1.5, true)
					draw_circle(p, 5.0, Color(0.75, 0.92, 1.0))
					lc = LABEL
				"forgotten":
					draw_arc(p, 6.0, 0.0, TAU, 32, Color(0.6, 0.65, 0.75, 0.7), 1.5, true)
				"closed", "lost":
					draw_circle(p, 3.0, Color(0.6, 0.6, 0.7, 0.3))
					draw_line(p + Vector2(-5, -5), p + Vector2(5, 5), LOST, 1.2)
					draw_line(p + Vector2(-5, 5), p + Vector2(5, -5), LOST, 1.2)
					lc = LOST
				_:
					draw_circle(p, 3.5, Color(0.7, 0.78, 0.95, 0.5))
			if st != "granted" and st != "closed" and st != "lost" and game.journal_answers(id):
				var sp := 0.6 + 0.4 * sin(_t * 3.0 + p.y)
				_rays(p + Vector2(12, -12), 4.0, Color(1.0, 1.0, 1.0, sp))
			if id in game.new_stars:
				draw_arc(p, 20.0 + 4.0 * sin(_t * 4.0), 0.0, TAU, 40, Color(1.0, 0.9, 0.6, 0.6), 1.5, true)
		if id == selected or id == _hover:
			draw_arc(p, 18.0, 0.0, TAU, 48, Color(1, 1, 1, 0.8 if id == selected else 0.4), 1.5, true)
		draw_string(font, p + Vector2(-90, 28), label_text, HORIZONTAL_ALIGNMENT_CENTER, 180, 14, lc)
	var legend := "●  your people have it      ◌  within reach      ?  something in the fog      ✕  lost forever"
	draw_string(font, Vector2(16, size.y - 14), legend, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 32, 12, Color(0.7, 0.8, 1.0, 0.5))


func _rays(p: Vector2, length: float, color: Color) -> void:
	draw_line(p + Vector2(-length, 0), p + Vector2(length, 0), color, 1.0, true)
	draw_line(p + Vector2(0, -length), p + Vector2(0, length), color, 1.0, true)


func _gui_input(event: InputEvent) -> void:
	if content == null or game == null:
		return
	if event is InputEventMouseMotion:
		var found := ""
		for id in _pos.keys():
			if _vis(id) != "hidden" and _px(_pos[id]).distance_to(event.position) < 22.0:
				found = id
		_hover = found
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if found != "" else Control.CURSOR_ARROW
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected = _hover
		star_clicked.emit(_hover)
