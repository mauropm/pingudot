extends Control
class_name EndingCinematic
## Airport escape sequence: security collapses, Pingu boards the black plane,
## takes off over the Pacific toward Oaxaca City.

signal finished

var _t := 0.0
var _stage := 0
var _pingu: AnimatedSprite2D
var _plane: Sprite2D
var _fx: ColorRect
var _sunset: ColorRect
var _capt: Label
var _done := false
var _bg: TextureRect


func _ready() -> void:
	var black := ColorRect.new()
	black.color = Color("05030a")
	black.set_anchors_preset(PRESET_FULL_RECT)
	add_child(black)

	_bg = TextureRect.new()
	_bg.texture = load("res://assets/environments/backgrounds/area5_bg.png")
	_bg.stretch_mode = TextureRect.STRETCH_TILE
	_bg.set_anchors_preset(PRESET_FULL_RECT)
	_bg.modulate = Color(1, 1, 1, 0.9)
	add_child(_bg)

	_sunset = ColorRect.new()
	_sunset.color = Color(0.95, 0.42, 0.12, 0.0)
	_sunset.set_anchors_preset(PRESET_FULL_RECT)
	add_child(_sunset)

	_fx = ColorRect.new()
	_fx.color = Color(0, 0, 0, 0)
	_fx.set_anchors_preset(PRESET_FULL_RECT)
	add_child(_fx)

	_pingu = AnimatedSprite2D.new()
	_pingu.sprite_frames = SpriteLib.build(GameState.character_def().atlas_path)
	_pingu.animation = "run"
	_pingu.play()
	_pingu.position = Vector2(-30, 150)
	_pingu.scale = Vector2(2, 2)
	add_child(_pingu)

	_plane = Sprite2D.new()
	_plane.texture = load("res://assets/environments/airplane.png")
	_plane.position = Vector2(300, 172)
	_plane.scale = Vector2(1.4, 1.4)
	add_child(_plane)

	_capt = UISkin.label("", 8, Color("f2f2f2"))
	_capt.position = Vector2(24, 18)
	_capt.size = Vector2(336, 52)
	_capt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_capt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_capt.modulate = Color(1, 1, 1, 0)
	add_child(_capt)

	AudioDirector.play_music("ending", 0.5)
	_show("SECURITY COLLAPSES.\nUNKNOWN AVIAN ON THE LOOSE.")
	_flash(Color(1, 0.25, 0.25, 0.55), 0.4)
	AudioDirector.play_sfx("boss_die")


func _flash(col: Color, dur: float) -> void:
	_fx.color = col
	var tw := create_tween()
	tw.tween_property(_fx, "color:a", 0.0, dur)


func _show(text: String) -> void:
	_capt.text = text
	_capt.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_capt, "modulate:a", 1.0, 0.6)


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	match _stage:
		0:
			if _t > 3.0:
				_stage = 1
				_t = 0.0
				_show("THE BLACK AIRPLANE WAITS.\nTWO BLUE LINES: TRUST, VERSION-CONTROLLED.")
				AudioDirector.play_sfx("penguin")
		1:
			var tx := 230.0
			var k := clampf(_t / 2.6, 0.0, 1.0)
			_pingu.position.x = lerpf(-30.0, tx, k)
			if _t > 3.0:
				_stage = 2
				_t = 0.0
		2:
			_pingu.position = _pingu.position.move_toward(Vector2(292, 178), 60 * delta)
			_pingu.scale = _pingu.scale.move_toward(Vector2(0.5, 0.5), 1.2 * delta)
			if _t > 2.4:
				_pingu.visible = false
				_stage = 3
				_t = 0.0
				_show("ENGINES SPOOL UP. RUNWAY LIGHTS BLINK GREEN FOR NO ONE.")
				AudioDirector.play_sfx("engine")
		3:
			_plane.position = Vector2(300, 172)
			if _t > 1.6:
				_stage = 4
				_t = 0.0
				_show("TAKEOFF. SAN JOSE SHINKS TO IRRELEVANCE.")
		4:
			_plane.position = Vector2(300 + _t * 50.0, 172 - _t * 46.0)
			_plane.rotation = deg_to_rad(-8.0)
			_sunset.color = Color(0.95, 0.42, 0.12, clampf(_t / 3.0, 0.0, 0.42))
			if _t > 3.2:
				_stage = 5
				_t = 0.0
		5:
			if not _sunset_applied:
				_apply_sunset_scene()
			if _t > 6.0:
				_show_final_prompt()
		6:
			pass


var _sunset_applied := false


func _apply_sunset_scene() -> void:
	_sunset_applied = true
	_plane.visible = false
	_bg.texture = load("res://assets/environments/backgrounds/area1_bg.png")
	_bg.modulate = Color(1.0, 0.72, 0.5, 0.95)
	var sun := Sprite2D.new()
	sun.texture = load("res://assets/ui/coin_big.png")
	sun.scale = Vector2(4, 4)
	sun.modulate = Color("ff8c14")
	sun.position = Vector2(192, 96)
	add_child(sun)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(sun, "position:y", 168.0, 6.0)
	tw.tween_property(sun, "modulate", Color("ff5a1f"), 6.0)
	_show("SUNSET OVER THE PACIFIC.\nDESTINATION: OAXACA CITY.")


func _show_final_prompt() -> void:
	if _stage == 6:
		return
	_stage = 6
	_show("PINGUDOT -- MISSION ACCOMPLISHED.\n\"TRUST IS NOT A FEATURE. IT IS THE FLIGHT PLAN.\"\n\n[PRESS ANY KEY]")
	AudioDirector.play_sfx("victory")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if _stage >= 6:
			if not _done:
				_done = true
				finished.emit()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("pause"):
			_stage = 5
			_t = 7.0
			_plane.visible = false
			_show_final_prompt()
		get_viewport().set_input_as_handled()
