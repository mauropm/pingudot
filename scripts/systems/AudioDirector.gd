extends Node
## AudioDirector — music crossfade + SFX pooling on Master/Music/SFX buses.

const SFX_DIR := "res://assets/audio/sfx"
const MUSIC_DIR := "res://assets/audio/music"

# Explicit lists (not directory scans) so exported builds reliably include and
# load every stream, including on the Web platform where res:// is packed.
const SFX_NAMES := [
	"step", "jump", "slash", "shoot", "hurt", "enemy_hurt", "enemy_die", "boom",
	"coin", "heal", "energy", "item_get", "levelup", "ui_move", "ui_ok", "ui_back",
	"kernelpanic", "forkbomb", "rootaccess", "segfault", "fireball", "penguin",
	"save", "door", "hazard", "blue", "stink", "boss_intro", "boss_hurt",
	"boss_die", "victory", "ocean", "glitch", "paywall", "engine", "achievement",
]
const MUSIC_NAMES := [
	"menu", "area1", "area2", "area3", "area4", "area5", "boss", "ending",
	"credits", "gameover",
]
const NON_LOOPING := ["gameover"]

var _sfx_streams: Dictionary = {}
var _music_streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_players := []
var _current_track := ""
var _tween: Tween

var master_volume := 1.0
var music_volume := 0.8
var sfx_volume := 0.9
var muted := false


func _ready() -> void:
	_load_streams()
	_music_a = _make_music_player()
	_music_b = _make_music_player()
	_music_players = [_music_a, _music_b]
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_apply_buses()


func _load_streams() -> void:
	for n: String in SFX_NAMES:
		var p := "%s/%s.wav" % [SFX_DIR, n]
		if ResourceLoader.exists(p):
			_sfx_streams[n] = load(p)
	for n: String in MUSIC_NAMES:
		var p := "%s/%s.wav" % [MUSIC_DIR, n]
		if not ResourceLoader.exists(p):
			push_warning("AudioDirector: missing track " + p)
			continue
		var s: AudioStreamWAV = load(p)
		if n in NON_LOOPING:
			s.loop_mode = AudioStreamWAV.LOOP_DISABLED
		else:
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_begin = 0
			# Loop points are in samples regardless of import compression
			# (Godot's WAV importer uses QOA by default), so derive the end
			# from the stream duration rather than the byte count.
			s.loop_end = int(round(s.get_length() * s.mix_rate))
		_music_streams[n] = s
	print("AudioDirector: %d sfx, %d tracks" % [_sfx_streams.size(), _music_streams.size()])


func _make_music_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "Music"
	add_child(p)
	return p


func play_music(track: String, crossfade := 0.6) -> void:
	if track == _current_track:
		return
	if not _music_streams.has(track):
		push_warning("Missing music track: " + track)
		return
	_current_track = track
	var idle: AudioStreamPlayer = _music_players[0] if not _music_players[0].playing else _music_players[1]
	var busy: AudioStreamPlayer = _music_players[1] if idle == _music_players[0] else _music_players[0]
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(busy, "volume_db", -40.0, crossfade)
	idle.stream = _music_streams[track]
	idle.volume_db = -40.0
	idle.play()
	t.tween_property(idle, "volume_db", 0.0, crossfade)
	t.chain().tween_callback(func(): busy.stop())


func stop_music(fade := 0.5) -> void:
	_current_track = ""
	for p in _music_players:
		if p.playing:
			var t := create_tween()
			t.tween_property(p, "volume_db", -40.0, fade)
			t.chain().tween_callback(p.stop)


func play_sfx(name: String, vol_db := 0.0, pitch_jitter := 0.06) -> void:
	if not _sfx_streams.has(name):
		return
	for p in _pool:
		if not p.playing:
			p.stream = _sfx_streams[name]
			p.volume_db = vol_db
			p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
			p.play()
			return


func has_sfx(name: String) -> bool:
	return _sfx_streams.has(name)


func set_volumes(master: float, music: float, sfx: float) -> void:
	master_volume = clampf(master, 0.0, 1.0)
	music_volume = clampf(music, 0.0, 1.0)
	sfx_volume = clampf(sfx, 0.0, 1.0)
	_apply_buses()


func _apply_buses() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume) if not muted else -80.0)
	AudioServer.set_bus_volume_db(1, linear_to_db(music_volume))
	AudioServer.set_bus_volume_db(2, linear_to_db(sfx_volume))


func set_muted(v: bool) -> void:
	muted = v
	_apply_buses()


func to_settings() -> Dictionary:
	return {"master": master_volume, "music": music_volume, "sfx": sfx_volume, "muted": muted}


func from_settings(s: Dictionary) -> void:
	master_volume = float(s.get("master", 1.0))
	music_volume = float(s.get("music", 0.8))
	sfx_volume = float(s.get("sfx", 0.9))
	muted = bool(s.get("muted", false))
	_apply_buses()
