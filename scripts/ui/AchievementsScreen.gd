extends Control
class_name AchievementsScreen

signal close_requested


func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	add_child(dim)
	var root := UISkin.make_panel("panel_dark")
	root.position = Vector2(20, 10)
	root.size = Vector2(344, 196)
	add_child(root)
	var title := UISkin.label("ACHIEVEMENTS  %d/%d" % [
		AchievementManager.unlocked_count(), AchievementManager.total()], 8, Color("f7e94b"))
	title.position = Vector2(30, 18)
	add_child(title)
	var trophy := Sprite2D.new()
	trophy.texture = load("res://assets/ui/trophy.png")
	trophy.position = Vector2(344, 24)
	add_child(trophy)
	var i := 0
	for a in AchievementManager.defs:
		var got := AchievementManager.is_unlocked(String(a["id"]))
		var line := "%s %s - %s" % ["[OK]" if got else "[ ]", a["name"], a["desc"]]
		if line.length() > 54:
			line = line.substr(0, 53) + "."
		var l := UISkin.label(line, 8, Color("6ec72c") if got else Color("5a6280"))
		l.position = Vector2(30, 36 + i * 13)
		add_child(l)
		i += 1


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("inventory") \
			or Input.is_action_just_pressed("stats") or Input.is_action_just_pressed("interact"):
		close_requested.emit()
		get_viewport().set_input_as_handled()
