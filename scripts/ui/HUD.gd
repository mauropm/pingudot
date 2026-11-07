extends Control
class_name HUD
## SNES-style heads-up display, drawn immediate-mode for pixel purity.

var _font: Font
var _portrait: AtlasTexture
var _ability_icons: Dictionary = {}
var _char_id := ""
var _interact_hint := ""
var _toasts: Array = []          # [{text, t, color}]
var _time := 0.0
var _player: Player


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group("hud")
	theme = UISkin.theme()
	_font = load(UISkin.FONT)
	_refresh_character()
	EventBus.interact_hint.connect(_on_hint)
	EventBus.achievement_unlocked.connect(_on_achievement)
	EventBus.sfx.connect(func(n): AudioDirector.play_sfx(n))


func _on_hint(text: String) -> void:
	_interact_hint = text


func toast(text: String, color := Color("f2f2f2")) -> void:
	_toasts.append({"text": text, "t": 4.0, "color": color})


func _on_achievement(_id: String, display_name: String) -> void:
	toast("ACHIEVEMENT: %s" % display_name, Color("f7e94b"))


func _refresh_character() -> void:
	_char_id = GameState.character_id
	var def := CharacterRegistry.get_def(_char_id)
	var anims := SpriteLib.load_manifest(def.atlas_path)
	if anims.has("portrait"):
		var p: Dictionary = anims["portrait"]
		var tex: Texture2D = load(def.atlas_path)
		_portrait = AtlasTexture.new()
		_portrait.atlas = tex
		_portrait.region = Rect2(0, p["row_y"], p["cell"][0], p["cell"][1])
	else:
		_portrait = null
	_ability_icons.clear()
	for id in GameState.ability_ids():
		if AbilityRegistry.defs.has(id):
			_ability_icons[id] = AbilityRegistry.defs[id].icon


func _process(delta: float) -> void:
	_time += delta
	if not visible:
		return
	if GameState.character_id != _char_id:
		_refresh_character()
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	# decay toasts
	var keep: Array = []
	for t in _toasts:
		t["t"] -= delta
		if t["t"] > 0.0:
			keep.append(t)
	_toasts = keep
	queue_redraw()


func _bar(pos: Vector2, size: Vector2, ratio: float, col: Color, label_text := "") -> void:
	draw_rect(Rect2(pos, size), Color(0, 0, 0, 0.75))
	var fill_w := maxf(0.0, size.x * clampf(ratio, 0.0, 1.0))
	draw_rect(Rect2(pos + Vector2(1, 1), Vector2(fill_w - 2, size.y - 2)), col)
	draw_rect(Rect2(pos, size), Color(1, 1, 1, 0.5), false, 1)
	if label_text != "":
		draw_string(_font, Vector2(pos.x - 16, pos.y + size.y - 1.0), label_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("f2f2f2"))


