extends EndingSequence
class_name MiggyEnding
## Ending B — Miggy: The Hacker's Winter.
##
## A cozy blue-lit apartment while snow falls. Miggy types at a three-monitor
## workstation (Godot editor + Mono runtime + terminal), compiles his legendary
## hack, then leans back and watches the snow.

const ENV := "res://assets/environments/endings/"
const LINES := [
	["Initializing Mono runtime...", Color("6ec72c")],
	["Godot integration: READY", Color("2de3ff")],
	["Hack compilation: 99%", Color("f7e94b")],
	["Miggy's legendary hack:", Color("c77dff")],
]

var _miggy: AnimatedSprite2D
var _monitors: Array[AnimatedSprite2D] = []
var _snow: Array[Dictionary] = []
var _lamp: Sprite2D
var _term: Control
var _term_y := 15.0
var _cursor: Label
var _typing := true
var _key_t := 0.0
var _build_card: Control


func _build() -> void:
	var room := TextureRect.new()
	room.texture = load(ENV + "miggy_room.png")
	room.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	room.stretch_mode = TextureRect.STRETCH_SCALE
	room.position = Vector2.ZERO
	room.size = size
	room.mouse_filter = MOUSE_FILTER_IGNORE
	_world.add_child(room)

	# monitor light spilling onto the desk
	_glow(Vector2(260, 126), Color(0.35, 0.55, 1.0, 0.30), 1.15)
	_glow(Vector2(208, 132), Color(0.4, 0.9, 0.6, 0.16), 0.75)
	_glow(Vector2(348, 136), Color(0.6, 0.35, 1.0, 0.20), 0.7)
	_lamp = _glow(Vector2(190, 148), Color(1.0, 0.7, 0.35, 0.50), 1.0)

	# animated CRT screens
	_monitor("miggy_monitor_terminal.png", Vector2(206, 112))
	_monitor("miggy_monitor_godot.png", Vector2(258, 100))
	_monitor("miggy_monitor_mono.png", Vector2(334, 120))

	# Miggy at the desk, then the snow outside
	_miggy = AnimatedSprite2D.new()
	_miggy.sprite_frames = SpriteLib.build("res://assets/characters/miggy.png")
	_miggy.animation = "sit_type"
	_miggy.play()
	_miggy.position = Vector2(154, 162)
	_miggy.scale = Vector2(3, 3)
	_miggy.z_index = 10
	_world.add_child(_miggy)

	var snow_tex: Texture2D = load(ENV + "miggy_snow.png")
	for i in 46:
		var flake := Sprite2D.new()
		flake.texture = snow_tex
		flake.position = Vector2(randf_range(19, 92), randf_range(18, 84))
		flake.scale = Vector2.ONE * (2.0 if i % 7 == 0 else 1.0)
		flake.modulate = Color(0.85, 0.9, 1.0, randf_range(0.5, 1.0))
		flake.z_index = 5
		_world.add_child(flake)
		_snow.append({"n": flake, "spd": randf_range(6.0, 18.0),
			"drift": randf_range(1.5, 4.0), "ph": randf_range(0.0, 6.28)})

	# CRT scanlines (below the readable terminal, above the room)
	var lines := ColorRect.new()
	lines.position = Vector2.ZERO
	lines.size = size
	lines.mouse_filter = MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/scanlines.gdshader")
	mat.set_shader_parameter("strength", 0.09)
	lines.material = mat
	lines.z_index = 700
	add_child(lines)

	# readable terminal output, top-right
	_term = Control.new()
	_term.position = Vector2(194, 12)
	_term.size = Vector2(184, 76)
	_term.mouse_filter = MOUSE_FILTER_IGNORE
	_term.z_index = 800
	add_child(_term)
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.02, 0.02, 0.86)
	bg.position = Vector2.ZERO
	bg.size = _term.size
	_term.add_child(bg)
	var border := ColorRect.new()
	border.color = Color("2e7a4a")
	border.position = Vector2.ZERO
	border.size = Vector2(_term.size.x, 1)
	_term.add_child(border)
	var border_b := ColorRect.new()
	border_b.color = Color("1e4a32")
	border_b.position = Vector2(0, _term.size.y - 1)
	border_b.size = Vector2(_term.size.x, 1)
	_term.add_child(border_b)
	var head := UISkin.label("miggy@pingudot:~$ ./build_hack", 8, Color("6ec72c"))
	head.position = Vector2(5, 3)
	head.size = Vector2(176, 10)
	head.clip_text = true
	_term.add_child(head)
	_cursor = UISkin.label("_", 8, Color("6ec72c"))
	_cursor.position = Vector2(5, _term_y)
	_term.add_child(_cursor)


func _glow(pos: Vector2, col: Color, sc: float) -> Sprite2D:
	var g := Sprite2D.new()
	g.texture = load(ENV + "miggy_lamp_glow.png")
	g.position = pos
	g.scale = Vector2(sc, sc)
	g.modulate = col
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	g.material = m
	g.z_index = 2
	_world.add_child(g)
	return g


