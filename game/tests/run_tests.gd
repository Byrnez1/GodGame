extends SceneTree
## Checks the story files for mistakes, then plays hundreds of games with two
## test players to make sure nothing breaks and to show how the numbers work out:
##   random:  picks discoveries and choices at random
##   focused: tries to rebuild the world described in the journal
## Run from the project root:
##   godot --headless --path game --script res://tests/run_tests.gd

const ContentData := preload("res://scripts/content.gd")
const GameRules := preload("res://scripts/game_state.gd")
const RUNS := 300
## The discoveries the journal describes, in the order a focused player wants them.
const HER_WORLD := ["speech", "fire", "river", "song", "sunrise_burial", "weaving", "stone", "temple"]


func _initialize() -> void:
	var c = ContentData.new()
	c.load_all()
	if not c.errors.is_empty():
		print("CONTENT ERRORS:")
		for e in c.errors:
			print("  ", e)
		quit(1)
		return
	print("Content OK: %d discoveries, %d prayers, %d journal pages, %d listed words, %d endings" % [c.revelations.size(), c.prayers.size(), c.pages.size(), c.words.size(), c.endings.size()])
	var seen := {}
	for focused in [false, true]:
		var ending_counts := {}
		var rank_counts := {}
		var pct_sum := 0
		var earned_sum := 0
		var people_sum := 0
		for run in RUNS:
			var g = _play(c, run, focused, seen)
			if g == null:
				quit(1)
				return
			var eid: String = g.ending.get("id", "none")
			ending_counts[eid] = ending_counts.get(eid, 0) + 1
			rank_counts[g.rank()] = rank_counts.get(g.rank(), 0) + 1
			pct_sum += g.readable_percent()
			earned_sum += g.faith_earned
			people_sum += g.people
		print("")
		print("%s player, %d games:" % ["Focused" if focused else "Random", RUNS])
		print("  Endings:      ", ending_counts)
		print("  Final ranks:  ", rank_counts)
		print("  Avg her-world words readable: %d%%   Avg lifetime faith: %d   Avg people at end: %d" % [pct_sum / RUNS, earned_sum / RUNS, people_sum / RUNS])
	var never: Array = []
	for p in c.prayers:
		if not seen.has(p["id"]):
			never.append(p["id"])
	if not never.is_empty():
		print("")
		print("Prayers that never came up: ", never)
	quit(0)


func _play(c, run: int, focused: bool, seen: Dictionary):
	var g = GameRules.new()
	g.start(c, run)
	var rng := RandomNumberGenerator.new()
	rng.seed = run * 7919 + (1 if focused else 2)
	var guard := 0
	while not g.over:
		guard += 1
		if guard > 2000:
			print("FAIL: game %d never ended" % run)
			return null
		_try_grant(g, c, rng, focused)
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
		if focused:
			pick = _focused_choice(p, opts)
		g.choose(pick)
	return g


func _try_grant(g, c, rng: RandomNumberGenerator, focused: bool) -> void:
	if focused:
		for id in HER_WORLD:
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


## Prefers choices that grant part of her world, then kind answers, never silence.
func _focused_choice(p: Dictionary, opts: Array) -> int:
	var best: int = opts[0]
	var best_score := -999
	for i in opts:
		var ch: Dictionary = p["choices"][i]
		var score := 0
		for gid in ch["grants"]:
			score += 10 if gid in HER_WORLD else -10
		score += ch["love"] * 2 + ch["people"] - ch["fear"] + ch["faith"]
		if ch["silent"]:
			score -= 5
		if score > best_score:
			best_score = score
			best = i
	return best
