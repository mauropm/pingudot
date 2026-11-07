extends Node
## AchievementManager — 12 achievements, persisted in the cross-save profile.

const ACH_PATH := "res://data/achievements/achievements.json"

var defs: Array = []
var unlocked: Dictionary = {}    # id -> unix time
var queue: Array[String] = []    # toast queue for the HUD


func _ready() -> void:
	var arr = JSON.parse_string(FileAccess.get_file_as_string(ACH_PATH))
	if arr is Array:
		defs = arr
	var profile := SaveSystem.load_profile()
	unlocked = profile["achievements"]
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.patch_collected.connect(_on_patches)
	EventBus.area_entered.connect(_on_area)
	EventBus.boss_defeated.connect(func():
		unlock("no_meetings")
		if _clean_phase:
			unlock("zero_trust"))
	EventBus.boss_phase_started.connect(_on_phase_start)
	EventBus.player_damaged.connect(_on_player_damaged)


func display_name(id: String) -> String:
	for a in defs:
		if a["id"] == id:
			return a["name"]
	return id


func description(id: String) -> String:
	for a in defs:
		if a["id"] == id:
			return a["desc"]
	return ""


func is_unlocked(id: String) -> bool:
	return unlocked.has(id)


func unlock(id: String) -> void:
	if unlocked.has(id):
		return
	unlocked[id] = int(Time.get_unix_time_from_system())
	var prof := SaveSystem.load_profile()
	SaveSystem.save_profile(unlocked, prof.get("unlocks", {}))
	EventBus.achievement_unlocked.emit(id, display_name(id))
	queue.append(id)
	AudioDirector.play_sfx("achievement")


var _clean_phase := true


func _on_phase_start(_phase: int) -> void:
	if _clean_phase:
		unlock("zero_trust")
	_clean_phase = true


func _on_player_damaged() -> void:
	_clean_phase = false


func total() -> int:
	return defs.size()


func unlocked_count() -> int:
	return unlocked.size()


# ---- gameplay hooks ---------------------------------------------------------
func _on_enemy_died(kind: String, _elite: bool) -> void:
	match kind:
		"bsdemon": unlock("kernel_survivor")
		"littlebill": unlock("sub_cancelled")
		"gplhipster": unlock("smells_like_gpl")


func _on_patches(_total: int) -> void:
	if GameState.counters.get("patches", 0) >= 10:
		unlock("oss_hero")


func _on_area(index: int, _name: String) -> void:
	if index == 3:
		unlock("unicorn_hunter")


func on_hidden_found() -> void:
	unlock("found_404")


func on_abilities_full() -> void:
	if GameState.unlocked_abilities.size() >= 4:
		unlock("root_unlocked")


func on_equipment_changed() -> void:
	if GameState.equipment["hardware"].size() >= 3:
		unlock("legacy_hw")


func on_ending_finished() -> void:
	unlock("oaxaca_express")
	unlock("exit_strategy")
