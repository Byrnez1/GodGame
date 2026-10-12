extends SceneTree
## Plays one game with the kind test player and prints every step (for balancing).
##   godot --headless --path game --script res://tests/trace.gd -- kind 3

const ContentData := preload("res://scripts/content.gd")
const GameRules := preload("res://scripts/game_state.gd")
const Bots := preload("res://tests/bots.gd")


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var style: String = args[0] if args.size() > 0 else "kind"
	var seed_v: int = args[1].to_int() if args.size() > 1 else 1
	var c = ContentData.new()
	c.load_all()
	var t = Bots.new()
	var g = GameRules.new()
	g.start(c, seed_v)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var last := 0
	while not g.over:
		if g.generation != last:
			last = g.generation
			print("== GEN %d  faith %d  love %d  fear %d  unrest %d  people %d  rank %s  zones %s  report %s" % [g.generation, g.faith, g.love, g.fear, g.unrest, g.people, g.rank(), g.extremes(), g.gen_report])
		while not g.scenes.is_empty():
			print("   [scene] ", g.scenes[0]["id"])
			g.scene_seen(g.scenes[0])
		var before: Array = g.granted.duplicate()
		t.try_grant(g, c, rng, style)
		for id in g.granted:
			if not id in before:
				print("   grant ", id)
		var p: Dictionary = g.current_prayer()
		if p.is_empty():
			g.end_generation()
			continue
		var pick: int = t.pick(g, p, rng, style)
		var ch: Dictionary = p["choices"][pick]
		var res: Dictionary = g.choose(pick, g.max_spend(ch) if style == "kind" else 0)
		print("   %s -> %s%s   (love %d fear %d faith %d)" % [p["id"], ch["text"], " FAILED" if res.get("failed", false) else "", g.love, g.fear, g.faith])
	print("ENDING: ", g.ending.get("id", ""), "  her world ", g.readable_percent(), "%  granted ", g.granted, "  lost ", g.lost)
	quit(0)
