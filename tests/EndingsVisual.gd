extends Node
## QA capture for the two character-specific endings.
## Screenshots land in /tmp/pingudot_endings.

const OUT := "/tmp/pingudot_endings"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	await wait(0.4)
	Main.show_menu()
	await wait(0.2)

	# ---- Pingu ending ----
	Main.start_new_game(111, "pingu")
	Main.begin_mission()
	await wait(0.8)
	Main.dialogue_box.reset()
	await wait(0.3)
	Main.start_ending()
	await wait(2.0)
	await shot("pingu_01_arrival")
	await wait(4.0)
	await shot("pingu_02_sunset")
	await wait(5.0)
	await shot("pingu_03_dusk")
	await wait(5.0)
	await shot("pingu_04_night")
	await wait(5.0)
	await shot("pingu_05_final")

	# ---- Miggy ending ----
	Main.show_menu()
	await wait(0.3)
	Main.start_new_game(222, "miggy")
	await wait(0.8)
	Main.dialogue_box.reset()
	await wait(0.3)
	Main.start_ending()
	await wait(2.0)
	await shot("miggy_01_setup")
	await wait(3.0)
	await shot("miggy_02_typing")
	await wait(3.0)
	await shot("miggy_03_success")
	await wait(4.0)
	await shot("miggy_04_window")
	await wait(7.0)
	await shot("miggy_05_final")
	get_tree().quit(0)

func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT.path_join(name + ".png"))
	print("SHOT ", name)
