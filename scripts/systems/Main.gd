extends Node
## Main — top-level orchestrator (autoload). Owns the persistent overlay
## (HUD + dialogue box) and swaps full-screen nodes: menu, game, ending.

enum Screen { MENU, INTRO, GAME, ENDING, CREDITS }

const MENU_SCENE := preload("res://scenes/ui/MainMenuScreen.tscn")
const GAMEOVER_SCENE := preload("res://scenes/ui/GameOverScreen.tscn")
const INVENTORY_SCENE := preload("res://scenes/ui/InventoryScreen.tscn")
const STATS_SCENE := preload("res://scenes/ui/StatsScreen.tscn")
const ACHIEVEMENTS_SCENE := preload("res://scenes/ui/AchievementsScreen.tscn")
const SETTINGS_SCENE := preload("res://scenes/ui/SettingsScreen.tscn")
const PAUSE_SCENE := preload("res://scenes/ui/PauseScreen.tscn")
const INTRO_SCENE := preload("res://scenes/cinematics/IntroCinematic.tscn")
const PINGU_ENDING_SCENE := preload("res://scenes/cinematics/PinguEnding.tscn")
const MIGGY_ENDING_SCENE := preload("res://scenes/cinematics/MiggyEnding.tscn")
const CREDITS_SCENE := preload("res://scenes/cinematics/CreditsScreen.tscn")
const LEVEL_SCENE := preload("res://scenes/levels/Level.tscn")
const MIGGY_ULTIMATE_SCENE := preload("res://scenes/cinematics/MiggyUltimate.tscn")
const HUD_SCENE := preload("res://scenes/ui/HUD.tscn")
const DIALOGUE_SCENE := preload("res://scenes/ui/DialogueBox.tscn")

var screen: Screen = Screen.MENU
var world: LevelDirector = null
var overlay: CanvasLayer
var hud: HUD
var dialogue_box: DialogueBox
var modal: Control = null
var _intro_after := ""
var _ultimate_active := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_ui_navigation()
	_build_overlay()
	show_menu()


func _setup_ui_navigation() -> void:
	# WASD should navigate menus just like the arrow keys. Godot's default
	# ui_* actions only bind arrows/gamepad, so add WASD here.
	var wasd := {
		"ui_left": KEY_A, "ui_right": KEY_D, "ui_up": KEY_W, "ui_down": KEY_S,
	}
	for action: String in wasd:
		if not InputMap.has_action(action):
			continue
		var key: int = wasd[action]
		var exists := false
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey and ev.physical_keycode == key:
				exists = true
				break
		if not exists:
			var e := InputEventKey.new()
			e.physical_keycode = key
			InputMap.action_add_event(action, e)


func _build_overlay() -> void:
	overlay = CanvasLayer.new()
	overlay.name = "Overlay"
	add_child(overlay)
	# subtle CRT vignette above the world, below the HUD
	var vig_layer := CanvasLayer.new()
	vig_layer.layer = 1
	add_child(vig_layer)
	var vig := ColorRect.new()
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/vignette.gdshader")
	vig.material = mat
	vig_layer.add_child(vig)
	hud = HUD_SCENE.instantiate() as HUD
	hud.visible = false
	overlay.add_child(hud)
	dialogue_box = DIALOGUE_SCENE.instantiate() as DialogueBox
	dialogue_box.theme = UISkin.theme()
	overlay.add_child(dialogue_box)


# ------------------------------------------------------------------ teardown ----
func _clear_screen() -> void:
	if world != null and is_instance_valid(world):
		world.queue_free()
		world = null
	dialogue_box.reset()
	for c in overlay.get_children():
		if c != hud and c != dialogue_box:
			c.queue_free()
	if modal != null and is_instance_valid(modal):
		modal.queue_free()
	modal = null
	get_tree().paused = false


# --------------------------------------------------------------------- menu ----
func show_menu() -> void:
	_clear_screen()
	screen = Screen.MENU
	hud.visible = false
	AudioDirector.play_music("menu", 0.3)
	var m := MENU_SCENE.instantiate()
	m.theme = UISkin.theme()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(m)


