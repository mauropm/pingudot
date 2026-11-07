extends Node
## FX — visual effect spawner + projectile factory. Lives at root, spawns into
## the current level's "effects" container so everything clears on transition.

const EFFECT_ATLAS := {
	"spark": "res://assets/effects/spark.png",
	"boom": "res://assets/effects/boom.png",
	"slash": "res://assets/effects/slash.png",
	"ring": "res://assets/effects/ring.png",
	"fireball": "res://assets/effects/fireball.png",
	"disc": "res://assets/effects/disc.png",
	"shard": "res://assets/effects/shard.png",
	"stink": "res://assets/effects/stink.png",
	"wavetext": "res://assets/effects/wavetext.png",
	"bsod": "res://assets/effects/bsod.png",
	"clone": "res://assets/effects/clone.png",
}

var _frames_cache: Dictionary = {}


func _container() -> Node2D:
	var c := get_tree().get_first_node_in_group("effects")
	return c


func toast(text: String, color := Color("f2f2f2")) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null:
		hud.toast(text, color)


## One-shot animated sprite effect from an atlas.
func spawn_effect(atlas_key: String, pos: Vector2, speed_mult := 1.0) -> AnimatedSprite2D:
	var parent := _container()
	if parent == null:
		return null
	if not _frames_cache.has(atlas_key):
		var path: String = EFFECT_ATLAS.get(atlas_key, atlas_key)
		if path == null or not ResourceLoader.exists(path):
			return null
		_frames_cache[atlas_key] = SpriteLib.build(path)
	var sf: SpriteFrames = _frames_cache[atlas_key]
	var anim_name := sf.get_animation_names()[0] if sf.get_animation_names().size() > 0 else ""
	if anim_name == "":
		return null
	var s := AnimatedSprite2D.new()
	s.sprite_frames = sf
	s.animation = anim_name
	s.speed_scale = speed_mult
	s.z_index = 20
	parent.add_child(s)
	s.position = pos
	s.play()
	s.animation_finished.connect(func(): s.queue_free())
	if not sf.get_animation_loop(anim_name):
		var t := get_tree().create_timer(1.2)
		t.timeout.connect(func():
			if is_instance_valid(s):
				s.queue_free())
	return s


func spawn_static(tex_path: String, pos: Vector2, z := 20) -> Sprite2D:
	var parent := _container()
	if parent == null or not ResourceLoader.exists(tex_path):
		return null
	var s := Sprite2D.new()
	s.texture = load(tex_path)
	s.z_index = z
	parent.add_child(s)
	s.position = pos
	return s


func spark(pos: Vector2) -> void:
	spawn_effect("spark", pos)


func boom(pos: Vector2) -> void:
	spawn_effect("boom", pos)


func slash_arc(pos: Vector2, dir: Vector2) -> void:
	var s := spawn_effect("slash", pos)
	if s and dir.x < 0:
		s.flip_h = true


func levelup_ring(pos: Vector2) -> void:
	spawn_effect("ring", pos)


## Floating damage number.
func damage_number(pos: Vector2, amount: int, crit := false, color := Color("f2f2f2")) -> void:
	var parent := _container()
	if parent == null:
		return
	var lbl := UISkin.label(str(amount), 16 if crit else 8,
		Color("f7e94b") if crit else color)
	if crit:
		lbl.text = "%d!" % amount
	lbl.z_index = 40
	lbl.position = pos + Vector2(randf_range(-4, 4), randf_range(-2, 2))
	parent.add_child(lbl)
	var t := lbl.create_tween()
	t.set_parallel(true)
	t.tween_property(lbl, "position:y", lbl.position.y - 18.0, 0.65)
	t.tween_property(lbl, "modulate:a", 0.0, 0.25).set_delay(0.4)
	t.chain().tween_callback(lbl.queue_free)


## Floating generic text (item names, hints).
func pop_text(pos: Vector2, text: String, color := Color.WHITE, size := 8) -> void:
	var parent := get_tree().get_first_node_in_group("effects")
	if parent == null:
		return
	var lbl := UISkin.label(text, size, color)
	lbl.z_index = 40
	lbl.position = pos
	parent.add_child(lbl)
	var t := lbl.create_tween()
	t.set_parallel(true)
	t.tween_property(lbl, "position:y", pos.y - 16.0, 0.6)
	t.tween_property(lbl, "modulate:a", 0.0, 0.25).set_delay(0.35)
	t.chain().tween_callback(lbl.queue_free)


## Launch a projectile (used by player ranged/abilities and enemies).
func shoot(frames_key: String, origin: Vector2, dir: Vector2, dmg: int,
		owner_kind := "player", speed := 150.0, kb := 90.0, pierce := false,
		status := "", coin_steal := 0, crit := false, vis_scale := 1.0) -> void:
	var parent := _container()
	if parent == null:
		return
	var p := Projectile.new()
	if not _frames_cache.has(frames_key):
		var path: String = EFFECT_ATLAS.get(frames_key, frames_key)
		if ResourceLoader.exists(path):
			_frames_cache[frames_key] = SpriteLib.build(path)
	if _frames_cache.has(frames_key):
		p.setup(_frames_cache[frames_key], dir, dmg, speed, owner_kind, kb, pierce, vis_scale)
	else:
		p.setup(null, dir, dmg, speed, owner_kind, kb, pierce, vis_scale)
	p.status_effect = status
	p.coin_steal = coin_steal
	p.crit = crit
	p.position = origin
	parent.add_child(p)


func spawn_clone(origin: Vector2, owner: Node, dmg: int, life := 6.0) -> void:
	var parent := _container()
	if parent == null:
		return
	if not _frames_cache.has("clone"):
		_frames_cache["clone"] = SpriteLib.build(EFFECT_ATLAS["clone"])
	var c := ForkBombClone.new()
	c.setup(_frames_cache["clone"], owner, dmg, life)
	c.position = origin
	parent.add_child(c)
