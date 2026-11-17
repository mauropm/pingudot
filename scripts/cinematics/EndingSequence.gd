extends Control
class_name EndingSequence
## Shared scaffolding for the character-specific ending cinematics.
##
## Owns the fade-to-black, captions, ambient audio, camera helper and the
## any-key skip. Subclasses build their world in _build() and drive the story
## in _play(). Gameplay is frozen by Main before this node is added.

signal finished

var _world: Control
var _black: ColorRect
var _caption_layer: Control
var _final_layer: Control
var _hint: Label
var _ambient: Array[AudioStreamPlayer] = []
var _done := false
var _t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = MOUSE_FILTER_STOP
	focus_mode = FOCUS_ALL
	var vp := get_viewport_rect().size
	position = Vector2.ZERO
	size = vp
	set_anchors_preset(PRESET_FULL_RECT)

	_world = Control.new()
	_world.name = "World"
	_world.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_world.position = Vector2.ZERO
	_world.size = vp
	_world.pivot_offset = Vector2(192, 118)
	_world.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_world)

	_caption_layer = Control.new()
	_caption_layer.position = Vector2.ZERO
	_caption_layer.size = vp
	_caption_layer.mouse_filter = MOUSE_FILTER_IGNORE
	_caption_layer.z_index = 900
	add_child(_caption_layer)

	_build()

	_black = ColorRect.new()
	_black.color = Color(0, 0, 0, 1)
	_black.position = Vector2.ZERO
	_black.size = vp
	_black.mouse_filter = MOUSE_FILTER_IGNORE
	_black.z_index = 1000
	add_child(_black)

	_hint = UISkin.label("[ANY KEY] SKIP", 8, Color(0.72, 0.76, 0.86, 0))
	_hint.position = Vector2(268, 200)
	_hint.size = Vector2(110, 10)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.z_index = 1001
	add_child(_hint)

	_run.call_deferred()
	grab_focus()


func _run() -> void:
	await get_tree().process_frame
	if _done:
		return
	await _play()


## Override: create sprites, backgrounds and UI inside _world.
func _build() -> void:
	pass


## Override: drive the timeline. Use await _wait(seconds).
func _play() -> void:
	pass


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	if _t > 1.2:
		_hint.modulate.a = clampf((6.0 - _t) / 2.0, 0.0, 0.65)
	_animate(delta)


## Override: per-frame environmental animation (surf, snow, typing).
func _animate(_delta: float) -> void:
	pass


## Await a timer, returning false if the cinematic was skipped meanwhile.
func _wait(seconds: float) -> bool:
	await get_tree().create_timer(seconds).timeout
	return not _done and is_inside_tree()


func _fade_in(seconds := 1.4) -> void:
	var tw := create_tween()
	tw.tween_property(_black, "color:a", 0.0, seconds)


func _fade_out(seconds := 2.4) -> void:
	var tw := create_tween()
	tw.tween_property(_black, "color:a", 1.0, seconds)


## Non-blocking caption strip at the top of the frame.
func _say(text: String, color := Color("f7e9bd"), hold := 3.4) -> void:
	if _caption_layer == null:
		return
	for c in _caption_layer.get_children():
		_caption_layer.remove_child(c)
		c.queue_free()
	var group := Control.new()
	group.position = Vector2.ZERO
	group.size = size
	group.modulate.a = 0.0
	group.mouse_filter = MOUSE_FILTER_IGNORE
	_caption_layer.add_child(group)
	var panel := ColorRect.new()
	panel.color = Color(0.02, 0.02, 0.06, 0.52)
	panel.position = Vector2(0, 12)
	panel.size = Vector2(size.x, 26)
	group.add_child(panel)
	var lbl := UISkin.label(text, 8, color)
	lbl.position = Vector2(0, 15)
	lbl.size = Vector2(size.x, 20)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	group.add_child(lbl)
	var tw := create_tween()
	tw.tween_property(group, "modulate:a", 1.0, 0.55)
	var timer := get_tree().create_timer(hold)
	timer.timeout.connect(func():
		if not is_instance_valid(group):
			return
		var out := create_tween()
		out.tween_property(group, "modulate:a", 0.0, 0.7)
		out.tween_callback(group.queue_free))


## Fade-to-black title card used right before the credits.
func _final(title: String, sub: String) -> void:
	# Guarantee a clean black card: z_index alone can be fought by world
	# sprites, so hide the world and force the overlay opaque.
	_black.color.a = 1.0
	_hint.visible = false
	if _world != null:
		_world.visible = false
	if _caption_layer != null:
		_caption_layer.visible = false
	if _final_layer != null and is_instance_valid(_final_layer):
		_final_layer.queue_free()
	_final_layer = Control.new()
	_final_layer.z_index = 1002
	_final_layer.position = Vector2.ZERO
	_final_layer.size = size
	_final_layer.mouse_filter = MOUSE_FILTER_IGNORE
	_final_layer.modulate.a = 0.0
	add_child(_final_layer)
	var t := UISkin.label(title, 16, Color("f7e94b"))
	t.position = Vector2(0, 84)
	t.size = Vector2(size.x, 20)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_final_layer.add_child(t)
	var s := UISkin.label(sub, 8, Color("9adcff"))
	s.position = Vector2(0, 108)
	s.size = Vector2(size.x, 10)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_final_layer.add_child(s)
	var p := UISkin.label("[PRESS ANY KEY]", 8, Color("5f6a86"))
	p.position = Vector2(0, 192)
	p.size = Vector2(size.x, 10)
	p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_final_layer.add_child(p)
	var tw := create_tween()
	tw.tween_property(_final_layer, "modulate:a", 1.0, 1.0)


func _play_ambient(path: String, volume_db := -10.0) -> AudioStreamPlayer:
	var stream: AudioStreamWAV = load(path)
	if stream == null:
		return null
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(round(stream.get_length() * stream.mix_rate))
	var p := AudioStreamPlayer.new()
	p.bus = "SFX"
	p.stream = stream
	p.volume_db = volume_db
	add_child(p)
	p.play()
	_ambient.append(p)
	return p


func _stop_ambient() -> void:
	for p in _ambient:
		if p != null and is_instance_valid(p):
			var tw := create_tween()
			tw.tween_property(p, "volume_db", -40.0, 0.6)
			tw.tween_callback(p.stop)
	_ambient.clear()


func _camera(scale_to: float, duration: float, pivot := Vector2(192, 118)) -> Tween:
	_world.pivot_offset = pivot
	var tw := create_tween()
	tw.tween_property(_world, "scale", Vector2(scale_to, scale_to), duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tw


func _finish() -> void:
	if _done:
		return
	_done = true
	_stop_ambient()
	finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	var pressed: bool = (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventMouseButton and event.pressed)
	if not pressed:
		return
	if _t > 1.0:
		_finish()
	get_viewport().set_input_as_handled()
