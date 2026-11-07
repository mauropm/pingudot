extends CharacterBody2D
class_name EnemyBase
## Shared enemy brain: wander/chase/attack FSM, hit reactions, HP bar, loot.
## Families override choose_attack()/perform_attack().

enum S { IDLE, CHASE, ATTACK, CAST, HURT, DEAD }

static var stat_table := {
	"bsdemon":      {"hp": 26, "atk": 6, "def": 2, "spd": 38.0, "xp": 12, "cell": 24},
	"littlebill":   {"hp": 20, "atk": 7, "def": 1, "spd": 44.0, "xp": 14, "cell": 24},
	"gplhipster":   {"hp": 30, "atk": 5, "def": 3, "spd": 30.0, "xp": 15, "cell": 24},
	"secbot":       {"hp": 18, "atk": 5, "def": 2, "spd": 52.0, "xp": 10, "cell": 24},
	"cto":          {"hp": 480, "atk": 12, "def": 5, "spd": 26.0, "xp": 400, "cell": 56},
}

var kind := "bsdemon"
var base_kind := "bsdemon"
var elite := false
var area_index := 0
var hp := 20
var max_hp := 20
var atk := 6
var defense := 2
var speed_val := 40.0
var xp_reward := 12
var aggro_range := 95.0
var state: S = S.IDLE
var facing_sign := 1.0
var knock := Vector2.ZERO
var rng := RandomNumberGenerator.new()
var player: Player

var sprite: AnimatedSprite2D
var _bar: Node2D
var _bar_fill: Sprite2D
var _bar_hide := 0.0
var _state_t := 0.0
var _attack_cd := 0.0
var _touch_cd := 0.0
var _stun_t := 0.0
var _pull_t := 0.0
var _pull_center := Vector2.ZERO
var _pull_speed := 0.0
var _wander_target := Vector2.ZERO
var _flash_tween: Tween
var _home := Vector2.ZERO


func _ready() -> void:
	add_to_group("enemies")
	base_kind = kind.trim_suffix("_elite")
	collision_layer = 4      # Enemies
	collision_mask = 1       # collide with world tiles (melee handled by distance)
	var shape := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	var cell: int = stat_table[base_kind]["cell"]
	circ.radius = cell * 0.28
	shape.shape = circ
	shape.position = Vector2(0, cell * 0.22)
	add_child(shape)

	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = SpriteLib.build("res://assets/enemies/%s.png" % kind)
	sprite.z_index = 5
	add_child(sprite)
	_play("idle")

	if cell >= 48:
		pass  # boss: no mini bar over head? still fine
	_build_hp_bar(cell)
	_home = position
	rng.seed = GameState.rng.randi()


func scale_for_area(area: int) -> void:
	area_index = area
	var base: Dictionary = stat_table[base_kind]
	var mult := 1.0 + area * 0.30
	var emult := 1.9 if elite else 1.0
	max_hp = int(base["hp"] * mult * emult)
	hp = max_hp
	atk = int(base["atk"] * mult * (1.4 if elite else 1.0))
	defense = int(base["def"] * (1.0 + area * 0.15))
	speed_val = base["spd"] * (1.12 if elite else 1.0)
	xp_reward = int(base["xp"] * mult * (2.0 if elite else 1.0))
	if elite:
		scale = Vector2.ONE * 1.18


func _build_hp_bar(cell: int) -> void:
	_bar = Node2D.new()
	_bar.position = Vector2(-11, -cell * 0.62)
	_bar.visible = false
	add_child(_bar)
	var back := Sprite2D.new()
	back.texture = load("res://assets/ui/bar_back.png")
	back.centered = false
	back.scale = Vector2(2.2, 1.0)
	_bar.add_child(back)
	_bar_fill = Sprite2D.new()
	_bar_fill.texture = load("res://assets/ui/bar_enemy.png")
	_bar_fill.centered = false
	_bar_fill.scale = Vector2(2.2, 1.0)
	_bar.add_child(_bar_fill)


func _update_bar() -> void:
	_bar_fill.scale = Vector2(2.2 * clampf(float(hp) / float(max_hp), 0.0, 1.0), 1.0)


func _play(anim: String) -> void:
	if sprite.sprite_frames.has_animation(anim):
		sprite.animation = anim
		sprite.play()
	elif sprite.sprite_frames.has_animation("idle"):
		sprite.animation = "idle"
		sprite.play()


func _physics_process(delta: float) -> void:
	if _bar_hide > 0.0:
		_bar_hide -= delta
		if _bar_hide <= 0.0:
			_bar.visible = false
	if _attack_cd > 0.0:
		_attack_cd -= delta
	if _touch_cd > 0.0:
		_touch_cd -= delta
	if _stun_t > 0.0:
		_stun_t -= delta
		velocity = Vector2.ZERO
		if sprite != null:
			sprite.modulate = Color(0.65, 0.9, 1.2) if int(_stun_t * 12.0) % 2 == 0 else Color.WHITE
		if _stun_t <= 0.0 and sprite != null:
			sprite.modulate = Color.WHITE
		return
	if _pull_t > 0.0:
		_pull_t -= delta
		var to := _pull_center - global_position
		if to.length() > 4.0:
			global_position += to.normalized() * minf(_pull_speed * delta, to.length())
		velocity = Vector2.ZERO
		return
	_state_t -= delta
	match state:
		S.DEAD:
			return
		S.HURT:
			velocity = knock
			knock = knock.move_toward(Vector2.ZERO, 400 * delta)
			if _state_t <= 0.0:
				_enter(S.CHASE)
		S.ATTACK, S.CAST:
			velocity = velocity.move_toward(Vector2.ZERO, 200 * delta)
			if _state_t <= 0.0:
				_enter(S.CHASE)
		S.IDLE:
			_do_idle(delta)
		S.CHASE:
			_do_chase(delta)
	move_and_slide()
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	_check_contact_damage()
	if sprite:
		var dir_to_p := (player.global_position - global_position) if player else Vector2.RIGHT
		facing_sign = 1.0 if dir_to_p.x >= 0.0 else -1.0
		sprite.flip_h = facing_sign < 0.0


