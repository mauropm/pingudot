extends Control
class_name IntroCinematic
## Story slides with parallax art + typed text. Skippable with any key.

signal finished

const SLIDES := [
	{"bg": "area1", "line": "intro_1", "dur": 5.0},
	{"bg": "area1", "line": "intro_2", "dur": 5.0},
	{"bg": "area4", "line": "intro_3", "dur": 5.0},
	{"bg": "area5", "line": "controls_card", "dur": 7.0},
]

var _i := 0
var _img: TextureRect
var _text: Label
var _t := 0.0
var _done := false


func _ready() -> void:
	var bgc := ColorRect.new()
	bgc.color = Color("0a0812")
	bgc.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bgc)
	_img = TextureRect.new()
	_img.set_anchors_preset(PRESET_FULL_RECT)
	_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_img.modulate = Color(1, 1, 1, 0.9)
	add_child(_img)
	var frame := UISkin.make_panel("panel_dialogue")
	frame.position = Vector2(24, 156)
	frame.size = Vector2(336, 52)
	add_child(frame)
	_text = UISkin.label("", 8, Color("f2f2f2"))
	_text.position = Vector2(36, 168)
	_text.size = Vector2(312, 40)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_text)
	var skip := UISkin.label("ANY KEY TO SKIP >", 8, Color("f7e94b"))
	skip.position = Vector2(240, 200)
	add_child(skip)
	_show_slide()


func _show_slide() -> void:
	if _i >= SLIDES.size():
		_finish()
		return
	var s: Dictionary = SLIDES[_i]
	_img.texture = load("res://assets/environments/backgrounds/%s_bg.png" % s["bg"])
	var d := DialogueDB.get_line(s["line"])
	_text.text = d["text"]
	_text.visible_characters = 0
	_t = 0.0
	create_tween().tween_property(_text, "visible_characters", d["text"].length(), 2.2)


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	if _t >= float(SLIDES[_i].get("dur", 4.5)) if _i < SLIDES.size() else false:
		_i += 1
		_show_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("pause"):
			_finish()
		else:
			_i += 1
			_show_slide()
		get_viewport().set_input_as_handled()


func _finish() -> void:
	if _done:
		return
	_done = true
	AudioDirector.play_sfx("ui_ok")
	finished.emit()
