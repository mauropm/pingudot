extends Interactable
class_name Checkpoint
## Public Terminal: saves the run, restores HP/energy, sets respawn point.

var area_index := 0
var tile := Vector2i.ZERO


func _ready() -> void:
	hint_text = "USE TERMINAL [E]"
	super()
	set_texture(load("res://assets/environments/objects/checkpoint.png"))
	var glow := Sprite2D.new()
	glow.texture = _sprite.texture
	glow.modulate = Color(0.6, 1.2, 1.2, 0.35)
	glow.position = Vector2(0, -1)
	add_child(glow)


func on_interact() -> void:
	GameState.checkpoint = {"area": area_index, "x": tile.x, "y": tile.y}
	var s := GameState.stats
	s.hp = s.max_hp
	s.en = s.max_en
	EventBus.player_hp_changed.emit(s.hp, s.max_hp)
	EventBus.player_energy_changed.emit(s.en, s.max_en)
	GameState.write_save()
	EventBus.checkpoint_reached.emit(area_index, tile.x, tile.y)
	AudioDirector.play_sfx("save")
	EventBus.dialogue_requested.emit("cp_save")
	EventBus.dialogue_finished.connect(_say_full, CONNECT_ONE_SHOT)


func _say_full() -> void:
	EventBus.dialogue_requested.emit("cp_full")
