extends Area2D
class_name LootPickup
## Dropped item: bobbing icon with rarity frame; collected by walking over it.

var item: ItemResource
var _t := 0.0
var _base_y := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body)
	var frame := Sprite2D.new()
	frame.texture = load("res://assets/ui/slot_%s.png" % item.rarity)
	add_child(frame)
	var icon := Sprite2D.new()
	icon.texture = item.icon
	icon.position = Vector2(0, -1)
	add_child(icon)
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 9.0
	shape.shape = c
	add_child(shape)
	_base_y = position.y
	z_index = 8


func _process(delta: float) -> void:
	_t += delta
	position.y = _base_y + sin(_t * 4.0) * 1.5


func _on_body(body: Node) -> void:
	if body is Player:
		if GameState.add_item(item):
			var col: Color = ItemResource.RARITY_COLORS[item.rarity]
			FX.pop_text(global_position + Vector2(0, -12), "%s" % item.display_name, col, 8)
			AudioDirector.play_sfx("item_get")
			queue_free()
		else:
			FX.pop_text(global_position + Vector2(0, -12), "INVENTORY FULL", Color("e2282e"), 8)
			AudioDirector.play_sfx("ui_back")
