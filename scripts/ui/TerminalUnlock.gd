extends Control
class_name TerminalUnlock
## Secret `root` unlock sequence. Full-screen terminal, typed lines, blinking
## cursor, then hands control back to the menu.

signal finished

const LINES := [
	"root@pingudot:~$ ./unlock_miggy",
	"",
	"Checking permissions...",
	"Loading GNOME modules...",
	"Initializing Mono runtime...",
	"Mounting /midnight/commander...",
	"Privilege escalation successful.",
	"",
	"WELCOME, MIGGY.",
]

var _t := 0.0
var _typed := 0
var _done := false
var _cursor: Label
var _body: Label
var _blink := 0.0


func _ready() -> void:
	var vp := get_viewport_rect().size
	position = Vector2.ZERO
	size = vp
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color("05050a")
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.position = Vector2.ZERO
	bg.size = vp
	add_child(bg)
	var scan := ColorRect.new()
	scan.color = Color(0.05, 0.25, 0.15, 0.18)
	scan.set_anchors_preset(PRESET_FULL_RECT)
	scan.position = Vector2.ZERO
	scan.size = vp
	add_child(scan)
	var lines := ColorRect.new()
	lines.set_anchors_preset(PRESET_FULL_RECT)
	lines.position = Vector2.ZERO
	lines.size = vp
	lines.mouse_filter = MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/scanlines.gdshader")
	lines.material = mat
	add_child(lines)
	_body = UISkin.label("", 8, Color("6ec72c"))
	_body.position = Vector2(24, 30)
	_body.size = Vector2(336, 150)
	_body.autowrap_mode = TextServer.AUTOWRAP_OFF
	add_child(_body)
	_cursor = UISkin.label("_", 8, Color("6ec72c"))
	_cursor.position = Vector2(24, 182)
	add_child(_cursor)
	var hint := UISkin.label("[ENTER] SKIP", 8, Color("2a5a3a"))
	hint.position = Vector2(276, 200)
	add_child(hint)
	AudioDirector.play_sfx("miggy_unlock")
	AudioDirector.play_sfx("terminal_type")
	_text_so_far = ""


var _text_so_far := ""
var _line_t := 0.0


func _all_text() -> String:
	return "\n".join(LINES)


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	_blink += delta
	_cursor.visible = fmod(_blink, 0.6) < 0.4
	var full := _all_text()
	var cps := 55.0
	_typed = mini(full.length(), int(_t * cps))
	_body.text = full.substr(0, _typed)
	if _typed >= full.length():
		_done = true
		await get_tree().create_timer(0.9).timeout
		finished.emit()


func skip() -> void:
	_typed = _all_text().length()
	_body.text = _all_text()
	if not _done:
		_done = true
		finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		if _t > 0.4:
			_typed = _all_text().length()
			_body.text = _all_text()
			if not _done:
				_done = true
				finished.emit()
