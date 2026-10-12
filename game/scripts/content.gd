extends RefCounted
## Loads every story file in res://content/ and checks it for mistakes.
## Problems are collected in `errors` as plain-language messages with the
## file and line number, so they can be shown on screen instead of crashing.

const ROOT := "res://content"
const RANKS := ["whisper", "spirit", "deity", "god"]
const MOODS := ["loved", "feared", "restless", "calm", "terrified", "fearless", "forsaken"]
## Settings that decide WHEN something can happen. Prayers, cutscenes,
## journal pages, and endings all understand these.
const CONDITION_FIELDS := ["when", "requires", "blocks", "after", "rank", "mood", "journal", "people", "silence"]
const REVELATION_FIELDS := ["name", "rank", "cost", "requires", "excludes", "income", "growth", "love", "fear", "glimpse", "appears", "from", "until", "lost", "sight"]
const PRAYER_FIELDS := ["speaker", "once", "weight", "kind", "picture", "by"]
const CHOICE_FIELDS := ["cost", "faith", "people", "love", "fear", "unrest", "sets", "grants", "forgets", "closes", "silent", "needs", "result", "ends",
	"test", "fail_result", "fail_faith", "fail_people", "fail_love", "fail_fear", "fail_unrest", "fail_sets", "fail_forgets"]
const CUTSCENE_FIELDS := ["picture", "sets", "once"]
const CHARACTER_FIELDS := ["name", "title", "group", "portrait", "renamed"]
const TEST_STATS := ["love", "fear", "faith"]
const PAGE_FIELDS := ["order", "title", "sketch", "ink"]
const ENDING_FIELDS := ["title", "kind", "condition"]
const SETTING_DEFAULTS := {
	"generations": 15,
	"starting_people": 30,
	"starting_faith": 4,
	"starting_love": 0,
	"starting_fear": 0,
	"love_per_faith": 4,
	"fear_per_faith": 2,
	"love_fade": 15,
	"fear_fade": 5,
	"fear_crowds_love": 2,
	"fear_unrest": 4,
	"love_calms": 6,
	"restless_at": 6,
	"silence_hurts_love": 3,
	"base_growth": 3,
	"prayers_per_generation": 2,
	"love_per_bonus": 6,
	"fear_per_bonus": 6,
	"rank_bonus": 2,
	"max_faith_on_cast": 5,
	"rank_spirit": 20,
	"rank_deity": 60,
	"rank_god": 130,
	"terror_at": 40,
	"terror_flee": 8,
	"fearless_below": 4,
	"fearless_from": 4,
	"fearless_faith_loss": 3,
	"forsaken_below": 6,
	"forsaken_from": 4,
	"forsaken_growth": 3,
	"forsaken_unrest": 2,
	"common_words": "speech",
}

var settings := {}
var revelations := {}
var revelation_order: Array = []
var prayers: Array = []
var cutscenes: Array = []
var pages: Array = []
var words := {}
var endings: Array = []
var epilogues: Array = []
var characters: Array = []
var errors: Array = []

var _field_re := RegEx.create_from_string("^([A-Za-z][A-Za-z _]*):\\s*(.*)$")
var _all_flags := {}
var _word_lines := {}


func load_all() -> void:
	_load_settings(ROOT + "/settings.txt")
	for path in _txt_files(ROOT + "/revelations"):
		for b in _parse_blocks(path):
			_add_revelation(b)
	for path in _txt_files(ROOT + "/prayers"):
		for b in _parse_blocks(path):
			_add_prayer(b)
	for path in _txt_files(ROOT + "/cutscenes"):
		for b in _parse_blocks(path):
			_add_cutscene(b)
	for path in _txt_files(ROOT + "/journal"):
		if path.get_file().to_lower() == "words.txt":
			_load_words(path)
		else:
			for b in _parse_blocks(path):
				_add_page(b)
	for path in _txt_files(ROOT + "/endings"):
		for b in _parse_blocks(path):
			_add_ending(b)
	for path in _txt_files(ROOT + "/characters"):
		for b in _parse_blocks(path):
			_add_character(b)
	pages.sort_custom(func(a, b): return a["order"] < b["order"])
	_check_links()


