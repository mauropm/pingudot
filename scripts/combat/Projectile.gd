extends Area2D
class_name Projectile
## Reusable projectile for both sides. Owner "player" hits enemies, "enemy" hits the player.

var direction := Vector2.RIGHT
var speed := 140.0
var damage := 5
var owner_kind := "player"       # player|enemy
var knockback := 90.0
var pierce := false
var crit := false
var life := 2.2
var status_effect := ""          # optional extra effect applied on hit
var coin_steal := 0

var _tex_frames: SpriteFrames
var _vis_scale := 1.0
var _hit: Array[RID] = []


func setup(frames: SpriteFrames, dir: Vector2, dmg: int, spd := 140.0, p_owner := "player", kb := 90.0, pierce_ := false, vis_scale := 1.0) -> void:
	_tex_frames = frames
	_vis_scale = vis_scale
	direction = dir.normalized()
	damage = dmg
	speed = spd
	owner_kind = p_owner
	knockback = kb
	pierce = pierce_


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4 if owner_kind == "player" else 2
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 4.0
	shape.shape = c
	add_child(shape)
	if _tex_frames != null:
		var s := AnimatedSprite2D.new()
		s.sprite_frames = _tex_frames
		var names := s.sprite_frames.get_animation_names()
		if names.size() > 0:
			s.animation = names[0]
			s.play()
		s.scale = Vector2.ONE * _vis_scale
		add_child(s)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	life -= delta
	if life <= 0.0:
		die()
		return
	if _hits_wall():
		FX.spark(global_position)
		die()


func _hits_wall() -> bool:
	var lv := get_tree().get_first_node_in_group("level")
	if lv != null and lv.has_method("point_is_solid"):
		return bool(lv.point_is_solid(global_position))
	return false


func _on_body_entered(body: Node) -> void:
	if body.get_rid() in _hit:
		return
	if owner_kind == "player" and body is EnemyBase and not body.is_dead():
		body.take_hit(damage, direction * knockback, crit, "player")
		_hit.append(body.get_rid())
		if not pierce:
			die()
	elif owner_kind == "enemy" and body is Player:
		var pl := body as Player
		var dir: Vector2 = (pl.global_position - global_position).normalized()
		pl.take_damage(damage, dir, status_effect, coin_steal)
		if not pierce:
			die()


func die() -> void:
	set_physics_process(false)
	queue_free()
