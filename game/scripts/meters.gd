extends Control
## The three vessels at the top of the screen: a glowing orb of faith, and two
## tubes for love and fear. The tubes mark their danger zones, and glow red
## when your people are in one. Hover over a vessel to read what it means.

const SCALE := 60.0  ## Love and fear are drawn out of this; anything above fills the tube.
const ORB := Vector2(34, 27)
const ORB_R := 20.0
const TUBE_W := 210.0
const TUBE_Y := 23.0
const TUBE_H := 20.0
const LOVE_X := 82.0
const FEAR_X := 318.0
const LOVE_LOW := Color("7a2335")
const LOVE_HIGH := Color("f3a65e")
const FEAR_LOW := Color("2a1c4c")
const FEAR_HIGH := Color("9a6ad6")
const DANGER := Color("e0505a")
const LABEL := Color("b9b2a2")

var faith := 0
var love := 0
var fear := 0
var love_cap := 100
var zones: Array = []  ## The danger zones your people are in right now
var terror_at := 40
var fearless_below := 4
var forsaken_below := 6

var _t := 0.0
var _love := 0.0
var _fear := 0.0
var _flash := 0.0
var _last_faith := -1
var _motes: Array = []


func _ready() -> void:
	custom_minimum_size = Vector2(FEAR_X + TUBE_W + 6, 60)
	tooltip_text = " "
	var r := RandomNumberGenerator.new()
	r.seed = 4
	for i in 26:
		_motes.append([r.randf(), r.randf(), r.randf_range(0.4, 1.2)])


func set_values(game) -> void:
	if _last_faith >= 0 and game.faith != _last_faith:
		_flash = 1.0
	_last_faith = game.faith
	faith = game.faith
	love = game.love
	fear = game.fear
	love_cap = game.love_cap()
	zones = game.extremes()
	terror_at = game.s("terror_at")
	fearless_below = game.s("fearless_below")
	forsaken_below = game.s("forsaken_below")


func _process(delta: float) -> void:
	_t += delta
	_love = lerpf(_love, float(love), clampf(delta * 4.0, 0.0, 1.0))
	_fear = lerpf(_fear, float(fear), clampf(delta * 4.0, 0.0, 1.0))
	_flash = maxf(0.0, _flash - delta * 1.5)
	queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	_draw_orb(font)
	# Love: danger at the bottom (forsaken). The far end is crowded out by fear.
	var lw := _love_word()
	_draw_tube(font, LOVE_X, "LOVE", lw[0], lw[1], _love, LOVE_LOW, LOVE_HIGH, "forsaken" in zones)
	_zone(LOVE_X, 0.0, forsaken_below, DANGER, "forsaken" in zones)
	if love_cap < SCALE:
		_crowded(LOVE_X, love_cap)
	# Fear: danger at both ends (fearless, terrified).
	var fw := _fear_word()
	_draw_tube(font, FEAR_X, "FEAR", fw[0], fw[1], _fear, FEAR_LOW, FEAR_HIGH, "fearless" in zones or "terrified" in zones)
	_zone(FEAR_X, 0.0, fearless_below, Color("bcd4ff"), "fearless" in zones)
	_zone(FEAR_X, terror_at, SCALE, DANGER, "terrified" in zones)


