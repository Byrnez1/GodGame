extends RefCounted
## The rules of the prototype, and everything about the current playthrough.
## No visuals here: the screen (main.gd) reads this and calls its actions.
##
## Three currencies pull against each other:
##   faith  is power you spend. Each generation it comes from love and fear.
##   fear   gives faith fast and never fades, but breeds unrest and crowds out love.
##   love   gives faith slowly, fades unless tended, calms unrest, helps people grow.
## And each has a danger zone (see settings.txt):
##   terrified  too much fear: people flee
##   fearless   too little fear: the offerings dwindle
##   forsaken   too little love: fewer children, more bitterness

const RANKS := ["whisper", "spirit", "deity", "god"]
const RANK_NAMES := {"whisper": "Whisper", "spirit": "Spirit", "deity": "Deity", "god": "God"}

var c  ## The loaded content (content.gd)
var generation := 1
var faith := 0
var faith_earned := 0  ## Lifetime faith; decides your rank
var people := 0
var love := 0
var fear := 0
var unrest := 0
var granted: Array = []    ## Discoveries your people have (including forgotten ones)
var forgotten: Array = []  ## Discoveries Memory has taken
var closed: Array = []     ## Paths shut by an earlier choice
var lost: Array = []       ## Discoveries whose moment passed before you granted them
var seen_stars: Array = [] ## Discoveries that have appeared in the heavens
var new_stars: Array = []  ## ...since the screen last showed them
var flags := {}            ## Story facts set by choices and cutscenes: flag -> generation it was set
var used: Array = []       ## Prayers and cutscenes that already happened
var queue: Array = []      ## Prayers waiting this generation
var scenes: Array = []     ## Cutscenes waiting to be shown this generation
var met: Array = []        ## People in the god's notes
var met_gen := {}          ## person -> generation first met
var notes: Array = []      ## Notes learned about people ("person:index")
var new_notes: Array = []  ## Notes learned since the screen last showed them
var interference := {}     ## god -> how many times you've felt their hand
var missed: Array = []     ## {"gen", "text"}: things you couldn't do for lack of a discovery
var granted_this_gen := false
var answered_gen := 0      ## Last generation a prayer was answered in
var answered := 0
var unanswered := 0
var log_entries: Array = []  ## {"gen", "text"} for the Chronicle
var gen_report: Array = []   ## What happened as this generation began (danger zones, lost chances)
var fresh: Array = []        ## Discoveries/flags whose words became readable this generation
var over := false
var ending := {}
var epilogue_lines: Array = []
var last_income := {"love": 0, "fear": 0}
var rng := RandomNumberGenerator.new()

var _tok_re := RegEx.create_from_string("[A-Za-z][A-Za-z']*|[^A-Za-z]+")
var _pending_extremes: Array = []


func start(content, seed_value: int = -1) -> void:
	c = content
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	generation = 1
	faith = s("starting_faith")
	love = s("starting_love")
	fear = s("starting_fear")
	people = s("starting_people")
	_begin_generation(true)
	new_stars.clear()


func s(key: String):
	return c.settings[key]


# ---------------------------------------------------------------- queries

func rank() -> String:
	var r := "whisper"
	for name in ["spirit", "deity", "god"]:
		if faith_earned >= s("rank_" + name):
			r = name
	return r


func rank_at_least(name: String) -> bool:
	return RANKS.find(rank()) >= RANKS.find(name)


## Returns [rank name, faith needed] for the next rank, or [] at the top.
func next_rank() -> Array:
	var i := RANKS.find(rank())
	if i >= RANKS.size() - 1:
		return []
	var nxt: String = RANKS[i + 1]
	return [nxt, s("rank_" + nxt)]


## True if the people have this discovery (and haven't forgotten it), or this flag is set.
func has(x: String) -> bool:
	return (x in granted and not (x in forgotten)) or flags.has(x)


func love_cap() -> int:
	return maxi(0, 100 - fear * int(s("fear_crowds_love")))


