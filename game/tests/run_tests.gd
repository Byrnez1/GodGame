extends SceneTree
## Checks the story files for mistakes, then plays hundreds of games with three
## test players to make sure nothing breaks and to show how the numbers work out:
##   random:  picks discoveries and choices at random
##   kind:    rebuilds her world, prefers love, pours faith into casts
##   cruel:   prefers fear and power, takes every offering
## Run from the project root:
##   godot --headless --path game --script res://tests/run_tests.gd

const ContentData := preload("res://scripts/content.gd")
const GameRules := preload("res://scripts/game_state.gd")
const RUNS := 300
const HER_WORLD := ["speech", "fire", "river", "song", "sunrise_burial", "weaving", "stone", "temple"]
const POWER := ["speech", "fire", "spear", "offerings", "sky_burial", "song", "stone", "war_drum", "temple", "wandering"]


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
	var seen := {}
	for style in ["random", "kind", "cruel"]:
		var stats := {"endings": {}, "ranks": {}, "pct": 0, "earned": 0, "people": 0, "love": 0, "fear": 0, "casts": 0, "cast_wins": 0, "restless": 0}
		for run in RUNS:
			var g = _play(c, run, style, seen, stats)
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
		print("")
		print("%s player, %d games:" % [style.capitalize(), RUNS])
		print("  Endings:     ", stats["endings"])
		print("  Final ranks: ", stats["ranks"])
		print("  Avg her world: %d%%   lifetime faith: %d   people: %d   love: %d   fear: %d" % [stats["pct"] / RUNS, stats["earned"] / RUNS, stats["people"] / RUNS, stats["love"] / RUNS, stats["fear"] / RUNS])
		print("  Casts won: %d of %d   Generations spent restless: %d" % [stats["cast_wins"], stats["casts"], stats["restless"]])
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


func _play(c, run: int, style: String, seen: Dictionary, stats: Dictionary):
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
		while not g.scenes.is_empty():
			seen[g.scenes[0]["id"]] = true
			g.scene_seen(g.scenes[0])
		_try_grant(g, c, rng, style)
		var p: Dictionary = g.current_prayer()
		if p.is_empty():
			g.end_generation()
			continue
		seen[p["id"]] = true
		var opts: Array = []
		for i in p["choices"].size():
			if g.choice_check(p["choices"][i]) == "":
				opts.append(i)
		if opts.is_empty():
			print("FAIL: stuck on prayer '%s' in generation %d with %d faith" % [p["id"], g.generation, g.faith])
			return null
		var pick: int = opts[rng.randi() % opts.size()]
		if style != "random":
			pick = _styled_choice(p, opts, style)
		var ch: Dictionary = p["choices"][pick]
		var spend := 0
		if not ch["test"].is_empty():
			spend = g.max_spend(ch) if style == "kind" else 0
		var res: Dictionary = g.choose(pick, spend)
		if res.is_empty():
			print("FAIL: choice %d on '%s' was refused" % [pick, p["id"]])
			return null
		if not res["cast"].is_empty():
			stats["casts"] += 1
			if not res["failed"]:
				stats["cast_wins"] += 1
	return g


func _try_grant(g, c, rng: RandomNumberGenerator, style: String) -> void:
	var order: Array = HER_WORLD if style == "kind" else POWER
	if style != "random":
		for id in order:
			if g.can_grant(id) == "":
				g.grant(id)
				return
		return
	var avail: Array = []
	for id in c.revelation_order:
		if g.can_grant(id) == "":
			avail.append(id)
	if not avail.is_empty() and rng.randf() < 0.7:
		g.grant(avail[rng.randi() % avail.size()])


func _styled_choice(p: Dictionary, opts: Array, style: String) -> int:
	var best: int = opts[0]
	var best_score := -9999
	for i in opts:
		var ch: Dictionary = p["choices"][i]
		var fx: Dictionary = ch["ok"]
		var score := 0
		var world: Array = HER_WORLD if style == "kind" else POWER
		for gid in ch["grants"]:
			score += 10 if gid in world else -10
		if style == "kind":
			score += fx["love"] * 2 + fx["people"] - fx["fear"] * 2
			if "blood_on_the_river" in fx["sets"] or "kept_cycle" in fx["sets"]:
				score -= 50
			if "broke_with_love" in fx["sets"]:
				score += 50
		else:
			score += fx["fear"] * 2 + fx["faith"] - fx["love"]
			if "broke_with_fear" in fx["sets"]:
				score += 50
		if ch["silent"]:
			score -= 3
		if score > best_score:
			best_score = score
			best = i
	return best
