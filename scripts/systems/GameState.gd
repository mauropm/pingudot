extends Node
## GameState — the run: stats, inventory, equipment, abilities, seed, progress.
## Persists to SaveSystem. All mutations emit EventBus signals for the HUD.

const TOTAL_AREAS := 5

var rng := RandomNumberGenerator.new()
var seed_value := 0
var stats: CharacterStats
var inventory: Array = []            # Array[ItemResource]
var equipment := {"weapon": null, "armor": null, "boots": null, "hardware": []}
var coins := 0
var unlocked_abilities: Array[String] = []
var selected_ability := ""
var area_index := 0                  # 0..4 current area
var area_names := [
	"BEACH OF BROKEN PROMISES", "STARTUP GRAVEYARD", "OPEN SOURCE WARZONE",
	"VALLEY OF UNICORNS", "OAKLAND ESCAPE TERMINAL"]
var objectives: Dictionary = {}      # area_index -> text
var checkpoint := {"area": 0, "x": 2, "y": 2}
var counters := {"patches": 0, "kills": {}, "hidden_found": 0, "area_reached": 0,
	"boss_defeated": false, "mission_complete": false}
var started := false
var mission_complete := false
var equipment_disabled := false    # GPL Hipster license-violation debuff
var character_id := "pingu"
var ultimate_charge := 0
var unlocked_characters := {"pingu": true}


func _ready() -> void:
	_load_unlocks()
	reset_run(0, "pingu")


func _load_unlocks() -> void:
	var profile := SaveSystem.load_profile()
	var u: Dictionary = profile.get("unlocks", {})
	unlocked_characters = {"pingu": true, "miggy": bool(u.get("miggy", false))}


func is_character_unlocked(id: String) -> bool:
	return bool(unlocked_characters.get(id, false))


func unlock_character(id: String) -> void:
	unlocked_characters[id] = true
	var unlocks := {}
	for cid in unlocked_characters:
		if bool(unlocked_characters[cid]):
			unlocks[cid] = true
	SaveSystem.save_profile(AchievementManager.unlocked, unlocks)
	EventBus.character_unlocked.emit(id)


func character_def() -> CharacterDefinition:
	return CharacterRegistry.get_def(character_id)


func ability_ids() -> Array[String]:
	return character_def().abilities


func ultimate_id() -> String:
	return character_def().ultimate_id


func has_ultimate() -> bool:
	return ultimate_id() != ""


func reset_run(sd: int, character := "pingu") -> void:
	if sd == 0:
		seed_value = int(Time.get_unix_time_from_system()) ^ randi()
	else:
		seed_value = sd
	if not CharacterRegistry.has(character):
		character = "pingu"
	character_id = character
	var cdef := CharacterRegistry.get_def(character)
	rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	inventory.clear()
	equipment = {"weapon": null, "armor": null, "boots": null, "hardware": []}
	stats = CharacterStats.new()
	var cs: Dictionary = cdef.stats
	stats.max_hp = int(cs.get("hp", 45))
	stats.base_max_hp = stats.max_hp
	stats.max_en = int(cs.get("en", 30))
	stats.atk = int(cs.get("atk", 6))
	stats.def_ = int(cs.get("def", 3))
	stats.spd = int(cs.get("spd", 4))
	stats.intel = int(cs.get("int", 4))
	stats.luck = int(cs.get("luck", 2))
	stats.level = 1
	stats.xp = 0
	stats.hp = stats.max_hp
	stats.en = stats.max_en
	_recalc_max_hp()
	stats.hp = stats.max_hp
	coins = 0
	ultimate_charge = 0
	unlocked_abilities.clear()
	for id in cdef.abilities:
		var a: AbilityResource = AbilityRegistry.defs.get(id)
		if a != null and a.unlock_level <= 1:
			unlocked_abilities.append(id)
	selected_ability = unlocked_abilities[0] if unlocked_abilities.size() > 0 else ""
	area_index = 0
	checkpoint = {"area": 0, "x": 2, "y": 2}
	counters = {"patches": 0, "kills": {}, "hidden_found": 0, "area_reached": 0,
		"boss_defeated": false, "mission_complete": false}
	objectives = {
		0: "EXIT EAST. COMPILE SOME DEMONS.",
		1: "CROSS THE GRAVEYARD. DONT GET BOUGHT.",
		2: "MIND THE LICENSES. AND THE FORKS.",
		3: "EVERYTHING HERE IS OVERPRICED.",
		4: "DEFEAT THE CTO. CATCH THE PLANE."}
	started = false
	mission_complete = false