func mood() -> String:
	if unrest >= s("restless_at"):
		return "restless"
	if love > fear:
		return "loved"
	if fear > love:
		return "feared"
	return "calm"


func is_restless() -> bool:
	return unrest >= s("restless_at")


func is_terrified() -> bool:
	return fear >= s("terror_at")


func is_fearless() -> bool:
	return generation >= s("fearless_from") and fear < s("fearless_below")


func is_forsaken() -> bool:
	return generation >= s("forsaken_from") and love < s("forsaken_below")


## The danger zones your people are in right now.
func extremes() -> Array:
	var out: Array = []
	if is_terrified():
		out.append("terrified")
	if is_fearless():
		out.append("fearless")
	if is_forsaken():
		out.append("forsaken")
	return out


## Faith coming next generation, split by source.
func income_parts() -> Dictionary:
	var from_love := floori(float(love) / float(maxi(1, s("love_per_faith"))))
	var from_fear := floori(float(fear) / float(maxi(1, s("fear_per_faith"))))
	var bonus := 0
	for id in granted:
		if has(id):
			bonus += c.revelations[id]["income"]
	if people <= 0:
		return {"love": 0, "fear": 0, "bonus": 0}
	return {"love": from_love, "fear": from_fear, "bonus": bonus}


func income() -> int:
	var p := income_parts()
	return p["love"] + p["fear"] + p["bonus"]


func growth() -> int:
	var total: int = s("base_growth") + floori(love / 20.0) - floori(fear / 25.0)
	for id in granted:
		if has(id):
			total += c.revelations[id]["growth"]
	if is_restless():
		total -= 2
	if is_forsaken():
		total -= s("forsaken_growth")
	return total


## How far you can see through the fog in the heavens (1, or more with Reading the Stars).
func sight() -> int:
	var total := 1
	for id in granted:
		if has(id):
			total += c.revelations[id]["sight"]
	return total


## What a person or god is called right now ("The quiet Voice" becomes "Memory").
func display_name(person: Dictionary) -> String:
	var n: String = person["name"]
	for rn in person["renamed"]:
		if has(rn[0]):
			n = rn[1]
	return n


## Does a set of conditions (from any content file) hold right now?
func conds_ok(cond: Dictionary) -> bool:
	if generation < cond["when"].x or generation > cond["when"].y:
		return false
	for r in cond["requires"]:
		if not has(r):
			return false
	for b in cond["blocks"]:
		if has(b) or b in closed:
			return false
	for a in cond["after"]:
		if not flags.has(a[0]) and not (a[0] in granted):
			return false
		var since: int = flags.get(a[0], generation)
		if generation - since < a[1]:
			return false
	if cond["rank"] != "" and not rank_at_least(cond["rank"]):
		return false
	match cond["mood"]:
		"loved":
			if not love > fear:
				return false
		"feared":
			if not fear > love:
				return false
		"restless":
			if not is_restless():
				return false
		"calm":
			if is_restless():
				return false
		"terrified":
			if not is_terrified():
				return false
		"fearless":
			if not is_fearless():
				return false
		"forsaken":
			if not is_forsaken():
				return false
	var j: Vector2i = cond["journal"]
	if j.x > -9999 or j.y < 9999:
		var pct := readable_percent()
		if pct < j.x or pct > j.y:
			return false
	var sil: Vector2i = cond["silence"]
	if unanswered < sil.x or unanswered > sil.y:
		return false
	if cond["people"] == "none" and people > 0:
		return false
	return true


func current_prayer() -> Dictionary:
	return queue[0] if not queue.is_empty() else {}


## Empty string if the choice can be picked, otherwise the reason it can't.
func choice_check(ch: Dictionary) -> String:
	var nd: String = ch["needs"]
	if nd in RANKS and not rank_at_least(nd):
		return "Only a %s could do this" % RANK_NAMES[nd]
	if c.revelations.has(nd) and not has(nd):
		return "Your people would need %s" % c.revelations[nd]["name"]
	if ch["cost"] > faith:
		return "Needs %d faith" % ch["cost"]
	for g in ch["grants"]:
		if g in closed:
			return "That path is closed"
	return ""


