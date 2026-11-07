extends Node
const OUT := "/tmp/miggy_shots"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	await frames(3)
	Main.show_menu()
	await frames(5)
	var menu = Main.overlay.get_child(Main.overlay.get_child_count() - 1)
	SaveSystem.delete_profile()
	GameState.unlocked_characters = {"pingu": true, "miggy": false}
	Main.show_menu()
	await frames(5)
	menu = Main.overlay.get_child(Main.overlay.get_child_count() - 1)
	menu._start_secret()
	await wait(1.4)
	await shot("01_terminal")
	var term = _find(menu, "TerminalUnlock")
	if term != null:
		term.skip()
	await wait(0.8)
	await shot("02_card")
	var card = _find(menu, "MiggyCard")
	if card != null:
		card._enter_shell()
	await wait(3.0)
	await shot("03_gameplay")
	Main.dialogue_box.reset()
	await wait(0.5)
	var w = Main.world
	var p: Player = w.player
	p.global_position = Vector2(200, 340)
	for i in 30: await frames(1)
	GameState.stats.level = 6
	GameState._check_ability_unlocks()
	GameState.stats.en = 200
	GameState.stats.max_en = 200
	GameState.stats.hp = 999
	GameState.stats.max_hp = 999
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	await frames(2)
	w._spawn_enemy("bsdemon", p.global_position + Vector2(60, 0), false)
	w._spawn_enemy("bsdemon", p.global_position + Vector2(-54, 20), false)
	w._spawn_enemy("littlebill", p.global_position + Vector2(20, -48), false)
	await frames(2)
	await shot("04_miggy_idle")
	GameState.select_ability("midnight_collider")
	p._try_cast()
	await wait(0.45)
	await shot("05_collider")
	await wait(0.5)
	await shot("05b_collider_boom")
	await wait(1.0)
	GameState.stats.en = 200
	GameState.select_ability("gnome_shell_shock")
	p._try_cast()
	await wait(0.35)
	await shot("06_gnome")
	await wait(0.8)
	GameState.stats.en = 200
	GameState.select_ability("mono_overdrive")
	p._try_cast()
	await wait(0.6)
	await shot("07_overdrive")
	await wait(0.8)
	GameState.stats.en = 200
	GameState.select_ability("gobject_factory")
	p._try_cast()
	await wait(0.6)
	await shot("08_gobject")
	await wait(0.8)
	GameState.stats.en = 200
	GameState.select_ability("dual_wield")
	p._try_cast()
	await wait(1.0)
	await shot("09_dual")
	await wait(0.5)
	GameState.ultimate_charge = 100
	p._try_ultimate()
	await wait(1.3)
	await shot("10_ult_warning")
	await wait(2.0)
	await shot("11_ult_vortex")
	await wait(1.4)
	await shot("12_ult_segfault")
	await wait(1.5)
	await shot("13_ult_after")
	await wait(1.0)
	Main.start_ending()
	await wait(7.0)
	await shot("14_ending")
	get_tree().quit(0)


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT.path_join(name + ".png"))
	print("SHOT ", name)

func _find(root: Node, cls: String) -> Node:
	for c in root.get_children():
		if c.get_script() != null and c.get_script().get_global_name() == cls:
			return c
		var r := _find(c, cls)
		if r != null: return r
	return null
