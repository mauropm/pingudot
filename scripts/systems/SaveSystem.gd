extends Node
## SaveSystem — versioned JSON saves in user:// with corruption protection.
## Stores: run save (user://save_pingudot.json), settings, achievements profile.

const SAVE_PATH := "user://save_pingudot.json"
const SAVE_BAK := "user://save_pingudot.json.bak"
const SETTINGS_PATH := "user://settings.json"
const PROFILE_PATH := "user://profile.json"
const SAVE_VERSION := 1
const MAGIC := "PINGUDOT_SAVE_V1"


func _write_json(path: String, data: Dictionary) -> bool:
	var text := JSON.stringify(data, "\t")
	# keep previous file as backup before overwriting
	if FileAccess.file_exists(path):
		_copy(path, _bak_for(path))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("SaveSystem: cannot open %s" % path)
		return false
	f.store_string(text)
	f.close()
	return true


func _bak_for(path: String) -> String:
	return path + ".bak"


func _copy(from: String, to: String) -> void:
	var src := FileAccess.open(from, FileAccess.READ)
	if src == null:
		return
	var dst := FileAccess.open(to, FileAccess.WRITE)
	if dst == null:
		return
	dst.store_string(src.get_as_text())
	src.close()
	dst.close()


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var raw := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(raw)
	if parsed is Dictionary and parsed.get("magic", "") == MAGIC:
		return parsed
	return {}


## Saves the full run. Returns success.
func save_run(data: Dictionary) -> bool:
	data["magic"] = MAGIC
	data["version"] = SAVE_VERSION
	data["timestamp"] = Time.get_unix_time_from_system()
	return _write_json(SAVE_PATH, data)


func has_run_save() -> bool:
	return _read_json(SAVE_PATH) != {} or _read_json(SAVE_BAK) != {}


func load_run() -> Dictionary:
	var d := _read_json(SAVE_PATH)
	if d.is_empty():
		d = _read_json(SAVE_BAK)  # primary corrupted — fall back to backup
		if not d.is_empty():
			print("SaveSystem: primary save corrupted, recovered backup")
	return d


func delete_run() -> void:
	for p in [SAVE_PATH, SAVE_BAK]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func save_settings(data: Dictionary) -> bool:
	return _write_json(SETTINGS_PATH, {"magic": MAGIC, "settings": data})


func load_settings() -> Dictionary:
	var d := _read_json(SETTINGS_PATH)
	return d.get("settings", {})


func save_profile(achievements: Dictionary, unlocks: Dictionary) -> bool:
	return _write_json(PROFILE_PATH, {"magic": MAGIC, "achievements": achievements, "unlocks": unlocks})


func delete_profile() -> void:
	for p in [PROFILE_PATH, PROFILE_PATH + ".bak"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func load_profile() -> Dictionary:
	var d := _read_json(PROFILE_PATH)
	if d.is_empty():
		return {"achievements": {}, "unlocks": {}}
	return {"achievements": d.get("achievements", {}), "unlocks": d.get("unlocks", {})}
