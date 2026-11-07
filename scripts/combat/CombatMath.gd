class_name CombatMath
## Pure static combat/probability helpers — the game's math backbone.
## Every function is deterministic given a seeded RNG, enabling unit tests.


static func xp_needed(level: int) -> int:
	return int(15.0 * pow(level, 1.3))


## Stat gains applied on level-up.
static func level_gains(_level: int) -> Dictionary:
	return {"max_hp": 7, "max_en": 4, "atk": 1, "def": 1, "spd": 0, "int": 1, "luck": 1}


static func crit_chance(luck: int) -> float:
	return clampf(0.05 + luck * 0.015, 0.0, 0.45)


## Player attack against an enemy. Returns {"dmg": int, "crit": bool}.
static func player_damage(atk: int, defense: int, luck: int, rng: RandomNumberGenerator) -> Dictionary:
	var raw := float(atk) * rng.randf_range(0.9, 1.15)
	var crit := rng.randf() < crit_chance(luck)
	if crit:
		raw *= 2.0
	raw -= defense * 0.4
	return {"dmg": maxi(1, int(round(raw))), "crit": crit}


## Enemy attack against the player (mitigated by DEF). Returns final int dmg.
static func enemy_damage(attack: int, defense: int, rng: RandomNumberGenerator) -> int:
	var raw := float(attack) * rng.randf_range(0.85, 1.1)
	raw *= (1.0 - clampf(defense * 0.035, 0.0, 0.6))
	return maxi(1, int(round(raw)))


static func weighted_pick(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for k in weights:
		total += float(weights[k])
	if total <= 0.0:
		return ""
	var pick := rng.randf() * total
	var keys := weights.keys()
	keys.sort()
	for k in keys:
		pick -= float(weights[k])
		if pick <= 0.0:
			return k
	return keys[keys.size() - 1]


## Combine base stats + equipment mods + temp buffs (all ints).
static func combine(base: int, equip_sum: int, buff_pct: float, disabled_equipment: bool) -> int:
	var eff := base + (0 if disabled_equipment else equip_sum)
	return maxi(1, int(round(eff * (1.0 + buff_pct))))
