extends Node2D
class_name LevelDirector
## Loads a handcrafted area grid from res://data/levels/areaN.json, builds the
## TileMapLayer + collision, then spawns entities with seeded (roguelite)
## randomization for enemies, loot, props and events. The boss run stays
## deterministic.

const TILE := 16.0
const AREAS := ["area1", "area2", "area3", "area4", "area5"]
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const ENEMY_SCENES := {
	"bsdemon": preload("res://scenes/enemies/BSDemon.tscn"),
	"littlebill": preload("res://scenes/enemies/LittleBill.tscn"),
	"gplhipster": preload("res://scenes/enemies/GPLHipster.tscn"),
	"secbot": preload("res://scenes/enemies/SecurityBot.tscn"),
}
const BOSS_SCENE := preload("res://scenes/bosses/CTOTechBoss.tscn")
const CHECKPOINT_SCENE := preload("res://scenes/objects/Checkpoint.tscn")
const EXIT_SCENE := preload("res://scenes/objects/ExitZone.tscn")
const HAZARD_SCENE := preload("res://scenes/objects/Hazard.tscn")
const WATER_SCENE := preload("res://scenes/objects/WaterZone.tscn")
# grid value -> atlas column in the per-area tileset
const TILEMAP := {0: 0, 1: 1, 2: 2, 3: 3, 8: 5, 9: 12}
# tier digit -> enemy count for a spawn marker
const TIER_COUNT := {1: 1, 2: 1, 3: 2, 4: 2, 5: 3, 6: 3}

var area_index := 0
var map: Dictionary
var w := 60
var h := 40
var grid: Array = []
var tile_layer: TileMapLayer
var player: Player
var enemies: Array[Node] = []
var boss: Node = null
var rng := RandomNumberGenerator.new()

var ground: Node2D
var walls_body: StaticBody2D
var effects: Node2D
var pickups: Node2D


func _ready() -> void:
	add_to_group("level")
	load_area(GameState.area_index, true)


func load_area(index: int, from_checkpoint: bool) -> void:
	area_index = index
	GameState.area_index = index
	var path := "res://data/levels/%s.json" % AREAS[index]
	map = JSON.parse_string(FileAccess.get_file_as_string(path))
	w = int(map["w"])
	h = int(map["h"])
	grid = map["grid"]
	rng.seed = GameState.seed_value + index * 1013   # deterministic per run+area

	_clear()
	_build_tiles()
	_build_zones()
	_build_parallax()
	_build_collisions()
	_spawn_player(from_checkpoint)
	_spawn_entities()
	_finalize(index)


func _clear() -> void:
	for c in get_children():
		c.queue_free()


func _build_tiles() -> void:
	tile_layer = TileMapLayer.new()
	tile_layer.name = "Ground"
	var ts := TileSet.new()
	var tex := load("res://assets/environments/tilesets/%s.png" % AREAS[area_index])
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(TILE, TILE)
	for col in 13:
		src.create_tile(Vector2i(col, 0))
	ts.add_source(src, 0)
	tile_layer.tile_set = ts
	add_child(tile_layer)
	for yy in h:
		for xx in w:
			var v: int = grid[yy * w + xx]
			var atlas_col := TILEMAP.get(v, 0)
			tile_layer.set_cell(Vector2i(xx, yy), 0, Vector2i(atlas_col, 0))


func _build_zones() -> void:
	# Merge runs of grid value 8 (hazard) / 9 (water) into Area2D zones.
	var y := 0
	while y < h:
		var x := 0
		while x < w:
			var v: int = grid[y * w + x]
			if v == 8 or v == 9:
				var run := 0
				while x + run < w and grid[y * w + x + run] == v:
					run += 1
				var zone: Area2D
				if v == 8:
					var hz := HAZARD_SCENE.instantiate() as Hazard
					hz.damage = 3 + area_index * 2
					zone = hz
				else:
					zone = WATER_SCENE.instantiate() as WaterZone
				zone.position = Vector2((x + run * 0.5) * TILE, (y + 0.5) * TILE)
				var sh := CollisionShape2D.new()
				var rect := RectangleShape2D.new()
				rect.size = Vector2(run * TILE, TILE)
				sh.shape = rect
				zone.add_child(sh)
				add_child(zone)
				x += run
			else:
				x += 1
		y += 1


