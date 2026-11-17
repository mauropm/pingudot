extends Node
## Visual capture: boots the game for real, screenshots key moments.

const OUT := "/tmp/pingudot_shots"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	await _shot("01_menu", 40)
	Main.start_new_game(2026)
	await _shot("01b_intro", 60)
	Main.begin_mission()
	await _shot("02_area1", 70)
	# walk a bit: emulate input via actions
	Input.action_press("move_right")
	await _shot("03_area1_running", 50)
	Input.action_release("move_right")
	Input.action_press("attack")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("attack")
	await _shot("04_attack", 10)
	Main.open_inventory()
	await _shot("05_inventory", 20)
	Main.close_modal()
	Main.open_stats()
	await _shot("06_stats", 20)
	Main.close_modal()
	Main.open_pause()
	await _shot("06b_pause", 10)
	Main.close_modal()
	Main.open_achievements()
	await _shot("06c_achievements", 10)
	Main.close_modal()
	Main.open_settings()
	await _shot("06e_settings", 10)
	Main.close_modal()
	Main._on_player_died()
	await get_tree().create_timer(1.8).timeout
	await _shot("06d_gameover", 5)
	Main.close_modal()
	get_tree().paused = false
	# area 2 / 3 / 4 looks
	GameState.checkpoint = {"area": 1, "x": 2, "y": 2}
	Main.goto_area(1)
	await _shot("07_area2", 50)
	GameState.checkpoint = {"area": 2, "x": 2, "y": 2}
	Main.goto_area(2)
	await _shot("07_area3", 50)
	GameState.checkpoint = {"area": 3, "x": 2, "y": 2}
	Main.goto_area(3)
	await _shot("07b_area4", 50)
	# boss
	GameState.checkpoint = {"area": 4, "x": 2, "y": 2}
	Main.goto_area(4)
	await frames(20)
	if Main.world:
		Main.world.spawn_boss()
	await _shot("08_boss", 40)
	# force phase 3 for the shot
	var b = get_tree().get_first_node_in_group("boss")
	if b:
		b.take_hit(int(b.max_hp * 0.7), Vector2.ZERO, false, "test")
		await frames(20)
		b.take_hit(int(b.max_hp * 0.3), Vector2.ZERO, false, "test")
	await _shot("08b_boss_p3", 30)
	# character-specific ending (Pingu run -> Puerto Escondido)
	Main.close_modal()
	Main.start_ending()
	await get_tree().create_timer(2.0).timeout
	await _shot("09_ending_arrival", 5)
	await get_tree().create_timer(5.0).timeout
	await _shot("09b_ending_sunset", 5)
	await get_tree().create_timer(8.0).timeout
	await _shot("09c_ending_night", 5)
	Main.show_credits()
	await frames(5)
	var c = Main.modal
	if c != null:
		c._scroll.position.y = 90
	await _shot("10_credits", 5)
	get_tree().quit(0)


var ESCAPED := 0


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String, wait_frames: int) -> void:
	await frames(wait_frames)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(OUT.path_join(name + ".png"))
	print("SHOT ", name)