func _enter(s: S) -> void:
	state = s
	_state_t = 0.0
	match s:
		S.IDLE:
			_play("idle")
		S.CHASE:
			_play("walk")
		S.ATTACK:
			_play("attack")
		S.CAST:
			_play("special")


func _do_idle(_delta: float) -> void:
	if player and global_position.distance_to(player.global_position) < aggro_range:
		_enter(S.CHASE)
		return
	if _state_t <= 0.0:
		_wander_target = _home + Vector2(randf_range(-26, 26), randf_range(-22, 22))
		_state_t = randf_range(1.5, 3.5)
	var d := _wander_target - global_position
	if d.length() > 4.0:
		velocity = velocity.move_toward(d.normalized() * speed_val * 0.35, 200 * _delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 200 * _delta)


func _do_chase(_delta: float) -> void:
	if player == null:
		return
	var to_p := player.global_position - global_position
	var dist := to_p.length()
	if dist > aggro_range * 1.7:
		_enter(S.IDLE)
		return
	if dist < aggro_range:
		velocity = velocity.move_toward(to_p.normalized() * speed_val, 240 * _delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 240 * _delta)
	if dist < _reach() and _attack_cd <= 0.0:
		perform_attack()


func _reach() -> float:
	return 20.0


## Family hook: pick and start an attack. Default: melee claw.
func perform_attack() -> void:
	_enter(S.ATTACK)
	_state_t = 0.45
	_attack_cd = randf_range(1.4, 2.2)
	maybe_quip()
	_do_melee(atk)


func _do_melee(dmg: int, status := "", steal := 0) -> void:
	if player and global_position.distance_to(player.global_position) < _reach() + 6.0:
		var dir := (player.global_position - global_position).normalized()
		player.take_damage(dmg, dir, status, steal)


func _check_contact_damage() -> void:
	if state == S.DEAD or _touch_cd > 0.0:
		return
	if player == null or not is_instance_valid(player) or player.is_dead():
		return
	var reach: float = float(stat_table[base_kind]["cell"]) * 0.30 + 8.0
	if global_position.distance_to(player.global_position) <= reach:
		_touch_cd = 0.8
		var dir := (player.global_position - global_position).normalized()
		player.take_contact_damage(maxi(1, int(atk * 0.5)), dir)


func maybe_quip() -> void:
	var line_ids := _quip_ids()
	if line_ids.is_empty() or rng.randf() > 0.22:
		return
	var d := DialogueDB.get_line(line_ids[rng.randi() % line_ids.size()])
	FX.pop_text(global_position + Vector2(0, -20), d["text"], Color("ffd23e"), 8)


func _quip_ids() -> Array[String]:
	return []


# ----------------------------------------------------------------- damage ----
func take_hit(dmg: int, knockback: Vector2, crit: bool, source := "player") -> void:
	if state == S.DEAD:
		return
	var final := maxi(1, dmg - int(defense * 0.25))
	hp -= final
	if source in ["player", "ability", "clone"] and GameState.character_id == "miggy":
		GameState.add_ultimate_charge(clampi(2 + final / 6, 2, 8))
	FX.damage_number(global_position + Vector2(0, -12), final, crit)
	AudioDirector.play_sfx("enemy_hurt")
	EventBus.screen_shake.emit(2.0, 0.08)
	_bar.visible = true
	_bar_hide = 2.0
	_update_bar()
	_flash()
	if hp <= 0:
		die()
	else:
		knock = knockback
		var prev := state
		_enter(S.HURT)
		_state_t = 0.24 if prev != S.DEAD else 0.0
		velocity = knockback


func _flash() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	sprite.modulate = Color(2.5, 2.5, 2.5)
	_flash_tween = create_tween()
	_flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)


func stun(duration: float) -> void:
	if state == S.DEAD:
		return
	_stun_t = maxf(_stun_t, duration)
	velocity = Vector2.ZERO
	FX.pop_text(global_position + Vector2(0, -22), "STUN", Color("2de3ff"), 8)


func apply_pull(center: Vector2, duration: float, speed: float) -> void:
	if state == S.DEAD:
		return
	_pull_center = center
	_pull_t = maxf(_pull_t, duration)
	_pull_speed = speed
	velocity = Vector2.ZERO


func is_dead() -> bool:
	return state == S.DEAD


func die() -> void:
	state = S.DEAD
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 1
	_play("death")
	_bar.visible = false
	FX.boom(global_position)
	AudioDirector.play_sfx("enemy_die")
	counters_on_death()
	LootSystem.on_enemy_died(self)
	EventBus.enemy_died.emit(kind.trim_suffix("_elite"), elite)
	if sprite.sprite_frames.get_animation_loop(sprite.animation):
		await get_tree().create_timer(0.5).timeout
	else:
		await sprite.animation_finished
	queue_free()


func counters_on_death() -> void:
	var k := kind.trim_suffix("_elite")
	GameState.counters["kills"][k] = GameState.counters["kills"].get(k, 0) + 1
	GameState.gain_xp(xp_reward)
