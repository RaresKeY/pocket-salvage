extends Node
## Plays the generated effects in assets/audio/ (see tools/audio/make_sfx.py) from a small voice pool.
const DIR := "res://assets/audio/"
## The one loop that follows the music volume and keeps playing when effects are off.
const MUSIC := &"music_yard"
const VOICES := 8
var _streams: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _next := 0
var played: Array[StringName] = []
var _silent := AudioServer.get_driver_name() == "Dummy"
var effects_enabled := true
var music_volume := 1.0
var effects_volume := 1.0
var output_bus: StringName = &"Master"
## Looping motors: name -> {player, level (0..1 target), current, pitch}.
var loops: Dictionary = {}
const LOOP_FLOOR_DB := -40.0
const LOOP_FADE := 6.0
const LOOP_DEAD_ZONE := 0.02

## Browser-managed buffers keep playing when the single-threaded game frame stalls.
## Native drivers retain their threaded stream mixer and bus-effect support.
static func playback_mode(web: bool = OS.has_feature("web")) -> AudioServer.PlaybackType:
	return AudioServer.PLAYBACK_TYPE_SAMPLE if web else AudioServer.PLAYBACK_TYPE_STREAM

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for index in VOICES: _voices.append(_player())

## Headless runs use the Dummy driver, which never mixes, so its playbacks would outlive the game.
func play(sound: StringName, volume_db: float = 0.0, pitch_jitter: float = 0.0) -> void:
	if not effects_enabled or effects_volume == 0.0: return
	played.append(sound)
	if played.size() > 256: played.pop_front()
	if _silent: return
	if not _streams.has(sound):
		_streams[sound] = load(_path(sound)) if ResourceLoader.exists(_path(sound)) else null
	if _streams[sound] == null or _voices.is_empty(): return
	var voice := _voices[_next]
	_next = (_next + 1) % _voices.size()
	voice.stream = _streams[sound]
	voice.set_meta("base_volume_db", volume_db)
	voice.volume_db = volume_db + _gain_db(effects_volume)
	voice.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	voice.play()

## Sets how hard a looping sound runs (0 silent, 1 full); volume eases toward it so it never clicks.
func set_loop(sound: StringName, level: float, pitch: float = 1.0, volume_db: float = -6.0) -> void:
	if not loops.has(sound):
		var player := _player()
		if ResourceLoader.exists(_path(sound)):
			var stream: AudioStreamWAV = load(_path(sound))
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
			if sound != MUSIC:
				loops[sound].player.stop()
				loops[sound].current = 0.0

## Independent session volumes; mute toggles never discard the chosen levels.
func set_volumes(music: float, effects: float) -> void:
	music_volume = clampf(music, 0.0, 1.0)
	effects_volume = clampf(effects, 0.0, 1.0)
	for voice in _voices:
		voice.volume_db = float(voice.get_meta("base_volume_db", 0.0)) + _gain_db(effects_volume)
		if effects_volume == 0.0: voice.stop()

static func _path(sound: StringName) -> String:
	return DIR + String(sound) + ".wav"

func _player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.playback_type = playback_mode()
	player.bus = output_bus
	add_child(player)
	return player

static func _gain_db(gain: float) -> float:
	return linear_to_db(gain) if gain > 0.0 else -80.0

func _process(delta: float) -> void:
	for sound in loops:
		var entry: Dictionary = loops[sound]
		if sound != MUSIC and not effects_enabled: continue
		entry.current = move_toward(entry.current, entry.level, LOOP_FADE * delta)
		var player: AudioStreamPlayer = entry.player
		if _silent or player.stream == null: continue
		var gain: float = music_volume if sound == MUSIC else effects_volume
		if entry.current <= 0.01 or gain == 0.0:
			if player.playing: player.stop()
			continue
		var volume := lerpf(LOOP_FLOOR_DB, entry.volume, sqrt(entry.current)) + _gain_db(gain)
		var pitch := lerpf(player.pitch_scale, entry.pitch * (0.85 + 0.15 * entry.current), minf(1.0, delta * 8.0))
		# Web Sample setters cross into the browser audio graph. Stable loops need
		# no new automation events; preserve fades/pitch changes while they settle.
		if not is_equal_approx(player.volume_db, volume): player.volume_db = volume
		if not is_equal_approx(player.pitch_scale, pitch): player.pitch_scale = pitch
		if not player.playing: player.play()

func _exit_tree() -> void:
	for entry in loops.values():
		entry.player.stop()
		entry.player.stream = null
	for voice in _voices:
		voice.stop()
		voice.stream = null
	_streams.clear()
