extends Control
class_name InventoryScreen
## Inventory: 6x4 item grid, equipped summary, and a full-width detail strip
## with the complete item description (no clipping/overflow).

signal close_requested

var _grid: GridContainer
var _equipped_col: Control
var _detail_panel: Control
var _sel: ItemResource = null
var _slot_btns: Array = []


func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	add_child(dim)
	var root := UISkin.make_panel("panel_dark")
	root.position = Vector2(8, 8)
	root.size = Vector2(368, 200)
	add_child(root)
	var title := UISkin.label("INVENTORY  [I] CLOSE", 8, Color("2de3ff"))
	title.position = Vector2(16, 12)
	add_child(title)

	add_child(_at(UISkin.label("ITEMS", 8, Color("f7e94b")), 16, 26))
	_grid = GridContainer.new()
	_grid.position = Vector2(16, 36)
	_grid.add_theme_constant_override("h_separation", 0)
	_grid.add_theme_constant_override("v_separation", 0)
	_grid.columns = 6
	add_child(_grid)

	add_child(_at(UISkin.label("EQUIPPED", 8, Color("f7e94b")), 198, 26))
	_equipped_col = Control.new()
	_equipped_col.position = Vector2(198, 36)
	add_child(_equipped_col)

	# full-width detail strip for the selected item
	var divider := ColorRect.new()
	divider.color = Color("3a4aa8")
	divider.position = Vector2(16, 148)
	divider.size = Vector2(352, 1)
	add_child(divider)
	_detail_panel = Control.new()
	_detail_panel.name = "DetailPanel"
	_detail_panel.position = Vector2(16, 150)
	add_child(_detail_panel)

	_refresh()
	_first_focus()


func _at(n: Control, x: float, y: float) -> Control:
	n.position = Vector2(x, y)
	return n


func _clear_children(node: Node) -> void:
	# remove immediately (queue_free is deferred and would overlap/rename)
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


func _refresh() -> void:
	_clear_children(_grid)
	_slot_btns.clear()
	for i in GameState.INVENTORY_CAP:
		var b := Button.new()
		b.custom_minimum_size = Vector2(26, 26)
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
	_redraw_equipped()
	_render_detail()


func _redraw_equipped() -> void:
	_clear_children(_equipped_col)
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
		if txt.length() > 25:
			txt = txt.substr(0, 24) + "."
		var lbl := UISkin.label("%s %s" % [r[0], txt], 8, rar_col)
		lbl.position = Vector2(0, y)
		_equipped_col.add_child(lbl)
		y += 10.0
	var hint := UISkin.label("ARROWS/SELECT  ENTER", 6, Color("5a6280"))
	hint.position = Vector2(0, y + 6)
	_equipped_col.add_child(hint)


func _render_detail() -> void:
	_clear_children(_detail_panel)
	var dp := _detail_panel
	if _sel == null:
		var l := UISkin.label("Select an item.", 8, Color("9aa4b2"))
		l.position = Vector2(0, 2)
		dp.add_child(l)
		return
	var col: Color = ItemResource.RARITY_COLORS[_sel.rarity]
	# Row 1: name (left, clipped before the action button).
	var name_l := UISkin.label(_sel.display_name.substr(0, 30), 8, col)
	name_l.position = Vector2(0, 0)
	name_l.size = Vector2(240, 10)
	name_l.clip_text = true
	dp.add_child(name_l)
	# Row 2: rarity (left) followed by the compact stat summary on the same line.
	var rar := UISkin.label(_sel.rarity.to_upper(), 8, col.darkened(0.15))
	rar.position = Vector2(0, 10)
	rar.size = Vector2(76, 10)
	rar.clip_text = true
	dp.add_child(rar)
	var stats_line := _stat_summary()
	if stats_line != "":
		var st := UISkin.label(stats_line, 8, Color("6ec72c"))
		st.position = Vector2(80, 10)
		st.size = Vector2(164, 10)
		st.clip_text = true
		dp.add_child(st)
	# Row 3+: full description, manually wrapped so it can never overflow the panel.
	var lines := _wrap_text(_sel.description, 43)
	for i in mini(lines.size(), 3):
		var dl := UISkin.label(lines[i], 8, Color("f2f2f2"))
		dl.position = Vector2(0, 20 + i * 11)
		dl.size = Vector2(352, 10)
		dl.clip_text = true
		dp.add_child(dl)
	if _sel.is_equippable():
		_act_button(dp, "EQUIP [ENTER]", Vector2(248, 0), _do_equip)
	elif _sel.slot == "consumable":
		_act_button(dp, "USE [ENTER]", Vector2(248, 0), _do_use)
	elif _sel.slot == "material":
		var m := UISkin.label("MATERIAL", 8, Color("9aa4b2"))
		m.position = Vector2(248, 2)
		dp.add_child(m)


func _stat_summary() -> String:
	if _sel == null:
		return ""
	var parts: Array[String] = []
	for k in _sel.mods.keys():
		if parts.size() >= 3:
			parts.append("+more")
			break
		var v = _sel.mods[k]
		if v is int and k in ["atk", "def", "spd", "int", "luck", "crit_pct", "hp"]:
			var chunk := "%s %+d" % [_mod_label(k), int(v)]
			var cur = _current_mod_for(k)
			if cur != null:
				chunk += "(%+d)" % (int(v) - int(cur))
			parts.append(chunk)
		elif k in ["hp_heal", "en_gain", "clear_cd"]:
			var label := "HEAL" if k == "hp_heal" else ("ENERGY" if k == "en_gain" else "RESET CD")
			parts.append("%s %s" % [label, str(v)])
	return " ".join(parts)


## Greedy word wrap. Descriptions are short (<=60 chars) so at most 3 lines.
func _wrap_text(text: String, max_chars: int) -> Array[String]:
	var out: Array[String] = []
	var cur := ""
	for word in text.split(" ", false):
		if cur == "":
			cur = word
		elif cur.length() + 1 + word.length() <= max_chars:
			cur += " " + word
		else:
			out.append(cur)
			cur = word
	if cur != "":
		out.append(cur)
	return out


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