func grant_cost(id: String) -> int:
	var cost: int = c.revelations[id]["cost"]
	if id in forgotten:
		return ceili(cost / 2.0)
	return cost


## Has the story revealed this discovery yet? ("appears" = any of these flags; "from" = generation)
func appeared(id: String) -> bool:
	var r: Dictionary = c.revelations[id]
	if generation < r["from"]:
		return false
	if r["appears"].is_empty():
		return true
	for x in r["appears"]:
		if flags.has(x) or x in granted:
			return true
	return false


## How a discovery shows in the heavens: "shown", "faint" (a glimpse in the fog), or "hidden".
func star_visibility(id: String) -> String:
	if id in granted or id in seen_stars:
		return "shown"
	if id in closed or id in lost:
		return "hidden"
	var r: Dictionary = c.revelations[id]
	var all_met := true
	var any_met := false
	for q in r["requires"]:
		if has(q):
			any_met = true
		else:
			all_met = false
	if all_met and appeared(id):
		return "shown"
	if r["requires"].is_empty() or any_met:
		return "faint"
	if sight() >= 2:
		for q in r["requires"]:
			if star_visibility(q) == "shown":
				return "faint"
	return "hidden"


## Empty string if this discovery can be granted now, otherwise the reason it can't.
func can_grant(id: String) -> String:
	var r: Dictionary = c.revelations[id]
	if id in granted and not (id in forgotten):
		return "Already granted"
	if id in closed:
		return "Path closed"
	if id in lost:
		return "Its moment has passed"
	for q in r["requires"]:
		if not has(q):
			return "Needs %s" % c.revelations[q]["name"]
	if not appeared(id):
		return "Your people aren't ready to see it yet"
	if not rank_at_least(r["rank"]):
		return "Only a %s could grant this" % RANK_NAMES[r["rank"]]
	if granted_this_gen:
		return "One discovery per generation"
	if grant_cost(id) > faith:
		return "Needs %d faith" % grant_cost(id)
	return ""


## Returns [state, reason]. State is granted, forgotten, closed, lost, available, or locked.
func revelation_state(id: String) -> Array:
	if id in forgotten:
		return ["forgotten", can_grant(id)]
	if id in granted:
		return ["granted", ""]
	if id in closed:
		return ["closed", ""]
	if id in lost:
		return ["lost", ""]
	var why := can_grant(id)
	if why == "":
		return ["available", ""]
	return ["locked", why]


# ---------------------------------------------------------------- journal

func journal_found() -> bool:
	return flags.has("journal_found")


func visible_pages() -> Array:
	if not journal_found():
		return []
	return c.pages.filter(func(p): return conds_ok(p["cond"]))


## Splits text into words and the spaces/punctuation between them.
func tokens(text: String) -> Array:
	var out: Array = []
	for m in _tok_re.search_all(text):
		var t := m.get_string()
		var first := t.unicode_at(0)
		out.append({"text": t, "is_word": (first >= 65 and first <= 90) or (first >= 97 and first <= 122)})
	return out


func concept_of(word: String) -> String:
	return c.words.get(word.to_lower(), c.settings["common_words"])


func readable(word: String) -> bool:
	return has(concept_of(word))


## x = readable words, y = total words, across the pages the god can see.
func journal_counts() -> Vector2i:
	var total := 0
	var ok := 0
	for page in visible_pages():
		for tok in tokens(page["text"]):
			if tok["is_word"]:
				total += 1
				if readable(tok["text"]):
					ok += 1
	return Vector2i(ok, total)


## How much of her world is rebuilt: the share of the journal's key words
## (words tied to discoveries in words.txt) that are readable, across ALL pages.
func readable_percent() -> int:
	var total := 0
	var ok := 0
	for page in c.pages:
		for tok in tokens(page["text"]):
			if tok["is_word"] and c.is_key_word(tok["text"]):
				total += 1
				if readable(tok["text"]):
					ok += 1
	if total == 0:
		return 0
	return roundi(100.0 * ok / total)


