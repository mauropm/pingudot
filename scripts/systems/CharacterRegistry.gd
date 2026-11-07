extends Node
## CharacterRegistry — playable character definitions (Pingu + secret MIGGY).

const PATH := "res://data/characters.json"
var defs: Dictionary = {}    # id -> CharacterDefinition


func _ready() -> void:
	var arr = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if arr is Array:
		for c in arr:
			var r := CharacterDefinition.new()
			r.id = String(c["id"])
			r.display_name = String(c["name"])
			r.title = String(c["title"])
			r.specialty = String(c.get("specialty", ""))
			r.status = String(c.get("status", "USER"))
			r.tagline = String(c.get("tagline", ""))
			r.atlas_path = String(c["atlas"])
			r.stats = c.get("stats", {})
			for a in c.get("abilities", []):
				r.abilities.append(String(a))
			r.ultimate_id = String(c.get("ultimate", ""))
			r.start_item = String(c.get("start_item", ""))
			r.unlocked_by_default = bool(c.get("unlocked", false))
			defs[r.id] = r


func has(id: String) -> bool:
	return defs.has(id)


func get_def(id: String) -> CharacterDefinition:
	return defs.get(id, defs.get("pingu"))


func ids() -> Array[String]:
	var out: Array[String] = []
	for id in defs:
		out.append(id)
	out.sort()
	return out
