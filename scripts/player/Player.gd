extends CharacterBody2D
class_name Player
## Pingu — player controller: 8-way movement (walk/run), jump-free top-down,
## melee (J), special (K), ranged (L), dodge-roll (SPACE, i-frames), interact
## (E), status effects (blue-screen control loss, root buff, smell DoT, etc).

enum State { FREE, ATTACK, CAST, RANGED, DODGE, HURT, DEAD }

const TILE := 16.0

@export var base_speed := 62.0
@export var run_mult := 1.45

var state: State = State.FREE
var facing := Vector2.RIGHT
var _anim := "idle"
var _anim_prefix := ""
var _run := false
var frozen := false     # locked by dialogue / cutscene

var sprite: AnimatedSprite2D
var melee_hitbox: Area2D
var melee_shape: CollisionShape2D
var hurtbox: Area2D
var cam: Camera2D

var stats: CharacterStats
var _iframes := 0.0
var _contact_lock := 0.0    # separate from i-frames: touching enemies must not
                            # shield you from fireballs/attacks
var _dodge_timer := 0.0
var _attack_timer := 0.0
var _cast_timer := 0.0
var _hurt_timer := 0.0
var _hit_registered := false

# Status effects (applied by enemies)
var _status := {}  # id -> {"t": remaining, "dot": dmg/s}
var _ctrl_lock := 0.0     # blue screen: no movement/attacks

# Ability system
var _cooldowns := {}
var _buff_atk := 0.0
var _buff_def := 0.0
var _buff_timer := 0.0

# Screen shake
var _shake := 0.0

# Interaction
var _nearest_interact: Node = null

var effects_container: Node2D

# --- character / MIGGY systems ---------------------------------------------
var _char: CharacterDefinition
var _spawn_t := 0.0
var _overdrive_t := 0.0
var _shield_hp := 0
var _shield_max := 0
var _shield_t := 0.0
var _reflect_pct := 0.0
var _shield_fx: AnimatedSprite2D
var _aura_fx: AnimatedSprite2D
var _ghost_t := 0.0
var _dual: Node
var _victory_t := 0.0
var _ult_spark_t := 0.0


func _ready() -> void:
	add_to_group("player")
	stats = GameState.stats
	_char = GameState.character_def()
	_register_ability_actions()
	_build_nodes()
	EventBus.player_hp_changed.connect(_on_hp_changed)
	EventBus.screen_shake.connect(func(s, _d): _shake = maxf(_shake, s))
	if GameState.character_id == "miggy":
		_spawn_t = 0.9
		sprite.play("spawn")
		AudioDirector.play_sfx("miggy_spawn")
		for i in 3:
			var frag := FX.spawn_effect("code_frag",
				global_position + Vector2(randf_range(-14, 14), randf_range(-16, 6)), 1.0, 0.9)
			if frag:
				frag.modulate = Color("c77dff")


func _register_ability_actions() -> void:
	# Hotkeys 1-6 select + cast abilities directly (bonus beyond K).
	for i in range(1, 7):
		var an := "ability_%d" % i
		if not InputMap.has_action(an):
			InputMap.add_action(an)
			var ev := InputEventKey.new()
			ev.physical_keycode = 48 + i
			InputMap.action_add_event(an, ev)
	if not InputMap.has_action("ultimate"):
		InputMap.add_action("ultimate")
		var r := InputEventKey.new()
		r.physical_keycode = KEY_R
		InputMap.action_add_event("ultimate", r)


func _build_nodes() -> void:
	collision_layer = 2      # Player
	collision_mask = 1       # collide with world tiles only (enemies use masks)
	# collision with enemies handled by their masks + our move

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	shape.position = Vector2(0, 8)
	add_child(shape)

	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = SpriteLib.build(_char.atlas_path if _char != null else "res://assets/characters/pingu.png")
	sprite.z_index = 10
	add_child(sprite)
	sprite.play("idle")

	# Melee hitbox: front arc, toggled during attacks
	melee_hitbox = Area2D.new()
	melee_hitbox.collision_layer = 8    # PlayerHitbox
	melee_hitbox.collision_mask = 4     # enemy bodies (Enemies layer)
	melee_hitbox.monitoring = false
	melee_hitbox.monitorable = false
	melee_shape = CollisionShape2D.new()
	var ms := CircleShape2D.new()
	ms.radius = 14.0
	melee_shape.shape = ms
	melee_hitbox.add_child(melee_shape)
	add_child(melee_hitbox)

	# Hurtbox (kept for enemy-area damage; melee attacks use distance checks)
	hurtbox = Area2D.new()
	hurtbox.collision_layer = 0
	hurtbox.collision_mask = 16 | 128  # EnemyHitbox + Hazards
	var hs := CollisionShape2D.new()
	var hc := CircleShape2D.new()
	hc.radius = 7.0
	hs.shape = hc
	hs.position = Vector2(0, 4)
	hurtbox.add_child(hs)
	add_child(hurtbox)
	# (Hazards/attacks damage the player through their own detection masks.)

	cam = Camera2D.new()
	cam.enabled = true
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	cam.zoom = Vector2.ONE
	add_child(cam)
	cam.make_current()