func roll_rng() -> RandomNumberGenerator:
	## Independent per-call RNG chained to the run seed (reproducible spawns).
	var r := RandomNumberGenerator.new()
	r.seed = rng.seed
	r.randi()  # advance once so consecutive calls differ but stay deterministic
	return r


# -------------------------------------------------------------------- XP ----
func gain_xp(amount: int) -> void:
	var before := stats.level
	var gained := stats.gain_xp(amount, [])
	EventBus.player_xp_changed.emit(stats.xp, stats.next_xp_needed(), stats.level)
	for i in gained:
		_check_ability_unlocks()
		AudioDirector.play_sfx("levelup")
	if gained > 0 and stats.level >= 2 and selected_ability == "" and unlocked_abilities.size() > 0:
		select_ability(unlocked_abilities[-1])


func _check_ability_unlocks() -> void:
	for id in ability_ids():
		var a: AbilityResource = AbilityRegistry.defs.get(id)
		if a == null or a.ultimate:
			continue
		if a.unlock_level <= stats.level and id not in unlocked_abilities:
			unlocked_abilities.append(id)
			if selected_ability == "":
				select_ability(id)
			EventBus.ability_unlocked.emit(id)
	if character_id == "pingu" and unlocked_abilities.size() >= 4:
		AchievementManager.on_abilities_full()


func select_ability(id: String) -> void:
	if id in unlocked_abilities:
		selected_ability = id
		EventBus.ability_used.emit(id)


# --------------------------------------------------------------- ultimate ----
func add_ultimate_charge(amount: int) -> void:
	if not has_ultimate():
		return
	ultimate_charge = clampi(ultimate_charge + amount, 0, 100)
	EventBus.ultimate_charge_changed.emit(ultimate_charge, 100)


func try_consume_ultimate() -> bool:
	if not has_ultimate() or ultimate_charge < 100:
		return false
	ultimate_charge = 0
	EventBus.ultimate_charge_changed.emit(0, 100)
	return true


# --------------------------------------------------------------- energy ----
var _energy_acc := 0.0

func regenerate_energy(amount: float) -> void:
	if stats.en >= stats.max_en:
		return
	_energy_acc += amount
	var whole := int(_energy_acc)
	if whole <= 0:
		return
	_energy_acc -= whole
	stats.en = mini(stats.max_en, stats.en + whole)
	EventBus.player_energy_changed.emit(stats.en, stats.max_en)


func try_spend_energy(cost: int) -> bool:
	if stats.en < cost:
		return false
	stats.en = maxi(0, stats.en - cost)
	EventBus.player_energy_changed.emit(stats.en, stats.max_en)
	return true


# ------------------------------------------------------------------ coins ----
func add_coins(n: int) -> void:
	coins = maxi(0, coins + n)
	EventBus.coins_changed.emit(coins)


func spend_coins(n: int) -> bool:
	if coins < n:
		return false
	coins -= n
	EventBus.coins_changed.emit(coins)
	return true


# --------------------------------------------------------------- inventory ----
const INVENTORY_CAP := 24


