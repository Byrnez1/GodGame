extends RefCounted
## The rules of the prototype, and everything about the current playthrough.
## No visuals here: the screen (main.gd) reads this and calls its actions.

const RANKS := ["whisper", "spirit", "deity", "god"]
const RANK_NAMES := {"whisper": "Whisper", "spirit": "Spirit", "deity": "Deity", "god": "God"}

var c  ## The loaded content (content.gd)
var generation := 1
var faith := 0
var faith_earned := 0  ## Lifetime faith; decides your rank
var people := 0
var love := 0
var fear := 0
var granted: Array = []    ## Discoveries your people have (including forgotten ones)
var forgotten: Array = []  ## Discoveries Memory has taken
var closed: Array = []     ## Paths shut by an earlier choice
var flags: Array = []      ## Story facts set by choices, e.g. "sana_heard"
var used: Array = []       ## Prayers already answered
var queue: Array = []      ## Prayers waiting this generation
var granted_this_gen := false
var answered := 0
var unanswered := 0
var log_entries: Array = []  ## {"gen", "text"} for the Pantheon view
var fresh: Array = []        ## Discoveries whose words became readable this generation
var over := false
var ending := {}
var rng := RandomNumberGenerator.new()

var _tok_re := RegEx.create_from_string("[A-Za-z][A-Za-z']*|[^A-Za-z]+")


func start(content, seed_value: int = -1) -> void:
	c = content
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	generation = 1
	faith = s("starting_faith")
	faith_earned = 0
	people = s("starting_people")
	_begin_generation(true)


func s(key: String):
	return c.settings[key]


# ---------------------------------------------------------------- queries

func rank() -> String:
	var r := "whisper"
	if faith_earned >= s("rank_spirit"):
		r = "spirit"
	if faith_earned >= s("rank_deity"):
		r = "deity"
	if faith_earned >= s("rank_god"):
		r = "god"
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


## True if the people have this discovery (and haven't forgotten it), or a choice set this flag.
func has(x: String) -> bool:
	return (x in granted and not (x in forgotten)) or x in flags


func income() -> int:
	var total := floori(float(people) / float(s("people_per_faith")))
	for id in granted:
		if has(id):
			total += c.revelations[id]["income"]
	return total


func growth() -> int:
	var total: int = s("base_growth")
	for id in granted:
		if has(id):
			total += c.revelations[id]["growth"]
	return total


func current_prayer() -> Dictionary:
	return queue[0] if not queue.is_empty() else {}


## Empty string if the choice can be picked, otherwise the reason it can't.
func choice_check(ch: Dictionary) -> String:
	if ch["needs"] != "" and not rank_at_least(ch["needs"]):
		return "You must be a %s" % RANK_NAMES[ch["needs"]]
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


## Empty string if this discovery can be granted now, otherwise the reason it can't.
func can_grant(id: String) -> String:
	var r: Dictionary = c.revelations[id]
	if id in granted and not (id in forgotten):
		return "Already granted"
	if id in closed:
		return "Path closed"
	for q in r["requires"]:
		if not has(q):
			return "Needs %s" % c.revelations[q]["name"]
	if not rank_at_least(r["rank"]):
		return "You must be a %s" % RANK_NAMES[r["rank"]]
	if granted_this_gen:
		return "One revelation per generation"
	if grant_cost(id) > faith:
		return "Needs %d faith" % grant_cost(id)
	return ""


## Returns [state, reason]. State is granted, forgotten, closed, available, or locked.
func revelation_state(id: String) -> Array:
	if id in forgotten:
		return ["forgotten", can_grant(id)]
	if id in granted:
		return ["granted", ""]
	if id in closed:
		return ["closed", ""]
	var why := can_grant(id)
	if why == "":
		return ["available", ""]
	return ["locked", why]


# ---------------------------------------------------------------- journal

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


## x = readable words, y = total words, across every journal page.
func journal_counts() -> Vector2i:
	var total := 0
	var ok := 0
	for page in c.pages:
		for tok in tokens(page["text"]):
			if tok["is_word"]:
				total += 1
				if readable(tok["text"]):
					ok += 1
	return Vector2i(ok, total)


## Like journal_counts, but only the key words listed in words.txt: the ones
## that show whether her world is being rebuilt. Endings use this.
func key_counts() -> Vector2i:
	var total := 0
	var ok := 0
	for page in c.pages:
		for tok in tokens(page["text"]):
			if tok["is_word"] and c.words.has(tok["text"].to_lower()):
				total += 1
				if readable(tok["text"]):
					ok += 1
	return Vector2i(ok, total)


func readable_percent() -> int:
	var n := key_counts()
	if n.y == 0:
		return 0
	return roundi(100.0 * n.x / n.y)


# ---------------------------------------------------------------- actions

func choose(index: int) -> String:
	var p := current_prayer()
	if p.is_empty() or index < 0 or index >= p["choices"].size():
		return ""
	var ch: Dictionary = p["choices"][index]
	if choice_check(ch) != "":
		return ""
	faith -= ch["cost"]
	_gain(ch["faith"])
	people = maxi(0, people + ch["people"])
	love += ch["love"]
	fear += ch["fear"]
	for fl in ch["sets"]:
		if not fl in flags:
			flags.append(fl)
	for g in ch["grants"]:
		_grant(g)
	for f in ch["forgets"]:
		_forget(f)
	if ch["silent"]:
		unanswered += 1
	else:
		answered += 1
	used.append(p["id"])
	queue.pop_front()
	var who: String = p["speaker"] if p["speaker"] != "" else "A prayer"
	_add_log("%s: you chose \"%s\"." % [who, ch["text"]])
	if people <= 0:
		_finish()
	return ch["result"]


func grant(id: String) -> bool:
	if can_grant(id) != "":
		return false
	faith -= grant_cost(id)
	granted_this_gen = true
	_grant(id)
	return true


func end_generation() -> void:
	if over or not queue.is_empty():
		return
	if generation >= s("generations"):
		_finish()
		return
	generation += 1
	_begin_generation(false)


# ---------------------------------------------------------------- internals

func _begin_generation(first: bool) -> void:
	fresh.clear()
	granted_this_gen = false
	if first:
		_add_log("You wake.")
	else:
		var inc := income()
		_gain(inc)
		var born := 0
		if people > 0:
			born = maxi(1, roundi(people * growth() / 100.0))
		people += born
		_add_log("A new generation. Worship brings %d faith. %d children are born." % [inc, born])
	_pick_prayers()


func _pick_prayers() -> void:
	queue.clear()
	var fixed: Array = []
	var pool: Array = []
	for p in c.prayers:
		if _eligible(p):
			if p["when"].x == p["when"].y:
				fixed.append(p)  # written for exactly this generation: always shown
			else:
				pool.append(p)
	queue.append_array(fixed)
	var want: int = s("prayers_per_generation")
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


func _eligible(p: Dictionary) -> bool:
	if p["once"] and p["id"] in used:
		return false
	if generation < p["when"].x or generation > p["when"].y:
		return false
	for r in p["requires"]:
		if not has(r):
			return false
	for b in p["blocks"]:
		if has(b) or b in closed:
			return false
	return true


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
		love += r["love"]
		fear += r["fear"]
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
	var pct := readable_percent()
	for e in c.endings:
		var cond: Dictionary = e["condition"]
		var ok := false
		match cond["type"]:
			"no_people":
				ok = people <= 0
			"readable":
				ok = people > 0 and pct >= cond["value"]
			"always":
				ok = true
		if ok:
			ending = e
			break
	_add_log("The first age ends.")


func _add_log(text: String) -> void:
	log_entries.append({"gen": generation, "text": text})
