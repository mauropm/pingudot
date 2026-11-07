extends Resource
class_name ItemResource
## Data definition for one item. Instances are duplicated per pickup so rolled
## modifiers and quantities stay independent.

@export var id: String = ""
@export var display_name: String = ""
@export var rarity: String = "common"          # common|rare|epic|legendary
@export var slot: String = "hardware"          # weapon|armor|boots|hardware|consumable|material
@export var description: String = ""
@export var mods: Dictionary = {}              # stat_id -> int (+ effect keys like hp_heal)
@export var quantity: int = 1
@export var icon: Texture2D

const RARITY_COLORS := {
	"common": Color("9aa4b2"),
	"rare": Color("2d6aff"),
	"epic": Color("#7a3fe8"),
	"legendary": Color("#f7c94b"),
}

const STAT_KEYS := ["atk", "def", "spd", "int", "luck", "crit_pct", "hp"]


func is_equippable() -> bool:
	return slot in ["weapon", "armor", "boots", "hardware"]


func stackable() -> bool:
	return slot in ["consumable", "material"]


func stat_line() -> String:
	var parts: Array[String] = []
	for k in mods.keys():
		if k in STAT_KEYS or k == "crit_pct":
			var v: int = int(mods[k])
			parts.append("%s %+d" % [k.to_upper(), v])
	return ", ".join(parts)
