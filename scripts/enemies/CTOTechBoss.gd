extends EnemyBase
class_name CTOTechBoss
## THE CHIEF TECHNOLOGY OFFICER OF EVERYTHING — 3-phase final boss.
## Phase 1 CORPORATE STRATEGY: PowerPoint throws + security bot summons.
## Phase 2 AI TRANSFORMATION: hallucinated enemies + unpredictable volleys.
## Phase 3 SUBSCRIPTION APOCALYPSE: charges the player for actions + traps.
## The boss encounter is deterministic (seeded independently of the run).

signal phase_changed(phase: int)
signal boss_died

const PHASE_HP := [1.0, 0.66, 0.33]   # hp fractions where phases advance

var phase := 1
var _phase_cd := 2.2
var _summon_count := 0
var _traps: Array[Node] = []
var _paywall_tick := 0.0
var _aggro := false


func _init() -> void:
	kind = "cto"


func _ready() -> void:
	add_to_group("boss")
	super()
	aggro_range = 260.0
	rng.seed = 987654321   # deterministic boss tuning
	max_hp = 520
	hp = max_hp
	atk = 14
	defense = 4
	speed_val = 34.0
	xp_reward = 400


func _build_hp_bar(_cell: int) -> void:
	# Boss uses the HUD bar instead of the floating overhead bar.
	_bar = Node2D.new()
	_bar.visible = false
	add_child(_bar)
	_bar_fill = Sprite2D.new()
	_bar_fill.visible = false
	add_child(_bar_fill)


func scale_for_area(area: int) -> void:
	area_index = area  # no re-scaling for the boss


func _enter(s: S) -> void:
	super(s)
	if s == S.CHASE and not _aggro:
		_aggro = true


func _physics_process(delta: float) -> void:
	super(delta)
	# detect phase change
	var frac := float(hp) / float(max_hp)
	var target := 1
	if frac <= PHASE_HP[2]:
		target = 3
	elif frac <= PHASE_HP[1]:
		target = 2
	if target != phase:
		_advance_phase(target)
	if phase == 3:
		_paywall_tick -= delta
		if _paywall_tick <= 0.0:
			_paywall_tick = 8.0
			_start_paywall()


func _reach() -> float:
	return 46.0 if player == null else 46.0


func _advance_phase(p: int) -> void:
	phase = p
	match p:
		2:
			_play("idle2")
		3:
			_play("idle3")
			for t in _traps:
				if is_instance_valid(t):
					t.queue_free()
			_traps.clear()
		_:
			_play("idle")
	_phase_cd = 1.2
	AudioDirector.play_sfx("boss_intro")
	EventBus.screen_flash.emit(Color(0.9, 0.2, 0.9, 0.5), 0.5)
	EventBus.screen_shake.emit(7.0, 0.6)
	_summon_count = 0
	EventBus.boss_phase_started.emit(p)
	EventBus.dialogue_requested.emit(_dialogue_for_phase())
	phase_changed.emit(p)


func _dialogue_for_phase() -> String:
	match phase:
		1: return "cto_intro"
		2: return "cto_p2"
		3: return "cto_p3"
	return "cto_intro"


# ---------------------------------------------------------------- attacks ----
func perform_attack() -> void:
	if _phase_cd > 0.0:
		return
	match phase:
		1:
			_p1_attack()
		2:
			_p2_attack()
		3:
			_p3_attack()


func _p1_attack() -> void:
	_enter(S.CAST)
	_state_t = 0.8
	_phase_cd = randf_range(1.8, 2.8)
	_attack_cd = _phase_cd
	if rng.randf() < 0.45 and _summon_count < 4:
		# summon corporate security bots
		_summon_count += 1
		maybe_quip()
		_spawn_summon("secbot")
	else:
		# throw a slide (projectile)
		_spawn_summon("", 1)


func _p2_attack() -> void:
	_enter(S.CAST)
	_state_t = 0.8
	_phase_cd = randf_range(1.5, 2.4)
	_attack_cd = _phase_cd
	var roll := rng.randf()
	if roll < 0.4:
		_spawn_summon(_random_family())
	elif roll < 0.75:
		# unpredictable fan of 6 projectiles in random directions
		maybe_quip()
		for i in 6:
			var dir := Vector2.RIGHT.rotated(i * TAU / 6.0 + rng.randf())
			FX.shoot("shard", global_position + dir * 16, dir, atk, "enemy", 90.0)
		EventBus.sfx.emit("glitch")
	else:
		_spawn_summon("", 1)


