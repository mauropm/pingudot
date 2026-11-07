extends Node
## ItemRegistry — loads res://data/items.json into typed ItemResource defs and
## rolls randomized loot (seeded per run) influenced by area depth and LUCK.

const ITEMS_PATH := "res://data/items.json"
const LOOT_PATH := "res://data/loot/tables.json"

var defs: Dictionary = {}        # id -> ItemResource (template)
var loot: Dictionary = {}
var slot_icons: Dictionary = {}


func _ready() -> void:
	_load()


func _load() -> void:
	var items = JSON.parse_string(FileAccess.get_file_as_string(ITEMS_PATH))
	defs.clear()
	if items is Array:
		for it in items:
			var r := ItemResource.new()
			r.id = it["id"]
			r.display_name = it["name"]
			r.rarity = it["rarity"]
			r.slot = it["slot"]
			r.description = it["desc"]
			r.mods = it["mods"]
			for k in r.mods.keys():
				if r.mods[k] is float:
					r.mods[k] = int(r.mods[k])
			var icon_path := "res://assets/ui/items/%s.png" % r.id
			if ResourceLoader.exists(icon_path):
				r.icon = load(icon_path)
			defs[r.id] = r
	var lt = JSON.parse_string(FileAccess.get_file_as_string(LOOT_PATH))
	if lt is Dictionary:
		loot = lt


## Roll a rarity tier from area depth + luck. Returns "" for "nothing".
func roll_rarity(rng: RandomNumberGenerator, area_index: int, luck: int) -> String:
	var chance: float = float(loot.get("drop_chance", 0.5)) + luck * 0.01
	if rng.randf() > chance:
		return ""
	var w: Dictionary = loot["weights_base"].duplicate()
	var shift := int(loot.get("area_weight_shift", 5)) * area_index
	w["common"] = maxf(10.0, w["common"] - shift)
	w["rare"] = w["rare"] + shift * 0.4
	w["epic"] = w["epic"] + shift * 0.25
	w["legendary"] = w["legendary"] + shift * 0.1 + luck * 0.25
	var total := 0.0
	for k in w:
		total += w[k]
	var pick := rng.randf() * total
	for k in ["legendary", "epic", "rare", "common"]:
		pick -= w[k]
		if pick <= 0.0:
			return k
	return "common"


## Full roll: returns a fresh ItemResource instance or null.
func roll_item(rng: RandomNumberGenerator, area_index: int, luck: int) -> ItemResource:
	var rarity := roll_rarity(rng, area_index, luck)
	if rarity == "":
		return null
	return make_item(rng, rarity_of_pool(rarity, area_index))


func rarity_of_pool(rarity: String, _area_index: int) -> String:
	return rarity


## Pick a random item id of the given rarity and instantiate it.
func make_item(rng: RandomNumberGenerator, rarity: String) -> ItemResource:
	var candidates: Array[String] = []
	for id in defs:
		if defs[id].rarity == rarity:
			candidates.append(id)
	if candidates.is_empty():
		return null
	candidates.sort()
	var tpl: ItemResource = defs[candidates[rng.randi_range(0, candidates.size() - 1)]]
	return rolled_copy(tpl, rng)


func rolled_copy(tpl: ItemResource, rng: RandomNumberGenerator) -> ItemResource:
	var inst := tpl.duplicate() as ItemResource
	# randomize numeric stat mods +-20% for rarity >= rare (roguelite affixes)
	if inst.rarity != "common":
		for k in inst.mods.keys():
			var v = inst.mods[k]
			if v is int and absi(v) > 0 and k not in ["hp_heal", "en_gain", "count", "clear_cd"]:
				var delta := 1 if v > 0 else -1
				var mag: int = maxi(1, int(round(absi(v) * rng.randf_range(0.8, 1.3))))
				inst.mods[k] = mag * delta
	return inst


func consumable(id: String, qty := 1) -> ItemResource:
	var tpl: ItemResource = defs.get(id)
	if tpl == null:
		return null
	var inst := tpl.duplicate() as ItemResource
	inst.quantity = qty
	return inst
