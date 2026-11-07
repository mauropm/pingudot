extends EnemyBase
class_name GplHipster
## GPL Hipster — slow trudge + perpetual stink aura.
## Attacks: Smell Cloud (passive DoT aura), Rant (text waves),
## License Violation (disables your equipment for a few seconds).

var _stink_tick := 0.0


func _init() -> void:
	kind = "gplhipster"


func _quip_ids() -> Array[String]:
	return ["hipster_1", "hipster_2"]


func _physics_process(delta: float) -> void:
	super(delta)
	if state == S.DEAD:
		return
	_stink_tick -= delta
	if player and not is_dead() and _stink_tick <= 0.0:
		if global_position.distance_to(player.global_position) < 26.0:
			_stink_tick = 1.1
			var dir := (player.global_position - global_position).normalized()
			player.apply_status("smell")
			FX.spawn_effect("stink", player.global_position + Vector2(0, -8))
			player.take_damage(2, dir, "", 0)


func perform_attack() -> void:
	var roll := rng.randf()
	if roll < 0.45:
		# Rant: distracting waves
		_enter(S.ATTACK)
		_state_t = 0.65
		_attack_cd = randf_range(2.6, 4.0)
		maybe_quip()
		await get_tree().create_timer(0.3).timeout
		if is_instance_valid(self) and player and not is_dead():
			var base := (player.global_position - global_position).normalized()
			for i in 3:
				var dir := base.rotated(deg_to_rad((i - 1) * 14.0))
				FX.shoot("wavetext", global_position + dir * 8, dir, atk, "enemy", 90.0, 90.0, false, "", 0, false, 1.2)
	elif roll < 0.75:
		# License Violation hex
		_enter(S.CAST)
		_state_t = 0.7
		_attack_cd = randf_range(4.0, 6.0)
		maybe_quip()
		await get_tree().create_timer(0.32).timeout
		if is_instance_valid(self) and player and not is_dead():
			var dir2 := (player.global_position - global_position).normalized()
			FX.shoot("stink", global_position + dir2 * 8, dir2, atk - 1, "enemy",
				110.0, 40.0, false, "license_violation", 0, false, 1.3)
	else:
		_enter(S.ATTACK)
		_state_t = 0.5
		_attack_cd = randf_range(1.8, 2.6)
		maybe_quip()
		_do_melee(atk)
