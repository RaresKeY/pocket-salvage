extends Node
## Plays the generated effects in assets/audio/ (see tools/audio/make_sfx.py) from a small voice pool.
const DIR := "res://assets/audio/"
const VOICES := 8
var _streams: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _next := 0
var played: Array[StringName] = []
var _silent := AudioServer.get_driver_name() == "Dummy"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for index in VOICES:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		_voices.append(voice)

## Headless runs use the Dummy driver, which never mixes, so its playbacks would outlive the game.
func play(sound: StringName, volume_db: float = 0.0, pitch_jitter: float = 0.0) -> void:
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

func _exit_tree() -> void:
	for voice in _voices:
		voice.stop()
		voice.stream = null
	_streams.clear()