# ------------------------------------------------------------------ input ----
func _unhandled_input(event: InputEvent) -> void:
	if state == State.DEAD or frozen:
		return
	if event.is_action_pressed("attack"):
		_try_attack()
	elif event.is_action_pressed("ranged"):
		_try_ranged()
	elif event.is_action_pressed("special"):
		_try_cast()
	elif event.is_action_pressed("dodge"):
		_try_dodge()
	elif event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("ultimate"):
		_try_ultimate()
	for i in range(1, 7):
		if event.is_action_pressed("ability_%d" % i):
			_select_and_cast_slot(i)


func _select_and_cast_slot(i: int) -> void:
	var ids := GameState.unlocked_abilities
	if i - 1 < ids.size():
		GameState.select_ability(ids[i - 1])
		_try_cast()


# ------------------------------------------------------------- game loop ----
func _physics_process(delta: float) -> void:
	if _iframes > 0.0:
		_iframes -= delta
		sprite.modulate.a = 0.5 if int(_iframes * 20.0) % 2 == 0 else 1.0
		if _iframes <= 0.0:
			sprite.modulate.a = 1.0
	_update_timers(delta)
	_update_status(delta)
	_update_buffs(delta)

	if _shake > 0.0:
		_shake = maxf(0, _shake - delta * 30.0)
		cam.offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
	else:
		cam.offset = Vector2.ZERO

	match state:
		State.DEAD:
			velocity = Vector2.ZERO
			return
		State.FREE, State.ATTACK, State.CAST, State.RANGED:
			_do_movement(delta)
		State.DODGE:
			_do_dodge(delta)
		State.HURT:
			_do_hurt(delta)
	move_and_slide()
	_update_anim_selection()
	_update_hitbox_position()
	_check_interact_proximity()
	_update_footsteps(delta)

	if state in [State.ATTACK, State.CAST, State.RANGED] and _attack_timer <= 0.0:
		_enter(State.FREE)


var _step_t := 0.0
var _idle_quip_t := 12.0


func _update_footsteps(delta: float) -> void:
	if state == State.FREE and velocity.length() > 12.0:
		_step_t -= delta
		if _step_t <= 0.0:
			_step_t = 0.28 if _run else 0.38
			if GameState.character_id == "miggy":
				AudioDirector.play_sfx("terminal_type", -14.0, 0.2)
			else:
				AudioDirector.play_sfx("step", -12.0, 0.15)
	if velocity.length() < 2.0 and state == State.FREE:
		_idle_quip_t -= delta
		if _idle_quip_t <= 0.0:
			_idle_quip_t = randf_range(16.0, 30.0)
			if GameState.character_id == "miggy":
				var qids := ["miggy_idle_1", "miggy_idle_2", "miggy_idle_4"]
				var q := DialogueDB.get_line(qids[randi() % qids.size()])
				AudioDirector.play_sfx("terminal_type", -6.0, 0.1)
				FX.pop_text(global_position + Vector2(0, -22), q["text"], Color("c77dff"), 8)
			else:
				AudioDirector.play_sfx("penguin", -6.0, 0.1)
				FX.pop_text(global_position + Vector2(0, -22), "hmph.", Color("9aa4b2"), 8)


func _enter(s: State) -> void:
	state = s
	melee_hitbox.monitoring = false


func _do_movement(_delta: float) -> void:
	if frozen:
		velocity = Vector2.ZERO
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _ctrl_lock > 0.0:
		# Blue screen: controls glitch — drift randomly.
		dir = Vector2.ZERO if randf() > 0.4 else dir.rotated(randf_range(-1.2, 1.2))
	if dir != Vector2.ZERO:
		facing = dir
		if absf(dir.x) >= absf(dir.y):
			facing = Vector2(signf(dir.x), 0)
	var mult := 1.0
	if state == State.ATTACK or state == State.CAST:
		mult = 0.35
	if _status.has("port"):
		mult *= 0.45   # Port Conflict
	if _overdrive_t > 0.0:
		mult *= 1.55   # Mono Runtime Overdrive
	var spd := base_speed + stats.effective_spd() * 3.0
	velocity = velocity.lerp(dir * spd * mult, 0.35)


