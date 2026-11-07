extends Area2D
class_name ExitZone
## Walking into the exit advances the mission (or seals the door in Area 5).

var next_index := -1   # -1 means "sealed door"


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body)
	# shimmer portal
	var s := Sprite2D.new()
	s.texture = load("res://assets/ui/star.png")
	s.modulate = Color(0.4, 1.0, 0.6, 0.9)
	s.z_index = 4
	add_child(s)
	var sh := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(18, 18)
	sh.shape = r
	add_child(sh)
	_spr = s


var _spr: Sprite2D
var _t := 0.0
var _cooldown := false


func _process(delta: float) -> void:
	_t += delta
	_spr.scale = Vector2.ONE * (1.0 + sin(_t * 5.0) * 0.15)
	_spr.rotation = _t * 0.8


func _on_body(body: Node) -> void:
	if _cooldown or not (body is Player):
		return
	_cooldown = true
	if next_index >= 0:
		AudioDirector.play_sfx("door")
		Main.goto_area(next_index)
	else:
		EventBus.dialogue_requested.emit("area5_intro")
		get_tree().create_timer(2.5).timeout.connect(func(): _cooldown = false)