func _draw_orb(font: Font) -> void:
	var pulse := 0.5 + 0.5 * sin(_t * 1.8)
	for k in 7:
		var f := 1.0 - k / 7.0
		draw_circle(ORB, ORB_R * (1.0 + 0.9 * f + _flash * 0.6), Color(1.0, 0.85, 0.45, 0.035 + 0.02 * pulse))
	for k in 6:
		var a := k * TAU / 6.0 + _t * 0.15
		draw_line(ORB + Vector2(cos(a), sin(a)) * (ORB_R + 2), ORB + Vector2(cos(a), sin(a)) * (ORB_R + 7 + 3 * pulse), Color(1.0, 0.9, 0.6, 0.35), 1.0, true)
	draw_circle(ORB, ORB_R, Color("3a2a12"))
	for k in 8:
		var f := 1.0 - k / 8.0
		draw_circle(ORB + Vector2(0, -2) * (1.0 - f), ORB_R * f, Color(1.0, 0.78 + 0.02 * k, 0.4 + 0.05 * k, 0.16))
	draw_arc(ORB, ORB_R, 0.0, TAU, 48, Color(1.0, 0.9, 0.65, 0.8), 1.5, true)
	var txt := str(faith)
	draw_string(font, ORB + Vector2(-ORB_R, 7), txt, HORIZONTAL_ALIGNMENT_CENTER, ORB_R * 2, 19, Color(1, 0.98, 0.92))
	draw_string(font, Vector2(ORB.x - 30, 59), "FAITH", HORIZONTAL_ALIGNMENT_CENTER, 60, 10, LABEL)


## Vertical extent of the tube at x (it has round ends).
func _extent(x0: float, x: float) -> Vector2:
	var r := TUBE_H / 2.0
	var cy := TUBE_Y + r
	var half := r
	if x < x0 + r:
		var dx := x0 + r - x
		half = sqrt(maxf(0.0, r * r - dx * dx))
	elif x > x0 + TUBE_W - r:
		var dx := x - (x0 + TUBE_W - r)
		half = sqrt(maxf(0.0, r * r - dx * dx))
	return Vector2(cy - half, cy + half)


func _tube_x(x0: float, value: float) -> float:
	return x0 + clampf(value / SCALE, 0.0, 1.0) * TUBE_W


func _draw_tube(font: Font, x0: float, title: String, word: String, word_color: Color, value: float, low: Color, high: Color, danger: bool) -> void:
	draw_string(font, Vector2(x0 + 2, 15), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, LABEL)
	draw_string(font, Vector2(x0, 15), word, HORIZONTAL_ALIGNMENT_RIGHT, TUBE_W - 2, 12, word_color)
	# The glass.
	for x in range(int(x0), int(x0 + TUBE_W)):
		var e := _extent(x0, x + 0.5)
		draw_line(Vector2(x + 0.5, e.x), Vector2(x + 0.5, e.y), Color(0.09, 0.09, 0.13), 1.0)
	# The liquid, with slow bands of light moving through it.
	var fill_x := _tube_x(x0, value)
	for x in range(int(x0), int(fill_x)):
		var e := _extent(x0, x + 0.5)
		var f := (x - x0) / TUBE_W
		var col := low.lerp(high, clampf(f * 1.4, 0.0, 1.0))
		var band := 0.5 + 0.5 * sin(x * 0.09 - _t * 1.6)
		col = col.lightened(0.12 * band)
		draw_line(Vector2(x + 0.5, e.x + 1), Vector2(x + 0.5, e.y - 1), col, 1.0)
	# A bright leading edge, and motes drifting inside.
	if value > 0.5:
		var e := _extent(x0, fill_x - 1)
		for k in 4:
			draw_line(Vector2(fill_x - 1 - k, e.x + 1), Vector2(fill_x - 1 - k, e.y - 1), Color(1, 1, 1, 0.22 - k * 0.05), 1.0)
		for m in _motes:
			var mx: float = x0 + fmod(m[0] + _t * 0.02 * m[2], 1.0) * (fill_x - x0)
			var my: float = TUBE_Y + 4 + fmod(m[1] + sin(_t * m[2] + m[0] * 9.0) * 0.1 + 1.0, 1.0) * (TUBE_H - 8)
			draw_circle(Vector2(mx, my), 0.9, Color(1, 1, 1, 0.35))
	# The rim. It pulses red when your people are in a danger zone.
	var rim := Color(0.75, 0.75, 0.82, 0.45)
	if danger:
		rim = DANGER.lerp(Color.WHITE, 0.2)
		rim.a = 0.55 + 0.45 * sin(_t * 5.0)
	var pts := PackedVector2Array()
	var r := TUBE_H / 2.0
	for i in 17:
		var a := PI / 2 + i * PI / 16
		pts.append(Vector2(x0 + r, TUBE_Y + r) + Vector2(cos(a), sin(a)) * r)
	for i in 17:
		var a := -PI / 2 + i * PI / 16
		pts.append(Vector2(x0 + TUBE_W - r, TUBE_Y + r) + Vector2(cos(a), sin(a)) * r)
	pts.append(pts[0])
	draw_polyline(pts, rim, 1.5 if danger else 1.0, true)