func add_item(item: ItemResource) -> bool:
	if item == null:
		return false
	if item.stackable():
		for existing: ItemResource in inventory:
			if existing.id == item.id:
				existing.quantity += item.quantity
				_notify_item(item)
				return true
	if inventory.size() >= INVENTORY_CAP:
		return false  # inventory full — drop the loot (funny message handled by caller)
	inventory.append(item)
	_notify_item(item)
	return true


func _notify_item(item: ItemResource) -> void:
	if item.id == "patch_software":
		counters["patches"] += item.quantity
		EventBus.patch_collected.emit(counters["patches"])
	EventBus.item_picked.emit(item)


func remove_item(item: ItemResource) -> void:
	if item == null:
		return
	if item.stackable() and item.quantity > 1:
		item.quantity -= 1
		return
	inventory.erase(item)


func use_consumable(item: ItemResource) -> void:
	if item == null or item.slot != "consumable":
		return
	var healed := false
	if item.mods.has("hp_heal"):
		stats.hp = mini(stats.max_hp, stats.hp + int(item.mods["hp_heal"]))
		EventBus.player_hp_changed.emit(stats.hp, stats.max_hp)
		healed = true
	if item.mods.has("en_gain"):
		stats.en = mini(stats.max_en, stats.en + int(item.mods["en_gain"]))
		EventBus.player_energy_changed.emit(stats.en, stats.max_en)
		healed = true
	if item.mods.has("clear_cd"):
		EventBus.clear_cooldowns.emit()
		healed = true
	if healed:
		remove_item(item)
		AudioDirector.play_sfx("heal")


# ---------------------------------------------------------------- equipment ----
func equip(item: ItemResource) -> void:
	if item == null or not item.is_equippable():
		return
	var slot: String = item.slot
	if slot == "hardware":
		if equipment["hardware"].size() >= 4:
			var old: ItemResource = equipment["hardware"].pop_front()
			inventory.append(old)
		equipment["hardware"].append(item)
	else:
		if equipment[slot] != null:
			inventory.append(equipment[slot])
		equipment[slot] = item
	inventory.erase(item)
	AchievementManager.on_equipment_changed()
	_recalc_max_hp()
	_stats_dirty()


func unequip(slot: String, index: int = -1) -> void:
	if slot == "hardware":
		if index < 0 or index >= equipment["hardware"].size():
			return
		var item: ItemResource = equipment["hardware"][index]
		equipment["hardware"].remove_at(index)
		inventory.append(item)
	else:
		if equipment[slot] == null:
			return
		inventory.append(equipment[slot])
		equipment[slot] = null
	_recalc_max_hp()
	_stats_dirty()


func _recalc_max_hp() -> void:
	var bonus := 0 if equipment_disabled else stats.equip_sum("hp", all_equipped())
	stats.max_hp = stats.base_max_hp + bonus
	stats.hp = mini(stats.hp, stats.max_hp)


func all_equipped() -> Array:
	var out: Array = []
	for s in ["weapon", "armor", "boots"]:
		if equipment[s] != null:
			out.append(equipment[s])
	out.append_array(equipment["hardware"])
	return out


func effective(stat_id: String, buff_pct: float, equipment_disabled: bool) -> int:
	var base := 0
	match stat_id:
		"atk": base = stats.atk
		"def": base = stats.def_
		"spd": base = stats.spd
		"int": base = stats.intel
		"luck": base = stats.luck
	return CombatMath.combine(base, stats.equip_sum(stat_id, all_equipped()), buff_pct, equipment_disabled)


func _stats_dirty() -> void:
	EventBus.player_hp_changed.emit(stats.hp, stats.max_hp)
	EventBus.player_energy_changed.emit(stats.en, stats.max_en)
	EventBus.player_xp_changed.emit(stats.xp, stats.next_xp_needed(), stats.level)


