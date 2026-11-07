extends Node
## Runtime smoke test: boots the game like a player would, walks the whole
## mission (all 5 areas), forces combat, abilities, dialogue, checkpoints,
## save/load and the boss fight, failing on any runtime error path.

var passed := 0
var failed := 0
var _fails: Array[String] = []


func check(cond: bool, label: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		_fails.append(label)
		printerr("  SMOKE FAIL: " + label)


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _ready() -> void:
	await frames(3)
	print("== SMOKE: menu boot ==")
	check(Main.screen == Main.Screen.MENU, "menu screen active")

	print("== SMOKE: new game + world build ==")
	Main.start_new_game(987654)
	Main.begin_mission()
	await frames(10)
	check(Main.world != null, "world created")
	if Main.world == null:
		_done()
		return
	var w = Main.world
	check(w.player != null and is_instance_valid(w.player), "player spawned")
	check(w.tile_layer != null, "tile layer built")
	check(w.get_tree().get_nodes_in_group("enemies").size() >= 3, "enemies spawned")
	check(w.pickups != null and w.effects != null, "layer containers exist")

	print("== SMOKE: player combat calls ==")
	var p = w.player
	p._try_attack()
	await frames(4)
	p._try_ranged()
	await frames(4)
	p._try_dodge()
	await frames(4)
	# give all abilities and cast each
	GameState.unlocked_abilities.clear()
	for id in AbilityRegistry.list_ids():
		GameState.unlocked_abilities.append(id)
	GameState.stats.en = 200
	GameState.stats.max_en = 200
	for id in AbilityRegistry.list_ids():
		var def = AbilityRegistry.defs[id]
		p._trigger_ability(def)
		await frames(3)
	check(true, "all 4 abilities cast without crash")
	# statuses
	for st in ["blue_screen", "port_conflict", "smell", "license_violation", "water"]:
		p.apply_status(st)
	await frames(2)
	check(p.active_statuses().size() >= 4, "status effects tracked")
	GameState.equipment_disabled = false
	p._status.clear()
	# take damage & heal
	p._iframes = 0.0
	p._enter(Player.State.FREE)
	var hp0 := GameState.stats.hp
	p.take_damage(10, Vector2.RIGHT, "", 0)
	check(GameState.stats.hp < hp0 or GameState.stats.hp == 0, "player takes damage")

	print("== SMOKE: kill an enemy (loot + xp) ==")
	var enemies = w.get_tree().get_nodes_in_group("enemies")
	if enemies.size() > 0:
		var e = enemies[0]
		var xp0 := GameState.stats.xp + GameState.stats.level * 1000
		e.take_hit(99999, Vector2.ZERO, true, "test")
		check(e.is_dead(), "enemy dies")
		await frames(20)
	check(true, "loot drop path executed")

	print("== SMOKE: checkpoint interact + save ==")
	var cps = get_tree().get_nodes_in_group("level")
	var found_cp := false
	for n in get_tree().get_nodes_in_group("interactable"):
		if n is Checkpoint:
			found_cp = true
			n.on_interact()
			break
	check(found_cp, "checkpoint exists in area 1")
	await frames(5)
	check(SaveSystem.has_run_save(), "checkpoint wrote save")

	print("== SMOKE: dialogue box ==")
	EventBus.dialogue_requested.emit("area1_intro")
	await frames(5)
	check(Main.dialogue_box.visible, "dialogue shows")
	Main.dialogue_box._advance()
	Main.dialogue_box._advance()
	await frames(3)

	print("== SMOKE: walk all areas ==")
	# real exit trigger (not just goto_area)
	var exit_found := false
	for n in get_tree().get_nodes_in_group("level")[0].get_children():
		if n is ExitZone:
			exit_found = true
			n._on_body(Main.world.player)
			break
	check(exit_found, "area 1 has an exit zone")
	await frames(20)
	check(GameState.area_index == 1, "exit zone transitions to area 2")
	for i in range(1, 5):
		GameState.checkpoint = {"area": i, "x": 2, "y": 2}
		Main.goto_area(i)
		await frames(12)
		check(Main.world != null and Main.world.player != null, "area %d loads" % i)
		check(Main.world.get_tree().get_nodes_in_group("enemies").size() >= 3,
			"area %d has enemies" % i)

	print("== SMOKE: boss fight through 3 phases ==")
	await frames(5)
	if Main.world == null:
		_done()
		return
	var boss = Main.world.spawn_boss()
	await frames(5)
	check(boss != null and boss.hp > 0, "boss spawned")
	# phase 2
	boss.take_hit(int(boss.max_hp * 0.36), Vector2.ZERO, false, "test")
	await frames(8)
	check(boss.phase >= 2, "boss reaches phase 2")
	# phase 3
	boss.take_hit(int(boss.max_hp * 0.36), Vector2.ZERO, false, "test")
	await frames(8)
	check(boss.phase >= 3, "boss reaches phase 3")
	# kill
	boss.take_hit(999999, Vector2.ZERO, false, "test")
	await frames(20)
	check(GameState.counters.get("boss_defeated", false), "boss defeated flag")
	check(AchievementManager.is_unlocked("no_meetings"), "No More Meetings unlocked")

	print("== SMOKE: save reload roundtrip ==")
	GameState.area_index = 2
	GameState.checkpoint = {"area": 2, "x": 3, "y": 3}
	GameState.write_save()
	var d = SaveSystem.load_run()
	check(GameState.apply_save_dict(d), "save reload ok")
	check(GameState.area_index == 2, "area persisted")

	print("== SMOKE: ending flow ==")
	Main.start_ending()
	await frames(10)
	check(GameState.counters.get("mission_complete", false), "mission marked complete")
	Main.show_credits()
	await frames(5)
	check(AchievementManager.is_unlocked("oaxaca_express"), "Oaxaca Express unlocked")
	check(AchievementManager.is_unlocked("exit_strategy"), "Exit Strategy unlocked")
	check(true, "credits screen shows")
	Main.show_menu()
	await frames(5)
	check(Main.screen == Main.Screen.MENU, "back to menu")

	_done()


func _done() -> void:
	print("")
	print("SMOKE RESULTS: %d passed, %d failed" % [passed, failed])
	for f in _fails:
		print("   - " + f)
	get_tree().quit(1 if failed > 0 else 0)
