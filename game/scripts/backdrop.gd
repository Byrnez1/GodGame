extends Control
## Draws a placeholder picture for cutscenes and prayers, in code, with a little
## movement. If an image exists at res://assets/art/<picture>.png it's shown
## instead, so real art can replace these one at a time.

var picture := "stars":
	set(v):
		picture = v
		_texture = null
		var path := "res://assets/art/%s.png" % v
		if ResourceLoader.exists(path):
			_texture = load(path)
		queue_redraw()
var tint := ""  ## "loved", "feared", or "restless": shifts the colors of world pictures

var _t := 0.0
var _texture: Texture2D = null
var _stars: Array = []


func _ready() -> void:
	clip_contents = true
	var r := RandomNumberGenerator.new()
	r.seed = 11
	for i in 140:
		_stars.append([r.randf(), r.randf(), r.randf_range(0.6, 1.8), r.randf() * TAU, r.randf_range(0.5, 2.0)])


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_t += delta
		queue_redraw()


func _draw() -> void:
	if _texture != null:
		_draw_cover(_texture)
		return
	match picture:
		"pantheon": _pantheon(1.0)
		"pool": _pool()
		"chamber": _chamber()
		"journal": _parchment([Color("3b2a1c")])
		"inks": _parchment([Color("8e2a1a"), Color("2a4a8e"), Color("2a2018")])
		"voices": _voices()
		"other_god": _other_god()
		"dream_river": _dusk(true, false)
		"village": _dusk(false, true)
		"fire": _fire()
		"fog": _fog()
		"storm": _storm()
		"harvest": _harvest()
		"birth": _birth()
		"time": _time()
		"cycle": _pantheon(0.35)
		_: _starfield(Color("05071a"), Color("141c48"), 1.0)


# ---------------------------------------------------------------- helpers

func P(x: float, y: float) -> Vector2:
	return Vector2(x * size.x, y * size.y)


func _vgrad(top: Color, bottom: Color, y0 := 0.0, y1 := 1.0) -> void:
	draw_polygon(PackedVector2Array([P(0, y0), P(1, y0), P(1, y1), P(0, y1)]), PackedColorArray([top, top, bottom, bottom]))


