extends Node
## Settings screen layout + mute toggle regression.

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

func _ready() -> void:
	await frames(4)
	var prev_muted: bool = AudioDirector.muted
	Main.show_menu()
	await frames(5)
	Main.open_settings()
	await frames(4)
	var s := Main.modal as SettingsScreen
	check(s != null, "settings opens")
	if s == null:
		_done()
		return
	var mute: Button = null
	var save_btn: Button = null
	var del_btn: Button = null
	var hint: Label = null
	for c in s.get_children():
		if c is Button:
			if String(c.text).begins_with("MUTE ALL"):
				mute = c
			elif c.text == "SAVE":
				save_btn = c
			elif c.text == "DELETE SAVE":
				del_btn = c
		elif c is Label and c.text == "[ESC] BACK":
			hint = c
	check(mute != null, "mute toggle exists")
	check(save_btn != null and del_btn != null, "save/delete buttons exist")
	if mute == null or save_btn == null or del_btn == null:
		_done()
		return
	check(not (mute is CheckBox), "mute is a themed toggle, not a raw CheckBox")
	check(mute.size.y <= 22.0, "mute toggle is compact (h=%.0f)" % mute.size.y)
	check(not mute.get_global_rect().intersects(save_btn.get_global_rect()),
		"mute toggle is clear of SAVE")
	check(not mute.get_global_rect().intersects(del_btn.get_global_rect()),
		"mute toggle is clear of DELETE SAVE")
	check(not save_btn.get_global_rect().intersects(del_btn.get_global_rect()),
		"SAVE and DELETE SAVE do not overlap")
	if hint != null:
		check(not save_btn.get_global_rect().intersects(hint.get_global_rect()),
			"[ESC] BACK is clear of the buttons")
	var panel := Rect2(64, 18, 256, 180)
	var inside := true
	for c in [mute, save_btn, del_btn]:
		if not panel.encloses(c.get_global_rect()):
			inside = false
	if hint != null and not panel.encloses(hint.get_global_rect()):
		inside = false
	check(inside, "all settings controls stay inside the panel")

	# Toggling must mute immediately and update its own label.
	var target: bool = not prev_muted
	mute.button_pressed = target
	await frames(2)
	check(AudioDirector.muted == target, "mute toggle applies immediately")
	check(mute.text == ("MUTE ALL: ON" if target else "MUTE ALL: OFF"),
		"mute label reflects state")
	mute.button_pressed = prev_muted
	await frames(2)
	check(AudioDirector.muted == prev_muted, "mute toggle restores state")
	var menu: MainMenuScreen = null
	for c in Main.overlay.get_children():
		if c is MainMenuScreen:
			menu = c
	check(menu != null, "main menu present behind settings")
	Main.close_modal()
	await frames(3)
	var focus := get_viewport().gui_get_focus_owner()
	check(focus != null and (focus == menu or menu.is_ancestor_of(focus)),
		"focus returns to the main menu")
	var before := focus
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = KEY_DOWN
	ev.physical_keycode = KEY_DOWN
	Input.parse_input_event(ev)
	await frames(2)
	var up := InputEventKey.new()
	up.pressed = false
	up.keycode = KEY_DOWN
	up.physical_keycode = KEY_DOWN
	Input.parse_input_event(up)
	await frames(2)
	var after := get_viewport().gui_get_focus_owner()
	check(after != null and after != before, "arrow keys select menu entries again")
	_done()

func _done() -> void:
	SaveSystem.save_settings(AudioDirector.to_settings())
	print("")
	print("SETTINGS RESULTS: %d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)
