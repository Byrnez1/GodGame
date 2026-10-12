extends RefCounted
## Test players, used by run_tests.gd and trace.gd.
##   random:  picks discoveries and choices at random
##   kind:    rebuilds her world, prefers love, pours faith into casts
##   wise:    like kind, but keeps a little fear so the people still take it seriously
##   cruel:   prefers fear and power, takes every offering

const HER_WORLD := ["speech", "fire", "river", "song", "sunrise_burial", "weaving", "stargazing", "pottery", "stone", "temple", "story_keepers", "herbs", "boats", "calendar"]
const POWER := ["speech", "fire", "idols", "spear", "offerings", "sky_burial", "wandering", "song", "priesthood", "stone", "war_drum", "walls", "blood_rites", "herding", "temple"]


func try_grant(g, c, rng: RandomNumberGenerator, style: String) -> void:
	if style == "random":
		var avail: Array = []
		for id in c.revelation_order:
			if g.can_grant(id) == "":
				avail.append(id)
		if not avail.is_empty() and rng.randf() < 0.7:
			g.grant(avail[rng.randi() % avail.size()])
		return
	var order: Array = POWER if style == "cruel" else HER_WORLD
	for id in order:
		if g.can_grant(id) == "":
			g.grant(id)
			return


func pick(g, p: Dictionary, rng: RandomNumberGenerator, style: String) -> int:
	var opts: Array = []
	for i in p["choices"].size():
		if g.choice_check(p["choices"][i]) == "":
			opts.append(i)
	if opts.is_empty():
		return -1
	if style == "random":
		return opts[rng.randi() % opts.size()]
	var best: int = opts[0]
	var best_score := -9999.0
	for i in opts:
		var ch: Dictionary = p["choices"][i]
		var fx: Dictionary = ch["ok"]
		var score := 0.0
		var world: Array = POWER if style == "cruel" else HER_WORLD
		for gid in ch["grants"]:
			score += 10 if gid in world else -10
		if style == "cruel":
			score += fx["fear"] * 2 + fx["faith"] - fx["love"]
			if "broke_with_fear" in fx["sets"]:
				score += 50
		else:
			var fear_weight := 2.0
			if style == "wise" and g.fear < 8:
				fear_weight = -0.5  # a little fear is healthy
			score += fx["love"] * 2 + fx["people"] - fx["fear"] * fear_weight - ch["cost"] * 0.5
			if not ch["needs"].is_empty() and not ch["needs"] in ["spirit", "deity", "god"]:
				score += 6  # the option your discoveries opened up
			if "blood_on_the_river" in fx["sets"] or "kept_cycle" in fx["sets"] or "took_the_gift" in fx["sets"]:
				score -= 50
			if "broke_with_love" in fx["sets"]:
				score += 50
		if ch["silent"]:
			score -= 3
		if score > best_score:
			best_score = score
			best = i
	return best
