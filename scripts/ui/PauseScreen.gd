extends Control
class_name PauseScreen

signal close_requested
signal resume
signal open_settings
signal open_achievements
signal quit_to_menu

var _items: Array[Control] = []


func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	add_child(dim)
	var p := UISkin.make_panel("panel_dark")
	p.position = Vector2(132, 22)
	p.size = Vector2(120, 172)
	add_child(p)
	var title := UISkin.label("PAUSED", 16, Color("2de3ff"))
	title.position = Vector2(148, 30)
	add_child(title)
	var box := VBoxContainer.new()
	box.position = Vector2(142, 56)
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	_btn(box, "RESUME", func(): resume.emit())
	_btn(box, "SAVE GAME", _on_save)
	_btn(box, "SETTINGS", func(): open_settings.emit())
	_btn(box, "ACHIEVEMENTS", func(): open_achievements.emit())
	_btn(box, "MAIN MENU", func(): quit_to_menu.emit())
	_items[0].grab_focus()


func _btn(parent: Control, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(100, 18)
	b.add_theme_font_size_override("font_size", 8)
	b.pressed.connect(cb)
	parent.add_child(b)
	_items.append(b)


func _on_save() -> void:
	if GameState.manual_save():
		FX.toast("PROGRESS SAVED TO /tmp/dignity", Color("6ec72c"))
		AudioDirector.play_sfx("save")
	else:
		AudioDirector.play_sfx("ui_back")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("inventory") or event.is_action_pressed("stats"):
		resume.emit()
		get_viewport().set_input_as_handled()