## True if a journal word belongs to a discovery (part of "her world"), not a story flag.
func is_key_word(w: String) -> bool:
	return revelations.has(words.get(w.to_lower(), ""))


# ---------------------------------------------------------------- reading files

func _txt_files(dir_path: String) -> Array:
	var out: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for f in dir.get_files():
		if f.get_extension().to_lower() == "txt" and f.to_lower() != "readme.txt":
			out.append(dir_path + "/" + f)
	out.sort()
	return out


## Splits a file into entries. Each entry starts with "=== name", then
## optional "key: value" settings, a blank line, the story text, and
## optional choices starting with ">" (each followed by indented settings).
func _parse_blocks(path: String) -> Array:
	var blocks: Array = []
	if not FileAccess.file_exists(path):
		_err(path, 0, "This file couldn't be found.")
		return blocks
	var lines := FileAccess.get_file_as_string(path).replace("\r\n", "\n").replace("\r", "\n").split("\n")
	var cur := {}
	var stage := ""
	var last_key := ""
	for i in lines.size():
		var raw: String = lines[i]
		var n := i + 1
		var line := raw.strip_edges()
		if line.begins_with("#"):
			continue
		if line.begins_with("==="):
			if not cur.is_empty():
				blocks.append(_finish_block(cur))
			var id := line.substr(3).strip_edges().to_lower().replace(" ", "_")
			if id == "":
				_err(path, n, "This '===' line needs a name after it, like '=== river_flood'.")
			cur = {"id": id, "file": path, "line": n, "fields": {}, "body": [], "body_lines": [], "choices": []}
			stage = "header"
			last_key = ""
			continue
		if cur.is_empty():
			if line != "":
				_err(path, n, "This text comes before the first entry. Every entry starts with a line like '=== river_flood'.")
			continue
		if line.begins_with(">"):
			var ctext := line.substr(1).strip_edges()
			if ctext == "":
				_err(path, n, "This choice is empty. Write the choice after the '>'.")
			cur["choices"].append({"text": ctext, "fields": {}, "line": n})
			stage = "choices"
			last_key = ""
			continue
		match stage:
			"header":
				if line == "":
					stage = "body"
				else:
					var kv := _field(line)
					if kv.is_empty():
						stage = "body"
						cur["body"].append(line)
						cur["body_lines"].append(n)
					else:
						_set_field(cur["fields"], kv)
			"body":
				cur["body"].append(line)
				cur["body_lines"].append(n)
			"choices":
				if line == "":
					continue
				var ckv := _field(line)
				if not ckv.is_empty():
					_set_field(cur["choices"].back()["fields"], ckv)
					last_key = ckv["key"]
				elif last_key in ["result", "fail_result"]:
					var cf: Dictionary = cur["choices"].back()["fields"]
					cf[last_key] = cf[last_key] + " " + line
				else:
					_err(path, n, "This line is below the choices, but it isn't a choice setting like 'cost: 3'. Story text belongs above the first '>' line.")
	if not cur.is_empty():
		blocks.append(_finish_block(cur))
	return blocks


func _finish_block(b: Dictionary) -> Dictionary:
	b["text"] = _paragraphs(b["body"])
	return b


func _paragraphs(lines: Array) -> String:
	var paras := PackedStringArray()
	var curp := PackedStringArray()
	for l in lines:
		if l == "":
			if not curp.is_empty():
				paras.append(" ".join(curp))
				curp = PackedStringArray()
		else:
			curp.append(l)
	if not curp.is_empty():
		paras.append(" ".join(curp))
	return "\n\n".join(paras)


func _field(line: String) -> Dictionary:
	var m := _field_re.search(line)
	if m == null:
		return {}
	return {"key": m.get_string(1).strip_edges().to_lower().replace(" ", "_"), "value": m.get_string(2).strip_edges()}


func _set_field(fields: Dictionary, kv: Dictionary) -> void:
	var k: String = kv["key"]
	if fields.has(k):
		fields[k] = fields[k] + ", " + kv["value"]
	else:
		fields[k] = kv["value"]


