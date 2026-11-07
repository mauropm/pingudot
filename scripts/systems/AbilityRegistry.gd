extends Node
## AbilityRegistry — loads res://data/abilities.json into AbilityResource defs.

const PATH := "res://data/abilities.json"
var defs: Dictionary = {}    # id -> AbilityResource


func _ready() -> void:
	var arr = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if arr is Array:
		for a in arr:
			var r := AbilityResource.new()
			r.id = a["id"]
			r.display_name = a["name"]
			r.unlock_level = int(a["unlock_level"])
			r.energy_cost = int(a["energy"])
			r.cooldown = float(a["cd"])
			r.power = float(a["power"])
			r.ability_type = a["type"]
			r.description = a["desc"]
			r.icon = load(a["icon"])
			defs[r.id] = r


func list_ids() -> Array[String]:
	var out: Array[String] = []
	for id in defs:
		out.append(id)
	out.sort()
	return out
