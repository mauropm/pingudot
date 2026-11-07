extends Node
## EventBus — central signal hub so gameplay systems stay decoupled.

signal player_hp_changed(hp: int, max_hp: int)
signal player_energy_changed(en: int, max_en: int)
signal player_xp_changed(xp: int, need: int, level: int)
signal player_died
signal player_respawned
signal enemy_died(kind: String, elite: bool)
signal coins_changed(coins: int)
signal ability_unlocked(id: String)
signal ability_used(id: String)
signal ability_cooldown(id: String, remaining: float)
signal item_picked(item: Resource)
signal patch_collected(total: int)
signal area_entered(index: int, area_name: String)
signal checkpoint_reached(area: int, x: int, y: int)
signal objective_updated(text: String)
signal dialogue_requested(line_id: String)
signal dialogue_finished
signal boss_defeated
signal boss_phase_started(phase: int)
signal player_hit_without_damage_during_phase(phase: int)
signal achievement_unlocked(id: String, display_name: String)
signal interact_hint(text: String)
signal status_effect_applied(effect_id: String, duration: float)
signal screen_shake(strength: float, duration: float)
signal screen_flash(color: Color, duration: float)
signal music_requested(track: String)
signal player_damaged
signal sfx(name: String)
signal clear_cooldowns