# ---------------------------------------------------------------- value helpers

func _err(path: String, line: int, msg: String) -> void:
	var where := path.replace(ROOT + "/", "content/")
	if line > 0:
		errors.append("%s, line %d: %s" % [where, line, msg])
	else:
		errors.append("%s: %s" % [where, msg])


func _num(v: String, path: String, line: int, key: String) -> int:
	var parts := v.strip_edges().split(" ", false)
	var t: String = parts[0] if parts.size() > 0 else ""
	t = t.replace("+", "").replace("%", "")
	if not t.is_valid_int():
		_err(path, line, "'%s' should be a whole number, like '%s: 3' or '%s: -2'." % [key, key, key])
		return 0
	return t.to_int()


func _list(v: String) -> Array:
	var out: Array = []
	for part in v.split(","):
		var p := part.strip_edges().to_lower().replace(" ", "_")
		if p != "":
			out.append(p)
	return out


func _yes(v: String) -> bool:
	return v.strip_edges().to_lower() in ["yes", "true", "y"]


func _check_fields(fields: Dictionary, allowed: Array, path: String, line: int, what: String) -> void:
	for k in fields.keys():
		if not k in allowed:
			_err(path, line, "'%s' isn't a setting %s can use. Allowed settings: %s." % [k, what, ", ".join(PackedStringArray(allowed))])


## Reads the shared "when can this happen" settings.
func _conditions(f: Dictionary, path: String, line: int) -> Dictionary:
	var cond := {
		"when": _when(str(f.get("when", "any")), path, line),
		"requires": _list(str(f.get("requires", ""))),
		"blocks": _list(str(f.get("blocks", ""))),
		"after": [],
		"rank": str(f.get("rank", "")).strip_edges().to_lower(),
		"mood": str(f.get("mood", "")).strip_edges().to_lower(),
		"journal": _range(str(f.get("journal", "")), path, line, "journal"),
		"people": str(f.get("people", "")).strip_edges().to_lower(),
		"silence": _range(str(f.get("silence", "")), path, line, "silence"),
	}
	if cond["rank"] != "" and not cond["rank"] in RANKS:
		_err(path, line, "'rank' must be one of: whisper, spirit, deity, god.")
		cond["rank"] = ""
	if cond["mood"] != "" and not cond["mood"] in MOODS:
		_err(path, line, "'mood' must be one of: loved, feared, restless, calm, terrified, fearless, forsaken.")
		cond["mood"] = ""
	if cond["people"] != "" and cond["people"] != "none":
		_err(path, line, "'people' can only be 'none' (everyone has died).")
		cond["people"] = ""
	for part in str(f.get("after", "")).split(","):
		var bits := part.strip_edges().split(" ", false)
		if bits.is_empty():
			continue
		var gens := 1
		if bits.size() > 1:
			gens = _num(bits[1], path, line, "after")
		cond["after"].append([bits[0].to_lower(), gens])
	return cond


func _when(v: String, path: String, line: int) -> Vector2i:
	var r := _range(v, path, line, "when")
	return Vector2i(maxi(1, r.x), r.y)


## Reads "3" (exactly), "3+" (3 or more), "3-6", "under 40", or "" (anything).
func _range(v: String, path: String, line: int, key: String) -> Vector2i:
	v = v.strip_edges().to_lower().replace("%", "")
	if v == "" or v == "any":
		return Vector2i(-9999, 9999)
	if v.ends_with("+"):
		var a := v.trim_suffix("+").strip_edges()
		if a.is_valid_int():
			return Vector2i(a.to_int(), 9999)
	elif v.begins_with("under "):
		var u := v.substr(6).strip_edges()
		if u.is_valid_int():
			return Vector2i(-9999, u.to_int() - 1)
	elif v.contains("-"):
		var parts := v.split("-")
		if parts.size() == 2 and parts[0].strip_edges().is_valid_int() and parts[1].strip_edges().is_valid_int():
			return Vector2i(parts[0].strip_edges().to_int(), parts[1].strip_edges().to_int())
	elif v.is_valid_int():
		return Vector2i(v.to_int(), v.to_int())
	_err(path, line, "'%s' should look like '3' (exactly), '3+' (3 or more), '3-6', or 'under 3'." % key)
	return Vector2i(-9999, 9999)


