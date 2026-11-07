extends Control
class_name MiggyCard
## Secret character-selection card shown after the `root` ritual.

signal back_requested

var seed_value := 0
var _enter_btn: Button


func _ready() -> void:
	var vp := get_viewport_rect().size
	position = Vector2.ZERO
	size = vp
	set_anchors_preset(PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.92)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	dim.position = Vector2.ZERO
	dim.size = vp
	add_child(dim)
	var panel := UISkin.make_panel("panel_dark")
	panel.position = Vector2(18, 12)
	panel.size = Vector2(348, 192)
	add_child(panel)

	var title := UISkin.label("MIGGY", 16, Color("c77dff"))
	title.position = Vector2(206, 24)
	add_child(title)
	var sub := UISkin.label("LEGENDARY HACKER", 8, Color("6ec72c"))
	sub.position = Vector2(206, 44)
	add_child(sub)
	var quote := UISkin.label("\"Why click when\nyou can compile?\"", 8, Color("9aa4b2"))
	quote.position = Vector2(206, 56)
	add_child(quote)

	var y := 82.0
	for line in [
		"SPECIALTY:",
		"  GNOME ENGINEERING",
		"  MONO MAGIC",
		"  MIDNIGHT OPERATIONS",
		"",
		"STATUS: ROOT",
		"ALIGNMENT: OPEN SOURCE",
		"SHELL: bash",
	]:
		var l := UISkin.label(line, 8,
			Color("2de3ff") if line == "SPECIALTY:" else Color("e8eef8"))
		l.position = Vector2(206, y)
		add_child(l)
		y += 10.0

	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = SpriteLib.build("res://assets/characters/miggy.png")
	sprite.animation = "idle"
	sprite.play()
	sprite.position = Vector2(112, 126)
	sprite.scale = Vector2(3, 3)
	add_child(sprite)
	var frame := Sprite2D.new()
	frame.texture = SpriteLib.atlas_texture("res://assets/characters/miggy.png", "portrait", 0)
	frame.position = Vector2(112, 56)
	frame.scale = Vector2(2, 2)
	add_child(frame)

	_enter_btn = Button.new()
	_enter_btn.text = "[ ENTER THE SHELL ]"
	_enter_btn.position = Vector2(60, 176)
	_enter_btn.size = Vector2(264, 18)
	_enter_btn.add_theme_font_size_override("font_size", 8)
	_enter_btn.pressed.connect(_enter_shell)
	add_child(_enter_btn)
	_enter_btn.grab_focus()

	var back := Button.new()
	back.text = "BACK [ESC]"
	back.flat = true
	back.position = Vector2(206, 158)
	back.size = Vector2(110, 14)
	back.add_theme_font_size_override("font_size", 7)
	back.add_theme_color_override("font_color", Color("9aa4b2"))
	back.pressed.connect(func():
		AudioDirector.play_sfx("ui_back")
		back_requested.emit())
	add_child(back)
	AudioDirector.play_sfx("miggy_unlock", 2.0)
	AudioDirector.play_sfx("terminal_type")


func _enter_shell() -> void:
	AudioDirector.play_sfx("ui_ok")
	Main.start_miggy_run(seed_value)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		back_requested.emit()
		get_viewport().set_input_as_handled()
