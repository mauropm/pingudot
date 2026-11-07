extends Area2D
class_name Hazard
## Environmental hazard zone (kernel-panic vent / lava / fire / electric floor).
## Applies damage ticks while the player stands on it.

var damage := 4
var tick_period := 0.9
var _inside: Node = null
var _t := 0.0


func _ready() -> void:
	add_to_group("hazards")
	collision_layer = 128
	collision_mask = 2
	set_meta("hazard_damage", damage)
	body_entered.connect(_on_body)
	body_exited.connect(_on_leave)
	monitoring = true


func _on_body(body: Node) -> void:
	if body is Player:
		_inside = body


func _on_leave(body: Node) -> void:
	if body == _inside:
		_inside = null
		_t = 0.0


func _process(delta: float) -> void:
	if _inside == null or not is_instance_valid(_inside):
		return
	_t += delta
	if _t >= tick_period:
		_t = 0.0
		AudioDirector.play_sfx("hazard")
		_inside.take_damage(damage, Vector2.UP, "hazard", 0)