# --------------------------------------------------------------- save/load ----
func build_save_dict() -> Dictionary:
	var inv: Array = []
	for item: ItemResource in inventory:
		inv.append(_item_to_dict(item))
	var eq := {}
	for s in ["weapon", "armor", "boots"]:
		eq[s] = _item_to_dict(equipment[s]) if equipment[s] != null else null
	var hw: Array = []
	for h: ItemResource in equipment["hardware"]:
		hw.append(_item_to_dict(h))
	eq["hardware"] = hw
	return {
		"seed": seed_value, "area": area_index, "coins": coins,
		"character": character_id, "ultimate": ultimate_charge,
		"stats": {
			"max_hp": stats.max_hp, "hp": stats.hp, "max_en": stats.max_en, "en": stats.en,
			"atk": stats.atk, "def": stats.def_, "spd": stats.spd, "int": stats.intel,
			"luck": stats.luck, "level": stats.level, "xp": stats.xp},
		"inventory": inv, "equipment": eq,
		"abilities": unlocked_abilities.duplicate(), "selected": selected_ability,
		"checkpoint": checkpoint.duplicate(), "counters": counters.duplicate(),
		"rng_state": rng.state,
	}


func _item_to_dict(item: ItemResource) -> Dictionary:
	return {"id": item.id, "qty": item.quantity, "mods": item.mods}


func _item_from_dict(d: Dictionary) -> ItemResource:
	if d.is_empty() or not ItemRegistry.defs.has(d.get("id", "")):
		return null
	var tpl: ItemResource = ItemRegistry.defs[d["id"]]
	var inst := tpl.duplicate() as ItemResource
	inst.quantity = int(d.get("qty", 1))
	if d.has("mods") and d["mods"] is Dictionary:
		inst.mods = d["mods"]
	return inst


func apply_save_dict(d: Dictionary) -> bool:
	if d.is_empty():
		return false
	reset_run(int(d.get("seed", 0)), String(d.get("character", "pingu")))
	ultimate_charge = int(d.get("ultimate", 0))
	stats.max_hp = int(d["stats"].get("max_hp", 45))
	stats.hp = int(d["stats"].get("hp", stats.max_hp))
	stats.max_en = int(d["stats"].get("max_en", 30))
	stats.en = int(d["stats"].get("en", stats.max_en))
	stats.atk = int(d["stats"].get("atk", 6))
	stats.def_ = int(d["stats"].get("def", 3))
	stats.spd = int(d["stats"].get("spd", 4))
	stats.intel = int(d["stats"].get("int", 4))
	stats.luck = int(d["stats"].get("luck", 2))
	stats.level = int(d["stats"].get("level", 1))
	stats.xp = int(d["stats"].get("xp", 0))
	coins = int(d.get("coins", 0))
	area_index = clampi(int(d.get("area", 0)), 0, TOTAL_AREAS - 1)
	inventory.clear()
	for it in d.get("inventory", []):
		var r := _item_from_dict(it)
		if r != null:
			inventory.append(r)
	var eq: Dictionary = d.get("equipment", {})
	for s in ["weapon", "armor", "boots"]:
		equipment[s] = _item_from_dict(eq.get(s, {})) if eq.get(s) != null else null
	equipment["hardware"] = []
	for h in eq.get("hardware", []):
		var r2 := _item_from_dict(h)
		if r2 != null:
			equipment["hardware"].append(r2)
	unlocked_abilities.clear()
	for a in d.get("abilities", []):
		unlocked_abilities.append(a)
	selected_ability = String(d.get("selected", ""))
	checkpoint = d.get("checkpoint", {"area": 0, "x": 2, "y": 2})
	var c: Dictionary = d.get("counters", {})
	for k in c:
		counters[k] = c[k]
	if d.has("rng_state"):
		rng.state = int(d["rng_state"])
	_recalc_max_hp()
	started = true
	_stats_dirty()
	return true


func write_save() -> bool:
	return SaveSystem.save_run(build_save_dict())


func manual_save() -> bool:
	if not started:
		return false
	return write_save()