var _hold_time := 0.0


func _update_timers(delta: float) -> void:
	var moving := Input.get_vector("move_left", "move_right", "move_up", "move_down").length() > 0.2
	if moving and _ctrl_lock <= 0.0:
		_hold_time += delta
	else:
		_hold_time = 0.0
	_run = _hold_time > 0.55 and moving
	if _dodge_timer > 0:
		_dodge_timer -= delta
	if _attack_timer > 0:
		_attack_timer -= delta
	if _cast_timer > 0:
		_cast_timer -= delta
	if _hurt_timer > 0:
		_hurt_timer -= delta
	if _contact_lock > 0:
		_contact_lock -= delta
	if _ctrl_lock > 0:
		_ctrl_lock -= delta
	if _spawn_t > 0.0:
		_spawn_t -= delta
	if _victory_t > 0.0:
		_victory_t -= delta
	if GameState.character_id == "miggy" and GameState.ultimate_charge >= 100:
		_ult_spark_t -= delta
		if _ult_spark_t <= 0.0:
			_ult_spark_t = 0.45
			var spark := FX.spawn_effect("code_frag",
				global_position + Vector2(randf_range(-12, 12), randf_range(-20, -4)),
				1.0, 0.7)
			if spark != null:
				spark.modulate = Color("f7e94b")
	if _overdrive_t > 0.0:
		_overdrive_t -= delta
		_update_afterimages(delta)
		if _overdrive_t <= 0.0 and _aura_fx != null and is_instance_valid(_aura_fx):
			_aura_fx.queue_free()
			_aura_fx = null
	if _shield_t > 0.0:
		_shield_t -= delta
		if _status.has("shield"):
			_status["shield"]["t"] = _shield_t
		if _shield_t <= 0.0:
			_expire_shield()
	var cd_mult := 2.0 if _overdrive_t > 0.0 else 1.0
	for k in _cooldowns.keys():
		_cooldowns[k] = maxf(0.0, _cooldowns[k] - delta * cd_mult)
		EventBus.ability_cooldown.emit(k, _cooldowns[k])
	sprite.speed_scale = 1.35 if _overdrive_t > 0.0 else 1.0
	# energy regen from INT
	if state != State.DEAD:
		GameState.regenerate_energy((3.0 + stats.intel * 0.4) * delta)


func _update_status(delta: float) -> void:
	var remove: Array = []
	for k in _status:
		_status[k]["t"] -= delta
		if _status[k].has("dot"):
			_status[k]["acc"] = _status[k].get("acc", 0.0) + delta
			if _status[k]["acc"] >= 0.6:
				_status[k]["acc"] = 0.0
				_take_raw(_status[k]["dot"], "stink")
		if _status[k]["t"] <= 0.0:
			remove.append(k)
	for k in remove:
		_status.erase(k)
	GameState.equipment_disabled = _status.has("lic")


func _update_buffs(delta: float) -> void:
	if _buff_timer > 0.0:
		_buff_timer -= delta
		if _buff_timer <= 0.0:
			_buff_atk = 0.0
			_buff_def = 0.0


# ------------------------------------------------------------- animation ----
func _update_anim_selection() -> void:
	if state == State.DEAD:
		return
	var moving := velocity.length() > 8.0
	var target := "idle"
	if _victory_t > 0.0:
		target = "victory"
	elif _spawn_t > 0.0:
		target = "spawn"
	elif state == State.DODGE:
		target = "dodge"
	elif state == State.HURT:
		target = "hurt"
	elif state == State.ATTACK:
		target = "attack"
	elif state == State.RANGED:
		target = "ranged"
	elif state == State.CAST:
		target = "special"
	elif moving:
		target = "run" if _run else "walk"
	# Up-facing variant for locomotion
	var up := facing.y < -0.4 and state == State.FREE
	var prefix := "_back" if (up and target in ["walk", "idle"]) else ""
	var anim := target + prefix
	if not sprite.sprite_frames.has_animation(anim):
		anim = target
	if _anim != anim:
		_anim = anim
		if state == State.DODGE or state == State.HURT or state in [State.ATTACK, State.CAST, State.RANGED]:
			sprite.play(anim)
		else:
			sprite.play(anim)
	# Flip horizontally based on facing
	sprite.flip_h = facing.x < -0.1


