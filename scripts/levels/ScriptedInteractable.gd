extends Interactable
class_name ScriptedInteractable
## An Interactable whose behavior is a Callable assigned at spawn time.
## Used for vendors, ATMs, signs, events and hidden-room chests.

var _action: Callable
var _consumable := false      # disappear after one use?
var _used := false


func _ready() -> void:
	super()


func configure(tex: Texture2D, hint: String, action: Callable, one_shot := false) -> void:
	set_texture(tex)
	hint_text = hint
	_action = action
	_consumable = one_shot


func on_interact() -> void:
	if _used and _consumable:
		return
	_used = true
	if _action.is_valid():
		_action.call()
	if _consumable:
		queue_free()