## Marks a danger zone along a tube: a thin colored band underneath, with ticks.
func _zone(x0: float, from: float, to: float, color: Color, active: bool) -> void:
	var a := _tube_x(x0, from)
	var b := _tube_x(x0, to)
	var c := color
	c.a = 0.9 if active else 0.5
	draw_line(Vector2(a, TUBE_Y + TUBE_H + 4), Vector2(b, TUBE_Y + TUBE_H + 4), c, 3.0)
	for x in [a, b]:
		if x > x0 + 1 and x < x0 + TUBE_W - 1:
			draw_line(Vector2(x, TUBE_Y - 1), Vector2(x, TUBE_Y + TUBE_H + 6), Color(c.r, c.g, c.b, 0.7), 1.0)


## The part of the love tube that fear has crowded out: love can't grow past here.
func _crowded(x0: float, cap: float) -> void:
	var a := _tube_x(x0, cap)
	var x := a
	while x < x0 + TUBE_W - 2:
		var e := _extent(x0, x)
		draw_line(Vector2(x, e.y - 2), Vector2(minf(x + 6, x0 + TUBE_W - 2), e.x + 2), Color(0.55, 0.4, 0.75, 0.45), 1.0)
		x += 5
	draw_line(Vector2(a, TUBE_Y - 2), Vector2(a, TUBE_Y + TUBE_H + 2), Color(0.7, 0.55, 0.95, 0.9), 1.5)


func _love_word() -> Array:
	if "forsaken" in zones:
		return ["forsaken", DANGER]
	if love < forsaken_below:
		return ["cold", Color("c9a0a0")]
	if love < 15:
		return ["warm", Color("e8b48a")]
	if love < 30:
		return ["devoted", Color("f3c27e")]
	return ["adoring", Color("ffd79a")]


func _fear_word() -> Array:
	if "terrified" in zones:
		return ["terrified", DANGER]
	if "fearless" in zones:
		return ["fearless", Color("bcd4ff")]
	if fear < fearless_below:
		return ["unafraid", Color("a9b4c8")]
	if fear < 15:
		return ["wary", Color("b9a6d8")]
	if fear < 28:
		return ["afraid", Color("c49ae0")]
	return ["dread", Color("e08aa8")]


func _get_tooltip(at_position: Vector2) -> String:
	if at_position.x < LOVE_X - 6:
		return "FAITH: your power. Spend it on discoveries and miracles.\nEvery generation it flows in from love (slowly) and fear (quickly)."
	if at_position.x < FEAR_X - 6:
		var t := "LOVE: gives faith slowly, calms unrest, helps your people grow.\nIt fades every generation unless you tend it."
		t += "\n\nDANGER (red mark): too little love and your people feel FORSAKEN.\nFewer children are born, and the young grow bitter."
		if love_cap < SCALE:
			t += "\n\nThe hatched end: fear has crowded love out. Love can't grow past it."
		return t
	var f := "FEAR: gives faith quickly and barely fades, but stirs unrest\nand crowds out love."
	f += "\n\nDANGER (pale mark): too little fear and your people are FEARLESS.\nThey stop bringing offerings."
	f += "\nDANGER (red mark): too much and they are TERRIFIED.\nEvery generation, some flee into the hills."
	return f