func _update_hitbox_position() -> void:
	if state == State.ATTACK and _attack_timer < 0.16 and _attack_timer > 0.0 and not _hit_registered:
		melee_shape.position = facing * 14.0
		_do_melee_query()
	else:
		melee_hitbox.monitoring = false


func _do_melee_query() -> void:
	var space := get_world_2d().direct_space_state
	var q := PhysicsShapeQueryParameters2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 15.0
	q.shape = circ
	q.transform = Transform2D(0.0, global_position + facing * 13.0)
	q.collision_mask = 4   # Enemies
	q.collide_with_bodies = true
	q.collide_with_areas = false
	q.exclude = [get_rid()]
	var results := space.intersect_shape(q, 8)
	for r in results:
		var body: Node = r["collider"]
		if body is EnemyBase and not body.is_dead():
			body.take_hit(_attack_damage(), facing * 140.0, _crit, "player")
			_hit_registered = true


var _crit := false


func _attack_damage() -> int:
	var atk := stats.effective_atk() + int(_buff_atk)
	return atk + randi_range(0, 2)


# ---------------------------------------------------------------- attacks ----
func _try_attack() -> void:
	if _ctrl_lock > 0.0 or state in [State.DODGE, State.HURT, State.DEAD]:
		return
	if state == State.ATTACK and _attack_timer > 0.1:
		return
	_hit_registered = false
	_crit = randf() < CombatMath.crit_chance(stats.effective_luck())
	_enter(State.ATTACK)
	_attack_timer = 0.28 / _attack_speed()
	AudioDirector.play_sfx("slash")
	var slash_tint := Color("c77dff") if GameState.character_id == "miggy" else Color.WHITE
	FX.slash_arc(global_position + facing * 13.0 + Vector2(0, 2), facing, slash_tint)


func _try_ranged() -> void:
	if _ctrl_lock > 0.0 or state in [State.DODGE, State.HURT, State.DEAD]:
		return
	if _cooldowns.get("ranged", 0.0) > 0.0:
		return
	_cooldowns["ranged"] = 0.45 / _attack_speed()
	_enter(State.RANGED)
	_attack_timer = 0.22 / _attack_speed()
	var dmg := stats.effective_atk()
	if randf() < CombatMath.crit_chance(stats.effective_luck()):
		dmg *= 2
	if GameState.character_id == "miggy":
		FX.shoot("code_frag", global_position + facing * 10, facing, dmg, "player",
			190.0, 60.0, false, "", 0, false, 1.7)
		AudioDirector.play_sfx("miggy_shoot")
	else:
		FX.shoot("disc", global_position + facing * 10, facing, dmg, "player", 150.0, 60.0, false, "", 0, false, 1.5)
		AudioDirector.play_sfx("shoot")
	FX.spark(global_position + facing * 10)


func _try_cast() -> void:
	if _ctrl_lock > 0.0 or state in [State.DODGE, State.HURT, State.DEAD]:
		return
	var ab := GameState.selected_ability
	if ab == "" or ab not in GameState.unlocked_abilities:
		if GameState.unlocked_abilities.size() > 0:
			ab = GameState.unlocked_abilities[-1]
			GameState.select_ability(ab)
		else:
			FX.pop_text(global_position + Vector2(0, -20), "NO ABILITIES! LEVEL UP", Color("e2282e"))
			return
	if _cooldowns.get(ab, 0.0) > 0.0:
		FX.pop_text(global_position + Vector2(0, -20), "COOLDOWN", Color("9aa4b2"))
		return
	var def: AbilityResource = AbilityRegistry.defs.get(ab)
	if def == null or def.ultimate:
		return
	if not GameState.try_spend_energy(def.energy_cost):
		FX.pop_text(global_position + Vector2(0, -20), "NEED ENERGY", Color("2d6aff"))
		return
	_cooldowns[ab] = def.cooldown
	_enter(State.CAST)
	_attack_timer = 0.36
	_trigger_ability(def)
	AbilityManager_notify(ab)


func AbilityManager_notify(ab: String) -> void:
	EventBus.ability_used.emit(ab)