func _ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	draw_set_transform(center, 0.0, Vector2(1.0, ry / maxf(rx, 0.001)))
	draw_circle(Vector2.ZERO, rx, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _hills(base: float, amp: float, seed_v: float, color: Color) -> void:
	var pts := PackedVector2Array([P(0, 1)])
	for i in 41:
		var x := i / 40.0
		var y := base - (sin(x * 7.0 + seed_v) * 0.5 + sin(x * 17.0 + seed_v * 2.3) * 0.25 + sin(x * 3.0 + seed_v * 0.7) * 0.5) * amp
		pts.append(P(x, y))
	pts.append(P(1, 1))
	draw_colored_polygon(pts, color)


func _figure(x: float, y: float, h: float, color: Color, robe := false) -> void:
	var px := P(x, y)
	var hh := h * size.y
	if robe:
		draw_colored_polygon(PackedVector2Array([px + Vector2(-hh * 0.18, 0), px + Vector2(0, -hh * 0.8), px + Vector2(hh * 0.18, 0)]), color)
	else:
		draw_line(px + Vector2(-hh * 0.12, 0), px + Vector2(0, -hh * 0.45), color, maxf(1.5, hh * 0.1))
		draw_line(px + Vector2(hh * 0.12, 0), px + Vector2(0, -hh * 0.45), color, maxf(1.5, hh * 0.1))
		draw_line(px + Vector2(0, -hh * 0.45), px + Vector2(0, -hh * 0.8), color, maxf(1.5, hh * 0.1))
	draw_circle(px + Vector2(0, -hh * 0.9), hh * 0.11, color)


func _hut(x: float, y: float, w: float, color: Color) -> void:
	var px := P(x, y)
	var ww := w * size.x
	draw_colored_polygon(PackedVector2Array([px + Vector2(-ww, 0), px + Vector2(0, -ww * 1.3), px + Vector2(ww, 0)]), color)


func _glow(center: Vector2, radius: float, color: Color) -> void:
	for i in 6:
		var k := 1.0 - i / 6.0
		var c := color
		c.a = color.a * (1.0 - k) * 0.35
		draw_circle(center, radius * k, c)


func _starfield(top: Color, bottom: Color, alpha: float) -> void:
	_vgrad(top, bottom)
	for s in _stars:
		var a: float = (0.35 + 0.35 * sin(_t * s[4] + s[3])) * alpha
		draw_circle(P(s[0], s[1] * 0.85), s[2] * 0.6, Color(0.88, 0.9, 1.0, a))


func _draw_cover(tex: Texture2D) -> void:
	var ts := tex.get_size()
	var scale := maxf(size.x / ts.x, size.y / ts.y)
	var ds := ts * scale
	draw_texture_rect(tex, Rect2((size - ds) / 2.0, ds), false)


func _tinted(base: Color) -> Color:
	match tint:
		"feared":
			return base.lerp(Color("5a1f22"), 0.35)
		"restless":
			return base.lerp(Color("4a4a52"), 0.4)
		"loved":
			return base.lerp(Color("f2a65a"), 0.12)
	return base


# ---------------------------------------------------------------- pictures

func _pantheon(light: float) -> void:
	_starfield(Color("04050e"), Color("1a1f45").darkened(1.0 - light), light)
	draw_rect(Rect2(P(0, 0.74), P(1, 0.26)), Color("080a18"))
	for i in 9:
		var x := 0.06 + i * 0.11
		var w := 0.035
		var col := Color(0.7, 0.75, 1.0, 0.10 * light)
		draw_rect(Rect2(P(x, 0.06), P(w, 0.68)), col)
		draw_rect(Rect2(P(x, 0.06), P(0.004, 0.68)), Color(0.85, 0.88, 1.0, 0.25 * light))
		draw_rect(Rect2(P(x, 0.74), P(w, 0.12)), Color(0.7, 0.75, 1.0, 0.04 * light))
	for i in 7:
		var tx := 0.12 + i * 0.13
		var lit := i != 3
		var col := Color(0.95, 0.82, 0.5, (0.35 if lit else 0.08) * light)
		draw_rect(Rect2(P(tx, 0.64), P(0.03, 0.1)), col)
		draw_circle(P(tx + 0.015, 0.64), 0.015 * size.x, col)
	_glow(P(0.5, 0.5), size.y * 0.6, Color(0.6, 0.65, 1.0, 0.25 * light))


func _pool() -> void:
	_pantheon(0.8)
	var c := P(0.5, 0.84)
	var rx := 0.3 * size.x
	var ry := 0.1 * size.y
	_ellipse(c, rx + 6, ry + 4, Color(0.85, 0.75, 0.45, 0.5))
	_ellipse(c, rx, ry, Color("2a1f3a"))
	_ellipse(c + Vector2(0, -ry * 0.2), rx * 0.92, ry * 0.7, Color("6b3e6e"))
	for i in 4:
		var hx := c.x - rx * 0.3 + i * rx * 0.18
		draw_colored_polygon(PackedVector2Array([Vector2(hx - 8, c.y + 6), Vector2(hx, c.y - 6), Vector2(hx + 8, c.y + 6)]), Color("1c1226"))
	_glow(c + Vector2(rx * 0.12, 4), 20 + sin(_t * 9.0) * 2.0, Color(1.0, 0.7, 0.35, 0.9))
	for k in 3:
		var ph := fmod(_t * 0.3 + k / 3.0, 1.0)
		draw_set_transform(c, 0.0, Vector2(1.0, ry / rx))
		draw_arc(Vector2.ZERO, rx * (0.2 + ph * 0.8), 0.0, TAU, 64, Color(0.9, 0.9, 1.0, 0.25 * (1.0 - ph)), 1.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _chamber() -> void:
	_vgrad(Color("0b0a10"), Color("17131c"))
	var w0 := P(0.56, 0.16)
	var w1 := P(0.86, 0.6)
	draw_polygon(PackedVector2Array([w0, Vector2(w1.x, w0.y), w1, Vector2(w0.x, w1.y)]), PackedColorArray([Color("2e2a55"), Color("2e2a55"), Color("f0a07a"), Color("f0a07a")]))
	draw_rect(Rect2(Vector2(w0.x, (w0.y + w1.y) * 0.5 + 30), Vector2(w1.x - w0.x, 10)), Color(1.0, 0.85, 0.7, 0.45))
	draw_rect(Rect2(w0, w1 - w0), Color("2b2232"), false, 6.0)
	draw_line(Vector2((w0.x + w1.x) / 2, w0.y), Vector2((w0.x + w1.x) / 2, w1.y), Color("2b2232"), 5.0)
	draw_polygon(PackedVector2Array([w0, Vector2(w1.x, w0.y), P(0.98, 1.0), P(0.38, 1.0)]), PackedColorArray([Color(1, 0.7, 0.5, 0.10), Color(1, 0.7, 0.5, 0.10), Color(1, 0.7, 0.5, 0.0), Color(1, 0.7, 0.5, 0.0)]))
	draw_rect(Rect2(P(0.1, 0.66), P(0.38, 0.04)), Color("231b20"))
	draw_rect(Rect2(P(0.13, 0.7), P(0.02, 0.3)), Color("1c1519"))
	draw_rect(Rect2(P(0.43, 0.7), P(0.02, 0.3)), Color("1c1519"))
	var pulse := 0.55 + 0.25 * sin(_t * 1.6)
	_glow(P(0.28, 0.64), size.y * 0.16, Color(0.95, 0.78, 0.4, pulse))
	draw_rect(Rect2(P(0.22, 0.625), P(0.12, 0.035)), Color("6a4a2a"))
	draw_rect(Rect2(P(0.225, 0.62), P(0.11, 0.01)), Color("e8dcc0"))
	draw_rect(Rect2(P(0.6, 0.48), P(0.05, 0.3)), Color("1a1418"))
	draw_rect(Rect2(P(0.58, 0.62), P(0.1, 0.03)), Color("1a1418"))


func _parchment(inks: Array) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("cdb487"))
	draw_rect(Rect2(P(0.03, 0.05), P(0.94, 0.9)), Color("e3d2ae"))
	draw_rect(Rect2(P(0.06, 0.09), P(0.88, 0.82)), Color("ecdfc3"))
	var r := RandomNumberGenerator.new()
	r.seed = 5
	var rows := 9
	for row in rows:
		var y := 0.16 + row * 0.08
		var x := 0.1
		var ink: Color = inks[int(row / float(rows) * inks.size()) % inks.size()]
		ink.a = 0.75
		while x < 0.88:
			var wlen := r.randf_range(0.03, 0.09)
			var px := P(x, y)
			var steps := int(wlen * 60)
			var pts := PackedVector2Array()
			for s in steps:
				pts.append(px + Vector2(s * 3.0, sin(s * 1.7 + row) * 4.0 + r.randf_range(-2, 2)))
			if pts.size() > 1:
				draw_polyline(pts, ink, 1.6)
			x += wlen + 0.025
	if inks.size() == 1:
		for i in 5:
			draw_circle(P(0.85, 0.82) + Vector2(cos(i * TAU / 5) * 9, sin(i * TAU / 5) * 9), 6, Color(0.8, 0.45, 0.5, 0.6))
		draw_circle(P(0.85, 0.82), 4, Color(0.9, 0.75, 0.3, 0.8))


func _voices() -> void:
	_vgrad(Color("1a1d2e"), Color("4a4f66"))
	for i in 6:
		var fx := fmod(i * 0.21 + _t * 0.015, 1.2) - 0.1
		_ellipse(P(fx, 0.75 + sin(i) * 0.08), size.x * 0.25, size.y * 0.12, Color(0.85, 0.88, 0.95, 0.06))
	var time_c := Color(0.9, 0.85, 0.7, 0.55)
	var mem_c := Color(0.8, 0.86, 0.95, 0.5)
	draw_colored_polygon(PackedVector2Array([P(0.30, 0.98), P(0.36, 0.2), P(0.42, 0.98)]), Color(0.08, 0.08, 0.12, 0.8))
	draw_circle(P(0.36, 0.16), size.y * 0.045, Color(0.08, 0.08, 0.12, 0.85))
	draw_arc(P(0.36, 0.16), size.y * 0.1, 0.0, TAU, 64, time_c, 2.0)
	for k in 12:
		var a := k * TAU / 12.0 + _t * 0.2
		draw_line(P(0.36, 0.16) + Vector2(cos(a), sin(a)) * size.y * 0.1, P(0.36, 0.16) + Vector2(cos(a), sin(a)) * size.y * 0.115, time_c, 2.0)
	draw_colored_polygon(PackedVector2Array([P(0.58, 0.98), P(0.64, 0.22), P(0.70, 0.98)]), Color(0.08, 0.08, 0.12, 0.8))
	draw_circle(P(0.64, 0.18), size.y * 0.045, Color(0.08, 0.08, 0.12, 0.85))
	for k in 5:
		var off := Vector2(sin(_t * 0.7 + k) * 18, cos(_t * 0.5 + k * 2) * 10)
		_ellipse(P(0.64, 0.18) + off, size.y * 0.09, size.y * 0.05, Color(mem_c.r, mem_c.g, mem_c.b, 0.12))


func _other_god() -> void:
	_pantheon(0.7)
	var g := Color(0.95, 0.9, 0.75, 0.5 + 0.1 * sin(_t))
	draw_colored_polygon(PackedVector2Array([P(0.7, 0.74), P(0.74, 0.3), P(0.78, 0.74)]), g)
	draw_circle(P(0.74, 0.27), size.y * 0.035, g)
	_glow(P(0.74, 0.5), size.y * 0.35, Color(1, 0.95, 0.8, 0.5))


func _dusk(lone_figure: bool, village: bool) -> void:
	var top := _tinted(Color("2e2a55"))
	var mid := _tinted(Color("9c4f86"))
	var low := _tinted(Color("f0a07a"))
	_vgrad(top, mid, 0.0, 0.5)
	_vgrad(mid, low, 0.5, 1.0)
	draw_circle(P(0.3, 0.58), size.y * 0.1, Color(1.0, 0.9, 0.72, 0.9))
	_hills(0.62, 0.08, 1.0, _tinted(Color("9a5480")))
	_hills(0.72, 0.06, 2.4, _tinted(Color("713e6e")))
	draw_rect(Rect2(P(0, 0.8), P(1, 0.05)), Color(1.0, 0.78, 0.63, 0.45))
	var ground := _tinted(Color("2a1a36"))
	_hills(0.9, 0.03, 4.0, ground)
	if village:
		for i in 4:
			_hut(0.5 + i * 0.07, 0.9, 0.03, ground)
		_glow(P(0.62, 0.88), size.y * 0.12 * (0.9 + 0.1 * sin(_t * 11.0)), Color(1.0, 0.7, 0.35, 0.9))
		for i in 5:
			var fx := 0.42 + i * 0.09 + sin(_t * 0.3 + i) * 0.01
			_figure(fx, 0.9, 0.07, ground)
	if lone_figure:
		_figure(0.66, 0.84, 0.13, ground, true)


func _fire() -> void:
	_starfield(Color("04050e"), Color("0b1026"), 1.0)
	draw_rect(Rect2(P(0, 0.7), P(1, 0.3)), Color("0d0a0e"))
	var fl := 0.85 + 0.15 * sin(_t * 12.0) + 0.07 * sin(_t * 23.7)
	_glow(P(0.5, 0.74), size.y * 0.7 * fl, Color(1.0, 0.55, 0.22, 0.9))
	for k in 5:
		var off := (k - 2) * 0.012
		var hgt := (0.16 + 0.05 * sin(_t * 3.0 + k * 1.7)) * fl
		var col := Color(1.0, 0.45 + k * 0.08, 0.15, 0.7)
		draw_colored_polygon(PackedVector2Array([P(0.5 + off - 0.018, 0.76), P(0.5 + off + sin(_t * 4 + k) * 0.01, 0.76 - hgt), P(0.5 + off + 0.018, 0.76)]), col)
	for i in 7:
		var a := i / 7.0 * TAU + 0.4
		var x := 0.5 + cos(a) * 0.22
		var y := 0.77 + sin(a) * 0.05
		var c := Color("2a1610").lerp(Color("080506"), (sin(a) + 1.0) / 2.0)
		_figure(x, y, 0.12 + 0.03 * (sin(a) + 1.0) / 2.0, c)


func _fog() -> void:
	_vgrad(Color("6f8794"), Color("b7c6c8"))
	_hills(0.6, 0.08, 3.0, Color("64767f"))
	_hills(0.68, 0.05, 5.0, Color("4f5e66"))
	draw_rect(Rect2(P(0, 0.72), P(1, 0.28)), Color("3a454b"))
	for i in 7:
		var a := i / 7.0 * TAU + 0.2
		var x := 0.5 + cos(a) * 0.26
		var y := 0.8 + sin(a) * 0.06
		draw_rect(Rect2(P(x - 0.012, y - 0.14), P(0.024, 0.14)), Color("59656b"))
	for i in 10:
		var fx := fmod(i * 0.17 + _t * 0.03, 1.4) - 0.2
		_ellipse(P(fx, 0.55 + sin(i * 1.3) * 0.25), size.x * 0.18, size.y * 0.1, Color(0.9, 0.92, 0.94, 0.16))


func _storm() -> void:
	_vgrad(Color("1c2230"), Color("7c808e"))
	_hills(0.6, 0.08, 1.0, Color("4d5266"))
	_hills(0.72, 0.06, 2.4, Color("363b4d"))
	draw_rect(Rect2(P(0, 0.76), P(1, 0.24)), Color(0.5, 0.58, 0.7, 0.7))
	_hills(0.9, 0.03, 4.0, Color("191c26"))
	var r := RandomNumberGenerator.new()
	r.seed = 3
	for i in 90:
		var x := fmod(r.randf() + _t * 0.15, 1.0)
		var y := fmod(r.randf() + _t * (0.9 + r.randf() * 0.4), 1.0)
		draw_line(P(x, y), P(x, y) + Vector2(-4, 16), Color(0.82, 0.86, 0.92, 0.35), 1.0)
	if fmod(_t, 7.0) < 0.12:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.9, 0.92, 1.0, 0.35))