## True if words tied to this discovery appear on a page the god can see.
func journal_answers(id: String) -> bool:
	for page in visible_pages():
		for tok in tokens(page["text"]):
			if tok["is_word"] and c.words.get(tok["text"].to_lower(), "") == id:
				return true
	return false


# ---------------------------------------------------------------- actions

## The bonus a currency gives when casting the bones.
func cast_bonus(stat: String) -> int:
	match stat:
		"love":
			return floori(float(love) / float(maxi(1, s("love_per_bonus"))))
		"fear":
			return floori(float(fear) / float(maxi(1, s("fear_per_bonus"))))
		"faith":
			return RANKS.find(rank()) * int(s("rank_bonus"))
	return 0


## How many bones' worth of faith the player may pour in (1 faith = +1).
func max_spend(ch: Dictionary) -> int:
	return clampi(faith - ch["cost"], 0, s("max_faith_on_cast"))


## A feeling for the odds, without exact numbers. Needed = what the bones must show.
func odds_word(ch: Dictionary, spend: int) -> String:
	var needed: int = ch["test"]["target"] - cast_bonus(ch["test"]["stat"]) - spend
	if needed <= 7:
		return "Likely"
	if needed <= 10:
		return "Even"
	if needed <= 13:
		return "Hard"
	return "Desperate"


## Picks a choice. spend = extra faith poured into a cast.
## Returns {"result", "failed", "cast": {} or {"bones", "bonus", "spend", "target", "total"}}.
func choose(index: int, spend := 0) -> Dictionary:
	var p := current_prayer()
	if p.is_empty() or index < 0 or index >= p["choices"].size():
		return {}
	var ch: Dictionary = p["choices"][index]
	if choice_check(ch) != "":
		return {}
	var who: String = p["speaker"] if p["speaker"] != "" else "A prayer"
	# Remember the doors that were shut because your people lacked something.
	for oi in p["choices"].size():
		var other: Dictionary = p["choices"][oi]
		var nd: String = other["needs"]
		if oi != index and c.revelations.has(nd) and not has(nd):
			missed.append({"gen": generation, "text": "%s: \"%s\" was out of reach without %s." % [who, other["text"], c.revelations[nd]["name"]]})
	if p["by"] != "":
		interference[p["by"]] = interference.get(p["by"], 0) + 1
	faith -= ch["cost"]
	var failed := false
	var cast := {}
	if not ch["test"].is_empty():
		spend = clampi(spend, 0, max_spend(ch))
		faith -= spend
		var bones := [rng.randi_range(1, 6), rng.randi_range(1, 6), rng.randi_range(1, 6)]
		var bonus := cast_bonus(ch["test"]["stat"])
		var total: int = bones[0] + bones[1] + bones[2] + bonus + spend
		failed = total < ch["test"]["target"]
		cast = {"bones": bones, "bonus": bonus, "spend": spend, "target": ch["test"]["target"], "total": total, "stat": ch["test"]["stat"]}
	var fx: Dictionary = ch["fail"] if failed else ch["ok"]
	_apply(fx)
	if not failed:
		for g in ch["grants"]:
			_grant(g)
	for f in (ch["fail_forgets"] if failed else []) + ch["forgets"]:
		_forget(f)
	for x in ch["closes"]:
		if not x in granted and not x in closed:
			closed.append(x)
			_add_log("The path of %s closes." % c.revelations[x]["name"])
	if ch["silent"]:
		unanswered += 1
		if love > 0:
			love = maxi(0, love - s("silence_hurts_love"))
	else:
		answered += 1
	used.append(p["id"])
	answered_gen = generation
	queue.pop_front()
	_add_log("%s: you chose \"%s\"%s." % [who, ch["text"], " (it went wrong)" if failed else ""])
	if ch["ends"] or people <= 0:
		_finish()
	update_notes()
	return {"result": fx["result"], "failed": failed, "cast": cast}