func _draw() -> void:
	var s := GameState.stats
	if s == null:
		return
	# -- top-left character panel ---------------------------------------------
	draw_rect(Rect2(2, 2, 138, 56), Color(0.05, 0.04, 0.12, 0.85))
	draw_rect(Rect2(2, 2, 138, 56), Color(0.35, 0.55, 0.9, 0.9), false, 1)
	if _portrait:
		draw_texture(_portrait, Vector2(6, 6))
	_bar(Vector2(50, 8), Vector2(80, 7), float(s.hp) / float(s.max_hp),
		Color("e2282e") if float(s.hp) / s.max_hp < 0.25 else Color("2aa02e"), "HP")
	_bar(Vector2(50, 19), Vector2(80, 6), float(s.en) / float(s.max_en), Color("2d6aff"), "EN")
	_bar(Vector2(50, 29), Vector2(80, 4), float(s.xp) / float(s.next_xp_needed()), Color("f7c94b"), "XP")
	draw_string(_font, Vector2(34, 46), "LV %d" % s.level, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("f2f2f2"))
	# coins
	draw_circle(Vector2(102, 44), 4.0, Color("f7c94b"))
	draw_circle(Vector2(102, 44), 2.0, Color("c08a10"))
	draw_string(_font, Vector2(108, 47), str(GameState.coins), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("f7e94b"))
	# -- area banner top-right --------------------------------------------------
	var area_name := String(GameState.area_names[GameState.area_index])
	draw_string(_font, Vector2(196, 10), area_name, HORIZONTAL_ALIGNMENT_RIGHT, 182, 8, Color("2de3ff"))
	draw_string(_font, Vector2(196, 20), "AREA %d/5" % (GameState.area_index + 1),
		HORIZONTAL_ALIGNMENT_RIGHT, 182, 8, Color("9aa4b2"))
	# -- boss bar ---------------------------------------------------------------
	var boss := get_tree().get_first_node_in_group("boss")
	if boss != null and not boss.is_dead():
		_bar(Vector2(146, 30), Vector2(228, 8), float(boss.hp) / float(boss.max_hp), Color("7a3fe8"))
		draw_string(_font, Vector2(146, 27), "CTO OF EVERYTHING  PHASE %d" % boss.phase,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("ff8c6b"))
	# -- ability slots bottom-left ----------------------------------------------
	var x := 6.0
	var sel := GameState.selected_ability
	var i := 1
	for id in GameState.ability_ids():
		var unlocked: bool = id in GameState.unlocked_abilities
		var r := Rect2(x, 190, 20, 20)
		draw_rect(r, Color(0, 0, 0, 0.7))
		if _ability_icons.has(id):
			var mod := Color(1, 1, 1) if unlocked else Color(0.25, 0.25, 0.3)
			draw_texture_rect(_ability_icons[id], r.grow(-2), false, mod)
		if unlocked and _player != null:
			var cd: float = _player.get_cooldown(id)
			var def_cd: float = AbilityRegistry.defs[id].cooldown
			if cd > 0.0:
				var hgt := 20.0 * clampf(cd / def_cd, 0.0, 1.0)
				draw_rect(Rect2(r.position, Vector2(20, hgt)), Color(0, 0, 0.2, 0.65))
		if id == sel:
			draw_rect(r, Color("2de3ff"), false, 1)
		else:
			draw_rect(r, Color("404050"), false, 1)
		draw_string(_font, Vector2(x + 6, 189), str(i), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("9aa4b2"))
		x += 24.0
		i += 1
	# ultimate meter (MIGGY)
	if GameState.has_ultimate():
		var ratio := clampf(GameState.ultimate_charge / 100.0, 0.0, 1.0)
		var ur := Rect2(6, 178, 144, 7)
		draw_rect(ur, Color(0, 0, 0, 0.75))
		draw_rect(Rect2(ur.position + Vector2(1, 1), Vector2(142 * ratio, 5)),
			Color("7a3fe8"))
		draw_rect(ur, Color("c77dff") if GameState.ultimate_charge >= 100 else Color("404050"), false, 1)
		var ult_label := "R: ULT %d%%" % GameState.ultimate_charge
		draw_string(_font, Vector2(154, 187), ult_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
			Color("f7e94b") if GameState.ultimate_charge >= 100 else Color("9aa4b2"))
	# dodge pip
	if _player != null and _player.get_cooldown("dodge") > 0.0:
		draw_string(_font, Vector2(x + 2, 203), "SPACE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.55, 0.55, 0.6))
	else:
		draw_string(_font, Vector2(x + 2, 203), "SPACE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("2de3ff"))
	# -- status effects ---------------------------------------------------------
	if _player != null:
		var sx := 6.0
		var sy := 166.0 if GameState.has_ultimate() else 176.0
		for k in _player.active_statuses():
			var col := Color("6ec72c")
			match k:
				"blue": col = Color("2d6aff")
				"port": col = Color("f7c94b")
				"lic": col = Color("e2282e")
				"water": col = Color("2de3ff")
				"shield": col = Color("c77dff")
			draw_rect(Rect2(sx, sy, 8, 8), col)
			sx += 10.0
	# -- interact hint ----------------------------------------------------------
	if _interact_hint != "":
		var wdt := _interact_hint.length() * 6 + 12
		var hy := 168.0
		draw_rect(Rect2(192 - wdt / 2.0, hy, wdt, 12), Color(0, 0, 0, 0.7))
		draw_string(_font, Vector2(192 - wdt / 2.0 + 6, hy + 9), _interact_hint,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("f7e94b"))
	# -- objective (bottom-right) -----------------------------------------------
	var obj := String(GameState.objectives.get(GameState.area_index, ""))
	if obj != "":
		draw_string(_font, Vector2(128, 212), obj, HORIZONTAL_ALIGNMENT_RIGHT, 248, 8, Color(0.75, 0.8, 0.9, 0.85))
	# -- toasts (top-center) -----------------------------------------------------
	var ty := 34.0
	for t in _toasts:
		var a: float = clampf(t["t"], 0.0, 1.0)
		var tw: float = t["text"].length() * 6 + 10
		draw_rect(Rect2(192 - tw / 2.0, ty, tw, 11), Color(0.05, 0.04, 0.12, 0.85 * a))
		draw_string(_font, Vector2(192 - tw / 2.0 + 5, ty + 9), t["text"],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(t["color"], a))
		ty += 13