# ---------------------------------------------------------------- entries

func _load_settings(path: String) -> void:
	settings = SETTING_DEFAULTS.duplicate()
	if not FileAccess.file_exists(path):
		return
	var lines := FileAccess.get_file_as_string(path).replace("\r\n", "\n").split("\n")
	for i in lines.size():
		var line := lines[i].split("#")[0].strip_edges()
		if line == "":
			continue
		var kv := _field(line)
		if kv.is_empty():
			_err(path, i + 1, "Settings look like 'generations: 15'.")
			continue
		var k: String = kv["key"]
		if not SETTING_DEFAULTS.has(k):
			_err(path, i + 1, "'%s' isn't a known setting." % k)
		elif SETTING_DEFAULTS[k] is int:
			settings[k] = _num(kv["value"], path, i + 1, k)
		else:
			settings[k] = String(kv["value"]).to_lower()


func _add_revelation(b: Dictionary) -> void:
	var f: Dictionary = b["fields"]
	var path: String = b["file"]
	var line: int = b["line"]
	var id: String = b["id"]
	_check_fields(f, REVELATION_FIELDS, path, line, "a discovery")
	if revelations.has(id):
		_err(path, line, "There are two discoveries named '%s'. Each name must be different." % id)
		return
	if not b["choices"].is_empty():
		_err(path, line, "Discoveries can't have '>' choices.")
	var r := {
		"id": id,
		"name": str(f.get("name", id.capitalize())),
		"rank": str(f.get("rank", "whisper")).to_lower(),
		"cost": _num(str(f.get("cost", "5")), path, line, "cost"),
		"requires": _list(str(f.get("requires", ""))),
		"excludes": _list(str(f.get("excludes", ""))),
		"income": _num(str(f.get("income", "0")), path, line, "income"),
		"growth": _num(str(f.get("growth", "0")), path, line, "growth"),
		"love": _num(str(f.get("love", "0")), path, line, "love"),
		"fear": _num(str(f.get("fear", "0")), path, line, "fear"),
		"glimpse": str(f.get("glimpse", "")),
		"appears": _list(str(f.get("appears", ""))),
		"from": _num(str(f.get("from", "1")), path, line, "from"),
		"until": _num(str(f.get("until", "0")), path, line, "until"),
		"lost": str(f.get("lost", "")),
		"sight": _num(str(f.get("sight", "0")), path, line, "sight"),
		"text": b["text"],
		"file": path,
		"line": line,
	}
	if not r["rank"] in RANKS:
		_err(path, line, "'rank' must be one of: whisper, spirit, deity, god.")
		r["rank"] = "whisper"
	revelations[id] = r
	revelation_order.append(id)