func _trigger_ability(def: AbilityResource) -> void:
	match def.ability_type:
		"aoe":
			AudioDirector.play_sfx("kernelpanic")
			EventBus.screen_shake.emit(6.0, 0.3)
			EventBus.screen_flash.emit(Color(0.9, 0.2, 0.2, 0.35), 0.2)
			var ring := FX.spawn_effect("ring", global_position)
			var dmg := stats.effective_atk() * 2 + stats.intel
			for e in get_tree().get_nodes_in_group("enemies"):
				if e is EnemyBase and not e.is_dead() and global_position.distance_to(e.global_position) < 72.0:
					var eb := e as EnemyBase
					var dir: Vector2 = (eb.global_position - global_position).normalized()
					eb.take_hit(dmg, dir * 160.0, false, "ability")
		"clones":
			AudioDirector.play_sfx("forkbomb")
			for i in 4:
				var ang := i * PI / 2.0
				FX.spawn_clone(global_position + Vector2(cos(ang), sin(ang)) * 14, self, stats.effective_atk())
		"buff":
			AudioDirector.play_sfx("rootaccess")
			_buff_atk = int(stats.effective_atk() * 0.5)
			_buff_def = 4
			_buff_timer = 12.0
			FX.pop_text(global_position + Vector2(0, -24), "ROOT", Color("f7e94b"), 10)
		"projectile":
			AudioDirector.play_sfx("segfault")
			FX.shoot("shard", global_position + facing * 8, facing,
				stats.effective_atk() * 3 + stats.intel * 2, "player", 220.0, 120.0, true)
		"collider":
			_cast_collider(def)
		"stun_shield":
			_cast_gnome_shock(def)
		"overdrive":
			_cast_overdrive()
		"shield":
			_cast_bonobo()
		"factory":
			_cast_factory(def)
		"dual_wield":
			_cast_dual_wield(def)


func _attack_speed() -> float:
	return 1.6 if _overdrive_t > 0.0 else 1.0


func _enemies_within(radius: float) -> Array[EnemyBase]:
	var out: Array[EnemyBase] = []
	for e in get_tree().get_nodes_in_group("enemies"):
		var eb := e as EnemyBase
		if eb == null or eb.is_dead():
			continue
		if global_position.distance_to(eb.global_position) <= radius:
			out.append(eb)
	return out


# ---------------------------------------------------------- MIGGY powers ----
func _cast_collider(def: AbilityResource) -> void:
	AudioDirector.play_sfx("collider")
	var center := global_position + facing * 8.0
	var panels: Array[AnimatedSprite2D] = []
	for sgn in [-1.0, 1.0]:
		var panel := FX.spawn_effect("collider_panel", center + Vector2(sgn * 46.0, 0),
			1.0, 1.2)
		if panel == null:
			continue
		panel.z_index = 9
		panel.scale = Vector2.ONE * 1.15
		panels.append(panel)
		var tw := create_tween()
		tw.tween_property(panel, "position", center, 0.55) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_interval(0.15)
		tw.tween_callback(panel.queue_free)
	for e in _enemies_within(150.0):
		e.apply_pull(center, 0.55, 220.0)
	var timer := get_tree().create_timer(0.55)
	timer.timeout.connect(_collider_explode.bind(center, def))


func _collider_explode(center: Vector2, def: AbilityResource) -> void:
	if not is_inside_tree() or state == State.DEAD:
		return
	AudioDirector.play_sfx("boom")
	FX.spawn_effect("collider_boom", center)
	EventBus.screen_shake.emit(8.0, 0.35)
	var dmg := int(stats.effective_atk() * def.power) + stats.effective_int() * 2
	for e in _enemies_within(86.0):
		var dir := (e.global_position - center).normalized()
		e.take_hit(dmg, dir * 240.0, true, "ability")


func _cast_gnome_shock(def: AbilityResource) -> void:
	AudioDirector.play_sfx("gnome_shock")
	var win := FX.spawn_effect("gnome_windows", global_position + Vector2(-16, -18), 1.0, 1.3)
	if win != null:
		win.z_index = 6
	var wave := FX.spawn_effect("gnome_wave", global_position)
	if wave != null:
		wave.z_index = 15
	EventBus.screen_flash.emit(Color(0.7, 0.9, 1.0, 0.25), 0.2)
	for e in _enemies_within(140.0):
		e.stun(2.6)
		var dir := (e.global_position - global_position).normalized()
		e.take_hit(int(stats.effective_atk() * def.power), dir * 90.0, false, "ability")
	_grant_shield(18 + stats.effective_int() * 2, 9.0, 0.0)
	FX.pop_text(global_position + Vector2(0, -28), "SHELL SHOCK", Color("2de3ff"), 8)


