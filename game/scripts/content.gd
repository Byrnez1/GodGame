extends RefCounted
## Loads every story file in res://content/ and checks it for mistakes.
## Problems are collected in `errors` as plain-language messages with the
## file and line number, so they can be shown on screen instead of crashing.

const ROOT := "res://content"
const RANKS := ["whisper", "spirit", "deity", "god"]
const REVELATION_FIELDS := ["name", "rank", "cost", "requires", "excludes", "income", "growth", "love", "fear", "glimpse"]
const PRAYER_FIELDS := ["when", "speaker", "requires", "blocks", "once", "weight", "kind"]
const CHOICE_FIELDS := ["cost", "faith", "people", "love", "fear", "sets", "grants", "forgets", "silent", "needs", "result"]
const PAGE_FIELDS := ["order", "title"]
const ENDING_FIELDS := ["condition", "title"]
const SETTING_DEFAULTS := {
	"generations": 12,
	"starting_people": 30,
	"starting_faith": 3,
	"people_per_faith": 10,
	"base_growth": 4,
	"prayers_per_generation": 2,
	"rank_spirit": 20,
	"rank_deity": 50,
	"rank_god": 100,
	"common_words": "speech",
}

var settings := {}
var revelations := {}
var revelation_order: Array = []
var prayers: Array = []
var pages: Array = []
var words := {}
var endings: Array = []
var errors: Array = []

var _field_re := RegEx.create_from_string("^([A-Za-z][A-Za-z _]*):\\s*(.*)$")


func load_all() -> void:
	_load_settings(ROOT + "/settings.txt")
	for path in _txt_files(ROOT + "/revelations"):
		for b in _parse_blocks(path):
			_add_revelation(b)
	for path in _txt_files(ROOT + "/prayers"):
		for b in _parse_blocks(path):
			_add_prayer(b)
	for path in _txt_files(ROOT + "/journal"):
		if path.get_file().to_lower() == "words.txt":
			_load_words(path)
		else:
			for b in _parse_blocks(path):
				_add_page(b)
	for path in _txt_files(ROOT + "/endings"):
		for b in _parse_blocks(path):
			_add_ending(b)
	pages.sort_custom(func(a, b): return a["order"] < b["order"])
	_check_links()


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
	var text := FileAccess.get_file_as_string(path)
	var lines := text.replace("\r\n", "\n").replace("\r", "\n").split("\n")
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
			cur = {"id": id, "file": path, "line": n, "fields": {}, "body": [], "choices": []}
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
					else:
						_set_field(cur["fields"], kv)
			"body":
				cur["body"].append(line)
			"choices":
				if line == "":
					continue
				var ckv := _field(line)
				if not ckv.is_empty():
					_set_field(cur["choices"].back()["fields"], ckv)
					last_key = ckv["key"]
				elif last_key == "result":
					var cf: Dictionary = cur["choices"].back()["fields"]
					cf["result"] = cf["result"] + " " + line
				else:
					_err(path, n, "This line is below the choices, but it isn't a choice setting like 'cost: 3'. Story text belongs above the first '>' line.")
	if not cur.is_empty():
		blocks.append(_finish_block(cur))
	return blocks


func _finish_block(b: Dictionary) -> Dictionary:
	var paras := PackedStringArray()
	var curp := PackedStringArray()
	for l in b["body"]:
		if l == "":
			if not curp.is_empty():
				paras.append(" ".join(curp))
				curp = PackedStringArray()
		else:
			curp.append(l)
	if not curp.is_empty():
		paras.append(" ".join(curp))
	b["text"] = "\n\n".join(paras)
	return b


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
	t = t.replace("+", "")
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
			_err(path, i + 1, "Settings look like 'generations: 12'.")
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
		"text": b["text"],
		"file": path,
		"line": line,
	}
	if not r["rank"] in RANKS:
		_err(path, line, "'rank' must be one of: whisper, spirit, deity, god.")
		r["rank"] = "whisper"
	revelations[id] = r
	revelation_order.append(id)


func _when(v: String, path: String, line: int) -> Vector2i:
	v = v.strip_edges().to_lower()
	if v == "" or v == "any":
		return Vector2i(1, 9999)
	if v.ends_with("+"):
		var a := v.trim_suffix("+").strip_edges()
		if a.is_valid_int():
			return Vector2i(a.to_int(), 9999)
	elif v.contains("-"):
		var parts := v.split("-")
		if parts.size() == 2 and parts[0].strip_edges().is_valid_int() and parts[1].strip_edges().is_valid_int():
			return Vector2i(parts[0].strip_edges().to_int(), parts[1].strip_edges().to_int())
	elif v.is_valid_int():
		return Vector2i(v.to_int(), v.to_int())
	_err(path, line, "'when' should look like '3' (only generation 3), '3+' (generation 3 or later), or '3-6'.")
	return Vector2i(1, 9999)


