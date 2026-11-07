extends Area2D
class_name CoinPickup
## Dropped coin; auto-collects on contact, drifts toward the player when close.

var amount := 1
var _t := 0.0
var _player: Node = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body)
	var s := Sprite2D.new()
	s.texture = load("res://assets/ui/coin.png")
	add_child(s)
	var sh := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 8.0
	sh.shape = c
	add_child(sh)
	z_index = 8
	_player = get_tree().get_first_node_in_group("player")
	# launch arc
	var ang := randf() * TAU
	_vel = Vector2(cos(ang), sin(ang) - 1.0) * 40.0


var _vel := Vector2.ZERO


func _physics_process(delta: float) -> void:
	_t += delta
	position += _vel * delta
	_vel = _vel.move_toward(Vector2.ZERO, 140 * delta)
	_vel += Vector2(randf_range(-6, 6), randf_range(-6, 6)) * delta
	if _player == null or not is_instance_valid(_player):
		return
	var d := position.distance_to(_player.position)
	if d < 30.0:
		position = position.move_toward(_player.position, (34.0 - d) * 5.0 * delta)


func _on_body(body: Node) -> void:
	if body is Player:
		GameState.add_coins(amount)
		FX.pop_text(global_position + Vector2(0, -10), "+%d" % amount, Color("f7e94b"), 8)
		AudioDirector.play_sfx("coin")
		queue_free()