func _build_parallax() -> void:
	var pb := ParallaxBackground.new()
	pb.name = "Backdrop"
	pb.layer = -10
	add_child(pb)
	for spec in [
		{"scale": Vector2(0.25, 0.0), "mod": Color(0.75, 0.75, 1.0, 1.0)},
		{"scale": Vector2(0.55, 0.0), "mod": Color(1, 1, 1, 1)},
	]:
		var layer := ParallaxLayer.new()
		layer.motion_scale = spec["scale"]
		layer.motion_mirroring = Vector2(384, 0)
		pb.add_child(layer)
		var bg := Sprite2D.new()
		bg.texture = load("res://assets/environments/backgrounds/%s_bg.png" % AREAS[area_index])
		bg.centered = false
		bg.modulate = spec["mod"]
		layer.add_child(bg)


func _build_collisions() -> void:
	walls_body = StaticBody2D.new()
	walls_body.name = "Walls"
	walls_body.collision_layer = 1
	walls_body.collision_mask = 0
	add_child(walls_body)
	# horizontal run merge for efficiency
	var yy := 0
	while yy < h:
		var xx := 0
		while xx < w:
			if _is_solid(xx, yy):
				var run := 0
				while xx + run < w and _is_solid(xx + run, yy):
					run += 1
				var shape := CollisionShape2D.new()
				var rect := RectangleShape2D.new()
				rect.size = Vector2(run * TILE, TILE)
				shape.shape = rect
				shape.position = Vector2((xx + run / 2.0) * TILE, (yy + 0.5) * TILE)
				walls_body.add_child(shape)
				xx += run
			else:
				xx += 1
		yy += 1


