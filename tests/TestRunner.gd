extends Node
## PINGUDOT test harness — run headless as a scene (autoloads present):
##   godot --headless --path . res://tests/Test.tscn
## Validates pure gameplay logic + all data integrity (maps, icons, audio).

var passed := 0
var failed := 0
var _fails: Array[String] = []


func check(cond: bool, label: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		_fails.append(label)
		printerr("  FAIL: " + label)


func section(name: String) -> void:
	print("-- " + name)


func _ready() -> void:
	get_tree().paused = true
	await _run()
	print("")
	print("RESULTS: %d passed, %d failed" % [passed, failed])
	for f in _fails:
		print("   - " + f)
	get_tree().quit(1 if failed > 0 else 0)


func _run() -> void:
	section("CombatMath")
	var r1 := RandomNumberGenerator.new()
	r1.seed = 42
	var r2 := RandomNumberGenerator.new()
	r2.seed = 42
	var a := CombatMath.player_damage(10, 3, 5, r1)
	var b := CombatMath.player_damage(10, 3, 5, r2)
	check(a["dmg"] == b["dmg"], "deterministic damage rolls")
	check(a["dmg"] >= 1, "damage floor >= 1")
	check(CombatMath.enemy_damage(1, 1000, r1) >= 1, "enemy damage floor >= 1")
	var prev := 0
	for lv in range(1, 12):
		var need := CombatMath.xp_needed(lv)
		check(need > prev, "xp curve monotonic lv%d" % lv)
		prev = need
	check(CombatMath.crit_chance(999) <= 0.45, "crit chance capped")
	check(CombatMath.weighted_pick({"a": 0.0, "b": 1.0}, r1) == "b", "weighted pick")

	section("CharacterStats leveling")
	var s := CharacterStats.new()
	s.gain_xp(CombatMath.xp_needed(1), [])
	check(s.level == 2, "levels up at threshold")
	check(s.hp == s.max_hp, "full heal on level")
	check(s.max_hp > 45 and s.atk > 6, "stat gains applied")

	section("GameState / inventory / equipment")
	GameState.reset_run(1234)
	var atk0 := GameState.effective("atk", 0.0, false)
	var w := ItemRegistry.defs.get("cable_10gbe")
	GameState.add_item(w)
	check(GameState.inventory.size() == 1, "item added")
	GameState.equip(w)
	check(GameState.inventory.find(w) == -1, "item leaves inventory on equip")
	check(GameState.equipment["weapon"] == w, "equipped in slot")
	check(GameState.effective("atk", 0.0, false) > atk0, "equipment raises ATK")
	GameState.equipment_disabled = true
	check(GameState.effective("atk", 0.0, true) == GameState.stats.atk, "license debuff disables equipment")
	GameState.equipment_disabled = false
	GameState.unequip("weapon")
	check(GameState.effective("atk", 0.0, false) == atk0, "unequip restores base")
	# stacking
	var c1 := ItemRegistry.consumable("cookie", 2)
	GameState.add_item(c1)
	var c2 := ItemRegistry.consumable("cookie", 3)
	GameState.add_item(c2)
	for it in GameState.inventory:
		if it.id == "cookie":
			check(it.quantity == 5, "consumables stack")
	# healing clamp
	GameState.stats.hp = 1
	GameState.use_consumable(ItemRegistry.consumable("heal_big", 1))
	check(GameState.stats.hp > 1, "consumable heals")
	# coins
	GameState.add_coins(50)
	check(GameState.coins == 50, "coins add")
	check(GameState.spend_coins(30), "coins spend")
	check(GameState.coins == 20, "coins deducted")
	check(not GameState.spend_coins(100), "cannot overspend")

	section("Save / load roundtrip")
	GameState.reset_run(777)
	GameState.add_coins(123)
	GameState.add_item(ItemRegistry.consumable("heal_small", 4))
	GameState.equip(ItemRegistry.consumable("kb_legendary", 1))
	GameState.stats.level = 5
	GameState.gain_xp(10)
	GameState.checkpoint = {"area": 2, "x": 5, "y": 6}
	var dict := GameState.build_save_dict()
	var restored := GameState2_fresh_from(dict)
	check(restored != null, "save dict serializable")
	if restored:
		check(GameState.coins == 123, "coins restored")
		check(GameState.stats.level == 5, "level restored")
		check(GameState.checkpoint.get("area") == 2, "checkpoint restored")
		check(GameState.equipment["weapon"] != null, "equipment restored")
	# disk roundtrip
	GameState.write_save()
	var disk := SaveSystem.load_run()
	check(not disk.is_empty(), "save written to disk")
	SaveSystem.delete_run()

	section("RNG reproducibility (roguelite)")
	var ra := RandomNumberGenerator.new()
	ra.seed = 99
	var rb := RandomNumberGenerator.new()
	rb.seed = 99
	var seq_a: Array[String] = []
	var seq_b: Array[String] = []
	for i in 12:
		var ia := ItemRegistry.roll_item(ra, 2, 5)
		var ib := ItemRegistry.roll_item(rb, 2, 5)
		seq_a.append(ia.id if ia != null else "-")
		seq_b.append(ib.id if ib != null else "-")
	check(seq_a == seq_b, "same seed => same loot sequence")

	section("Data integrity")
	var items = JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json"))
	check(items is Array and items.size() >= 25, "at least 25 items (%d)" % items.size())
	for it in items:
		var icon := "res://assets/ui/items/%s.png" % it["id"]
		check(ResourceLoader.exists(icon), "icon exists: %s" % it["id"])
		check(it["rarity"] in ["common", "rare", "epic", "legendary"], "valid rarity: " + it["id"])
		check(it["slot"] in ["weapon", "armor", "boots", "hardware", "consumable", "material"], "valid slot: " + it["id"])
	var dlg = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/lines.json"))
	check(dlg.size() >= 40, "at least 40 dialogue lines (%d)" % dlg.size())
	var jokes := 0
	for k in dlg:
		if k.begins_with("joke_"):
			jokes += 1
	check(jokes >= 15, "at least 15 environmental jokes (%d)" % jokes)
	var ach = JSON.parse_string(FileAccess.get_file_as_string("res://data/achievements/achievements.json"))
	check(ach.size() >= 12, "at least 12 achievements (%d)" % ach.size())
	var abils = JSON.parse_string(FileAccess.get_file_as_string("res://data/abilities.json"))
	check(abils.size() == 4, "4 abilities defined")

	section("Area maps (walls, reachability)")
	for area_i in 5:
		_check_area_map(area_i)

	section("Sprites & audio")
	_check_sprite("res://assets/characters/pingu.png", ["idle", "walk", "run", "attack", "ranged", "special", "dodge", "hurt", "death", "victory", "interact", "portrait", "jump", "fall", "idle_back", "walk_back"])
	for fam in ["bsdemon", "littlebill", "gplhipster", "secbot", "cto", "bsdemon_elite", "littlebill_elite", "gplhipster_elite", "secbot_elite"]:
		_check_sprite("res://assets/enemies/%s.png" % fam, ["idle", "walk", "attack", "hurt", "death"])
	for eff in ["fireball", "disc", "shard", "spark", "boom", "ring", "stink", "wavetext", "bsod", "clone", "slash"]:
		_check_sprite("res://assets/effects/%s.png" % eff, [])
	for n in range(1, 6):
		check(ResourceLoader.exists("res://assets/environments/tilesets/area%d.png" % n), "tileset area%d" % n)
		check(ResourceLoader.exists("res://assets/environments/backgrounds/area%d_bg.png" % n), "background area%d" % n)
	for sfx_name in ["step", "slash", "hurt", "coin", "levelup", "kernelpanic", "forkbomb", "rootaccess", "segfault", "boss_intro", "victory", "achievement"]:
		check(AudioDirector.has_sfx(sfx_name), "sfx exists: " + sfx_name)
	for trk in ["menu", "area1", "area2", "area3", "area4", "area5", "boss", "ending", "credits", "gameover"]:
		check(ResourceLoader.exists("res://assets/audio/music/%s.wav" % trk), "music track: " + trk)
		var st: AudioStreamWAV = AudioDirector._music_streams.get(trk)
		check(st != null, "music loaded: " + trk)
		if st != null:
			if trk == "gameover":
				check(st.loop_mode == AudioStreamWAV.LOOP_DISABLED, "gameover sting does not loop")
			else:
				check(st.loop_mode == AudioStreamWAV.LOOP_FORWARD, trk + " loops")
				var expected_samples := int(round(st.get_length() * st.mix_rate))
				check(absi(st.loop_end - expected_samples) <= 1,
					"%s loop point covers the full track (%d/%d)" % [trk, st.loop_end, expected_samples])
				check(st.get_length() >= 20.0, "%s is a long-form loop (%.1fs)" % [trk, st.get_length()])
	check(ResourceLoader.exists("res://assets/environments/airplane.png"), "airplane sprite")
	check(ResourceLoader.exists("res://assets/fonts/pixel6x8.fnt"), "pixel font")

	print("")


## Helper: apply a save dict as if freshly loading.
func GameState2_fresh_from(d: Dictionary) -> bool:
	return GameState.apply_save_dict(d)


func _check_area_map(index: int) -> void:
	var id := "area%d" % (index + 1)
	var map = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/%s.json" % id))
	if not (map is Dictionary):
		check(false, id + " parse")
		return
	var w: int = map["w"]
	var h: int = map["h"]
	var grid: Array = map["grid"]
	check(grid.size() == w * h, id + " grid size")
	# entry: mirror _spawn_tile scan (south-west, avoiding hazard/water)
	var entry := Vector2i(-1, -1)
	for yy in range(h - 6, h):
		for xx in range(1, w):
			var v: int = grid[yy * w + xx]
			if v != 3 and v != 8 and v != 9:
				entry = Vector2i(xx, yy)
				break
		if entry.x >= 0:
			break
	if entry.x < 0:
		entry = Vector2i(1, h - 3)
	check(entry.x >= 0, id + " has entry tile")
	# BFS flood fill from entry
	var seen := {}
	var stack := [entry]
	seen[entry] = true
	while stack.size() > 0:
		var c: Vector2i = stack.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h:
				continue
			if seen.has(n):
				continue
			if grid[n.y * w + n.x] == 3:
				continue
			seen[n] = true
			stack.append(n)
	var must_reach := {}
	var any_exit := false
	for e in map["entities"]:
		if e["kind"] in ["exit", "checkpoint", "hidden", "bossgate"]:
			any_exit = true
		if e["kind"] in ["exit", "bossgate"]:
			must_reach["exit"] = Vector2i(e["x"], e["y"])
			break  # first exit is the transition
	for e in map["entities"]:
		if e["kind"] == "checkpoint" and not must_reach.has("cp"):
			must_reach["cp"] = Vector2i(e["x"], e["y"])
		if e["kind"] == "bossgate" and index == 4:
			must_reach["boss"] = Vector2i(e["x"], e["y"])
	if index == 4:
		must_reach.erase("exit")
	for key in must_reach:
		var t: Vector2i = must_reach[key]
		check(seen.has(t), "%s: %s reachable from entry" % [id, key])
	# all entities on open tiles
	var ok := true
	for e in map["entities"]:
		if e["kind"] != "exit" and grid[e["y"] * w + e["x"]] == 3:
			ok = false
	check(ok, id + ": all entities on walkable tiles")
	# enemy variety: at least one spawn marker
	var spawns := 0
	for e in map["entities"]:
		if e["kind"] == "enemy":
			spawns += 1
	check(spawns >= 3, id + ": enemy spawn markers present (%d)" % spawns)


func _check_sprite(path: String, anims: Array) -> void:
	if not ResourceLoader.exists(path):
		check(false, "atlas missing: " + path)
		return
	var tex: Texture2D = load(path)
	var man := SpriteLib.load_manifest(path)
	check(not man.is_empty(), "manifest for " + path)
	for name: String in anims:
		check(man.has(name), "%s anim '%s'" % [path.get_file(), name])
	for name: String in man.keys():
		var a: Dictionary = man[name]
		var need_w: int = int(a["frames"]) * int(a["cell"][0])
		var need_h: int = int(a["row_y"]) + int(a["cell"][1])
		check(need_w <= tex.get_width() and need_h <= tex.get_height(),
			"%s '%s' fits atlas" % [path.get_file(), name])