func _add_prayer(b: Dictionary) -> void:
	var f: Dictionary = b["fields"]
	var path: String = b["file"]
	var line: int = b["line"]
	_check_fields(f, CONDITION_FIELDS + PRAYER_FIELDS, path, line, "a prayer")
	var p := {
		"id": b["id"],
		"cond": _conditions(f, path, line),
		"speaker": str(f.get("speaker", "")),
		"once": not str(f.get("once", "yes")).strip_edges().to_lower() in ["no", "false", "n"],
		"weight": _num(str(f.get("weight", "10")), path, line, "weight"),
		"kind": str(f.get("kind", "")).strip_edges().to_lower(),
		"picture": str(f.get("picture", "")).strip_edges().to_lower(),
		"by": str(f.get("by", "")).strip_edges().to_lower(),
		"text": b["text"],
		"choices": [],
		"file": path,
		"line": line,
	}
	for ch in b["choices"]:
		var cf: Dictionary = ch["fields"]
		var cl: int = ch["line"]
		_check_fields(cf, CHOICE_FIELDS, path, cl, "a choice")
		var c := {
			"text": ch["text"],
			"cost": _num(str(cf.get("cost", "0")), path, cl, "cost"),
			"needs": str(cf.get("needs", "")).strip_edges().to_lower(),
			"silent": _yes(str(cf.get("silent", "no"))),
			"ends": _yes(str(cf.get("ends", "no"))),
			"grants": _list(str(cf.get("grants", ""))),
			"forgets": _list(str(cf.get("forgets", ""))),
			"fail_forgets": _list(str(cf.get("fail_forgets", ""))),
			"closes": _list(str(cf.get("closes", ""))),
			"test": _test(str(cf.get("test", "")), path, cl),
			"line": cl,
			"ok": _effects(cf, "", path, cl),
			"fail": _effects(cf, "fail_", path, cl),
		}
		# 'needs' is either a rank or a discovery; discoveries are checked in _check_links.
		c["needs"] = c["needs"].replace(" ", "_")
		if not c["test"].is_empty() and str(cf.get("fail_result", "")) == "":
			_err(path, cl, "This choice casts the bones, so it needs a 'fail_result' saying what happens when the cast fails.")
		for fl in c["ok"]["sets"] + c["fail"]["sets"]:
			_all_flags[fl] = true
		p["choices"].append(c)
	if p["choices"].is_empty():
		_err(path, line, "Prayer '%s' needs at least one choice (a line starting with '>')." % p["id"])
	else:
		var has_free := false
		for c in p["choices"]:
			if c["cost"] <= 0 and c["needs"] == "":
				has_free = true
		if not has_free:
			_err(path, line, "Prayer '%s' needs at least one choice that costs nothing and needs no rank, so the player can never get stuck." % p["id"])
	prayers.append(p)


## "love 12" means: cast three bones (3-18), add the Love bonus, and succeed on 12 or more.
func _test(v: String, path: String, line: int) -> Dictionary:
	v = v.strip_edges().to_lower()
	if v == "":
		return {}
	var bits := v.split(" ", false)
	if bits.size() != 2 or not bits[0] in TEST_STATS or not bits[1].is_valid_int():
		_err(path, line, "'test' should look like 'love 12', 'fear 10', or 'faith 14': what guides the bones, then the total needed (3 to 18).")
		return {}
	return {"stat": bits[0], "target": bits[1].to_int()}


## The effects of a choice. prefix "" = when it works, "fail_" = when a cast fails.
func _effects(cf: Dictionary, prefix: String, path: String, line: int) -> Dictionary:
	return {
		"faith": _num(str(cf.get(prefix + "faith", "0")), path, line, prefix + "faith"),
		"people": _num(str(cf.get(prefix + "people", "0")), path, line, prefix + "people"),
		"love": _num(str(cf.get(prefix + "love", "0")), path, line, prefix + "love"),
		"fear": _num(str(cf.get(prefix + "fear", "0")), path, line, prefix + "fear"),
		"unrest": _num(str(cf.get(prefix + "unrest", "0")), path, line, prefix + "unrest"),
		"sets": _list(str(cf.get(prefix + "sets", ""))),
		"result": str(cf.get(prefix + "result", "")),
	}


## A cutscene is a series of panels separated by a line containing only "---".
## A panel can start with "picture: name" to change the picture.
func _add_cutscene(b: Dictionary) -> void:
	var f: Dictionary = b["fields"]
	var path: String = b["file"]
	var line: int = b["line"]
	_check_fields(f, CONDITION_FIELDS + CUTSCENE_FIELDS, path, line, "a cutscene")
	if not b["choices"].is_empty():
		_err(path, line, "Cutscenes can't have '>' choices. Use a prayer for choices.")
	var panels: Array = []
	var picture := str(f.get("picture", "stars")).strip_edges().to_lower()
	var cur_lines: Array = []
	var cur_pic := picture
	for i in b["body"].size():
		var l: String = b["body"][i]
		if l == "---":
			panels.append({"picture": cur_pic, "text": _paragraphs(cur_lines)})
			cur_lines = []
			continue
		var kv := _field(l)
		if not kv.is_empty() and kv["key"] == "picture" and cur_lines.filter(func(x): return x != "").is_empty():
			cur_pic = String(kv["value"]).to_lower()
			continue
		cur_lines.append(l)
	if not cur_lines.filter(func(x): return x != "").is_empty():
		panels.append({"picture": cur_pic, "text": _paragraphs(cur_lines)})
	panels = panels.filter(func(p): return p["text"] != "")
	if panels.is_empty():
		_err(path, line, "Cutscene '%s' has no text." % b["id"])
	var sets := _list(str(f.get("sets", "")))
	for fl in sets:
		_all_flags[fl] = true
	cutscenes.append({
		"id": b["id"],
		"cond": _conditions(f, path, line),
		"panels": panels,
		"sets": sets,

		"once": not str(f.get("once", "yes")).strip_edges().to_lower() in ["no", "false", "n"],
		"file": path,
		"line": line,
	})