func grant(id: String) -> bool:
	if can_grant(id) != "":
		return false
	faith -= grant_cost(id)
	granted_this_gen = true
	_grant(id)
	update_notes()
	return true


## Call when the screen has shown a cutscene.
func scene_seen(cs: Dictionary) -> void:
	scenes.erase(cs)
	for fl in cs["sets"]:
		_set_flag(fl)
	# A cutscene can change what should happen this generation (e.g. a birth before the final choice).
	if answered_gen != generation:
		_pick_prayers()
	update_notes()


## Learns any notes about people whose conditions are now true (notes stay learned),
## and notices any new stars in the heavens.
func update_notes() -> void:
	for person in c.characters:
		if not person["id"] in met and conds_ok(person["cond"]):
			met.append(person["id"])
			met_gen[person["id"]] = generation
		if not person["id"] in met:
			continue
		for n in person["notes"]:
			if not n["key"] in notes and conds_ok(n["cond"]):
				notes.append(n["key"])
				new_notes.append(n["key"])
	for id in c.revelation_order:
		if not id in seen_stars and star_visibility(id) == "shown":
			seen_stars.append(id)
			if not id in granted:
				new_stars.append(id)


func end_generation() -> void:
	if over or not queue.is_empty():
		return
	if generation >= s("generations"):
		_finish()
		return
	_pending_extremes = extremes()
	generation += 1
	_begin_generation(false)


# ---------------------------------------------------------------- internals

func _apply(fx: Dictionary) -> void:
	_gain(fx["faith"])
	people = maxi(0, people + fx["people"])
	fear = clampi(fear + fx["fear"], 0, 100)
	love = clampi(love + fx["love"], 0, love_cap())
	unrest = maxi(0, unrest + fx["unrest"])
	for fl in fx["sets"]:
		_set_flag(fl)


func _set_flag(fl: String) -> void:
	if not flags.has(fl):
		flags[fl] = generation
		if not fl in fresh:
			fresh.append(fl)


func _begin_generation(first: bool) -> void:
	fresh.clear()
	gen_report.clear()
	granted_this_gen = false
	if first:
		_add_log("You wake.")
	else:
		var parts := income_parts()
		last_income = parts
		_gain(parts["love"] + parts["fear"] + parts["bonus"])
		# The danger zones your people were in when the generation ended.
		if "fearless" in _pending_extremes:
			var loss := mini(faith, int(s("fearless_faith_loss")))
			faith -= loss
			_report("Your people have stopped fearing you. Fewer offerings reach the flat rock (%d faith lost)." % loss)
		if "terrified" in _pending_extremes:
			var fled := maxi(1, roundi(people * s("terror_flee") / 100.0))
			people = maxi(0, people - fled)
			unrest += 2
			_report("Your people live in terror of the sky. %d fled into the hills in the night." % fled)
		if "forsaken" in _pending_extremes:
			unrest += s("forsaken_unrest")
			_report("Your people feel forsaken. Fewer children are born, and the young grow bitter.")
		var born := 0
		if people > 0:
			born = maxi(0, roundi(people * growth() / 100.0))
		people += born
		var faded := roundi(love * s("love_fade") / 100.0)
		fear = maxi(0, fear - roundi(fear * s("fear_fade") / 100.0))
		love = maxi(0, love - faded)
		var stir := floori(float(fear) / float(maxi(1, s("fear_unrest"))))
		var calm := floori(float(love) / float(maxi(1, s("love_calms"))))
		unrest = maxi(0, unrest + stir - calm)
		love = mini(love, love_cap())
		_add_log("A new generation. Faith from love: %d. From fear: %d. %d children born." % [parts["love"], parts["fear"] + parts["bonus"], born])
		# Chances that came and went.
		for id in c.revelation_order:
			var r: Dictionary = c.revelations[id]
			if r["until"] > 0 and generation > r["until"] and not id in granted and not id in closed and not id in lost:
				lost.append(id)
				if id in seen_stars:
					_report(r["lost"] if r["lost"] != "" else "The moment for %s has passed." % r["name"])
	scenes = c.cutscenes.filter(func(cs): return not (cs["once"] and cs["id"] in used) and conds_ok(cs["cond"]))
	for cs in scenes:
		used.append(cs["id"])
	_pick_prayers()
	update_notes()


