extends EndingSequence
class_name PinguEnding
## Ending A — Pingu in Puerto Escondido.
##
## A warm, quiet sunset on the Pacific: animated surf, drifting clouds, swaying
## palms, birds, a descending sun and Pingu walking to the water and sitting
## down as the sky turns to night.

const BG := "res://assets/environments/endings/"

var _day: TextureRect
var _sunset: TextureRect
var _night: TextureRect
var _sun: Sprite2D
var _cloud_a: Sprite2D
var _cloud_b: Sprite2D
var _wave_a: Sprite2D
var _wave_b: Sprite2D
var _foam: Sprite2D
var _pingu: AnimatedSprite2D
var _scroll := 0.0
var _bird_t := 1.0
var _palms: Array[Dictionary] = []
var _birds: Array[Dictionary] = []
var _bird_frames: SpriteFrames


func _build() -> void:
	_night = _bg("pingu_beach_night.png")
	_sunset = _bg("pingu_beach_sunset.png")
	_day = _bg("pingu_beach_day.png")

	_cloud_a = _strip("pingu_clouds.png", Vector2(0, 18))
	_cloud_b = _strip("pingu_clouds.png", Vector2(384, 18))
	_wave_a = _strip("pingu_waves.png", Vector2(0, 118))
	_wave_b = _strip("pingu_waves.png", Vector2(384, 118))
	_foam = _strip("pingu_foam.png", Vector2(0, 152))

	_sun = Sprite2D.new()
	_sun.texture = load(BG + "pingu_sun.png")
	_sun.position = Vector2(282, 94)
	_sun.scale = Vector2(1.25, 1.25)
	_sun.z_index = 2
	_world.add_child(_sun)

	_palm(Vector2(44, 216), 2.0, false, 3.4)
	_palm(Vector2(342, 214), 2.2, true, 4.1)

	_pingu = AnimatedSprite2D.new()
	_pingu.sprite_frames = SpriteLib.build("res://assets/characters/pingu.png")
	_pingu.animation = "idle"
	_pingu.play()
	_pingu.position = Vector2(108, 176)
	_pingu.scale = Vector2(2, 2)
	_pingu.z_index = 8
	_world.add_child(_pingu)

	_bird_frames = SpriteLib.build(BG + "pingu_birds.png")


func _bg(file: String) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(BG + file)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.position = Vector2.ZERO
	t.size = size
	t.mouse_filter = MOUSE_FILTER_IGNORE
	_world.add_child(t)
	return t


func _strip(file: String, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(BG + file)
	s.centered = false
	s.position = pos
	s.z_index = 3
	s.modulate.a = 0.9
	_world.add_child(s)
	return s


func _palm(base: Vector2, sc: float, mirror: bool, sway: float) -> void:
	var pivot := Node2D.new()
	pivot.position = base
	_world.add_child(pivot)
	var s := Sprite2D.new()
	s.texture = load(BG + "pingu_palm.png")
	s.centered = false
	s.flip_h = mirror
	s.scale = Vector2(sc, sc)
	s.position = Vector2(-32.0 * sc, -112.0 * sc)
	s.z_index = 9
	pivot.add_child(s)
	_palms.append({"n": pivot, "amp": deg_to_rad(1.1),
		"spd": 1.6 / maxf(1.0, sway), "ph": 0.0 if base.x < 192.0 else 1.7})


func _play() -> void:
	AudioDirector.play_music("ending", 1.2)
	_play_ambient("res://assets/audio/ambient/beach.wav", -11.0)
	_fade_in(1.6)
	_camera(1.06, 16.0, Vector2(262, 112))
	_say("PUERTO ESCONDIDO, OAXACA.\nTHE PACIFIC, AT LAST.", Color("fff0cc"), 3.6)
	await _wait(1.6)
	if _done:
		return

	# walk down to the water
	_pingu.play("walk")
	var walk := create_tween()
	walk.tween_property(_pingu, "position:x", 174.0, 3.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	AudioDirector.play_sfx("ocean", -14.0, 0.0)
	await _wait(3.4)
	if _done:
		return
	_pingu.play("idle")
	await _wait(0.6)
	if _done:
		return
	_pingu.position = Vector2(174, 178)
	_pingu.play("sit")

	# the sun begins to set
	var day_fade := create_tween()
	day_fade.tween_property(_day, "modulate:a", 0.0, 6.0)
	var sun_drop := create_tween()
	sun_drop.tween_property(_sun, "position:y", 140.0, 11.0) \
		.set_trans(Tween.TRANS_SINE)
	_say("NO MEETINGS. NO BACKLOG.\nJUST THE SUN AND THE SEA.", Color("ffc9a0"), 4.2)
	await _wait(4.0)
	if _done:
		return

	# twilight: fade the sunset into the starry night
	var dusk := create_tween()
	dusk.tween_property(_sunset, "modulate:a", 0.0, 4.2)
	var sun_gone := create_tween()
	sun_gone.tween_property(_sun, "modulate:a", 0.0, 3.6)
	await _wait(4.4)
	if _done:
		return
	await _wait(1.6)
	if _done:
		return

	_fade_out(2.6)
	await _wait(2.8)
	if _done:
		return
	_final("MISSION ACCOMPLISHED", "PINGU FOUND THE PLACE.")
	await _wait(4.6)
	_finish()


func _animate(delta: float) -> void:
	_scroll += delta * 4.0
	_cloud_a.position.x = fposmod(-_scroll * 0.35, 384.0)
	_cloud_b.position.x = _cloud_a.position.x + 384.0
	var surf := fposmod(-_scroll, 384.0)
	_wave_a.position.x = surf
	_wave_b.position.x = surf + 384.0
	_foam.position.x = fposmod(-_scroll * 0.6, 384.0)
	_foam.modulate.a = 0.55 + 0.22 * sin(_t * 1.4)
	_foam.position.y = 152.0 + sin(_t * 1.1) * 1.0

	for p in _palms:
		var pn: Node2D = p["n"]
		if is_instance_valid(pn):
			pn.rotation = p["amp"] * sin(_t * p["spd"] + p["ph"])
	for b in _birds:
		var bn: AnimatedSprite2D = b["n"]
		if is_instance_valid(bn):
			bn.position.y = b["base"] + sin(_t * 4.4 + b["ph"]) * 2.5

	# birds crossing the evening sky during the first half
	if _t < 13.0:
		_bird_t -= delta
		if _bird_t <= 0.0:
			_bird_t = randf_range(2.4, 4.2)
			_spawn_bird()


func _spawn_bird() -> void:
	var b := AnimatedSprite2D.new()
	b.sprite_frames = _bird_frames
	b.animation = "fly"
	b.play()
	var y := randf_range(44.0, 92.0)
	b.position = Vector2(-12, y)
	b.scale = Vector2(2, 2)
	b.z_index = 4
	b.modulate.a = 0.85
	_world.add_child(b)
	_birds.append({"n": b, "base": y, "ph": randf_range(0.0, 6.28)})
	var dur := randf_range(6.5, 9.5)
	var tw := create_tween()
	tw.tween_property(b, "position:x", 402.0, dur)
	tw.tween_callback(func():
		for i in range(_birds.size() - 1, -1, -1):
			if _birds[i]["n"] == b:
				_birds.remove_at(i)
				break
		b.queue_free())