func _add_page(b: Dictionary) -> void:
	var f: Dictionary = b["fields"]
	_check_fields(f, CONDITION_FIELDS + PAGE_FIELDS, b["file"], b["line"], "a journal page")
	pages.append({
		"id": b["id"],
		"cond": _conditions(f, b["file"], b["line"]),
		"title": str(f.get("title", "")),
		"sketch": str(f.get("sketch", "")),
		"ink": str(f.get("ink", "")),
		"order": _num(str(f.get("order", str(pages.size() + 1))), b["file"], b["line"], "order"),
		"text": b["text"],
	})


func _load_words(path: String) -> void:
	var lines := FileAccess.get_file_as_string(path).replace("\r\n", "\n").split("\n")
	for i in lines.size():
		var line := lines[i].strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		var kv := _field(line)
		if kv.is_empty():
			_err(path, i + 1, "Lines here look like 'fire: fire, flame, warmth' (a discovery or flag, a colon, then words).")
			continue
		var concept: String = kv["key"]
		_word_lines[concept] = [path, i + 1]
		for w in _list(kv["value"]):
			if words.has(w):
				_err(path, i + 1, "The word '%s' is listed twice." % w)
			words[w] = concept


func _add_ending(b: Dictionary) -> void:
	var f: Dictionary = b["fields"]
	var path: String = b["file"]
	var line: int = b["line"]
	_check_fields(f, CONDITION_FIELDS + ENDING_FIELDS, path, line, "an ending")
	var kind := str(f.get("kind", "ending")).strip_edges().to_lower()
	if not kind in ["ending", "epilogue"]:
		_err(path, line, "'kind' must be 'ending' or 'epilogue'.")
	if f.has("condition"):
		_err(path, line, "'condition' is from v0.1. Use 'journal: 90+', 'people: none', 'requires: flag', or 'mood: loved' instead.")
	var e := {"id": b["id"], "cond": _conditions(f, path, line), "title": str(f.get("title", "")), "text": b["text"]}
	if kind == "epilogue":
		epilogues.append(e)
	else:
		endings.append(e)


## A person in the god's notes. Each "> note" line is something the god can
## learn about them, with its own conditions. Once learned, a note stays.
func _add_character(b: Dictionary) -> void:
	var f: Dictionary = b["fields"]
	var path: String = b["file"]
	var line: int = b["line"]
	_check_fields(f, CONDITION_FIELDS + CHARACTER_FIELDS, path, line, "a person")
	var person := {
		"id": b["id"],
		"name": str(f.get("name", b["id"].capitalize())),
		"title": str(f.get("title", "")),
		"cond": _conditions(f, path, line),
		"intro": b["text"],
		"group": str(f.get("group", "people")).strip_edges().to_lower(),
		"portrait": str(f.get("portrait", "")).strip_edges().to_lower(),
		"renamed": [],
		"notes": [],
		"file": path,
		"line": line,
	}
	# "renamed: names_known = Time" means: once names_known is true, show the name "Time".
	for part in str(f.get("renamed", "")).split(","):
		if part.strip_edges() == "":
			continue
		var bits := part.split("=")
		if bits.size() != 2 or bits[0].strip_edges() == "" or bits[1].strip_edges() == "":
			_err(path, line, "'renamed' should look like 'renamed: names_known = Time' (a flag, '=', then the new name).")
			continue
		person["renamed"].append([bits[0].strip_edges().to_lower().replace(" ", "_"), bits[1].strip_edges()])
	for i in b["choices"].size():
		var ch: Dictionary = b["choices"][i]
		_check_fields(ch["fields"], CONDITION_FIELDS, path, ch["line"], "a note about a person")
		person["notes"].append({"key": "%s:%d" % [b["id"], i], "text": ch["text"], "cond": _conditions(ch["fields"], path, ch["line"]), "line": ch["line"]})
	characters.append(person)


