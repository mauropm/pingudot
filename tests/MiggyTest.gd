extends Node
## MIGGY Easter egg + secret character integration test.

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
		await get_tree().process_frame


func press(key: int) -> void:
	var e := InputEventKey.new()
	e.pressed = true
	e.keycode = key
	e.physical_keycode = key
	Input.parse_input_event(e)
	var u := InputEventKey.new()
	u.pressed = false
	u.keycode = key
	u.physical_keycode = key
	Input.parse_input_event(u)


func type_word(word: String) -> void:
	for ch in word:
		press(KEY_A + (ch.to_upper().unicode_at(0) - 65))
		await frames(1)


func _ready() -> void:
	await frames(6)
	print("== MIGGY EASTER EGG ==")
	# isolate: clear any previous unlock
	SaveSystem.delete_profile()
	GameState.unlocked_characters = {"pingu": true, "miggy": false}
	Main.show_menu()
	await frames(6)
	check(Main.screen == Main.Screen.MENU, "menu shown")
	var menu = Main.overlay.get_child(Main.overlay.get_child_count() - 1)
	check(menu is MainMenuScreen, "main menu instance")

	# invalid sequence doesn't trigger
	await type_word("roox")
	await frames(3)
	check(not GameState.is_character_unlocked("miggy"), "invalid sequence ignored")
	check(Main.screen == Main.Screen.MENU, "menus unaffected while typing")

	# typing in the seed field must not trigger
	menu._seed_edit.grab_focus()
	await type_word("root")
	await frames(2)
	check(not GameState.is_character_unlocked("miggy"), "seed text field is not hijacked")
	menu._focus_first()

	# correct secret
	await type_word("root")
	await frames(4)
	check(GameState.is_character_unlocked("miggy"), "root unlocks MIGGY")
	check(menu.has_node("MiggyCard") or _find_child(menu, "TerminalUnlock") != null,
		"terminal/card appears")
	var term = _find_child(menu, "TerminalUnlock")
	if term != null:
		term.skip()
	await frames(6)
	var card = _find_child(menu, "MiggyCard")
	check(card != null, "MIGGY character card shown")
	if card == null:
		_done()
		return
	check(GameState.is_character_unlocked("miggy"), "unlock persisted in memory")
	var prof = SaveSystem.load_profile()
	check(bool(prof.get("unlocks", {}).get("miggy", false)), "unlock persisted to disk")

	# enter the shell
	await press(KEY_ENTER)
	await frames(25)
	check(GameState.character_id == "miggy", "MIGGY run started")
	check(Main.screen == Main.Screen.GAME, "gameplay active")
	world = Main.world
	check(world != null and world.player != null, "world/player created")
	if world == null:
		_done()
		return
	player = world.player
	check(GameState.ability_ids().size() == 6, "MIGGY has 6 ability slots")
	check(GameState.has_ultimate(), "MIGGY has an ultimate")
	check(player.sprite.sprite_frames.has_animation("ultimate"), "MIGGY atlas loaded")
	Main.dialogue_box.reset()
	await frames(4)

	# level to 6 and unlock all powers for testing
	GameState.stats.level = 6
	GameState._check_ability_unlocks()
	check(GameState.unlocked_abilities.size() == 6, "all six powers unlocked by level 6")

	# spawn a target
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	await frames(3)
	world._spawn_enemy("bsdemon", player.global_position + Vector2(34, 0), false)
	await frames(3)
	var enemy = get_tree().get_nodes_in_group("enemies")[0] as EnemyBase
	enemy.set_physics_process(false)

	for id in ["midnight_collider", "gnome_shell_shock", "mono_overdrive",
			"bonobo_interface", "gobject_factory", "dual_wield"]:
		GameState.stats.en = GameState.stats.max_en
		player._cooldowns.clear()
		GameState.select_ability(id)
		var en0 = GameState.stats.en
		player._try_cast()
		await frames(4)
		check(GameState.stats.en < en0, "cast spends energy: " + id)
		check(player.get_cooldown(id) > 0.0, "cooldown set: " + id)
		var en1 = GameState.stats.en
		player._try_cast()
		check(GameState.stats.en == en1, "cooldown blocks recast: " + id)
		await get_tree().create_timer(0.9).timeout

	check(player._dual != null and is_instance_valid(player._dual), "dual panels active")
	await get_tree().create_timer(9.2).timeout
	check(player._dual == null or not is_instance_valid(player._dual), "dual panels cleaned up")
	check(player._shield_hp <= 0, "temporary shield expired")
	check(player._overdrive_t <= 0.0, "overdrive expired")
	var clones := 0
	for c in get_tree().get_nodes_in_group("effects"):
		for n in c.get_children():
			if n is ForkBombClone:
				clones += 1
	check(clones == 0, "GObject helpers cleaned up")

	# shield absorbs damage (Bonobo) and can reflect projectiles
	player._iframes = 0.0
	player._grant_shield(40, 9.0, 0.0)
	var hp_shield: int = GameState.stats.hp
	var shield_left: int = player._shield_hp
	player.receive_projectile(10, Vector2.RIGHT)
	check(GameState.stats.hp == hp_shield, "shield absorbs projectile damage")
	check(player._shield_hp < shield_left, "shield HP decreases")
	player._reflect_pct = 1.0
	check(player.receive_projectile(10, Vector2.RIGHT) == 2, "shield can reflect projectiles")
	player._expire_shield()

	# all looping one-shot effects must clean up
	await get_tree().create_timer(1.8).timeout
	var strays := 0
	for cont in get_tree().get_nodes_in_group("effects"):
		for n in cont.get_children():
			if n is AnimatedSprite2D and n.animation in ["collider_panel", "gnome_windows", "bonobo_shield"]:
				strays += 1
	check(strays == 0, "temporary power effects cleaned themselves up")

	# ultimate
	GameState.stats.hp = GameState.stats.max_hp
	GameState.ultimate_charge = 100
	world._spawn_enemy("bsdemon", player.global_position + Vector2(60, 20), false)
	await frames(3)
	var target2 = get_tree().get_nodes_in_group("enemies")
	var alive_before := 0
	for e in target2:
		if e is EnemyBase and not e.is_dead():
			alive_before += 1
	player._try_ultimate()
	await frames(3)
	check(Main.modal is MiggyUltimate, "ultimate cinematic shown")
	check(GameState.ultimate_charge == 0, "ultimate meter consumed")
	check(get_tree().paused, "gameplay paused during cinematic")
	var cin = Main.modal
	if cin != null and cin.has_method("skip"):
		cin.skip()
	await frames(6)
	check(not get_tree().paused, "gameplay resumes after cinematic")
	check(not player.frozen, "MIGGY can act after ultimate")
	var alive_after := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is EnemyBase and not e.is_dead():
			alive_after += 1
	check(alive_after < alive_before, "ultimate clears ordinary enemies")

	# boss takes substantial damage but isn't auto-defeated
	var boss = world.spawn_boss()
	await frames(4)
	var boss_hp: int = boss.hp
	GameState.ultimate_charge = 100
	player._iframes = 9.0
	GameState.stats.hp = 999
	player._try_ultimate()
	await frames(3)
	var cin2 = Main.modal
	if cin2 != null and cin2.has_method("skip"):
		cin2.skip()
	await frames(6)
	check(is_instance_valid(boss) and boss.hp < boss_hp, "ultimate damages the boss")
	check(is_instance_valid(boss) and boss.hp > 0, "ultimate does not auto-defeat the boss")

	# save/load keeps the character
	GameState.checkpoint = {"area": 0, "x": 2, "y": 2}
	GameState.write_save()
	var d = SaveSystem.load_run()
	check(GameState.apply_save_dict(d), "MIGGY save reloads")
	check(GameState.character_id == "miggy", "character persisted in save")

	# Pingu still works
	Main.start_new_game(4242, "pingu")
	await frames(3)
	Main.begin_mission()
	await frames(20)
	check(GameState.character_id == "pingu", "Pingu run still starts")
	check(GameState.ability_ids().size() == 4, "Pingu still has 4 abilities")
	check(Main.world != null and Main.world.player != null, "Pingu world loads")
	_done()


func _find_child(root: Node, cls: String) -> Node:
	for c in root.get_children():
		if c.get_class() == "Control" and c.get_script() != null:
			if c.get_script().get_global_name() == cls:
				return c
		var r := _find_child(c, cls)
		if r != null:
			return r
	return null


func _done() -> void:
	print("")
	print("MIGGY RESULTS: %d passed, %d failed" % [passed, failed])
	SaveSystem.delete_profile()
	get_tree().quit(1 if failed > 0 else 0)
