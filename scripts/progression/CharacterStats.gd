extends Resource
class_name CharacterStats
## The RPG stat block. Base values + level; equipment/buffs are applied by
## consumers (Player) via CombatMath.combine using get_equip_sum().

@export var max_hp: int = 45
@export var base_max_hp: int = 45
@export var hp: int = 45
@export var max_en: int = 30
@export var en: int = 30
@export var atk: int = 6
@export var def_: int = 3
@export var spd: int = 4
@export var intel: int = 4
@export var luck: int = 2
@export var level: int = 1
@export var xp: int = 0


func next_xp_needed() -> int:
	return CombatMath.xp_needed(level)


# Effective stats — equipment + global debuffs resolved via GameState.
func effective_atk() -> int:
	return GameState.effective("atk", 0.0, GameState.equipment_disabled)


func effective_def() -> int:
	return GameState.effective("def", 0.0, GameState.equipment_disabled)


func effective_spd() -> int:
	return GameState.effective("spd", 0.0, GameState.equipment_disabled)


func effective_int() -> int:
	return GameState.effective("int", 0.0, GameState.equipment_disabled)


func effective_luck() -> int:
	return GameState.effective("luck", 0.0, GameState.equipment_disabled)


func equip_sum(mod_id: String, equips: Array) -> int:
	var s := 0
	for item: ItemResource in equips:
		if item == null:
			continue
		var v = item.mods.get(mod_id, 0)
		if v is int:
			s += v
	return s


func gain_xp(amount: int, rng_equipment: Array) -> int:
	## Adds XP, consuming levels. Returns number of levels gained.
	var gained := 0
	xp += amount
	while xp >= next_xp_needed():
		xp -= next_xp_needed()
		level += 1
		var g := CombatMath.level_gains(level)
		max_hp += g["max_hp"]
		max_en += g["max_en"]
		atk += g["atk"]
		def_ += g["def"]
		spd += g["spd"]
		intel += g["int"]
		luck += g["luck"]
		hp = max_hp
		en = max_en
		gained += 1
	return gained
