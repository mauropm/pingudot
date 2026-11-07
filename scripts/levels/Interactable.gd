extends Area2D
class_name Interactable
## A world object the player can interact with by pressing E.
## `hint_text` shows the button prompt; `on_interact()` runs the behavior.

var hint_text := ""
var _sprite: Sprite2D
var _near := false


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_in)
	body_exited.connect(_on_out)
	if _sprite == null:
		_sprite = Sprite2D.new()
		_sprite.z_index = 6
		add_child(_sprite)
	var sh := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(22, 20)
	sh.shape = r
	add_child(sh)


func set_texture(tex: Texture2D) -> void:
	if _sprite == null:
		return
	_sprite.texture = tex


func set_sprite_offset(o: Vector2) -> void:
	if _sprite != null:
		_sprite.offset = o


func _on_in(body: Node) -> void:
	if body is Player:
		_near = true
		if hint_text != "":
			EventBus.interact_hint.emit(hint_text)


func _on_out(body: Node) -> void:
	if body is Player:
		_near = false
		EventBus.interact_hint.emit("")


func interact() -> void:
	if _near:
		on_interact()


func on_interact() -> void:
	pass
