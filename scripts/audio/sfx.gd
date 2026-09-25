extends Node
## Plays the generated effects in assets/audio/ (see tools/audio/make_sfx.py) from a small voice pool.
const DIR := "res://assets/audio/"
const VOICES := 8
var _streams: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _next := 0
var played: Array[StringName] = []
var _silent := AudioServer.get_driver_name() == "Dummy"
var effects_enabled := true
var output_bus: StringName = &"Master"
## Looping motors: name -> {player, level (0..1 target), current, pitch}.
var loops: Dictionary = {}
const LOOP_FLOOR_DB := -40.0
const LOOP_FADE := 6.0
const LOOP_DEAD_ZONE := 0.02

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for index in VOICES:
		var voice := AudioStreamPlayer.new()
		voice.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		voice.bus = output_bus
		add_child(voice)
		_voices.append(voice)

## Headless runs use the Dummy driver, which never mixes, so its playbacks would outlive the game.
func play(sound: StringName, volume_db: float = 0.0, pitch_jitter: float = 0.0) -> void:
	if not effects_enabled: return
	played.append(sound)
	if played.size() > 256: played.pop_front()
	if _silent: return
	if not _streams.has(sound):
		var path := DIR + String(sound) + ".wav"
		_streams[sound] = load(path) if ResourceLoader.exists(path) else null
	if _streams[sound] == null or _voices.is_empty(): return
	var voice := _voices[_next]
	_next = (_next + 1) % _voices.size()
	voice.stream = _streams[sound]
	voice.volume_db = volume_db
	voice.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	voice.play()

## Sets how hard a looping sound runs (0 silent, 1 full); volume eases toward it so it never clicks.
func set_loop(sound: StringName, level: float, pitch: float = 1.0, volume_db: float = -6.0) -> void:
	if not loops.has(sound):
		var player := AudioStreamPlayer.new()
		player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		player.bus = output_bus
		add_child(player)
		var path := DIR + String(sound) + ".wav"
		if ResourceLoader.exists(path):
			var stream: AudioStreamWAV = load(path)
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_end = int(stream.get_length() * stream.mix_rate)
			player.stream = stream
		loops[sound] = {"player": player, "level": 0.0, "current": 0.0, "pitch": 1.0, "volume": volume_db}
	var entry: Dictionary = loops[sound]
	entry.level = clampf(level, 0.0, 1.0) if level > LOOP_DEAD_ZONE else 0.0
	entry.pitch = pitch
	entry.volume = volume_db

func loop_level(sound: StringName) -> float:
	return loops[sound].level if loops.has(sound) else 0.0

func set_effects_enabled(value: bool) -> void:
	effects_enabled = value
	if not value:
		for voice in _voices: voice.stop()
		for sound in loops:
			if sound != &"music_yard":
				loops[sound].player.stop()
				loops[sound].current = 0.0

func _process(delta: float) -> void:
	for sound in loops:
		var entry: Dictionary = loops[sound]
		if sound != &"music_yard" and not effects_enabled: continue
		entry.current = move_toward(entry.current, entry.level, LOOP_FADE * delta)
		var player: AudioStreamPlayer = entry.player
		if _silent or player.stream == null: continue
		if entry.current <= 0.01:
			if player.playing: player.stop()
			continue
		player.volume_db = lerpf(LOOP_FLOOR_DB, entry.volume, sqrt(entry.current))
		player.pitch_scale = lerpf(player.pitch_scale, entry.pitch * (0.85 + 0.15 * entry.current), minf(1.0, delta * 8.0))
		if not player.playing: player.play()

func _exit_tree() -> void:
	for entry in loops.values():
		entry.player.stop()
		entry.player.stream = null
	for voice in _voices:
		voice.stop()
		voice.stream = null
	_streams.clear()