func _cast_overdrive() -> void:
	AudioDirector.play_sfx("mono_overdrive")
	_overdrive_t = 9.0
	_ghost_t = 0.0
	if _aura_fx == null or not is_instance_valid(_aura_fx):
		_aura_fx = AnimatedSprite2D.new()
		_aura_fx.sprite_frames = SpriteLib.build("res://assets/effects/mono_aura.png")
		var names := _aura_fx.sprite_frames.get_animation_names()
		if names.size() > 0:
			_aura_fx.animation = names[0]
			_aura_fx.play()
		_aura_fx.scale = Vector2(1.55, 1.55)
		_aura_fx.position = Vector2(0, -4)
		_aura_fx.z_as_relative = false
		_aura_fx.z_index = 9
		add_child(_aura_fx)
	EventBus.screen_flash.emit(Color(0.5, 0.2, 0.9, 0.3), 0.25)
	FX.pop_text(global_position + Vector2(0, -28), "MONO OVERDRIVE", Color("c77dff"), 8)


func _update_afterimages(delta: float) -> void:
	_ghost_t -= delta
	if _ghost_t > 0.0:
		return
	_ghost_t = 0.07
	if sprite == null or sprite.sprite_frames == null:
		return
	var tex := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if tex == null:
		return
	var ghost := Sprite2D.new()
	ghost.texture = tex
	ghost.flip_h = sprite.flip_h
	ghost.modulate = Color(0.65, 0.35, 1.0, 0.45)
	ghost.z_index = 9
	var fx := get_tree().get_first_node_in_group("effects")
	if fx != null:
		fx.add_child(ghost)
		ghost.global_position = global_position
	else:
		add_child(ghost)
		ghost.position = Vector2.ZERO
	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.3)
	tw.tween_callback(ghost.queue_free)


func _cast_bonobo() -> void:
	AudioDirector.play_sfx("bonobo_shield")
	_grant_shield(30 + stats.effective_int() * 2, 9.0, 0.35)
	var burst := FX.spawn_effect("bonobo_shield", global_position + Vector2(0, -4), 1.0, 1.3)
	if burst != null:
		burst.z_index = 8
	FX.pop_text(global_position + Vector2(0, -28), "BONOBO SHIELD", Color("2de3ff"), 8)


func _grant_shield(hp: int, duration: float, reflect_pct: float) -> void:
	_shield_max = hp
	_shield_hp = hp
	_shield_t = duration
	_reflect_pct = reflect_pct
	_status["shield"] = {"t": duration}
	if _shield_fx != null and is_instance_valid(_shield_fx):
		_shield_fx.queue_free()
	_shield_fx = AnimatedSprite2D.new()
	_shield_fx.sprite_frames = SpriteLib.build("res://assets/effects/bonobo_shield.png")
	var names := _shield_fx.sprite_frames.get_animation_names()
	if names.size() > 0:
		_shield_fx.animation = names[0]
		_shield_fx.play()
	_shield_fx.scale = Vector2(1.5, 1.5)
	_shield_fx.position = Vector2(0, -2)
	_shield_fx.z_as_relative = false
	_shield_fx.z_index = 9
	add_child(_shield_fx)


func _expire_shield() -> void:
	_shield_hp = 0
	_shield_t = 0.0
	_reflect_pct = 0.0
	_status.erase("shield")
	if _shield_fx != null and is_instance_valid(_shield_fx):
		_shield_fx.queue_free()
		_shield_fx = null


func _absorb_shield(dmg: int) -> int:
	if _shield_hp <= 0:
		return dmg
	var absorbed := mini(_shield_hp, dmg)
	_shield_hp -= absorbed
	FX.pop_text(global_position + Vector2(0, -26), "BLOCK %d" % absorbed, Color("2de3ff"), 8)
	AudioDirector.play_sfx("bonobo_shield", -6.0)
	if _shield_hp <= 0:
		_expire_shield()
	return dmg - absorbed


func _cast_factory(def: AbilityResource) -> void:
	AudioDirector.play_sfx("gobject_factory")
	var dmg := int(stats.effective_atk() * def.power)
	for i in 3:
		var ang := TAU * i / 3.0
		FX.spawn_helper(global_position + Vector2(cos(ang), sin(ang)) * 16.0,
			self, dmg, 8.0)
	FX.pop_text(global_position + Vector2(0, -28), "g_object_new()", Color("c77dff"), 8)


