extends Node
## Regression: selecting items must replace the detail text, never stack it, and
## the full description must stay inside the detail strip (no clipping/overflow).

var passed := 0
var failed := 0

func check(cond: bool, label: String) -> void:
	if cond:
		passed += 1
		print("  ok: " + label)
	else:
		failed += 1
		printerr("  FAIL: " + label)

func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _ready() -> void:
	await frames(4)
	Main.start_new_game(2468)
	Main.begin_mission()
	await frames(20)
	Main.dialogue_box.reset()
	await frames(4)
	# Fill the bag with every unique item so all descriptions are exercised.
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json"))
	for tpl in data:
		if GameState.inventory.size() >= GameState.INVENTORY_CAP:
			break
		GameState.add_item(ItemRegistry.consumable(String(tpl["id"]), 1))
	Main.open_inventory()
	await frames(4)
	var inv = Main.modal as InventoryScreen
	check(inv != null, "inventory opens")
	if inv == null:
		_done()
		return
	check(inv.has_node("DetailPanel"), "detail panel exists")
	var detail = inv.get_node("DetailPanel")
	var items: Array = GameState.inventory.duplicate()
	check(items.size() >= 20, "bag filled for selection (%d items)" % items.size())
	var prev_name := ""
	var full_desc_ok := true
	var bounds_ok := true
	var overlap_ok := true
	for item: ItemResource in items:
		inv._select(item)
		await frames(2)
		var panels := 0
		for c in inv.get_children():
			if String(c.name).begins_with("DetailPanel"):
				panels += 1
		check(panels == 1, "only one detail panel (item %s)" % item.id)
		var labels := []
		var desc_lines: Array[String] = []
		for c in detail.get_children():
			if c is Button and c.position.y + c.size.y > 20.0:
				overlap_ok = false
				printerr("  action button overlaps description: %s" % item.id)
			if c is Label:
				labels.append(c.text)
				if c.position.y >= 20:
					desc_lines.append(c.text)
				# the detail strip is 352 px wide and ends at y=58 inside the panel
				if c.position.x + c.size.x > 352.0 or c.position.y + c.size.y > 58.0:
					bounds_ok = false
					printerr("  out of bounds: %s (%s)" % [item.id, c.text])
		check(labels.size() > 0 and labels[0] == item.display_name.substr(0, 30),
			"detail shows current item: " + item.id)
		var joined := " ".join(desc_lines)
		if joined != item.description:
			full_desc_ok = false
			printerr("  description mismatch: %s\n    got: %s\n    want: %s" %
				[item.id, joined, item.description])
		var stale := false
		if prev_name != "" and prev_name != item.display_name:
			for t in labels:
				if String(t).begins_with(prev_name):
					stale = true
		check(not stale, "previous item text is gone: " + item.id)
		prev_name = item.display_name
	check(full_desc_ok, "every description is shown in full")
	check(bounds_ok, "every detail element stays inside the strip")
	check(overlap_ok, "rarity/stat/description rows do not overlap")
	Main.close_modal()
	_done()

func _done() -> void:
	print("")
	print("INVENTORY RESULTS: %d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)
