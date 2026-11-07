extends Node2D
class_name DualPanelWield
## MIGGY's Midnight Commander dual-panel weapon: two orbiting panels — one fires
## files, the other explosive folders. Temporary (setup duration), auto-cleans.

var _player: Player
var _t := 8.0
var _fire_t := 0.35
var _angle := 0.0
var _panels: Array[AnimatedSprite2D] = []


func setup(player: Player, duration := 8.0) -> void:
	_player = player
	_t = duration


func _ready() -> void:
	z_index = 25
	var frames := SpriteLib.build("res://assets/effects/dual_panel.png")
	for i in 2:
		var s := AnimatedSprite2D.new()
		s.sprite_frames = frames
		var names := frames.get_animation_names()
		if names.size() > 0:
			s.animation = names[0]
			s.play()
		s.scale = Vector2(1.1, 1.1)
		s.z_index = 9
		add_child(s)
		_panels.append(s)


func _process(delta: float) -> void:
	_t -= delta
	if _t <= 0.0 or _player == null or not is_instance_valid(_player) or _player.is_dead():
		queue_free()
		return
	_angle += delta * 2.2
	for i in _panels.size():
		var a := _angle + i * PI
		_panels[i].position = Vector2(cos(a), sin(a)) * 30.0
		_panels[i].rotation = 0.0
	_fire_t -= delta
	if _fire_t <= 0.0:
		_fire_t = 0.55
		_fire()


func _fire() -> void:
	var target: EnemyBase = null
	var best := 210.0
	for e in get_tree().get_nodes_in_group("enemies"):
		var eb := e as EnemyBase
		if eb == null or eb.is_dead():
			continue
		var d: float = global_position.distance_to(eb.global_position)
		if d < best:
			best = d
			target = eb
	if target == null or _panels.size() < 2:
		return
	var dmg := int(_player.stats.effective_atk() * 0.9 + _player.stats.effective_int() * 0.5)
	var p0 := _panels[0].global_position
	var p1 := _panels[1].global_position
	var dir0 := (target.global_position - p0).normalized()
	var dir1 := (target.global_position - p1).normalized()
	FX.shoot("file_proj", p0, dir0, dmg, "player", 260.0, 40.0, false, "", 0, false, 1.2)
	FX.shoot("folder_proj", p1, dir1, int(dmg * 1.5), "player", 165.0, 90.0,
		false, "", 0, false, 1.2, 34.0, int(dmg * 0.7))
	AudioDirector.play_sfx("dual_wield", -10.0, 0.2)
