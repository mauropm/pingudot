extends Control
class_name DialogueBox
## SNES dialogue box with typewriter effect. Consumes movement/attack keys
## while active so combat doesn't fire accidentally.

var _panel: Panel
var _speaker: Label
var _text: Label
var _prompt: Label
var _queue: Array[String] = []
var _typing := false
var _visible_chars := 0
var _full := ""
var _char_t := 0.0
var _showing := false
var _blink_t := 0.0
var _player_cache: Player = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group("dialogue")
	visible = false
	_panel = UISkin.make_panel("panel_dialogue")
	_panel.position = Vector2(16, 150)
	_panel.size = Vector2(352, 62)
	add_child(_panel)
	_speaker = UISkin.label("", 8, Color("2de3ff"))
	_speaker.position = Vector2(28, 156)
	add_child(_speaker)
	_text = UISkin.label("", 8, Color("f2f2f2"))
	_text.position = Vector2(28, 168)
	_text.size = Vector2(328, 30)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_text)
	_prompt = UISkin.label("ANY KEY TO SKIP >", 8, Color("f7e94b"))
	_prompt.position = Vector2(244, 202)
	_prompt.visible = false
	add_child(_prompt)
	EventBus.dialogue_requested.connect(show_line)
	EventBus.area_entered.connect(func(_i, _n): pass)


func has_pending() -> bool:
	return _showing or _queue.size() > 0


func reset() -> void:
	_queue.clear()
	_showing = false
	_typing = false
	visible = false
	_prompt.visible = false
	if _player_cache and is_instance_valid(_player_cache):
		_player_cache.frozen = false


func show_line(id: String) -> void:
	_queue.append(id)
	if not _showing:
		_next()


func _next() -> void:
	if _queue.is_empty():
		_showing = false
		visible = false
		_prompt.visible = false
		if _player_cache and is_instance_valid(_player_cache):
			_player_cache.frozen = false
		EventBus.dialogue_finished.emit()
		return
	var id := String(_queue.pop_front())
	var d := DialogueDB.get_line(id)
	_speaker.text = d.get("speaker", "")
	_full = d.get("text", id)
	_text.visible_ratio = 0.0
	_text.text = _full
	_showing = true
	_typing = true
	_visible_chars = 0
	_char_t = 0.0
	_blink_t = 0.0
	_prompt.visible = false
	visible = true
	if _player_cache == null or not is_instance_valid(_player_cache):
		_player_cache = get_tree().get_first_node_in_group("player")
	if _player_cache:
		_player_cache.frozen = true
	AudioDirector.play_sfx("ui_move")


func _process(delta: float) -> void:
	if not _showing:
		return
	if _typing:
		_prompt.visible = false
		_char_t += delta
		var cps := 42.0
		while _char_t > 1.0 / cps and _visible_chars < _full.length():
			_char_t -= 1.0 / cps
			_visible_chars += 1
			_text.visible_characters = _visible_chars
		if _visible_chars >= _full.length():
			_typing = false
			_text.visible_characters = -1
			_blink_t = 0.0
	else:
		# Blinking "SPACE >" affordance once the line has finished typing.
		_blink_t += delta
		_prompt.visible = fmod(_blink_t, 0.8) < 0.55


func consume_key(event: InputEvent) -> bool:
	if not _showing:
		return false
	# "ANY KEY TO SKIP" — accept any real key press (ignore modifiers/echo).
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if k in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META, KEY_CAPSLOCK, KEY_NUMLOCK, KEY_SCROLLLOCK]:
			return false
		_advance()
		return true
	if event is InputEventJoypadButton and event.pressed:
		_advance()
		return true
	return false


func _advance() -> void:
	if _typing:
		_visible_chars = _full.length()
		_text.visible_characters = -1
		_typing = false
	else:
		AudioDirector.play_sfx("ui_ok")
		_next()