func _report(text: String) -> void:
	gen_report.append(text)
	_add_log(text)


func _pick_prayers() -> void:
	queue.clear()
	var fixed: Array = []
	var pool: Array = []
	for p in c.prayers:
		if p["once"] and p["id"] in used:
			continue
		if not conds_ok(p["cond"]):
			continue
		if p["cond"]["when"].x == p["cond"]["when"].y:
			fixed.append(p)  # written for exactly this generation: always shown
		else:
			pool.append(p)
	var finals := fixed.filter(func(p): return p["kind"] == "final")
	if not finals.is_empty():
		queue = finals
		return
	queue.append_array(fixed)
	var want: int = s("prayers_per_generation")
	# Unrest and the danger zones push one of their prayers to the front of the line.
	# Only one, so the rest of the story keeps moving.
	var crises: Array = []
	if is_restless():
		crises.append("restless")
	crises.append_array(extremes())
	var crisis_pool := pool.filter(func(p): return p["cond"]["mood"] in crises)
	if not crisis_pool.is_empty() and queue.size() < want:
		var pick = crisis_pool[rng.randi() % crisis_pool.size()]
		queue.append(pick)
		pool.erase(pick)
	# Other crisis prayers wait their turn.
	pool = pool.filter(func(p): return not p["cond"]["mood"] in crises)
	while queue.size() < want and not pool.is_empty():
		var total := 0
		for p in pool:
			total += maxi(0, p["weight"])
		var roll := rng.randi_range(1, maxi(1, total))
		var pick = pool[0]
		for p in pool:
			roll -= maxi(0, p["weight"])
			if roll <= 0:
				pick = p
				break
		queue.append(pick)
		pool.erase(pick)


func _gain(n: int) -> void:
	var before := rank()
	faith = maxi(0, faith + n)
	if n > 0:
		faith_earned += n
	var after := rank()
	if after != before:
		_add_log("Your people's faith has made you stronger. You are now a %s." % RANK_NAMES[after])


func _grant(id: String) -> void:
	var r: Dictionary = c.revelations[id]
	if id in forgotten:
		forgotten.erase(id)
		_add_log("%s returns to your people." % r["name"])
	elif not id in granted:
		granted.append(id)
		lost.erase(id)
		fear = clampi(fear + r["fear"], 0, 100)
		love = clampi(love + r["love"], 0, love_cap())
		_add_log("Your people discover %s." % r["name"])
	else:
		return
	for x in r["excludes"]:
		if not x in granted and not x in closed:
			closed.append(x)
			_add_log("The path of %s closes." % c.revelations[x]["name"])
	if not id in fresh:
		fresh.append(id)


func _forget(id: String) -> void:
	if id in granted and not id in forgotten:
		forgotten.append(id)
		fresh.erase(id)
		_add_log("Your people forget %s. Its words go dark in the journal." % c.revelations[id]["name"])


func _finish() -> void:
	over = true
	queue.clear()
	scenes.clear()
	ending = {}
	for e in c.endings:
		if conds_ok(_ignore_when(e["cond"])):
			ending = e
			break
	epilogue_lines.clear()
	for e in c.epilogues:
		if conds_ok(_ignore_when(e["cond"])):
			epilogue_lines.append(e["text"])
	_add_log("The age ends.")


## Endings can happen at any generation, so their 'when' is ignored.
func _ignore_when(cond: Dictionary) -> Dictionary:
	var d := cond.duplicate()
	d["when"] = Vector2i(1, 9999)
	return d


func _add_log(text: String) -> void:
	log_entries.append({"gen": generation, "text": text})
