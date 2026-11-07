extends Node
## First-life regression test: the intro -> area-intro dialogue must be
## dismissible with J (and not leave the player permanently frozen).

var passed := 0
var failed := 0


func check(cond: bool, label: String) -> void:
	if cond:
		passed += 1
		print("  ok: " + label)
	else:
		failed += 1
		printerr("  FAIL: " + label)


func press_key(code: int) -> void:
	var e := InputEventKey.new()
	e.pressed = true
	e.keycode = code
	e.physical_keycode = code
	Input.parse_input_event(e)
	var u := InputEventKey.new()
	u.pressed = false
	u.keycode = code
	u.physical_keycode = code
	Input.parse_input_event(u)


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _ready() -> void:
	await frames(5)
	print("== FIRST LIFE / DIALOGUE INPUT ==")
	Main.start_new_game(13579)
	await frames(10)
	check(Main.screen == Main.Screen.INTRO, "intro plays on a new game")
	for i in 8:
		if Main.screen == Main.Screen.GAME:
			break
		press_key(KEY_ENTER)
		await frames(8)
	check(Main.screen == Main.Screen.GAME, "intro finishes into gameplay")
	await frames(30)
	var w = Main.world
	check(w != null and w.player != null, "world and player exist")
	if w == null:
		_done()
		return
	var p: Player = w.player
	check(Main.dialogue_box.visible, "area intro dialogue is shown")
	check(p.frozen, "player is frozen while reading")
	# the blinking advance prompt must appear once typing completes
	await get_tree().create_timer(2.4).timeout
	var prompt_seen := false
	for i in 14:
		if Main.dialogue_box._prompt.visible:
			prompt_seen = true
			break
		await get_tree().create_timer(0.1).timeout
	check(prompt_seen, "dialogue shows a blinking ANY KEY TO SKIP prompt")
	check(Main.dialogue_box._prompt.text == "ANY KEY TO SKIP >", "prompt text is correct")
	# J must dismiss the dialogue
	for i in 6:
		if not Main.dialogue_box.visible:
			break
		press_key(KEY_J)
		await frames(12)
	check(not Main.dialogue_box.visible, "J dismisses the dialogue")
	check(not p.frozen, "player unfreezes after dialogue")
	# and J must then attack
	var attacked := false
	for i in 4:
		press_key(KEY_J)
		await frames(3)
		if p.state == Player.State.ATTACK:
			attacked = true
			break
	check(attacked, "J attacks after the dialogue closes")
	# movement must be ignored while frozen, and work after
	p.frozen = true
	var x0 := p.global_position.x
	Input.action_press("move_right")
	await frames(12)
	Input.action_release("move_right")
	check(absf(p.global_position.x - x0) < 1.0, "movement locked while frozen")
	p.frozen = false
	Input.action_press("move_right")
	await frames(15)
	Input.action_release("move_right")
	check(p.global_position.x > x0 + 1.0, "movement works after unfreezing")

	# "ANY KEY TO SKIP": a key that is not a gameplay action must also advance
	Main.dialogue_box.show_line("joke_1")
	await get_tree().create_timer(0.4).timeout
	for i in 2:
		press_key(KEY_Z)
		await get_tree().create_timer(0.25).timeout
	check(not Main.dialogue_box.visible, "any key advances dialogue (not just J/E/Space)")
	_done()


func _done() -> void:
	print("")
	print("FIRSTLIFE RESULTS: %d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)
