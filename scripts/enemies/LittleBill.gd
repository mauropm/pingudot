extends EnemyBase
class_name LittleBill
## Little Bill — kiting mini-billionaire. Keeps his distance and monetizes you.
## Attacks: Forced Update (disc volley), Blue Screen (BSOD projectile → control
## loss), Licensing Fee (dash melee that steals coins).


func _init() -> void:
	kind = "littlebill"


func _quip_ids() -> Array[String]:
	return ["bill_1", "bill_2"]


func _do_chase(delta: float) -> void:
	if player == null:
		return
	var to_p := player.global_position - global_position
	var dist := to_p.length()
	if dist > aggro_range * 1.7:
		_enter(S.IDLE)
		return
	if dist > 0.1:
		var want := to_p.normalized()
		if dist < 52.0:
			want = -want            # back away — premium personal space
		elif dist < 78.0:
			want = want.rotated(deg_to_rad(90.0 * side_strafe()))
		velocity = velocity.move_toward(want * speed_val, 260 * delta)
	if dist < 120.0 and _attack_cd <= 0.0:
		perform_attack()


func side_strafe() -> float:
	return 1.0 if rng.randf() < 0.5 else -1.0


func perform_attack() -> void:
	var roll := rng.randf()
	if roll < 0.30:
		# Licensing Fee: dash + coin theft
		_enter(S.ATTACK)
		_state_t = 0.55
		_attack_cd = randf_range(2.6, 3.8)
		maybe_quip()
		if player:
			var dir := (player.global_position - global_position).normalized()
			velocity = dir * speed_val * 4.0
			await get_tree().create_timer(0.22).timeout
			if is_instance_valid(self) and player and not is_dead():
				_do_melee(atk, "", maxi(2, int(GameState.coins * 0.12)))
	elif roll < 0.65:
		# Blue Screen
		_enter(S.CAST)
		_state_t = 0.6
		_attack_cd = randf_range(3.2, 4.6)
		maybe_quip()
		await get_tree().create_timer(0.28).timeout
		if is_instance_valid(self) and player and not is_dead():
			var dir2 := (player.global_position - global_position).normalized()
			FX.shoot("bsod", global_position + dir2 * 10, dir2, atk - 2, "enemy",
				110.0, 60.0, false, "blue_screen", 0, false, 1.3)
	else:
		# Forced Update: 3 discs
		_enter(S.CAST)
		_state_t = 0.7
		_attack_cd = randf_range(2.2, 3.4)
		maybe_quip()
		await get_tree().create_timer(0.3).timeout
		if is_instance_valid(self) and player and not is_dead():
			var base := (player.global_position - global_position).normalized()
			for i in 3:
				var dir3 := base.rotated(deg_to_rad((i - 1) * 18.0))
				FX.shoot("disc", global_position + dir3 * 8, dir3, atk, "enemy", 145.0, 90.0, false, "", 0, false, 1.2)
