extends SceneTree
## Checks the story files for mistakes, then plays hundreds of games with four
## test players (see bots.gd) to make sure nothing breaks and to show how the
## numbers work out. Run from the project root:
##   godot --headless --path game --script res://tests/run_tests.gd

const ContentData := preload("res://scripts/content.gd")
const GameRules := preload("res://scripts/game_state.gd")
const Bots := preload("res://tests/bots.gd")
const RUNS := 300


func _initialize() -> void:
	var c = ContentData.new()
	c.load_all()
	if not c.errors.is_empty():
		print("CONTENT ERRORS:")
		for e in c.errors:
			print("  ", e)
		quit(1)
		return
	print("Content OK: %d discoveries, %d prayers, %d cutscenes, %d pages, %d people, %d endings" % [c.revelations.size(), c.prayers.size(), c.cutscenes.size(), c.pages.size(), c.characters.size(), c.endings.size()])
	var bots = Bots.new()
	var seen := {}
	for style in ["random", "kind", "wise", "cruel"]:
		var stats := {"endings": {}, "ranks": {}, "pct": 0, "earned": 0, "people": 0, "love": 0, "fear": 0, "casts": 0, "cast_wins": 0,
			"restless": 0, "granted": 0, "lost": 0, "missed": 0, "zones": {}}
		for run in RUNS:
			var g = _play(c, bots, run, style, seen, stats)
			if g == null:
				quit(1)
				return
			var eid: String = g.ending.get("id", "none")
			stats["endings"][eid] = stats["endings"].get(eid, 0) + 1
			stats["ranks"][g.rank()] = stats["ranks"].get(g.rank(), 0) + 1
			stats["pct"] += g.readable_percent()
			stats["earned"] += g.faith_earned
			stats["people"] += g.people
			stats["love"] += g.love
			stats["fear"] += g.fear
			stats["granted"] += g.granted.size()
			stats["lost"] += g.lost.filter(func(id): return id in g.seen_stars).size()
			stats["missed"] += g.missed.size()
		print("")
		print("%s player, %d games:" % [style.capitalize(), RUNS])
		print("  Endings:     ", stats["endings"])
		print("  Final ranks: ", stats["ranks"])
		print("  Avg her world: %d%%   lifetime faith: %d   people: %d   love: %d   fear: %d" % [stats["pct"] / RUNS, stats["earned"] / RUNS, stats["people"] / RUNS, stats["love"] / RUNS, stats["fear"] / RUNS])
		print("  Avg discoveries: %.1f   chances lost: %.1f   options out of reach: %.1f" % [stats["granted"] / float(RUNS), stats["lost"] / float(RUNS), stats["missed"] / float(RUNS)])
		print("  Casts won: %d of %d   Generations restless: %.1f per game   in danger zones: %s" % [stats["cast_wins"], stats["casts"], stats["restless"] / float(RUNS), stats["zones"]])
	var never: Array = []
	for p in c.prayers:
		if not seen.has(p["id"]):
			never.append(p["id"])
	for cs in c.cutscenes:
		if not seen.has(cs["id"]):
			never.append("cutscene " + cs["id"])
	print("")
	if never.is_empty():
		print("Every prayer and cutscene came up at least once.")
	else:
		print("Never came up: ", never)
	quit(0)


func _play(c, bots, run: int, style: String, seen: Dictionary, stats: Dictionary):
	var g = GameRules.new()
	g.start(c, run)
	var rng := RandomNumberGenerator.new()
	rng.seed = run * 7919 + style.length()
	var guard := 0
	var last_gen := 0
	while not g.over:
		guard += 1
		if guard > 3000:
			print("FAIL: %s game %d never ended (generation %d)" % [style, run, g.generation])
			return null
		if g.generation != last_gen:
			last_gen = g.generation
			if g.is_restless():
				stats["restless"] += 1
			for z in g.extremes():
				stats["zones"][z] = stats["zones"].get(z, 0) + 1
		while not g.scenes.is_empty():
			seen[g.scenes[0]["id"]] = true
			g.scene_seen(g.scenes[0])
		bots.try_grant(g, c, rng, style)
		var p: Dictionary = g.current_prayer()
		if p.is_empty():
			g.end_generation()
			continue
		seen[p["id"]] = true
		var pick: int = bots.pick(g, p, rng, style)
		if pick < 0:
			print("FAIL: stuck on prayer '%s' in generation %d with %d faith" % [p["id"], g.generation, g.faith])
			return null
		var ch: Dictionary = p["choices"][pick]
		var spend := 0
		if not ch["test"].is_empty() and style in ["kind", "wise"]:
			spend = g.max_spend(ch)
		var res: Dictionary = g.choose(pick, spend)
		if res.is_empty():
			print("FAIL: choice %d on '%s' was refused" % [pick, p["id"]])
			return null
		if not res["cast"].is_empty():
			stats["casts"] += 1
			if not res["failed"]:
				stats["cast_wins"] += 1
	return g
