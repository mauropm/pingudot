extends Control
class_name StatsScreen

signal close_requested


func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	add_child(dim)
	var root := UISkin.make_panel("panel_dark")
	root.position = Vector2(24, 12)
	root.size = Vector2(336, 192)
	add_child(root)
	var title := UISkin.label("CHARACTER  [C] CLOSE", 8, Color("2de3ff"))
	title.position = Vector2(34, 18)
	add_child(title)

	var por := Sprite2D.new()
	var anims := SpriteLib.load_manifest("res://assets/characters/pingu.png")
	var p: Dictionary = anims["portrait"]
	var tex: Texture2D = load("res://assets/characters/pingu.png")
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(0, p["row_y"], p["cell"][0], p["cell"][1])
	por.texture = at
	por.position = Vector2(46, 44)
	por.scale = Vector2(2, 2)
	add_child(por)
	var name_l := UISkin.label("PINGU", 16, Color("f7e94b"))
	name_l.position = Vector2(34, 94)
	add_child(name_l)
	var cls := UISkin.label("THE SYSADMIN", 8, Color("9aa4b2"))
	cls.position = Vector2(34, 114)
	add_child(cls)

	var s := GameState.stats
	var rows := [
		["LEVEL", str(s.level), "f2f2f2"],
		["XP", "%d/%d" % [s.xp, s.next_xp_needed()], "f7c94b"],
		["HP", "%d/%d" % [s.hp, s.max_hp], "2aa02e"],
		["ENERGY", "%d/%d" % [s.en, s.max_en], "2d6aff"],
		["ATK", str(GameState.effective("atk", 0, false)), "ff8c6b"],
		["DEF", str(GameState.effective("def", 0, false)), "8ecff0"],
		["SPD", str(GameState.effective("spd", 0, false)), "f2f2f2"],
		["INT", str(GameState.effective("int", 0, false)), "f2f2f2"],
		["LUCK", str(GameState.effective("luck", 0, false)), "6ec72c"],
		["CRIT", "%d%%" % int(round(CombatMath.crit_chance(
			GameState.effective("luck", 0, false)) * 100)), "f7e94b"],
	]
	var col := 118
	var y := 40.0
	for r in rows:
		var k := UISkin.label(str(r[0]) + ":", 8, Color("9aa4b2"))
		k.position = Vector2(col, y)
		add_child(k)
		var v := UISkin.label(str(r[1]), 8, Color(str(r[2])))
		v.position = Vector2(col + 54, y)
		add_child(v)
		y += 13.0

	# right column: abilities + run data
	var ax := 222
	add_child(_head("ABILITIES", ax, 40))
	var ay := 54.0
	for id in AbilityRegistry.list_ids():
		var a: AbilityResource = AbilityRegistry.defs[id]
		var learned := id in GameState.unlocked_abilities
		var label := a.display_name
		if not learned:
			label = "[X] " + label
		var l := UISkin.label(label, 8, Color("6ec72c") if learned else Color("5a6280"))
		l.position = Vector2(ax, ay)
		add_child(l)
		ay += 11.0

	var k2: Dictionary = GameState.counters
	add_child(_head("RUN DATA", ax, ay + 4))
	var ry := ay + 18.0
	var rd := [
		"AREA %d/5" % (GameState.area_index + 1),
		"PATCHES %d/10" % k2.get("patches", 0),
		"HIDDEN %d" % k2.get("hidden_found", 0),
		"ACHIEVEMENTS %d/%d" % [AchievementManager.unlocked_count(),
			AchievementManager.total()],
		"SEED %d" % GameState.seed_value,
	]
	for line in rd:
		var l := UISkin.label(String(line), 8, Color("9aa4b2"))
		l.position = Vector2(ax, ry)
		add_child(l)
		ry += 11.0


func _head(text: String, x: float, y: float) -> Label:
	var l := UISkin.label(text, 8, Color("2de3ff"))
	l.position = Vector2(x, y)
	return l


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("stats") or Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("inventory"):
		close_requested.emit()
		get_viewport().set_input_as_handled()