func _cast_dual_wield(def: AbilityResource) -> void:
	AudioDirector.play_sfx("dual_wield")
	if _dual != null and is_instance_valid(_dual):
		_dual.queue_free()
	_dual = DualPanelWield.new()
	_dual.setup(self, 8.0)
	add_child(_dual)
	FX.pop_text(global_position + Vector2(0, -28), "DUAL WIELD", Color("2de3ff"), 8)


func play_victory() -> void:
	if state == State.DEAD:
		return
	_victory_t = 2.0
	_enter(State.FREE)
	sprite.play("victory")
	FX.levelup_ring(global_position)


func _try_ultimate() -> void:
	if GameState.character_id != "miggy" or state == State.DEAD or frozen:
		return
	if GameState.ultimate_charge < 100:
		FX.pop_text(global_position + Vector2(0, -24),
			"ULT %d%%" % GameState.ultimate_charge, Color("9aa4b2"), 8)
		return
	if not GameState.try_consume_ultimate():
		return
	_enter(State.CAST)
	_attack_timer = 2.5
	frozen = true
	AudioDirector.play_sfx("ultimate_rmrf")
	Main.play_miggy_ultimate(self)


## Called by Main's cinematic when the terminal sequence finishes.
func apply_ultimate() -> void:
	frozen = false
	_enter(State.FREE)
	EventBus.screen_flash.emit(Color(1, 1, 1, 0.85), 0.45)
	EventBus.screen_shake.emit(12.0, 0.9)
	for container in get_tree().get_nodes_in_group("effects"):
		for c in container.get_children():
			var pr := c as Projectile
			if pr != null and pr.owner_kind == "enemy":
				pr.queue_free()
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is CTOTechBoss:
			e.take_hit(int(e.max_hp * 0.30), Vector2.ZERO, false, "ultimate")
		elif e is EnemyBase and not e.is_dead():
			e.take_hit(99999, Vector2.ZERO, true, "ultimate")
	FX.pop_text(global_position + Vector2(0, -30), "SEGMENTATION FAULT", Color("ff5a5a"), 16)


func _try_dodge() -> void:
	if state in [State.DODGE, State.DEAD] or _ctrl_lock > 0.0:
		return
	if _cooldowns.get("dodge", 0.0) > 0.0:
		return
	_cooldowns["dodge"] = 0.7
	_enter(State.DODGE)
	_dodge_timer = 0.28
	_iframes = maxf(_iframes, 0.35)
	velocity = facing * 240.0
	AudioDirector.play_sfx("jump")


func _do_dodge(_delta: float) -> void:
	if _dodge_timer <= 0.0:
		_enter(State.FREE)


func _do_hurt(_delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 120 * _hurt_timer)
	if _hurt_timer <= 0.0:
		_enter(State.FREE)


# ------------------------------------------------------------- interactions ----
func _try_interact() -> void:
	if _nearest_interact and _nearest_interact.has_method("interact"):
		_nearest_interact.interact()


func _check_interact_proximity() -> void:
	var best: Node = null
	var best_d := 26.0
	for n in get_tree().get_nodes_in_group("interactable"):
		if not is_instance_valid(n):
			continue
		var d: float = global_position.distance_to(n.global_position)
		if d < best_d:
			best_d = d
			best = n
	if best != _nearest_interact:
		_nearest_interact = best
		EventBus.interact_hint.emit(best.hint_text if best and "hint_text" in best else "")


# ------------------------------------------------------------------ damage ----
func take_damage(raw: int, from_dir := Vector2.ZERO, status := "", coin_steal := 0) -> void:
	if _iframes > 0.0 or state == State.DEAD:
		return
	var def := stats.effective_def() + int(_buff_def)
	var dmg := CombatMath.enemy_damage(raw, def, GameState.roll_rng())
	dmg = _absorb_shield(dmg)
	if dmg <= 0:
		_iframes = 0.35
		EventBus.screen_shake.emit(1.5, 0.1)
		return
	stats.hp = maxi(0, stats.hp - dmg)
	_iframes = 0.9
	EventBus.player_hp_changed.emit(stats.hp, stats.max_hp)
	EventBus.player_damaged.emit()
	FX.pop_text(global_position + Vector2(0, -18), "-%d" % dmg, Color("e2282e"))
	AudioDirector.play_sfx("hurt")
	EventBus.screen_shake.emit(4.0, 0.2)
	if status != "":
		apply_status(status)
	if coin_steal > 0:
		GameState.add_coins(-mini(coin_steal, GameState.coins))
		FX.pop_text(global_position + Vector2(4, -26), "-%d" % coin_steal, Color("f7c94b"))
	_enter(State.HURT)
	_hurt_timer = 0.3
	velocity = from_dir * 150.0
	if stats.hp <= 0:
		die()