# ----------------------------------------------------------------- new game ----
func start_new_game(seed_override := 0, character := "pingu") -> void:
	GameState.reset_run(seed_override, character)
	GameState.started = true
	# Starter kit
	GameState.add_item(ItemRegistry.consumable("heal_small", 2))
	GameState.add_item(ItemRegistry.consumable("en_small", 1))
	var start_item := GameState.character_def().start_item
	if start_item != "":
		var weapon := ItemRegistry.consumable(start_item, 1)
		if weapon != null:
			GameState.equip(weapon)
	GameState.stats.en = GameState.stats.max_en
	if character == "miggy":
		AudioDirector.play_sfx("miggy_spawn")
		begin_mission()
	else:
		show_intro()


func start_miggy_run(seed_override := 0) -> void:
	start_new_game(seed_override, "miggy")


func play_miggy_ultimate(player: Player) -> void:
	if _ultimate_active:
		return
	_ultimate_active = true
	get_tree().paused = true
	var cin := MIGGY_ULTIMATE_SCENE.instantiate()
	cin.theme = UISkin.theme()
	cin.set_anchors_preset(Control.PRESET_FULL_RECT)
	cin.process_mode = Node.PROCESS_MODE_ALWAYS
	cin.finished.connect(func():
		get_tree().paused = false
		_ultimate_active = false
		if is_instance_valid(player):
			player.apply_ultimate()
		if modal == cin:
			modal = null
		cin.queue_free())
	overlay.add_child(cin)
	modal = cin
	cin.tree_exited.connect(func():
		if _ultimate_active:
			_ultimate_active = false
			get_tree().paused = false)


func show_intro() -> void:
	_clear_screen()
	screen = Screen.INTRO
	hud.visible = false
	AudioDirector.play_music("menu", 0.4)
	var ic := INTRO_SCENE.instantiate()
	ic.theme = UISkin.theme()
	ic.set_anchors_preset(Control.PRESET_FULL_RECT)
	ic.finished.connect(begin_mission)
	overlay.add_child(ic)


func _connect_death() -> void:
	_on_player_died_reset()
	EventBus.player_died.connect(_on_player_died, CONNECT_ONE_SHOT)


func begin_mission() -> void:
	_clear_screen()
	screen = Screen.GAME
	GameState.area_index = GameState.checkpoint.get("area", 0)
	world = LEVEL_SCENE.instantiate() as LevelDirector
	get_tree().root.add_child.call_deferred(world)
	hud.visible = true
	_connect_death()


func goto_area(index: int) -> void:
	if index >= GameState.TOTAL_AREAS:
		return
	_clear_screen()
	screen = Screen.GAME
	GameState.area_index = index
	world = LEVEL_SCENE.instantiate() as LevelDirector
	get_tree().root.add_child.call_deferred(world)
	hud.visible = true
	_connect_death()


# ---------------------------------------------------------------- game over ----
func _on_player_died() -> void:
	if screen != Screen.GAME:
		return
	await get_tree().create_timer(1.1).timeout
	if screen != Screen.GAME:
		return
	get_tree().paused = true
	var go := GAMEOVER_SCENE.instantiate()
	go.theme = UISkin.theme()
	go.set_anchors_preset(Control.PRESET_FULL_RECT)
	go.restart_requested.connect(restart_from_checkpoint)
	go.menu_requested.connect(func():
		_on_player_died_reset()
		show_menu())
	overlay.add_child(go)
	modal = go


func _on_player_died_reset() -> void:
	# disconnect the one-shot died connection if still present
	if EventBus.player_died.is_connected(_on_player_died):
		EventBus.player_died.disconnect(_on_player_died)


func restart_from_checkpoint() -> void:
	var penalty := int(GameState.coins * 0.2)
	if penalty > 0:
		GameState.add_coins(-penalty)
		FX.toast("LICENSE FEES FOR RESURRECTION: -%d coins" % penalty)
	GameState.stats.hp = int(ceilf(GameState.stats.max_hp * 0.5))
	GameState.stats.en = GameState.stats.max_en
	get_tree().paused = false
	goto_area(GameState.checkpoint.get("area", 0))


