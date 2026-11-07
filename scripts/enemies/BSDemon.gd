extends EnemyBase
class_name BSDemon
## BSDemon — port-obsessed red imp. Attacks: Daemon Fire (aimed fireball),
## Fork Bomb (spread projectiles), Port Conflict (melee that slows the player).


func _init() -> void:
	kind = "bsdemon"


func _quip_ids() -> Array[String]:
	return ["bsdemon_1", "bsdemon_2"]


func perform_attack() -> void:
	var roll := rng.randf()
	var dist := global_position.distance_to(player.global_position) if player else 999.0
	if dist < 26.0 and roll < 0.5:
		# Port Conflict
		_enter(S.ATTACK)
		_state_t = 0.5
		_attack_cd = randf_range(2.0, 3.0)
		maybe_quip()
		_do_melee(atk, "port_conflict")
		return
	if roll < 0.45:
		# Daemon Fire: single aimed fireball
		_enter(S.CAST)
		_state_t = 0.6
		_attack_cd = randf_range(2.4, 3.6)
		maybe_quip()
		await get_tree().create_timer(0.25).timeout
		if is_instance_valid(self) and player and not is_dead():
			var dir := (player.global_position - global_position).normalized()
			FX.shoot("fireball", global_position + dir * 10, dir, atk + area_index * 2,
				"enemy", 125.0, 90.0, false, "", 0, false, 1.4)
	else:
		# Fork Bomb: 5-way spread
		_enter(S.CAST)
		_state_t = 0.7
		_attack_cd = randf_range(3.0, 4.5)
		maybe_quip()
		await get_tree().create_timer(0.3).timeout
		if is_instance_valid(self) and not is_dead():
			var base := (player.global_position - global_position).normalized() if player else Vector2.RIGHT
			for i in 5:
				var dir := base.rotated(deg_to_rad((i - 2) * 24.0))
				FX.shoot("fireball", global_position + dir * 8, dir, atk, "enemy", 105.0, 90.0, false, "", 0, false, 1.3)
