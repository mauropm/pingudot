extends EnemyBase
class_name SecBot
## Corporate Security Bot — charges like it means it, zaps from short range.


func _init() -> void:
	kind = "secbot"


func _quip_ids() -> Array[String]:
	return ["bot_1"]


func perform_attack() -> void:
	if rng.randf() < 0.6:
		# Charge attack
		_enter(S.ATTACK)
		_state_t = 0.6
		_attack_cd = randf_range(2.0, 3.0)
		maybe_quip()
		if player:
			var dir := (player.global_position - global_position).normalized()
			velocity = dir * speed_val * 4.5
			await get_tree().create_timer(0.3).timeout
			if is_instance_valid(self) and player and not is_dead():
				_do_melee(atk + 1)
	else:
		# Taser zap
		_enter(S.CAST)
		_state_t = 0.5
		_attack_cd = randf_range(2.4, 3.6)
		maybe_quip()
		await get_tree().create_timer(0.22).timeout
		if is_instance_valid(self) and player and not is_dead():
			var dir2 := (player.global_position - global_position).normalized()
			FX.shoot("fireball", global_position + dir2 * 8, dir2, atk, "enemy", 150.0, 90.0, false, "", 0, false, 1.4)
