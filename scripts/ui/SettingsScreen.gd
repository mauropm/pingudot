extends Control
class_name SettingsScreen

signal close_requested


func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	add_child(dim)
	var root := UISkin.make_panel("panel_dark")
	root.position = Vector2(64, 18)
	root.size = Vector2(256, 180)
	add_child(root)
	var title := UISkin.label("SETTINGS", 16, Color("2de3ff"))
	title.position = Vector2(80, 26)
	add_child(title)
	_slider_row("MASTER", 0, 58)
	_slider_row("MUSIC", 1, 82)
	_slider_row("SFX", 2, 106)

	var mute := CheckBox.new()
	mute.text = "MUTE ALL"
	mute.position = Vector2(80, 128)
	mute.size = Vector2(120, 18)
	mute.add_theme_font_size_override("font_size", 8)
	mute.button_pressed = AudioDirector.muted
	mute.toggled.connect(func(p): AudioDirector.set_muted(p); _save())
	add_child(mute)

	var save_btn := Button.new()
	save_btn.text = "SAVE"
	save_btn.position = Vector2(80, 150)
	save_btn.size = Vector2(100, 18)
	save_btn.add_theme_font_size_override("font_size", 8)
	save_btn.pressed.connect(func(): _save(); FX.toast("SETTINGS SAVED", Color("6ec72c")))
	add_child(save_btn)

	var reset := Button.new()
	reset.text = "DELETE SAVE"
	reset.position = Vector2(190, 150)
	reset.size = Vector2(100, 18)
	reset.add_theme_font_size_override("font_size", 8)
	reset.pressed.connect(_on_reset)
	add_child(reset)
	_reset_armed = false
	var hint := UISkin.label("[ESC] BACK", 8, Color("5a6280"))
	hint.position = Vector2(80, 176)
	add_child(hint)


var _reset_armed := false


func _slider_row(label_text: String, idx: int, y: float) -> void:
	var l := UISkin.label(label_text, 8, Color("9aa4b2"))
	l.position = Vector2(80, y + 2)
	add_child(l)
	var s := HSlider.new()
	s.position = Vector2(142, y)
	s.size = Vector2(160, 14)
	s.min_value = 0
	s.max_value = 100
	s.value = [AudioDirector.master_volume, AudioDirector.music_volume,
		AudioDirector.sfx_volume][idx] * 100.0
	s.step = 1
	s.value_changed.connect(func(v):
		match idx:
			0: AudioDirector.master_volume = v / 100.0
			1: AudioDirector.music_volume = v / 100.0
			2: AudioDirector.sfx_volume = v / 100.0
		AudioDirector.set_volumes(AudioDirector.master_volume,
			AudioDirector.music_volume, AudioDirector.sfx_volume))
	add_child(s)
	if idx == 0:
		s.grab_focus()


func _save() -> void:
	SaveSystem.save_settings(AudioDirector.to_settings())


func _on_reset() -> void:
	if not _reset_armed:
		_reset_armed = true
		FX.toast("CLICK AGAIN TO CONFIRM WIPE", Color("e2282e"))
		return
	SaveSystem.delete_run()
	FX.toast("SAVE DELETED. DREAMS WIPED.", Color("e2282e"))
	AudioDirector.play_sfx("glitch")


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("interact"):
		close_requested.emit()
		get_viewport().set_input_as_handled()
