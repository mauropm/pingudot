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


func _ready() -> void:
	add_to_group("player")
	stats = GameState.stats
	_register_ability_actions()
	_build_nodes()
	EventBus.player_hp_changed.connect(_on_hp_changed)
	EventBus.screen_shake.connect(func(s, _d): _shake = maxf(_shake, s))


func _register_ability_actions() -> void:
	# Hotkeys 1-4 select + cast abilities directly (bonus beyond K).
	for i in range(1, 5):
		var an := "ability_%d" % i
		if not InputMap.has_action(an):
			InputMap.add_action(an)
			var ev := InputEventKey.new()
			ev.physical_keycode = 48 + i
			InputMap.action_add_event(an, ev)


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
	sprite.sprite_frames = SpriteLib.build("res://assets/characters/pingu.png")
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
	for i in range(1, 5):
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
			AudioDirector.play_sfx("step", -12.0, 0.15)
	if velocity.length() < 2.0 and state == State.FREE:
		_idle_quip_t -= delta
		if _idle_quip_t <= 0.0:
			_idle_quip_t = randf_range(16.0, 30.0)
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
	for k in _cooldowns.keys():
		_cooldowns[k] = maxf(0.0, _cooldowns[k] - delta)
		EventBus.ability_cooldown.emit(k, _cooldowns[k])
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
	if state == State.DODGE:
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
	_attack_timer = 0.28
	AudioDirector.play_sfx("slash")
	FX.slash_arc(global_position + facing * 13.0 + Vector2(0, 2), facing)


func _try_ranged() -> void:
	if _ctrl_lock > 0.0 or state in [State.DODGE, State.HURT, State.DEAD]:
		return
	if _cooldowns.get("ranged", 0.0) > 0.0:
		return
	_cooldowns["ranged"] = 0.45
	_enter(State.RANGED)
	_attack_timer = 0.22
	var dmg := stats.effective_atk()
	if randf() < CombatMath.crit_chance(stats.effective_luck()):
		dmg *= 2
	FX.shoot("disc", global_position + facing * 10, facing, dmg, "player", 150.0, 60.0, false, "", 0, false, 1.5)
	FX.spark(global_position + facing * 10)
	AudioDirector.play_sfx("shoot")


func _try_cast() -> void:
	if _ctrl_lock > 0.0 or state in [State.DODGE, State.HURT, State.DEAD]:
		return
	var ab := GameState.selected_ability
	if ab == "":
		if GameState.unlocked_abilities.size() > 0:
			GameState.select_ability(GameState.unlocked_abilities[-1])
			ab = GameState.selected_ability
		else:
			FX.pop_text(global_position + Vector2(0, -20), "NO ABILITIES! LEVEL UP", Color("e2282e"))
			return
	if _cooldowns.get(ab, 0.0) > 0.0:
		FX.pop_text(global_position + Vector2(0, -20), "COOLDOWN", Color("9aa4b2"))
		return
	var def: AbilityResource = AbilityRegistry.defs[ab]
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