func _harvest() -> void:
	_starfield(Color("04050e"), Color("191440"), 1.0)
	_hills(0.88, 0.03, 4.0, Color("0d0a14"))
	for i in 5:
		_hut(0.38 + i * 0.06, 0.9, 0.025, Color("0d0a14"))
	for f in [0.36, 0.64]:
		draw_colored_polygon(PackedVector2Array([P(f - 0.04, 0.42), P(f, 0.06), P(f + 0.04, 0.42)]), Color(0.75, 0.75, 0.9, 0.18))
		draw_circle(P(f, 0.05), size.y * 0.03, Color(0.75, 0.75, 0.9, 0.25))
	for k in 14:
		var sx := 0.36 + k * 0.022
		var target := 0.36 if k < 7 else 0.64
		var a := P(sx, 0.86)
		var b := P(target, 0.4)
		draw_line(a, b, Color(1.0, 0.85, 0.5, 0.18), 1.5)
		var ph := fmod(_t * 0.4 + k * 0.13, 1.0)
		draw_circle(a.lerp(b, ph), 2.5, Color(1.0, 0.9, 0.6, 0.9 * (1.0 - ph)))


func _birth() -> void:
	_vgrad(Color("6a8fc0"), Color("f6c59a"), 0.0, 0.62)
	_vgrad(Color("f6c59a"), Color("ffe3b8"), 0.62, 1.0)
	var rise := minf(1.0, _t * 0.05)
	_glow(P(0.5, 0.66 - rise * 0.06), size.y * 0.5, Color(1.0, 0.85, 0.55, 0.9))
	draw_circle(P(0.5, 0.66 - rise * 0.06), size.y * 0.08, Color(1.0, 0.92, 0.7))
	_hills(0.66, 0.05, 1.5, Color("b07a7a"))
	draw_rect(Rect2(P(0, 0.74), P(1, 0.06)), Color(1.0, 0.95, 0.85, 0.55))
	_hills(0.88, 0.03, 4.0, Color("4a2e3e"))
	_hut(0.3, 0.88, 0.035, Color("4a2e3e"))
	_glow(P(0.3, 0.86), size.y * 0.06, Color(1.0, 0.75, 0.4, 0.8))
	for i in 3:
		var bx := 0.6 + i * 0.05 + _t * 0.01
		var by := 0.3 + i * 0.03
		draw_polyline(PackedVector2Array([P(bx - 0.01, by - 0.01), P(bx, by), P(bx + 0.01, by - 0.01)]), Color("4a2e3e"), 2.0)


func _time() -> void:
	_vgrad(Color("06060c"), Color("1a1630"))
	var c := P(0.5, 0.5)
	for k in 5:
		var r := size.y * (0.12 + k * 0.1)
		var a0 := _t * (0.15 - k * 0.025)
		draw_arc(c, r, a0, a0 + PI * 1.4, 64, Color(0.9, 0.85, 0.7, 0.18 + k * 0.03), 1.5)
	for s in _stars:
		var ang: float = s[3] + _t * 0.05
		var rad: float = s[0] * size.y * 0.55
		draw_circle(c + Vector2(cos(ang), sin(ang)) * rad, s[2] * 0.6, Color(0.9, 0.9, 1.0, 0.5))