# ------------------------------------------------------------------ modals ----
func open_inventory() -> void:
	_open_modal(INVENTORY_SCENE.instantiate())


func open_stats() -> void:
	_open_modal(STATS_SCENE.instantiate())


func open_achievements() -> void:
	_open_modal(ACHIEVEMENTS_SCENE.instantiate())


func open_settings() -> void:
	_open_modal(SETTINGS_SCENE.instantiate())


func open_pause() -> void:
	if screen != Screen.GAME or modal != null:
		return
	var p := PAUSE_SCENE.instantiate()
	p.resume.connect(close_modal)
	p.open_settings.connect(func(): _open_modal(SETTINGS_SCENE.instantiate()))
	p.open_achievements.connect(func(): _open_modal(ACHIEVEMENTS_SCENE.instantiate()))
	p.quit_to_menu.connect(func():
		close_modal()
		_on_player_died_reset()
		show_menu())
	_open_modal(p)


func _open_modal(s: Control) -> void:
	if modal != null and is_instance_valid(modal):
		modal.queue_free()
	modal = null
	get_tree().paused = true
	s.theme = UISkin.theme()
	s.set_anchors_preset(Control.PRESET_FULL_RECT)
	s.close_requested.connect(close_modal)
	overlay.add_child(s)
	modal = s


func close_modal() -> void:
	if modal != null and is_instance_valid(modal):
		modal.queue_free()
	modal = null
	get_tree().paused = false
	# Closing a menu modal frees the focused control, so give focus back to the
	# title screen; otherwise arrow keys/Enter stop working until the player
	# clicks something.
	if screen == Screen.MENU:
		for c in overlay.get_children():
			if c is MainMenuScreen and is_instance_valid(c):
				c.focus_menu()
				break


# ------------------------------------------------------------------- ending ----
func start_ending() -> void:
	if screen != Screen.GAME:
		return
	if modal != null:
		# A pause/settings/game-over screen owns the foreground; never stack
		# an ending on top of it or start the ending twice.
		return
	get_tree().paused = false
	# Freeze the gameplay world (but not the autoloads/overlay) so enemies,
	# hazards, timers and player input cannot interfere with the cinematic.
	if world != null and is_instance_valid(world):
		world.process_mode = Node.PROCESS_MODE_DISABLED
	hud.visible = false
	screen = Screen.ENDING
	GameState.counters["mission_complete"] = true
	GameState.mission_complete = true
	GameState.write_save()

	var scene := MIGGY_ENDING_SCENE if GameState.character_id == "miggy" else PINGU_ENDING_SCENE
	var e := scene.instantiate()
	e.theme = UISkin.theme()
	e.set_anchors_preset(Control.PRESET_FULL_RECT)
	e.finished.connect(show_credits)
	overlay.add_child(e)
	modal = e


func show_credits() -> void:
	if modal != null and is_instance_valid(modal):
		modal.queue_free()
		modal = null
	screen = Screen.CREDITS
	AchievementManager.on_ending_finished()
	var c := CREDITS_SCENE.instantiate()
	c.theme = UISkin.theme()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.finished.connect(show_menu)
	overlay.add_child(c)
	modal = c


# ------------------------------------------------------------------- input ----
func _unhandled_input(event: InputEvent) -> void:
	if _ultimate_active:
		return
	if screen != Screen.GAME:
		return
	if dialogue_box.visible and dialogue_box.has_method("consume_key"):
		if dialogue_box.consume_key(event):
			return
	if modal != null:
		if event.is_action_pressed("pause") or event.is_action_pressed("inventory") or event.is_action_pressed("stats"):
			close_modal()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause"):
		open_pause()
	elif event.is_action_pressed("inventory"):
		open_inventory()
	elif event.is_action_pressed("stats"):
		open_stats()
