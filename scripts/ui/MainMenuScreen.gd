extends Control
class_name MainMenuScreen
## Title screen: New Game / Continue / Achievements / Settings / Controls.

var _box: VBoxContainer
var _seed_edit: LineEdit
var _page := "main"
var _controls_panel: Control
var _selected := 0
var _items: Array[Control] = []


func _ready() -> void:
	AudioDirector.play_music("menu", 0.0)
	var bg := ColorRect.new()
	bg.color = Color("1a1033")
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	var sky := TextureRect.new()
	sky.texture = load("res://assets/environments/backgrounds/area1_bg.png")
	sky.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	sky.modulate = Color(0.7, 0.7, 0.9, 0.6)
	sky.set_anchors_preset(PRESET_FULL_RECT)
	add_child(sky)

	var logo := TextureRect.new()
	logo.texture = load("res://assets/ui/title.png")
	logo.position = Vector2(66, 4)
	logo.size = Vector2(256, 78)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(logo)
	var tag := TextureRect.new()
	tag.texture = load("res://assets/ui/tagline.png")
	tag.position = Vector2(48, 86)
	tag.size = Vector2(288, 14)
	tag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(tag)

	_box = VBoxContainer.new()
	_box.position = Vector2(152, 104)
	_box.add_theme_constant_override("separation", 1)
	add_child(_box)
	_add_button("NEW GAME", _on_new)
	_add_button("CONTINUE", _on_continue).disabled = not SaveSystem.has_run_save()
	_add_button("ACHIEVEMENTS (%d/%d)" % [AchievementManager.unlocked_count(), AchievementManager.total()],
		func(): _emit_menu_modal(AchievementsScreen.new()))
	_add_button("SETTINGS", func(): _emit_menu_modal(SettingsScreen.new()))
	_add_button("QUIT", func(): get_tree().quit())

	var pingu := Sprite2D.new()
	pingu.texture = SpriteLib.atlas_texture("res://assets/characters/pingu.png", "idle", 0)
	pingu.position = Vector2(64, 150)
	pingu.scale = Vector2(2, 2)
	add_child(pingu)
	var t := pingu.create_tween()
	t.set_loops()
	t.tween_property(pingu, "position:y", 146.0, 0.9).set_trans(Tween.TRANS_SINE)

	_seed_edit = LineEdit.new()
	_seed_edit.position = Vector2(12, 188)
	_seed_edit.size = Vector2(120, 13)
	_seed_edit.placeholder_text = "seed (optional)"
	_seed_edit.max_length = 10
	add_child(_seed_edit)
	var v := UISkin.label("v1.0 // 1994 build", 8, Color("5a6280"))
	v.position = Vector2(276, 204)
	add_child(v)
	_focus_first()


func _focus_first() -> void:
	for b in _items:
		if not b.disabled:
			b.grab_focus()
			return


func _add_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(124, 15)
	b.add_theme_font_size_override("font_size", 8)
	b.pressed.connect(cb)
	_box.add_child(b)
	_items.append(b)
	return b


func _seed_value() -> int:
	var s := _seed_edit.text.strip_edges()
	if s.is_empty():
		return 0
	if s.is_valid_int():
		return int(s)
	var h := 0
	for ch in s:
		h = (h * 31 + ch.unicode_at(0)) & 0x7fffffff
	return h


func _on_new() -> void:
	AudioDirector.play_sfx("ui_ok")
	Main.start_new_game(_seed_value())


func _on_continue() -> void:
	var d := SaveSystem.load_run()
	if d.is_empty():
		return
	AudioDirector.play_sfx("ui_ok")
	if GameState.apply_save_dict(d):
		if d.get("counters", {}).get("mission_complete", false):
			Main.show_menu()
		else:
			Main.goto_area(GameState.checkpoint.get("area", 0))


func _emit_menu_modal(s: Control) -> void:
	AudioDirector.play_sfx("ui_ok")
	Main._open_modal(s)


func _show_controls() -> void:
	AudioDirector.play_sfx("ui_ok")
	if _controls_panel:
		_controls_panel.queue_free()
		_controls_panel = null
		return
	var p := UISkin.make_panel("panel_dark")
	p.position = Vector2(18, 96)
	p.size = Vector2(124, 116)
	add_child(p)
	_controls_panel = p
	var lines := [
		"CONTROLS",
		"",
		"WASD/ARROWS  MOVE",
		"HOLD MOVE    RUN",
		"J    ATTACK (WING)",
		"L    THROW DISK",
		"K    SPECIAL (SEL)",
		"1-4  PICK ABILITY",
		"SPACE  DODGE ROLL",
		"E    INTERACT",
		"I    INVENTORY",
		"C    CHARACTER",
		"ESC  PAUSE / SAVE",
	]
	var y := 12.0
	for l in lines:
		var col := Color("2de3ff") if l == "CONTROLS" else Color("f2f2f2")
		var lbl := UISkin.label(l, 8, col)
		lbl.position = Vector2(10, y)
		p.add_child(lbl)
		y += 8.0
