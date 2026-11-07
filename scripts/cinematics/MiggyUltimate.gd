extends Control
class_name MiggyUltimate
## THE FINAL RECURSION — a purely fictional terminal cinematic.
## No shell command is ever executed; this only paints pixels and damages
## in-game enemies.

signal finished

var _t := 0.0
var _stage := 0
var _fired := false
var _cmd: Label
var _warn: Label
var _exec: Label
var _big: Label
var _caption: Label
var _sprite: AnimatedSprite2D
var _vortex: AnimatedSprite2D
var _extra_vortex: Array[AnimatedSprite2D] = []
var _flash: ColorRect
var _black: ColorRect
var _cmd_full := "miggy@pingudot:~$ sudo rm -rf /"
var _typed := 0


func _ready() -> void:
	var vp := get_viewport_rect().size
	position = Vector2.ZERO
	size = vp
	set_anchors_preset(PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color("030306")
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.position = Vector2.ZERO
	bg.size = vp
	add_child(bg)

	_cmd = UISkin.label("", 8, Color("6ec72c"))
	_cmd.position = Vector2(24, 26)
	add_child(_cmd)
	_warn = UISkin.label("WARNING: THIS OPERATION CANNOT BE UNDONE.", 8, Color("ff5a5a"))
	_warn.position = Vector2(24, 46)
	_warn.visible = false
	add_child(_warn)
	_caption = UISkin.label("", 8, Color("c77dff"))
	_caption.position = Vector2(24, 62)
	add_child(_caption)
	_exec = UISkin.label("EXECUTING...", 8, Color("f7e94b"))
	_exec.position = Vector2(24, 78)
	_exec.visible = false
	add_child(_exec)

	_vortex = AnimatedSprite2D.new()
	_vortex.sprite_frames = SpriteLib.build("res://assets/effects/vortex.png")
	var names := _vortex.sprite_frames.get_animation_names()
	if names.size() > 0:
		_vortex.animation = names[0]
		_vortex.play()
	_vortex.scale = Vector2(0.4, 0.4)
	_vortex.position = Vector2(192, 128)
	_vortex.visible = false
	add_child(_vortex)

	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteLib.build("res://assets/characters/miggy.png")
	_sprite.animation = "ultimate"
	_sprite.play()
	_sprite.scale = Vector2(3, 3)
	_sprite.position = Vector2(192, 142)
	_sprite.visible = false
	add_child(_sprite)

	# extra vortex rings for density
	_extra_vortex = []
	for i in 2:
		var vx := AnimatedSprite2D.new()
		vx.sprite_frames = _vortex.sprite_frames
		if names.size() > 0:
			vx.animation = names[0]
			vx.play()
		vx.position = Vector2(192, 128)
		vx.scale = Vector2(0.2, 0.2)
		vx.modulate = [Color("c77dff"), Color("6ec72c")][i]
		vx.visible = false
		add_child(vx)
		_extra_vortex.append(vx)

	_big = UISkin.label("SEGMENTATION FAULT", 16, Color("ff5a5a"))
	_big.position = Vector2(82, 96)
	_big.visible = false
	add_child(_big)

	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_preset(PRESET_FULL_RECT)
	_flash.position = Vector2.ZERO
	_flash.size = vp
	add_child(_flash)

	_black = ColorRect.new()
	_black.color = Color(0, 0, 0, 0)
	_black.set_anchors_preset(PRESET_FULL_RECT)
	_black.position = Vector2.ZERO
	_black.size = vp
	add_child(_black)

	AudioDirector.play_sfx("miggy_ult")


func _process(delta: float) -> void:
	if _fired:
		return
	_t += delta
	# typing the command
	if _t < 1.5:
		_typed = mini(_cmd_full.length(), int(_t / 0.8 * _cmd_full.length()))
		_cmd.text = _cmd_full.substr(0, _typed)
		if _typed >= _cmd_full.length() and _stage == 0:
			_stage = 1
			AudioDirector.play_sfx("terminal_type")
	elif _stage == 1 and _t > 1.6:
		_stage = 2
		_warn.visible = true
		_caption.text = "MIGGY: \"Hold my terminal.\""
		_sprite.visible = true
		AudioDirector.play_sfx("break" if false else "segfault", -2.0)
	elif _stage == 2 and _t > 2.6:
		_stage = 3
		_exec.visible = true
		_vortex.visible = true
		for i in _extra_vortex.size():
			_extra_vortex[i].visible = true
			_extra_vortex[i].scale = Vector2(0.2, 0.2)
			var tv := create_tween()
			tv.tween_property(_extra_vortex[i], "scale",
				Vector2(2.2 if i == 0 else 1.4, 2.2 if i == 0 else 1.4), 1.6)
			tv.parallel().tween_property(_extra_vortex[i], "rotation", -12.0 if i == 0 else 7.0, 1.6)
		AudioDirector.play_sfx("boom")
		var tw := create_tween()
		tw.tween_property(_vortex, "scale", Vector2(3.6, 3.6), 1.6).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(_vortex, "rotation", 9.0, 1.6)
	elif _stage == 3 and _t > 4.1:
		_stage = 4
		_big.visible = true
		_warn.visible = false
		_exec.visible = false
		_flash.color = Color(1, 1, 1, 0.75)
		EventBus.screen_shake.emit(10.0, 0.8)
		AudioDirector.play_sfx("ultimate_rmrf")
		var tw := create_tween()
		tw.tween_property(_flash, "color:a", 0.0, 0.6)
	elif _stage == 4 and _t > 5.2:
		_stage = 5
		_big.visible = false
		_sprite.visible = false
		var tw := create_tween()
		tw.tween_property(_black, "color:a", 1.0, 0.5)
		tw.tween_interval(0.15)
		tw.tween_callback(_finish)
	elif _stage == 5 and _t > 6.5:
		_finish()


func skip() -> void:
	_finish()


func _finish() -> void:
	if _fired:
		return
	_fired = true
	finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		if _t > 0.5:
			_finish()
