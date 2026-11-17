extends Node
## Character-specific ending cinematics.

var passed := 0
var failed := 0

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

func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

func _ready() -> void:
	await frames(5)
	print("== ENDINGS: assets ==")
	for p in [
		"res://assets/environments/endings/pingu_beach_day.png",
		"res://assets/environments/endings/pingu_beach_sunset.png",
		"res://assets/environments/endings/pingu_beach_night.png",
		"res://assets/environments/endings/pingu_sun.png",
		"res://assets/environments/endings/pingu_clouds.png",
		"res://assets/environments/endings/pingu_waves.png",
		"res://assets/environments/endings/pingu_foam.png",
		"res://assets/environments/endings/pingu_palm.png",
		"res://assets/environments/endings/pingu_birds.png",
		"res://assets/environments/endings/miggy_room.png",
		"res://assets/environments/endings/miggy_lamp_glow.png",
		"res://assets/environments/endings/miggy_snow.png",
		"res://assets/environments/endings/miggy_monitor_terminal.png",
		"res://assets/environments/endings/miggy_monitor_godot.png",
		"res://assets/environments/endings/miggy_monitor_mono.png",
		"res://assets/audio/ambient/beach.wav",
		"res://assets/audio/ambient/winter.wav",
		"res://assets/audio/music/ending_miggy.wav",
		"res://assets/audio/sfx/bird.wav",
		"res://assets/audio/sfx/key_clack.wav",
		"res://assets/audio/sfx/terminal_alert.wav",
	]:
		check(ResourceLoader.exists(p), "asset: " + p.get_file())
	var pa := SpriteLib.load_manifest("res://assets/characters/pingu.png")
	check(pa.has("sit") and pa.has("sit_idle"), "Pingu has seated animations")
	check(SpriteLib.has_anim(pa, "sit"), "Pingu sit animation resolvable")
	var ma := SpriteLib.load_manifest("res://assets/characters/miggy.png")
	for a in ["sit_idle", "sit_type", "sit_lean"]:
		check(ma.has(a), "Miggy seated animation: " + a)
	check(AudioDirector.has_sfx("bird"), "bird sfx loaded")
	check(AudioDirector.has_sfx("key_clack"), "key_clack sfx loaded")

	# ------------------------------------------------------------------ Pingu
	print("== ENDINGS: Pingu in Puerto Escondido ==")
	Main.show_menu()
	await frames(4)
	Main.start_new_game(1111, "pingu")
	Main.begin_mission()
	await frames(24)
	Main.dialogue_box.reset()
	await frames(4)
	check(Main.screen == Main.Screen.GAME, "Pingu run active")
	Main.start_ending()
	await frames(6)
	var pe := Main.modal as PinguEnding
	check(pe != null, "Pingu gameplay selects the beach ending")
	check(Main.screen == Main.Screen.ENDING, "ending screen state")
	check(Main.world != null and Main.world.process_mode == Node.PROCESS_MODE_DISABLED,
		"gameplay world frozen")
	check(pe != null and pe._day != null and pe._night != null, "beach layers built")
	check(pe != null and pe._pingu.animation == "idle", "Pingu animated on the sand")
	var before_count := _ending_count()
	Main.start_ending()
	await frames(2)
	check(_ending_count() == before_count, "ending cannot start twice")

	# gameplay input must not move Pingu under the cinematic
	var pos0: Vector2 = Main.world.player.global_position
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = KEY_RIGHT
	ev.physical_keycode = KEY_RIGHT
	Input.parse_input_event(ev)
	await wait(0.4)
	var up := InputEventKey.new()
	up.pressed = false
	up.keycode = KEY_RIGHT
	up.physical_keycode = KEY_RIGHT
	Input.parse_input_event(up)
	check(Main.world.player.global_position == pos0, "player cannot move during ending")

	var emissions := [0]
	pe.finished.connect(func(): emissions[0] += 1)
	pe._finish()
	check(pe._ambient.is_empty(), "ambient audio cleaned up")
	pe._finish()
	await frames(5)
	check(emissions[0] == 1, "ending finishes exactly once (idempotent)")
	check(Main.modal is CreditsScreen, "credits follow the beach ending")
	check(Main.screen == Main.Screen.CREDITS, "credits screen state")
	Main.show_menu()
	await frames(6)
	check(Main.screen == Main.Screen.MENU, "returns to the title screen")
	check(not get_tree().paused, "tree is not left paused")

	# ------------------------------------------------------------------ Miggy
	print("== ENDINGS: Miggy's winter ==")
	Main.start_new_game(2222, "miggy")
	await frames(24)
	Main.dialogue_box.reset()
	await frames(4)
	check(Main.screen == Main.Screen.GAME, "Miggy run active")
	Main.start_ending()
	await frames(6)
	var me := Main.modal as MiggyEnding
	check(me != null, "Miggy gameplay selects the winter ending")
	check(Main.screen == Main.Screen.ENDING, "Miggy ending screen state")
	check(Main.world != null and Main.world.process_mode == Node.PROCESS_MODE_DISABLED,
		"Miggy gameplay world frozen")
	check(me != null and me._monitors.size() == 3, "three animated monitors")
	check(me != null and me._miggy.animation == "sit_type", "Miggy types at the desk")
	check(me != null and me._term != null and me._term.get_child_count() >= 3,
		"terminal overlay built")
	var snow := 0
	if me != null:
		for f in me._snow:
			if is_instance_valid(f["n"]):
				snow += 1
	check(snow >= 30, "snow flakes active in the window")
	await wait(2.4)
	var typed := 0
	if me != null:
		for c in me._term.get_children():
			if c is Label and c.text != "" and c.text != "_":
				typed += 1
	check(typed >= 2, "terminal messages type out")

	var memissions := [0]
	me.finished.connect(func(): memissions[0] += 1)
	me._finish()
	await frames(5)
	check(memissions[0] == 1, "Miggy ending finishes exactly once")
	check(Main.modal is CreditsScreen, "credits follow the winter ending")
	check(Main.screen == Main.Screen.CREDITS, "Miggy credits screen state")
	Main.show_menu()
	await frames(5)
	check(Main.screen == Main.Screen.MENU, "Miggy returns to the title screen")

	_done()

func _ending_count() -> int:
	var n := 0
	for c in Main.overlay.get_children():
		if c is EndingSequence:
			n += 1
	return n

func _done() -> void:
	print("")
	print("ENDINGS RESULTS: %d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)