# ---------------------------------------------------------------- cross-checks

func _known(x: String) -> bool:
	return revelations.has(x) or _all_flags.has(x)


func _check_cond(cond: Dictionary, path: String, line: int) -> void:
	for key in ["requires", "blocks"]:
		for x in cond[key]:
			if not _known(x):
				_err(path, line, "'%s' in '%s' isn't a discovery or a flag that anything sets. Check the spelling." % [x, key])
	for a in cond["after"]:
		if not _known(a[0]):
			_err(path, line, "'%s' in 'after' isn't a discovery or a flag that anything sets. Check the spelling." % a[0])


func _check_links() -> void:
	for id in revelation_order:
		var r: Dictionary = revelations[id]
		for key in ["requires", "excludes"]:
			for other in r[key]:
				if not revelations.has(other):
					_err(r["file"], r["line"], "'%s' in '%s' isn't a discovery name. Check the spelling." % [other, key])
		for x in r["appears"]:
			if not _known(x):
				_err(r["file"], r["line"], "'%s' in 'appears' isn't a discovery or a flag that anything sets. Check the spelling." % x)
	var people_ids := {}
	for person in characters:
		people_ids[person["id"]] = true
	for p in prayers:
		_check_cond(p["cond"], p["file"], p["line"])
		if p["by"] != "" and not people_ids.has(p["by"]):
			_err(p["file"], p["line"], "'by: %s' should be the name of someone in the characters folder (like 'time' or 'memory')." % p["by"])
		for c in p["choices"]:
			if c["needs"] != "" and not c["needs"] in RANKS and not revelations.has(c["needs"]):
				_err(p["file"], c["line"], "'needs' must be a rank (spirit, deity, god) or a discovery name. '%s' is neither." % c["needs"])
			for key in ["grants", "forgets", "fail_forgets", "closes"]:
				for x in c[key]:
					if not revelations.has(x):
						_err(p["file"], c["line"], "'%s' in '%s' isn't a discovery name. Check the spelling." % [x, key])
	for cs in cutscenes:
		_check_cond(cs["cond"], cs["file"], cs["line"])
	for pg in pages:
		_check_cond(pg["cond"], ROOT + "/journal", 0)
	for e in endings + epilogues:
		_check_cond(e["cond"], ROOT + "/endings", 0)
	for person in characters:
		_check_cond(person["cond"], person["file"], person["line"])
		for rn in person["renamed"]:
			if not _known(rn[0]):
				_err(person["file"], person["line"], "'%s' in 'renamed' isn't a discovery or a flag that anything sets." % rn[0])
		for n in person["notes"]:
			_check_cond(n["cond"], person["file"], n["line"])
	for concept in _word_lines.keys():
		if not _known(concept):
			var where: Array = _word_lines[concept]
			_err(where[0], where[1], "'%s' isn't a discovery or a flag that anything sets." % concept)
	if not revelations.has(settings["common_words"]):
		_err(ROOT + "/settings.txt", 0, "'common_words' must be the name of a discovery (it's '%s')." % settings["common_words"])
	if endings.is_empty():
		_err(ROOT + "/endings", 0, "There are no endings. Add at least one with no conditions, so the game always has an ending to show.")
	if revelations.is_empty():
		_err(ROOT + "/revelations", 0, "No discoveries were found.")
	if prayers.is_empty():
		_err(ROOT + "/prayers", 0, "No prayers were found.")
