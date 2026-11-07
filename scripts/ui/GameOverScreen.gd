extends Control
class_name GameOverScreen

signal restart_requested
signal menu_requested


func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.28, 0.02, 0.05, 0.72)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	add_child(dim)
	var p := UISkin.make_panel("panel_red")
	p.position = Vector2(70, 38)
	p.size = Vector2(244, 144)
	add_child(p)
	var title := UISkin.label("SYSTEM HALTED", 16, Color("ff8c8c"))
	title.position = Vector2(84, 46)
	add_child(title)
	var d := DialogueDB.get_line("gameover_1")
	var txt := String(d["text"]).replace(" (", "\n(")
	var l1 := UISkin.label(txt, 8, Color("f2f2f2"))
	l1.position = Vector2(84, 76)
	l1.size = Vector2(216, 30)
	add_child(l1)
	var d2 := DialogueDB.get_line("gameover_2")
	var l2 := UISkin.label(d2["text"], 8, Color("9aa4b2"))
	l2.position = Vector2(84, 108)
	l2.size = Vector2(216, 20)
	l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(l2)
	var b1 := Button.new()
	b1.text = "REBOOT AT TERMINAL"
	b1.position = Vector2(84, 126)
	b1.size = Vector2(216, 18)
	b1.add_theme_font_size_override("font_size", 8)
	b1.pressed.connect(func():
		AudioDirector.play_sfx("ui_ok")
		restart_requested.emit())
	add_child(b1)
	b1.grab_focus()
	var b2 := Button.new()
	b2.text = "GIVE UP TO THE BOARD"
	b2.position = Vector2(84, 150)
	b2.size = Vector2(216, 18)
	b2.add_theme_font_size_override("font_size", 8)
	b2.pressed.connect(func():
		AudioDirector.play_sfx("ui_back")
		menu_requested.emit())
	add_child(b2)
	AudioDirector.play_music("gameover", 0.2)
