extends SceneTree

const AudioContext = preload("../../_audio_context.gd")
var context := AudioContext.new()
var OUT_PATH := ""
var SAMPLE_RATE := 44100
var DURATION_SECONDS := 0.28


func _initialize() -> void:
	if not context.setup("crs-button"):
		push_error(context.error)
		quit(2)
		return
	SAMPLE_RATE = int(context.config.get("rate", 44100))
	DURATION_SECONDS = float(context.config.get("duration", .28))
	OUT_PATH = context.destination(str(context.config.get("file", "button.wav")))
	if OUT_PATH.is_empty():
		push_error(context.error)
		quit(2)
		return
	assert(DirAccess.make_dir_recursive_absolute(OUT_PATH.get_base_dir()) == OK)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = _clip_data()
	assert(stream.save_to_wav(OUT_PATH) == OK)
	print("Generated diegetic button SFX: %s" % (ProjectSettings.localize_path(OUT_PATH) if context.root_path == ProjectSettings.globalize_path("res://").trim_suffix("/") else OUT_PATH))
	quit(0)


func _clip_data() -> PackedByteArray:
	var sample_count := int(SAMPLE_RATE * DURATION_SECONDS)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var state := 74291
	var filtered_noise := 0.0
	for i in range(sample_count):
		var t := float(i) / float(SAMPLE_RATE)
		state = int((1103515245 * state + 12345) & 0x7fffffff)
		var raw_noise := (float(state) / 1073741824.0) - 1.0
		filtered_noise = filtered_noise * 0.46 + raw_noise * 0.54
		var click := filtered_noise * _decay_envelope(t, 0.0008, 165.0) * 0.22
		var plasticky_knock := sin(TAU * 310.0 * t) * _pulse_envelope(t, 0.018, 0.032) * 0.42
		var goofy_pop := sin(TAU * _pitch_slide(t, 720.0, 390.0, 0.12) * t) * _decay_envelope(t, 0.004, 16.0) * 0.46
		var spring := sin(TAU * 1240.0 * t) * _pulse_envelope(t, 0.072, 0.072) * 0.16
		var low_body := sin(TAU * 118.0 * t) * _pulse_envelope(t, 0.105, 0.12) * 0.24
		var sample := clampf((click + plasticky_knock + goofy_pop + spring + low_body) * _tail_gate(t), -0.92, 0.92)
		bytes.encode_s16(i * 2, int(round(sample * 32767.0)))
	return bytes


func _decay_envelope(t: float, attack: float, decay: float) -> float:
	var attack_gain := clampf(t / maxf(attack, 0.0001), 0.0, 1.0)
	return attack_gain * exp(-t * decay)


func _pulse_envelope(t: float, center: float, width: float) -> float:
	var x: float = absf(t - center) / maxf(width, 0.0001)
	return pow(clampf(1.0 - x, 0.0, 1.0), 2.0)


func _pitch_slide(t: float, start_hz: float, end_hz: float, seconds: float) -> float:
	var amount := clampf(t / maxf(seconds, 0.0001), 0.0, 1.0)
	return lerpf(start_hz, end_hz, amount)


func _tail_gate(t: float) -> float:
	var release_start := DURATION_SECONDS - 0.045
	if t <= release_start:
		return 1.0
	return clampf((DURATION_SECONDS - t) / maxf(DURATION_SECONDS - release_start, 0.0001), 0.0, 1.0)
