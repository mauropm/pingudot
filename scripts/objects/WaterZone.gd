extends Area2D
class_name WaterZone
## Shallow water / tide pool: slows movement, no damage.

func _ready() -> void:
	add_to_group("hazards")
	collision_layer = 128
	collision_mask = 2
	body_entered.connect(_on_body)


func _on_body(body: Node) -> void:
	if body is Player:
		body.apply_status("water")
