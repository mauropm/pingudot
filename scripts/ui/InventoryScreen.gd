extends Control
class_name InventoryScreen

signal close_requested

var _grid: GridContainer
var _detail: Node
var _sel: ItemResource = null
var _slot_btns: Array = []


func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	add_child(dim)
	var root := UISkin.make_panel("panel_dark")
	root.position = Vector2(10, 10)
	root.size = Vector2(364, 196)
	add_child(root)
	var title := UISkin.label("INVENTORY  [I] CLOSE", 8, Color("2de3ff"))
	title.position = Vector2(18, 16)
	add_child(title)

	add_child(_at(UISkin.label("ITEMS", 8, Color("f7e94b")), 18, 30))
	_grid = GridContainer.new()
	_grid.position = Vector2(18, 42)
	_grid.add_theme_constant_override("h_separation", 0)
	_grid.add_theme_constant_override("v_separation", 0)
	_grid.columns = 5
	add_child(_grid)

	add_child(_at(UISkin.label("EQUIPPED", 8, Color("f7e94b")), 178, 30))
	_detail = Control.new()
	_detail.position = Vector2(178, 42)
	add_child(_detail)
	_refresh()
	_first_focus()


func _at(n: Control, x: float, y: float) -> Control:
	n.position = Vector2(x, y)
	return n


func _refresh() -> void:
	for c in _grid.get_children():
		c.queue_free()
	_slot_btns.clear()
	for i in GameState.INVENTORY_CAP:
		var b := Button.new()
		b.custom_minimum_size = Vector2(30, 30)
		if i < GameState.inventory.size():
			var item: ItemResource = GameState.inventory[i]
			b.icon = item.icon
			b.expand_icon = false
			b.tooltip_text = "%s\n%s" % [item.display_name, item.description]
			b.pressed.connect(_select.bind(item))
		else:
			b.disabled = true
		_grid.add_child(b)
		_slot_btns.append(b)
	_redraw_equipped()
	_render_detail()


func _first_focus() -> void:
	for b in _slot_btns:
		if not b.disabled:
			b.grab_focus()
			return


func _select(item: ItemResource) -> void:
	_sel = item
	AudioDirector.play_sfx("ui_move")
	_reredraw()


func _reredraw() -> void:
	_redraw_equipped()
	_render_detail()
	# keep focus on a real slot
	for b in _slot_btns:
		if not b.disabled:
			b.grab_focus()
			break


func _redraw_equipped() -> void:
	for c in _detail.get_children():
		c.queue_free()
	var rows: Array = []
	for s in ["weapon", "armor", "boots"]:
		var it: ItemResource = GameState.equipment[s]
		rows.append(["%s:" % s.substr(0, 1).to_upper(),
			it.display_name if it != null else "- empty -",
			it.rarity if it != null else "common"])
	var hi := 0
	for h: ItemResource in GameState.equipment["hardware"]:
		hi += 1
		rows.append(["H%d:" % hi, h.display_name, h.rarity])
	if hi < 4:
		rows.append(["H%d:" % (hi + 1), "- empty -", "common"])
	var y := 0.0
	for r in rows:
		var rar_col: Color = ItemResource.RARITY_COLORS.get(r[2], Color("f2f2f2"))
		var txt: String = str(r[1])
		if txt.length() > 22:
			txt = txt.substr(0, 21) + "."
		var lbl := UISkin.label("%s %s" % [r[0], txt], 8, rar_col)
		lbl.position = Vector2(0, y)
		_detail.add_child(lbl)
		y += 10.0


func _render_detail() -> void:
	if has_node("DetailPanel"):
		var old := get_node("DetailPanel")
		old.queue_free()
	var dp := Control.new()
	dp.name = "DetailPanel"
	dp.position = Vector2(18, 196)
	add_child(dp)
	# note: positioned over the lower half of the right column via absolute pos
	dp.position = Vector2(178, 120)
	if _sel == null:
		var l := UISkin.label("Select an item.", 8, Color("9aa4b2"))
		l.position = Vector2(0, 2)
		dp.add_child(l)
		return
	var col: Color = ItemResource.RARITY_COLORS[_sel.rarity]
	var name_l := UISkin.label(_sel.display_name.substr(0, 30), 8, col)
	name_l.position = Vector2(0, 0)
	dp.add_child(name_l)
	var rar := UISkin.label(_sel.rarity.to_upper(), 8, col.darkened(0.2))
	rar.position = Vector2(0, 10)
	dp.add_child(rar)
	var desc_txt: String = _sel.description
	if desc_txt.length() > 62:
		desc_txt = desc_txt.substr(0, 61) + "."
	var desc := UISkin.label(desc_txt, 8, Color("f2f2f2"))
	desc.position = Vector2(0, 22)
	desc.size = Vector2(188, 20)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dp.add_child(desc)
	var y := 44.0
	var shown := 0
	for k in _sel.mods.keys():
		if shown >= 2:
			var more := UISkin.label("...", 8, Color("9aa4b2"))
			more.position = Vector2(0, y)
			dp.add_child(more)
			break
		var v = _sel.mods[k]
		var line: String
		if v is int and k in ["atk", "def", "spd", "int", "luck", "crit_pct", "hp"]:
			line = "%s %+d" % [_mod_label(k), int(v)]
			var cur = _current_mod_for(k)
			if cur != null:
				var delta := int(v) - int(cur)
				line += "  (%+d)" % delta
		elif k in ["hp_heal", "en_gain", "clear_cd"]:
			line = "%s %s" % [k.to_upper().replace("_", " "), str(v)]
		else:
			line = String(k).to_upper()
		var c2 := Color("6ec72c") if (v is int and int(v) > 0) else Color("e2282e")
		var l2 := UISkin.label(line, 8, c2)
		l2.position = Vector2(0, y)
		dp.add_child(l2)
		y += 10.0
		shown += 1
	if _sel.is_equippable():
		_act_button(dp, "EQUIP [ENTER]", Vector2(0, 68), _do_equip)
	elif _sel.slot == "consumable":
		_act_button(dp, "USE [ENTER]", Vector2(0, 68), _do_use)


func _mod_label(k: String) -> String:
	match k:
		"atk": return "ATK"
		"def": return "DEF"
		"spd": return "SPD"
		"int": return "INT"
		"luck": return "LUCK"
		"hp": return "MAXHP"
		"crit_pct": return "CRIT"
		_: return k.to_upper()


func _current_mod_for(k: String) -> Variant:
	for it: ItemResource in GameState.all_equipped():
		if it.mods.has(k):
			return int(it.mods[k])
	return null


func _act_button(parent: Control, text: String, pos: Vector2, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.custom_minimum_size = Vector2(104, 16)
	b.add_theme_font_size_override("font_size", 8)
	b.pressed.connect(cb)
	parent.add_child(b)


func _do_equip() -> void:
	if _sel == null:
		return
	GameState.equip(_sel)
	AudioDirector.play_sfx("ui_ok")
	FX.toast("EQUIPPED %s" % _sel.display_name, Color(ItemResource.RARITY_COLORS[_sel.rarity]))
	_sel = null
	_refresh()
	_first_focus()


func _do_use() -> void:
	if _sel == null:
		return
	GameState.use_consumable(_sel)
	_sel = null
	_refresh()
	_first_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") or event.is_action_pressed("pause") or event.is_action_pressed("stats"):
		close_requested.emit()
		get_viewport().set_input_as_handled()
