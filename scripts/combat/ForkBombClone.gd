extends Node2D
class_name ForkBombClone
## Mini-Pingu spawned by the Fork Bomb ability. Homes on the nearest enemy,
## tackles it for a hit of damage, then poofs.

var _dmg := 5
var _life := 6.0
var _speed := 95.0
var _target: EnemyBase = null
var _owner: Node


func setup(frames: SpriteFrames, owner: Node, dmg: int, life := 6.0) -> void:
	_owner = owner
	_dmg = dmg
	_life = life
	if frames != null:
		var s := AnimatedSprite2D.new()
		s.sprite_frames = frames
		s.animation = frames.get_animation_names()[0]
		s.play()
		add_child(s)


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		FX.spark(position)
		queue_free()
		return
	if _target == null or not is_instance_valid(_target) or _target.is_dead():
		_target = _find_target()
		if _target == null:
			return
	var dir: Vector2 = (_target.position - position).normalized()
	position += dir * _speed * delta
	if position.distance_to(_target.position) < 12.0:
		_target.take_hit(_dmg, dir * 70.0, false, "clone")
		FX.spark(position)
		queue_free()


func _find_target() -> EnemyBase:
	var best: EnemyBase = null
	var best_d := 240.0
	for e in get_tree().get_nodes_in_group("enemies"):
		var eb := e as EnemyBase
		if eb == null or eb.is_dead():
			continue
		var d: float = position.distance_to(eb.position)
		if d < best_d:
			best_d = d
			best = eb
	return best
