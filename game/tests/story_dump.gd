extends SceneTree
## Writes every story beat (cutscenes, prayers, endings) and how they connect, as JSON.
## Used to draw the story map:  godot --headless --path game --script res://tests/story_dump.gd -- out.json

const ContentData := preload("res://scripts/content.gd")


func _v(v: Vector2i) -> Array:
	return [v.x, v.y]


func _cond(c: Dictionary) -> Dictionary:
	return {"when": _v(c["when"]), "requires": c["requires"], "blocks": c["blocks"], "after": c["after"],
		"rank": c["rank"], "mood": c["mood"], "journal": _v(c["journal"]), "people": c["people"], "silence": _v(c["silence"])}


func _fx(f: Dictionary) -> Dictionary:
	return {"sets": f["sets"], "result": f["result"], "love": f["love"], "fear": f["fear"], "faith": f["faith"], "people": f["people"]}


func _initialize() -> void:
	var c = ContentData.new()
	c.load_all()
	var out := {"cutscenes": [], "prayers": [], "endings": [], "epilogues": [], "discoveries": {}}
	for cs in c.cutscenes:
		var panels: Array = []
		for p in cs["panels"]:
			panels.append({"picture": p["picture"], "text": p["text"]})
		out["cutscenes"].append({"id": cs["id"], "file": cs["file"].get_file(), "cond": _cond(cs["cond"]), "sets": cs["sets"], "panels": panels})
	for p in c.prayers:
		var chs: Array = []
		for ch in p["choices"]:
			chs.append({"text": ch["text"], "cost": ch["cost"], "needs": ch["needs"], "silent": ch["silent"], "ends": ch["ends"],
				"grants": ch["grants"], "forgets": ch["forgets"] + ch["fail_forgets"], "closes": ch["closes"],
				"test": ch["test"], "ok": _fx(ch["ok"]), "fail": _fx(ch["fail"])})
		out["prayers"].append({"id": p["id"], "file": p["file"].get_file(), "cond": _cond(p["cond"]), "speaker": p["speaker"],
			"kind": p["kind"], "by": p["by"], "once": p["once"], "text": p["text"], "choices": chs})
	for e in c.endings:
		out["endings"].append({"id": e["id"], "title": e["title"], "cond": _cond(e["cond"]), "text": e["text"]})
	for e in c.epilogues:
		out["epilogues"].append({"id": e["id"], "cond": _cond(e["cond"]), "text": e["text"]})
	for id in c.revelation_order:
		out["discoveries"][id] = c.revelations[id]["name"]
	var path: String = OS.get_cmdline_user_args()[0]
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	print("wrote ", path)
	quit(0)
