class_name SpriteLib
## Builds SpriteFrames from a packed atlas + JSON manifest written by the
## Python art tools (see tools/art/*.py). Keeps all sprite slicing in one place.


static func load_manifest(atlas_path: String) -> Dictionary:
	var mp := atlas_path.rsplit(".", true, 1)[0] + "_manifest.json"
	if not FileAccess.file_exists(mp):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(mp))
	if d is Dictionary:
		return d.get("anims", {})
	return {}


static func build(atlas_path: String) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var tex := load(atlas_path) as Texture2D
	var anims := load_manifest(atlas_path)
	for name: String in anims.keys():
		var a: Dictionary = anims[name]
		var cw: int = a["cell"][0]
		var ch: int = a["cell"][1]
		frames.add_animation(name)
		frames.set_animation_loop(name, a["loop"])
		frames.set_animation_speed(name, a["fps"])
		for i in range(a["frames"]):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * cw, a["row_y"], cw, ch)
			frames.add_frame(name, at)
	return frames


static func atlas_texture(atlas_path: String, anim: String, frame: int = 0) -> AtlasTexture:
	var tex := load(atlas_path) as Texture2D
	var anims := load_manifest(atlas_path)
	var a: Dictionary = anims[anim]
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(frame * a["cell"][0], a["row_y"], a["cell"][0], a["cell"][1])
	return at


static func has_anim(anims: Dictionary, name: String) -> bool:
	return anims.has(name)