func _monitor(file: String, pos: Vector2) -> void:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = SpriteLib.build(ENV + file)
	var names := s.sprite_frames.get_animation_names()
	if names.is_empty():
		return
	s.animation = names[0]
	s.play()
	s.position = pos
	s.z_index = 3
	_world.add_child(s)
	_monitors.append(s)


func _term_line(text: String, col: Color) -> void:
	var l := UISkin.label(text, 8, col)
	l.position = Vector2(5, _term_y)
	l.size = Vector2(176, 10)
	l.clip_text = true
	l.visible_characters = 0
	_term.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "visible_characters", text.length(), 0.5)
	_term_y += 10
	_cursor.position = Vector2(5, _term_y)
	AudioDirector.play_sfx("terminal_alert", -10.0, 0.1)


func _play() -> void:
	AudioDirector.play_music("ending_miggy", 1.4)
	_play_ambient("res://assets/audio/ambient/winter.wav", -12.0)
	_fade_in(1.5)
	_camera(1.14, 7.5, Vector2(268, 120))
	await _wait(1.2)
	if _done:
		return
	_term_line(LINES[0][0], LINES[0][1])
	await _wait(1.7)
	if _done:
		return
	_term_line(LINES[1][0], LINES[1][1])
	await _wait(1.7)
	if _done:
		return
	_term_line(LINES[2][0], LINES[2][1])
	await _wait(1.7)
	if _done:
		return
	_term_line(LINES[3][0], LINES[3][1])
	await _wait(0.6)
	if _done:
		return
	_term_line("SUCCESS", Color("6ec72c"))
	await _wait(1.2)
	if _done:
		return

	# final command: the build succeeds
	_typing = false
	_miggy.play("sit_lean")
	AudioDirector.play_sfx("victory")
	AudioDirector.play_sfx("achievement", -4.0)
	_build_success()
	_camera(1.0, 4.6, Vector2(192, 118))
	await _wait(2.8)
	if _done:
		return
	await _wait(1.4)
	if _done:
		return

	# he turns toward the snowy window
	_miggy.flip_h = true
	_miggy.play("sit_idle")
	await _wait(1.8)
	if _done:
		return

	_fade_out(2.4)
	await _wait(2.6)
	if _done:
		return
	_final("BUILD SUCCESSFUL", "MONO + GODOT = MAGIC")
	await _wait(4.6)
	_finish()


func _build_success() -> void:
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.55)
	flash.position = Vector2.ZERO
	flash.size = size
	flash.mouse_filter = MOUSE_FILTER_IGNORE
	flash.z_index = 950
	add_child(flash)
	var ftw := create_tween()
	ftw.tween_property(flash, "color:a", 0.0, 0.6)
	ftw.tween_callback(flash.queue_free)

	_build_card = Control.new()
	_build_card.position = Vector2.ZERO
	_build_card.size = size
	_build_card.mouse_filter = MOUSE_FILTER_IGNORE
	_build_card.modulate.a = 0.0
	_caption_layer.add_child(_build_card)
	var panel := ColorRect.new()
	panel.color = Color(0.01, 0.02, 0.03, 0.95)
	panel.position = Vector2(0, 80)
	panel.size = Vector2(384, 36)
	_build_card.add_child(panel)
	var top := ColorRect.new()
	top.color = Color("2e7a4a")
	top.position = Vector2(0, 80)
	top.size = Vector2(384, 1)
	_build_card.add_child(top)
	var bottom := ColorRect.new()
	bottom.color = Color("1a3a2a")
	bottom.position = Vector2(0, 115)
	bottom.size = Vector2(384, 1)
	_build_card.add_child(bottom)
	var t := UISkin.label("BUILD SUCCESSFUL", 16, Color("6ec72c"))
	t.position = Vector2(0, 83)
	t.size = Vector2(384, 20)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_build_card.add_child(t)
	var s := UISkin.label("MONO + GODOT = MAGIC", 8, Color("c77dff"))
	s.position = Vector2(0, 103)
	s.size = Vector2(384, 10)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_build_card.add_child(s)
	var tw := create_tween()
	tw.tween_property(_build_card, "modulate:a", 1.0, 0.7)


func _animate(delta: float) -> void:
	# snow drifts inside the window frame
	for f in _snow:
		var n: Sprite2D = f["n"]
		if not is_instance_valid(n):
			continue
		n.position.y += f["spd"] * delta
		n.position.x += sin(_t * 0.8 + f["ph"]) * f["drift"] * delta
		if n.position.y > 84.0:
			n.position.y = 18.0
			n.position.x = randf_range(19.0, 92.0)
		n.position.x = clampf(n.position.x, 19.0, 92.0)
	if _lamp != null and is_instance_valid(_lamp):
		_lamp.modulate.a = 0.42 + 0.10 * sin(_t * 1.7)
	for m in _monitors:
		if is_instance_valid(m):
			m.modulate.a = 0.94 + 0.06 * sin(_t * 7.0 + m.position.x)
	# keyboard clatter while he types
	if _typing and _t < 9.0:
		_key_t -= delta
		if _key_t <= 0.0:
			_key_t = randf_range(0.07, 0.15)
			AudioDirector.play_sfx("key_clack", -12.0, 0.25)
	if _cursor != null and is_instance_valid(_cursor):
		_cursor.visible = fmod(_t, 0.66) < 0.42