func _take_raw(dmg: int, _kind: String) -> void:
	if _iframes > 0.5 or state == State.DEAD:
		return
	stats.hp = maxi(0, stats.hp - dmg)
	EventBus.player_hp_changed.emit(stats.hp, stats.max_hp)
	FX.pop_text(global_position + Vector2(0, -14), "-%d" % dmg, Color("6ec72c"))
	if stats.hp <= 0:
		die()


## Contact damage (walking into an enemy). Uses its own cooldown so it never
## grants the long attack invulnerability — otherwise enemy fire could never
## land while you stand next to them.
func take_contact_damage(raw: int, from_dir: Vector2) -> void:
	if _contact_lock > 0.0 or _iframes > 0.0 or state == State.DEAD:
		return
	_contact_lock = 0.7
	var def := stats.effective_def() + int(_buff_def)
	var dmg := CombatMath.enemy_damage(raw, def, GameState.roll_rng())
	dmg = _absorb_shield(dmg)
	if dmg <= 0:
		return
	stats.hp = maxi(0, stats.hp - dmg)
	EventBus.player_hp_changed.emit(stats.hp, stats.max_hp)
	EventBus.player_damaged.emit()
	FX.pop_text(global_position + Vector2(0, -18), "-%d" % dmg, Color("e2282e"))
	AudioDirector.play_sfx("hurt", -4.0)
	EventBus.screen_shake.emit(3.0, 0.15)
	const KNOCK := 120.0
	velocity = from_dir.normalized() * KNOCK
	_enter(State.HURT)
	_hurt_timer = 0.22
	if stats.hp <= 0:
		die()


func apply_status(id: String) -> void:
	match id:
		"blue_screen":
			_ctrl_lock = 2.5
			_status["blue"] = {"t": 2.5}
			EventBus.screen_flash.emit(Color(0.1, 0.2, 0.9, 0.5), 0.4)
			AudioDirector.play_sfx("blue")
		"port_conflict":
			_status["port"] = {"t": 3.0}
		"smell":
			_status["stink"] = {"t": 4.0, "dot": 3, "acc": 0.0}
			AudioDirector.play_sfx("stink")
		"license_violation":
			_status["lic"] = {"t": 5.0}
		_:
			_status[id] = {"t": 3.0}
	GameState.equipment_disabled = _status.has("lic")
	EventBus.status_effect_applied.emit(id, _status.get(id, {}).get("t", 0.0))


func is_license_blocked() -> bool:
	return _status.has("lic")


func get_cooldown(id: String) -> float:
	return _cooldowns.get(id, 0.0)


func is_dead() -> bool:
	return state == State.DEAD


func active_statuses() -> Array:
	return _status.keys()


func hazard_tick(dmg: int) -> void:
	take_damage(dmg, Vector2.ZERO, "hazard", 0)


## Incoming projectile hook: allows Bonobo's shield to absorb/reflect.
## Returns 0 = normal hit, 2 = reflected (projectile should flip sides).
func receive_projectile(dmg: int, from_dir: Vector2, status := "", steal := 0) -> int:
	if _shield_hp > 0 and _reflect_pct > 0.0 and randf() < _reflect_pct:
		FX.pop_text(global_position + Vector2(0, -28), "REFLECT", Color("c77dff"), 8)
		AudioDirector.play_sfx("bonobo_shield", -3.0, 0.2)
		return 2
	take_damage(dmg, from_dir, status, steal)
	return 0


func _on_hp_changed(hp: int, _m: int) -> void:
	if hp <= 0 and state != State.DEAD:
		die()


func die() -> void:
	if state == State.DEAD:
		return
	_enter(State.DEAD)
	stats.hp = 0
	sprite.play("death")
	velocity = Vector2.ZERO
	melee_hitbox.set_deferred("monitoring", false)
	EventBus.player_died.emit()


func revive_at(pos: Vector2, hp_frac := 0.5) -> void:
	global_position = pos
	stats.hp = int(ceilf(stats.max_hp * hp_frac))
	_enter(State.FREE)
	sprite.play("idle")
	sprite.flip_h = false
	_iframes = 1.2
	_ctrl_lock = 0.0
	_status.clear()
	EventBus.player_respawned.emit()
	EventBus.player_hp_changed.emit(stats.hp, stats.max_hp)