func _p3_attack() -> void:
	_enter(S.CAST)
	_state_t = 0.9
	_phase_cd = randf_range(1.3, 2.0)
	_attack_cd = _phase_cd
	if _traps.size() < 3:
		_spawn_trap()
	else:
		# desperate barrage
		maybe_quip()
		var base := (player.global_position - global_position).normalized() if player else Vector2.RIGHT
		for i in 7:
			var dir := base.rotated(deg_to_rad((i - 3) * 16.0))
			FX.shoot("fireball", global_position + dir * 14, dir, atk, "enemy", 120.0)


func _spawn_summon(family: String, proj := 0) -> void:
	maybe_quip()
	var dir := (player.global_position - global_position).normalized() if player else Vector2.RIGHT
	if proj == 1:
		FX.shoot("disc", global_position + dir * 20, dir, atk + 2, "enemy", 120.0)
		return
	var parent := get_parent()
	var e: EnemyBase = null
	match family:
		"secbot":
			e = SecBot.new()
		"littlebill":
			e = LittleBill.new()
		"gplhipster":
			e = GplHipster.new()
		_:
			e = BSDemon.new()
	e.position = global_position + Vector2(randf_range(-30, 30), randf_range(-20, 20))
	parent.add_child(e)
	e.scale_for_area(area_index)


func _random_family() -> String:
	var fams := ["littlebill", "gplhipster", "secbot", "bsdemon"]
	return fams[rng.randi() % fams.size()]


func _spawn_trap() -> void:
	var t := SubTrap.new()
	t.position = global_position + Vector2(randf_range(-60, 60), randf_range(-40, 40))
	get_parent().add_child(t)
	_traps.append(t)


func _start_paywall() -> void:
	# Subscription Apocalypse: charge the player for every action for a time.
	if player and is_instance_valid(player):
		var fee := mini(5, GameState.coins)
		if fee > 0:
			GameState.add_coins(-fee)
			FX.pop_text(player.global_position + Vector2(0, -30), "-%d SUB FEE" % fee, Color("f7c94b"), 9)
		AudioDirector.play_sfx("paywall")
		EventBus.screen_flash.emit(Color(0.1, 0.2, 0.9, 0.3), 0.3)
	_phase_cd = 0.8


func _quip_ids() -> Array[String]:
	return ["cto_p1", "cto_intro"]


func die() -> void:
	if state == S.DEAD:
		return
	state = S.DEAD
	_play("death")
	AudioDirector.play_sfx("boss_die")
	EventBus.screen_shake.emit(10.0, 1.0)
	GameState.counters["boss_defeated"] = true
	GameState.gain_xp(xp_reward)
	EventBus.boss_defeated.emit()
	boss_died.emit()
	for t in _traps:
		if is_instance_valid(t):
			t.queue_free()
	for i in 6:
		FX.boom(global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30)))
	await get_tree().create_timer(1.4).timeout
	queue_free()


func take_hit(dmg: int, knockback: Vector2, crit: bool, source := "player") -> void:
	# Bosses aren't knocked back
	super(dmg, Vector2.ZERO, crit, source)
	if phase == 3 and rng.randf() < 0.4 and GameState.coins > 0:
		# PAY PER HIT™
		GameState.add_coins(-mini(2, GameState.coins))
		FX.pop_text(global_position + Vector2(randf_range(-16, 16), -40), "PAY PER HIT", Color("f7c94b"), 8)
		AudioDirector.play_sfx("paywall")


## Phase 3 charges on any attack the player throws at the boss.
func charge_paywall() -> void:
	if phase == 3:
		_start_paywall()


class SubTrap:
	extends Area2D
	## A floating subscription paywall box. Touching it stuns + charges coins.
	var _t := 0.0

	func _init() -> void:
		add_to_group("hazards")
		collision_layer = 128  # hazard
		collision_mask = 2
		var sp := Sprite2D.new()
		sp.texture = load("res://assets/ui/ability_segfault.png")
		sp.modulate = Color(0.9, 0.3, 0.5)
		add_child(sp)
		var sh := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(16, 16)
		sh.shape = r
		add_child(sh)
		body_entered.connect(_on_body)

	func _process(delta: float) -> void:
		_t += delta
		position += Vector2(sin(_t * 2.0), cos(_t * 1.6)) * 0.2
		scale = Vector2.ONE * (1.0 + sin(_t * 4.0) * 0.1)

	func _on_body(body: Node) -> void:
		if body is Player:
			body.take_damage(8, (body.global_position - global_position).normalized(), "blue_screen", mini(6, GameState.coins))
			queue_free()
