extends Node
## Keyboard navigation test: proves the title screen is operable with
## arrows/WASD/Enter without a mouse.

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


func press(key: int) -> void:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = key
	ev.physical_keycode = key
	Input.parse_input_event(ev)
	await frames(2)
	var up := InputEventKey.new()
	up.pressed = false
	up.keycode = key
	up.physical_keycode = key
	Input.parse_input_event(up)
	await frames(2)


func focused_button() -> Button:
	var fo := get_viewport().gui_get_focus_owner()
	return fo as Button


func _ready() -> void:
	await frames(5)
	print("== KEYBOARD NAVIGATION ==")
	check(Main.screen == Main.Screen.MENU, "menu visible")
	var b := focused_button()
	check(b != null, "a menu button has focus at boot")
	if b == null:
		_done()
		return
	print("  focused: " + b.text)
	var t0 := b.text
	await press(KEY_DOWN)
	b = focused_button()
	check(b != null and b.text != t0, "DOWN arrow moves selection")
	var t1 := b.text if b != null else ""
	await press(KEY_S)
	b = focused_button()
	check(b != null and b.text != t1, "S (WASD) moves selection")
	var t2 := b.text if b != null else ""
	await press(KEY_UP)
	b = focused_button()
	check(b != null and b.text != t2, "UP arrow moves selection back")
	await press(KEY_W)
	b = focused_button()
	check(b != null, "W (WASD) navigates")
	# activate whatever is focused (should open a screen or start the game)
	b = focused_button()
	print("  activating: " + b.text)
	await press(KEY_ENTER)
	await frames(5)
	check(Main.screen != Main.Screen.MENU or Main.modal != null,
		"ENTER activates the focused menu item")
	_done()


func _done() -> void:
	print("")
	print("INPUT RESULTS: %d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)
