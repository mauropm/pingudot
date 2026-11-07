extends Node
## DialogueDB — every text line in the game (dialogue, jokes, event results).

const PATH := "res://data/dialogue/lines.json"
var lines: Dictionary = {}


func _ready() -> void:
	var d = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if d is Dictionary:
		lines = d


func get_line(id: String) -> Dictionary:
	return lines.get(id, {"speaker": "", "text": id})


func random_id_with_prefix(prefix: String) -> String:
	var ids: Array[String] = []
	for k in lines.keys():
		if k.begins_with(prefix):
			ids.append(k)
	ids.sort()
	if ids.is_empty():
		return ""
	return ids[randi() % ids.size()]