func _add_prayer(b: Dictionary) -> void:
	var f: Dictionary = b["fields"]
	var path: String = b["file"]
	var line: int = b["line"]
	_check_fields(f, PRAYER_FIELDS, path, line, "a prayer")
	var p := {
		"id": b["id"],
		"speaker": str(f.get("speaker", "")),
		"when": _when(str(f.get("when", "any")), path, line),
		"requires": _list(str(f.get("requires", ""))),
		"blocks": _list(str(f.get("blocks", ""))),
		"once": not str(f.get("once", "yes")).strip_edges().to_lower() in ["no", "false", "n"],
		"weight": _num(str(f.get("weight", "10")), path, line, "weight"),
		"kind": str(f.get("kind", "")).to_lower(),
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
			"faith": _num(str(cf.get("faith", "0")), path, cl, "faith"),
			"people": _num(str(cf.get("people", "0")), path, cl, "people"),
			"love": _num(str(cf.get("love", "0")), path, cl, "love"),
			"fear": _num(str(cf.get("fear", "0")), path, cl, "fear"),
			"sets": _list(str(cf.get("sets", ""))),
			"grants": _list(str(cf.get("grants", ""))),
			"forgets": _list(str(cf.get("forgets", ""))),
			"silent": _yes(str(cf.get("silent", "no"))),
			"needs": str(cf.get("needs", "")).strip_edges().to_lower(),
			"result": str(cf.get("result", "")),
			"line": cl,
		}
		if c["needs"] != "" and not c["needs"] in RANKS:
			_err(path, cl, "'needs' must be a rank: whisper, spirit, deity, or god.")
			c["needs"] = ""
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


func _add_page(b: Dictionary) -> void:
	var f: Dictionary = b["fields"]
	_check_fields(f, PAGE_FIELDS, b["file"], b["line"], "a journal page")
	pages.append({
		"id": b["id"],
		"title": str(f.get("title", "")),
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
			_err(path, i + 1, "Lines here look like 'fire: fire, flame, warmth' (a discovery name, a colon, then words).")
			continue
		var concept: String = kv["key"]
		if not revelations.has(concept):
			_err(path, i + 1, "'%s' isn't the name of a discovery in content/revelations." % concept)
		for w in _list(kv["value"]):
			if words.has(w):
				_err(path, i + 1, "The word '%s' is listed twice." % w)
			words[w] = concept


func _add_ending(b: Dictionary) -> void:
	var f: Dictionary = b["fields"]
	var path: String = b["file"]
	var line: int = b["line"]
	_check_fields(f, ENDING_FIELDS, path, line, "an ending")
	var raw := str(f.get("condition", "always")).strip_edges().to_lower()
	var cond := {"type": "always", "value": 0}
	if raw == "always":
		pass
	elif raw == "no people":
		cond["type"] = "no_people"
	elif raw.begins_with("readable"):
		cond["type"] = "readable"
		cond["value"] = _num(raw.substr(8).replace("%", ""), path, line, "readable")
	else:
		_err(path, line, "'condition' should be 'always', 'no people', or 'readable 90' (a percentage of the journal).")
	endings.append({"id": b["id"], "title": str(f.get("title", "")), "condition": cond, "text": b["text"]})


# ---------------------------------------------------------------- cross-checks

func _check_links() -> void:
	var flags := {}
	for p in prayers:
		for c in p["choices"]:
			for fl in c["sets"]:
				flags[fl] = true
	for id in revelation_order:
		var r: Dictionary = revelations[id]
		for key in ["requires", "excludes"]:
			for other in r[key]:
				if not revelations.has(other):
					_err(r["file"], r["line"], "'%s' in '%s' isn't a discovery name. Check the spelling." % [other, key])
	for p in prayers:
		for key in ["requires", "blocks"]:
			for x in p[key]:
				if not revelations.has(x) and not flags.has(x):
					_err(p["file"], p["line"], "'%s' in '%s' isn't a discovery or a flag that any choice sets. Check the spelling." % [x, key])
		for c in p["choices"]:
			for key in ["grants", "forgets"]:
				for x in c[key]:
					if not revelations.has(x):
						_err(p["file"], c["line"], "'%s' in '%s' isn't a discovery name. Check the spelling." % [x, key])
	if not revelations.has(settings["common_words"]):
		_err(ROOT + "/settings.txt", 0, "'common_words' must be the name of a discovery (it's '%s')." % settings["common_words"])
	var has_always := false
	for e in endings:
		if e["condition"]["type"] == "always":
			has_always = true
	if not has_always:
		_err(ROOT + "/endings", 0, "Add an ending with 'condition: always' so the game always has an ending to show.")
	if revelations.is_empty():
		_err(ROOT + "/revelations", 0, "No discoveries were found.")
	if prayers.is_empty():
		_err(ROOT + "/prayers", 0, "No prayers were found.")
