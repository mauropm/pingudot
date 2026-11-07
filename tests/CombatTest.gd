extends Node
## Combat + input integration test:
##  - WASD movement actually moves the player
##  - J melee damages an enemy
##  - L ranged disc damages an enemy
##  - K special consumes energy and damages enemies
##  - enemy contact damage hurts the player
##  - enemy projectiles hurt the player

var passed := 0
var failed := 0
var player: Player
var world: LevelDirector


func check(cond: bool, label: String) -> void:
	if cond:
		passed += 1
		print("  ok: " + label)
	else:
		failed += 1
		printerr("  FAIL: " + label)


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func key_down(code: int) -> void:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = code
	ev.physical_keycode = code
	Input.parse_input_event(ev)
	await frames(2)
	var up := InputEventKey.new()
	up.pressed = false
	up.keycode = code
	up.physical_keycode = code
	Input.parse_input_event(up)


func clear_enemies() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	await frames(3)


func heal_full() -> void:
	GameState.stats.hp = GameState.stats.max_hp
	player._iframes = 0.0
	player._enter(Player.State.FREE)


func spawn(kind: String, offset: Vector2, elite := false) -> EnemyBase:
	world._spawn_enemy(kind, player.global_position + offset, elite)
	await frames(3)
	var es := get_tree().get_nodes_in_group("enemies")
	return es[es.size() - 1] as EnemyBase


func _ready() -> void:
	await frames(5)
	print("== COMBAT / INPUT ==")
	Main.start_new_game(424242)
	Main.begin_mission()
	await frames(20)
	world = Main.world
	player = world.player
	Main.dialogue_box.reset()
	await frames(5)

	# 1) movement via WASD
	clear_enemies()
	heal_full()
	var x0 := player.global_position.x
	Input.action_press("move_right")
	await frames(20)
	Input.action_release("move_right")
	await frames(2)
	check(player.global_position.x > x0 + 4.0, "D/WASD moves the player right")
	# specifically the physical D key
	var x1 := player.global_position.x
	await key_down(KEY_D)
	Input.action_press("move_right")
	await frames(12)
	Input.action_release("move_right")
	await frames(2)
	check(player.global_position.x > x1, "physical D key is bound to movement")

	# 2) melee attack (J)
	clear_enemies()
	heal_full()
	player.facing = Vector2.RIGHT
	var e1 := await spawn("bsdemon", Vector2(26, 0))
	e1.set_physics_process(false)   # keep it perfectly still for the hit test
	await frames(2)
	await key_down(KEY_J)
	await frames(24)
	check(e1 == null or not is_instance_valid(e1) or e1.is_dead() or e1.hp < e1.max_hp,
		"J melee damages an adjacent enemy")

	# 3) ranged attack (L)
	clear_enemies()
	heal_full()
	player.facing = Vector2.RIGHT
	var e2 := await spawn("bsdemon", Vector2(52, 0))
	var hp2 := e2.hp
	var proj_before := get_tree().get_nodes_in_group("effects")[0].get_child_count()
	await key_down(KEY_L)
	await frames(3)
	var proj_after := get_tree().get_nodes_in_group("effects")[0].get_child_count()
	check(proj_after > proj_before, "L spawns a visible disc projectile")
	await frames(40)
	check(not is_instance_valid(e2) or e2.is_dead() or e2.hp < hp2,
		"L disc hits an enemy at range")

	# 4) special ability (K) — kernel panic
	clear_enemies()
	heal_full()
	GameState.unlocked_abilities.clear()
	for id in AbilityRegistry.list_ids():
		GameState.unlocked_abilities.append(id)
	GameState.select_ability("kernel_panic")
	GameState.stats.en = GameState.stats.max_en
	var en0 := GameState.stats.en
	var e3 := await spawn("bsdemon", Vector2(26, 0))
	var hp3 := e3.hp
	await key_down(KEY_K)
	await frames(20)
	check(GameState.stats.en < en0, "K consumes energy")
	check(not is_instance_valid(e3) or e3.is_dead() or e3.hp < hp3,
		"K special damages a nearby enemy")

	# 5) enemy projectile hits the player
	clear_enemies()
	heal_full()
	GameState.stats.hp = GameState.stats.max_hp
	var hp_before := GameState.stats.hp
	FX.shoot("fireball", player.global_position + Vector2(40, 0), Vector2.LEFT,
		10, "enemy", 120.0)
	await frames(35)
	check(GameState.stats.hp < hp_before, "enemy projectile damages the player")

	# 6) contact damage from walking into an enemy
	clear_enemies()
	heal_full()
	var hp_c := GameState.stats.hp
	await spawn("bsdemon", Vector2(9, 0))
	await frames(80)
	check(GameState.stats.hp < hp_c, "touching an enemy causes damage")

	# 7) enemy fire still hurts while you are touching an enemy
	clear_enemies()
	heal_full()
	var e7 := await spawn("bsdemon", Vector2(9, 0))
	await frames(30)               # get contact-damaged at least once
	e7.set_physics_process(false)  # stop further contact/melee for isolation
	heal_full()
	GameState.stats.hp = 40
	var hp7 := GameState.stats.hp
	FX.shoot("fireball", player.global_position + Vector2(30, 0), Vector2.LEFT,
		10, "enemy", 120.0)
	await frames(35)
	check(GameState.stats.hp < hp7, "enemy fire hurts while in contact")

	# 8) UI keys I / C
	clear_enemies()
	heal_full()
	await key_down(KEY_I)
	await frames(5)
	check(Main.modal is InventoryScreen, "I opens the inventory")
	Main.close_modal()
	await frames(3)
	await key_down(KEY_C)
	await frames(5)
	check(Main.modal is StatsScreen, "C opens the character screen")
	Main.close_modal()
	await frames(3)

	print("")
	print("COMBAT RESULTS: %d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)