func _is_solid(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= w or y >= h:
		return true
	return grid[y * w + x] == 3


func _spawn_player(from_cp: bool) -> void:
	player = PLAYER_SCENE.instantiate() as Player
	var tile := _spawn_tile(from_cp)
	player.position = Vector2(tile.x * TILE + 8, tile.y * TILE - 6)
	add_child(player)
	player.cam.limit_left = -64
	player.cam.limit_top = -64
	player.cam.limit_right = int(w * TILE) + 64
	player.cam.limit_bottom = int(h * TILE) + 64
	# effects + pickups containers
	effects = Node2D.new()
	effects.name = "Effects"
	effects.add_to_group("effects")
	add_child(effects)
	pickups = Node2D.new()
	pickups.name = "Pickups"
	pickups.add_to_group("pickups")
	add_child(pickups)


func _spawn_tile(from_cp: bool) -> Vector2i:
	if from_cp and GameState.checkpoint.get("area", -1) == area_index:
		return Vector2i(GameState.checkpoint.get("x", 2), GameState.checkpoint.get("y", 2))
	# default: first safe floor tile scanning from the south-west
	for yy in range(h - 6, h):
		for xx in range(1, w):
			var v: int = grid[yy * w + xx]
			if v != 3 and v != 8 and v != 9:
				return Vector2i(xx, yy)
	for yy in range(1, h):
		for xx in range(1, w):
			var v2: int = grid[yy * w + xx]
			if v2 != 3 and v2 != 8 and v2 != 9:
				return Vector2i(xx, yy)
	return Vector2i(2, 2)


func _tile_center(x: int, y: int) -> Vector2:
	return Vector2(x * TILE + 8, y * TILE + 8)


# ----------------------------------------------------------------- spawns ----
func _spawn_entities() -> void:
	var ents: Array = map["entities"]
	var pool: Array = map.get("enemy_pool", ["bsdemon"])
	for e in ents:
		var pos := _tile_center(e["x"], e["y"])
		match e["kind"]:
			"enemy":
				_spawn_enemy_group(e, pos, pool)
			"loot":
				_spawn_loot(pos)
			"exit":
				if area_index < GameState.TOTAL_AREAS - 1:
					_spawn_exit(pos, area_index + 1)
			"checkpoint":
				_spawn_checkpoint(pos, Vector2i(e["x"], e["y"]))
			"vendor":
				_spawn_vendor(pos)
			"atm":
				_spawn_atm(pos)
			"hidden":
				_spawn_hidden(pos)
			"joke":
				_spawn_joke(pos)
			"prop":
				_spawn_prop(pos)
			"bossgate":
				if area_index == GameState.TOTAL_AREAS - 1:
					pass  # the boss trigger is set up in _setup_boss_room
				else:
					_spawn_exit(pos, area_index + 1)
	# Area 5: spawn the boss arena trigger near the top
	if area_index == GameState.TOTAL_AREAS - 1:
		_setup_boss_room()


func _spawn_enemy_group(e: Dictionary, pos: Vector2, pool: Array) -> void:
	var tier: int = clampi(int(e.get("tier", 1)), 1, 6)
	var count: int = TIER_COUNT.get(tier, 1)
	for i in range(count):
		var name := String(pool[rng.randi() % pool.size()])
		var elite := tier >= 4 and rng.randf() < (0.5 if area_index >= 3 else 0.25)
		if elite and not name.ends_with("_elite"):
			name = name + "_elite"
		var ang := rng.randf() * TAU
		var off := Vector2(cos(ang), sin(ang)) * (10.0 + i * 9.0) + Vector2(0, -4)
		_spawn_enemy(name, pos + off, elite)


func _spawn_enemy(name: String, pos: Vector2, elite: bool) -> void:
	var base := name.trim_suffix("_elite")
	var scene: PackedScene = ENEMY_SCENES.get(base, ENEMY_SCENES["bsdemon"])
	var e := scene.instantiate() as EnemyBase
	e.kind = name if elite else base
	e.elite = elite
	e.position = pos
	add_child(e)
	e.scale_for_area(area_index)
	enemies.append(e)


func _spawn_loot(pos: Vector2) -> void:
	LootSystem.spawn_world_drop(pos, rng, area_index, GameState.stats.effective_luck(), true)


func _spawn_exit(pos: Vector2, next_index: int) -> void:
	var x := EXIT_SCENE.instantiate() as ExitZone
	x.position = pos
	x.next_index = next_index
	add_child(x)


func _spawn_checkpoint(pos: Vector2, tile: Vector2i) -> void:
	var c := CHECKPOINT_SCENE.instantiate() as Checkpoint
	c.position = pos
	c.area_index = area_index
	c.tile = tile
	add_child(c)


func _spawn_prop(pos: Vector2) -> void:
	var props: Array = map.get("props", ["desk"])
	var pname := String(props[rng.randi() % props.size()])
	var path := "res://assets/environments/objects/%s.png" % pname
	if not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	var p := ScriptedInteractable.new()
	p.position = pos
	add_child(p)
	p.set_texture(tex)
	if tex.get_height() > 20:
		p.set_sprite_offset(Vector2(0, -6))
	if rng.randf() < 0.28:
		var jd: Array = map.get("jokes", ["joke_1"])
		var jid := String(jd[rng.randi() % jd.size()])
		p.hint_text = "READ [E]"
		p._action = func(): EventBus.dialogue_requested.emit(jid)


func _spawn_vendor(pos: Vector2) -> void:
	var v := ScriptedInteractable.new()
	v.position = pos
	add_child(v)
	v.configure(load("res://assets/environments/objects/vendor.png"),
		"VENDING [E]", _do_vendor)


func _do_vendor() -> void:
	EventBus.dialogue_requested.emit("ev_vend")
	AudioDirector.play_sfx("item_get")
	var roll := rng.randf()
	var it: ItemResource = null
	if roll < 0.4:
		it = ItemRegistry.consumable("heal_big", 1)
	elif roll < 0.75:
		it = ItemRegistry.consumable("en_big", 1)
	else:
		it = ItemRegistry.consumable("coffee", 1)
	if it != null:
		GameState.add_item(it)


func _spawn_atm(pos: Vector2) -> void:
	var a := ScriptedInteractable.new()
	a.position = pos
	add_child(a)
	a.configure(load("res://assets/environments/objects/atm.png"), "ATM [E]", _do_atm)


func _do_atm() -> void:
	EventBus.dialogue_requested.emit("ev_atm")
	var roll := rng.randf()
	if roll < 0.5:
		GameState.add_coins(rng.randi_range(3, 12))
		AudioDirector.play_sfx("coin")
	else:
		if player and not player.is_dead():
			player.take_damage(4, Vector2.UP, "hazard", 0)
		AudioDirector.play_sfx("glitch")


func _spawn_hidden(pos: Vector2) -> void:
	var c := ScriptedInteractable.new()
	c.position = pos
	add_child(c)
	c.configure(load("res://assets/environments/objects/chest.png"),
		"OPEN [E]", _do_hidden, true)


func _do_hidden() -> void:
	GameState.counters["hidden_found"] += 1
	AchievementManager.on_hidden_found()
	EventBus.dialogue_requested.emit("joke_9")
	LootSystem.spawn_chest_content(player.global_position if player else Vector2.ZERO, 2)
	AudioDirector.play_sfx("item_get")


func _spawn_joke(pos: Vector2) -> void:
	var j := ScriptedInteractable.new()
	j.position = pos
	add_child(j)
	var jd: Array = map.get("jokes", ["joke_1"])
	var jid := String(jd[rng.randi() % jd.size()])
	j.configure(load("res://assets/ui/star.png"), "INSPECT [E]",
		func(): EventBus.dialogue_requested.emit(jid))


func _finalize(index: int) -> void:
	# Autosave at the start of each area: a fair checkpoint for the run.
	var st := _spawn_tile(true)
	GameState.checkpoint = {"area": index, "x": st.x, "y": st.y}
	GameState.area_index = index
	GameState.started = true
	GameState.write_save()
	_spawn_events()
	EventBus.area_entered.emit(index, GameState.area_names[index])
	EventBus.objective_updated.emit(GameState.objectives.get(index, ""))
	AudioDirector.play_music(map.get("music", "area%d" % (index + 1)))
	var intro_line := "area%d_intro" % (index + 1)
	if GameState.character_id == "miggy":
		intro_line = "miggy_intro" if index == 0 else "miggy_area%d" % (index + 1)
	EventBus.dialogue_requested.emit(intro_line)


func point_is_solid(global_pos: Vector2) -> bool:
	return _is_solid(int(global_pos.x / TILE), int(global_pos.y / TILE))


# ------------------------------------------------------------------- events ----
func _spawn_events() -> void:
	# 2 random scripted encounters per area from the area's event pool.
	var pool: Array = map.get("events", [])
	if pool.is_empty():
		return
	var candidates: Array[Vector2i] = []
	var entry := _spawn_tile(true)
	for yy in range(2, h - 2):
		for xx in range(2, w - 2):
			var v: int = grid[yy * w + xx]
			if v in [0, 1] and Vector2i(xx, yy).distance_to(entry) > 6.0:
				candidates.append(Vector2i(xx, yy))
	if candidates.is_empty():
		return
	var count := mini(2, candidates.size())
	for i in count:
		var t: Vector2i = candidates[rng.randi() % candidates.size()]
		var ev_id := String(pool[rng.randi() % pool.size()])
		var pos := _tile_center(t.x, t.y)
		var node := ScriptedInteractable.new()
		node.position = pos
		add_child(node)
		node.configure(load("res://assets/ui/star.png"), "ENCOUNTER [E]",
			func(): _run_event(ev_id), true)


func _run_event(ev_id: String) -> void:
	EventBus.dialogue_requested.emit(ev_id)
	var roll := rng.randf()
	match ev_id:
		"ev_pitch":
			GameState.add_coins(rng.randi_range(8, 20))
			GameState.gain_xp(10 + area_index * 6)
		"ev_vend", "ev_intern":
			var it := ItemRegistry.consumable("en_small" if roll < 0.5 else "heal_small", 1)
			GameState.add_item(it)
		"ev_meme":
			GameState.stats.hp = mini(GameState.stats.max_hp, GameState.stats.hp + 20)
			EventBus.player_hp_changed.emit(GameState.stats.hp, GameState.stats.max_hp)
		"ev_drone":
			if roll < 0.5 and player:
				player.take_damage(6 + area_index * 2, Vector2.UP, "", 0)
			else:
				GameState.add_coins(14)
		"ev_shark":
			GameState.add_coins(20)
			GameState.add_item(ItemRegistry.consumable("cookie", 1))
		"ev_elevator":
			GameState.gain_xp(20)
		_:
			GameState.add_coins(rng.randi_range(5, 12))
func _setup_boss_room() -> void:
	# Boss arena is the top block of Area 5; place a trigger line.
	var trig := Area2D.new()
	trig.position = Vector2(19 * TILE + 8, 2 * TILE)
	trig.collision_layer = 0
	trig.collision_mask = 2
	var sh := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(w * TILE, TILE)
	sh.shape = r
	trig.add_child(sh)
	add_child(trig)
	trig.body_entered.connect(_on_boss_trigger)
	# store arena bounds for later
	_boss_arena_top = 2


var _boss_arena_top := 0
var _boss_started := false


func _on_boss_trigger(body: Node) -> void:
	if _boss_started or not (body is Player):
		return
	_boss_started = true
	GameState.counters["area_reached"] = 5
	AchievementManager.on_abilities_full()
	EventBus.dialogue_requested.emit("cto_intro")
	AudioDirector.play_music("boss", 1.0)
	await get_tree().create_timer(1.6).timeout
	if not is_instance_valid(self):
		return
	spawn_boss()


func spawn_boss() -> CTOTechBoss:
	boss = BOSS_SCENE.instantiate() as CTOTechBoss
	boss.position = Vector2(19 * TILE + 8, 8 * TILE)
	add_child(boss)
	boss.scale_for_area(area_index)
	boss.phase_changed.connect(func(p): EventBus.boss_phase_started.emit(p))
	boss.boss_died.connect(_on_boss_dead)
	return boss


func _on_boss_dead() -> void:
	if player != null and is_instance_valid(player):
		player.play_victory()
	EventBus.dialogue_requested.emit("cto_die")
	await get_tree().create_timer(1.8).timeout
	if is_instance_valid(self):
		EventBus.dialogue_requested.emit("cto_outro")
		await get_tree().create_timer(2.2).timeout
		Main.start_ending()
