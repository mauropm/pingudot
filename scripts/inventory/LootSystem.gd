extends Node
class_name LootSystem

const LOOT_PICKUP_SCENE := preload("res://scenes/objects/LootPickup.tscn")
const COIN_PICKUP_SCENE := preload("res://scenes/objects/CoinPickup.tscn")
## Static loot-drop helper: rolls item + coins on enemy death, spawns pickups.
## Deterministic given the run seed (uses GameState.roll_rng()).


static func on_enemy_died(enemy: EnemyBase) -> void:
	var rng := GameState.roll_rng()
	var luck := GameState.stats.effective_luck()
	var item := ItemRegistry.roll_item(rng, enemy.area_index, luck)
	if item != null:
		_spawn_pickup(enemy.global_position + Vector2(randf_range(-6, 6), -4), item)
	var coins := rng.randi_range(3, 7) + enemy.area_index * 4 + (6 if enemy.elite else 0)
	_spawn_coins(enemy.global_position, coins)
	if rng.randf() < 0.30:
		var heal := ItemRegistry.consumable("heal_small", 1)
		if heal != null:
			_spawn_pickup(enemy.global_position + Vector2(8, 0), heal)


static func spawn_world_drop(pos: Vector2, rng: RandomNumberGenerator, area: int, luck: int, guaranteed := false) -> void:
	var item := ItemRegistry.roll_item(rng, area, luck)
	if item == null and guaranteed:
		var rarities := ["common", "rare", "epic", "legendary"]
		item = ItemRegistry.make_item(rng, rarities[min(rng.randi_range(0, 1 + area), 3)])
	if item != null:
		_spawn_pickup(pos, item)
		_spawn_coins(pos, rng.randi_range(4, 12) + area * 4)


## Chests / hidden rooms: guaranteed roll with rarity boost.
static func spawn_chest_content(pos: Vector2, boost := 0) -> void:
	var rng := GameState.roll_rng()
	var area := clampi(GameState.area_index + boost, 0, 4)
	var item := ItemRegistry.roll_item(rng, area, 6)
	if item != null:
		_spawn_pickup(pos, item)
	_spawn_coins(pos, rng.randi_range(8, 18) + area * 5)
	if rng.randf() < 0.6:
		var patch := ItemRegistry.consumable("patch_software", 1)
		if patch != null:
			_spawn_pickup(pos + Vector2(10, 0), patch)


static func _layer() -> Node2D:
	var tree := Engine.get_main_loop() as SceneTree
	var c := tree.get_first_node_in_group("pickups")
	return c as Node2D


static func _spawn_pickup(pos: Vector2, item: ItemResource) -> void:
	var parent := _layer()
	if parent == null:
		return
	var p := LOOT_PICKUP_SCENE.instantiate() as LootPickup
	p.item = item
	p.position = pos
	parent.add_child(p)


static func _spawn_coins(pos: Vector2, amount: int) -> void:
	var parent := _layer()
	if parent == null:
		return
	var n := mini(3, maxi(1, int(amount / 4.0)))
	for i in n:
		var c := COIN_PICKUP_SCENE.instantiate() as CoinPickup
		c.amount = int(ceilf(amount / float(n)))
		c.position = pos + Vector2(randf_range(-8, 8), randf_range(-4, 4))
		parent.add_child(c)
