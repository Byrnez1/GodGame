extends Control
## A god's portrait in a round astral frame, drawn in code with a little movement.
## An image at res://assets/art/portraits/<style>.png replaces it.
##   you          a figure of soft light with no face
##   time         tall and still, with dust always falling around it
##   memory       a figure whose edges never hold still
##   golden_eyes  a dark figure with two golden eyes

var style := "":
	set(v):
		style = v
		_texture = null
		var path := "res://assets/art/portraits/%s.png" % v
		if ResourceLoader.exists(path):
			_texture = load(path)
		queue_redraw()

var _t := 0.0
var _texture: Texture2D = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_t += delta
		queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 3.0
	for k in 14:
		var f := 1.0 - k / 14.0
		draw_circle(c + Vector2(0, -r * 0.15) * (1.0 - f), r * f, Color(0.05 + 0.03 * k / 14.0, 0.08 + 0.06 * k / 14.0, 0.2 + 0.14 * k / 14.0))
	for i in 18:
		var a := i * 2.399
		var d := r * (0.25 + 0.7 * fmod(i * 0.381, 1.0))
		var tw := 0.3 + 0.3 * sin(_t * (0.8 + i * 0.07) + i)
		draw_circle(c + Vector2(cos(a), sin(a)) * d, 0.8, Color(0.85, 0.9, 1.0, tw))
	if _texture != null:
		draw_texture_rect(_texture, Rect2(c - Vector2(r, r) * 0.72, Vector2(r, r) * 1.44), false)
	else:
		match style:
			"you": _you(c, r)
			"time": _time(c, r)
			"memory": _memory(c, r)
			"golden_eyes": _golden(c, r)
			_: _figure(c, r, Color(0.2, 0.22, 0.32, 0.8))
	draw_arc(c, r, 0.0, TAU, 96, Color(0.78, 0.86, 1.0, 0.75), 2.0, true)
	draw_arc(c, r + 2.5, 0.0, TAU, 96, Color(0.78, 0.86, 1.0, 0.2), 1.0, true)


## A robed figure. Returns the head center.
func _figure(c: Vector2, r: float, col: Color, tall := 1.0, wide := 1.0) -> Vector2:
	var head := c + Vector2(0, -r * 0.38 * tall)
	var body := PackedVector2Array([
		c + Vector2(-r * 0.13 * wide, -r * 0.22 * tall),
		c + Vector2(r * 0.13 * wide, -r * 0.22 * tall),
		c + Vector2(r * 0.42 * wide, r * 0.72),
		c + Vector2(-r * 0.42 * wide, r * 0.72),
	])
	draw_colored_polygon(body, col)
	draw_circle(head, r * 0.14, col)
	return head


func _glow(p: Vector2, radius: float, col: Color) -> void:
	for k in 6:
		var f := 1.0 - k / 6.0
		draw_circle(p, radius * f, Color(col.r, col.g, col.b, col.a * (1.0 - f) * 0.4))


func _you(c: Vector2, r: float) -> void:
	_glow(c + Vector2(0, -r * 0.1), r * 0.9, Color(1.0, 0.88, 0.6, 0.6))
	var head := _figure(c, r, Color(1.0, 0.93, 0.78, 0.85))
	# Where a face should be, nothing; and a thin crack, like something broken off.
	draw_polyline(PackedVector2Array([head + Vector2(-r * 0.09, -r * 0.05), head + Vector2(-r * 0.02, 0), head + Vector2(r * 0.03, -r * 0.03), head + Vector2(r * 0.09, r * 0.04)]), Color(0.55, 0.45, 0.35, 0.8), 1.2, true)
	for k in 8:
		var ph := fmod(_t * 0.15 + k / 8.0, 1.0)
		var x := sin(k * 1.7 + _t * 0.4) * r * 0.3
		draw_circle(c + Vector2(x, r * 0.5 - ph * r * 1.1), 1.2, Color(1.0, 0.92, 0.7, 0.6 * (1.0 - ph)))


func _time(c: Vector2, r: float) -> void:
	_figure(c, r, Color(0.03, 0.03, 0.07, 0.95), 1.35, 0.7)
	# Fine dust, always falling, never landing.
	for k in 50:
		var dx := (fmod(k * 0.618, 1.0) - 0.5) * r * 1.4
		var ph := fmod(k * 0.271 + _t * 0.03, 1.0)
		var p := c + Vector2(dx, -r * 0.8 + ph * r * 1.6)
		if p.distance_to(c) < r - 2:
			draw_circle(p, 0.9, Color(0.95, 0.88, 0.7, 0.55 * sin(ph * PI)))


func _memory(c: Vector2, r: float) -> void:
	# The same figure, again and again, never quite in the same place.
	for k in 5:
		var off := Vector2(sin(_t * 0.6 + k * 1.3) * r * 0.08, cos(_t * 0.45 + k * 2.1) * r * 0.04)
		_figure(c + off, r, Color(0.78, 0.84, 0.95, 0.13))
	for k in 4:
		var ph := fmod(_t * 0.05 + k * 0.25, 1.0)
		var p := c + Vector2((-0.6 + ph * 1.2) * r, r * (0.2 + 0.15 * sin(k * 2.0)))
		draw_set_transform(p, 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, r * 0.3, Color(0.85, 0.9, 1.0, 0.07 * sin(ph * PI)))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _golden(c: Vector2, r: float) -> void:
	_glow(c, r * 0.8, Color(1.0, 0.8, 0.4, 0.3))
	var head := _figure(c, r, Color(0.06, 0.05, 0.08, 0.95))
	var blink := 1.0 if fmod(_t, 6.0) > 0.15 else 0.1
	for s in [-1, 1]:
		var e: Vector2 = head + Vector2(s * r * 0.055, 0)
		_glow(e, r * 0.08, Color(1.0, 0.8, 0.3, 0.9))
		draw_set_transform(e, 0.0, Vector2(1.0, blink * 0.6))
		draw_circle(Vector2.ZERO, r * 0.025, Color(1.0, 0.86, 0.4))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
