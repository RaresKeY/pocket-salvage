extends SceneTree

const AudioContext = preload("../../_audio_context.gd")
var context := AudioContext.new()
var OUT_DIR := ""
var SAMPLE_RATE := 44100


func _initialize() -> void:
	if not context.setup("crs-feedback"):
		push_error(context.error)
		quit(2)
		return
	OUT_DIR = context.output()
	SAMPLE_RATE = int(context.config.get("rate", 44100))
	for job in context.config.get("jobs", []):
		if context.destination(str(job.file)).is_empty() or str(job.kernel) not in ["_menu_click_data", "_checkbox_click_data", "_door_traversal_data", "_jump_data"]:
			push_error(context.error + " invalid feedback job")
			quit(2)
			return
	assert(DirAccess.make_dir_recursive_absolute(OUT_DIR) == OK)
	for job in context.config.get("jobs", []):
		_write_clip(str(job.file), call(str(job.kernel)))
	print("Generated project audio feedback SFX clips.")
	quit(0)


func _write_clip(file_name: String, data: PackedByteArray) -> void:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	var target := context.destination(file_name)
	assert(not target.is_empty(), context.error)
	assert(stream.save_to_wav(target) == OK)


func _menu_click_data() -> PackedByteArray:
	var duration := 0.13
	var sample_count := int(SAMPLE_RATE * duration)
	var bytes := _empty_audio_bytes(sample_count)
	var state := 24857
	var filtered_noise := 0.0
	for i in range(sample_count):
		var t := float(i) / float(SAMPLE_RATE)
		state = _next_noise_state(state)
		var raw_noise := _noise_value(state)
		filtered_noise = filtered_noise * 0.74 + raw_noise * 0.26
		var body := sin(TAU * 255.0 * t) * _decay_envelope(t, 0.004, 34.0) * 0.17
		var felt := sin(TAU * 430.0 * t) * _decay_envelope(t, 0.006, 40.0) * 0.075
		var soft_tick := filtered_noise * _decay_envelope(t, 0.003, 58.0) * 0.055
		var tail := sin(TAU * 165.0 * t) * _pulse_envelope(t, 0.038, 0.085) * 0.06
		var sample := clampf((body + felt + soft_tick + tail) * _tail_gate(t, duration, 0.032), -0.72, 0.72)
		bytes.encode_s16(i * 2, int(round(sample * 32767.0)))
	return bytes


func _checkbox_click_data() -> PackedByteArray:
	var duration := 0.10
	var sample_count := int(SAMPLE_RATE * duration)
	var bytes := _empty_audio_bytes(sample_count)
	var state := 31847
	var filtered_noise := 0.0
	for i in range(sample_count):
		var t := float(i) / float(SAMPLE_RATE)
		state = _next_noise_state(state)
		var raw_noise := _noise_value(state)
		filtered_noise = filtered_noise * 0.68 + raw_noise * 0.32
		var body := sin(TAU * 390.0 * t) * _decay_envelope(t, 0.003, 48.0) * 0.075
		var tick := filtered_noise * _decay_envelope(t, 0.002, 86.0) * 0.045
		var settle := sin(TAU * 210.0 * t) * _pulse_envelope(t, 0.030, 0.060) * 0.040
		var sample := clampf((body + tick + settle) * 0.70 * _tail_gate(t, duration, 0.024), -0.46, 0.46)
		bytes.encode_s16(i * 2, int(round(sample * 32767.0)))
	return bytes


func _door_traversal_data() -> PackedByteArray:
	var duration := 0.46
	var sample_count := int(SAMPLE_RATE * duration)
	var bytes := _empty_audio_bytes(sample_count)
	var state := 79133
	var filtered_noise := 0.0
	for i in range(sample_count):
		var t := float(i) / float(SAMPLE_RATE)
		state = _next_noise_state(state)
		var raw_noise := _noise_value(state)
		filtered_noise = filtered_noise * 0.86 + raw_noise * 0.14
		var whoosh := filtered_noise * _pulse_envelope(t, 0.18, 0.30) * 0.18
		var hinge := sin(TAU * _pitch_slide(t, 165.0, 96.0, 0.36) * t) * _pulse_envelope(t, 0.22, 0.32) * 0.16
		var body := sin(TAU * 82.0 * t) * _pulse_envelope(t, 0.34, 0.18) * 0.13
		var latch := sin(TAU * 118.0 * t) * _decay_after(t, 0.330, 0.010, 20.0) * 0.09
		var felt := filtered_noise * _decay_after(t, 0.338, 0.012, 30.0) * 0.035
		var sample := clampf((whoosh + hinge + body + latch + felt) * _tail_gate(t, duration, 0.075), -0.76, 0.76)
		bytes.encode_s16(i * 2, int(round(sample * 32767.0)))
	return bytes


func _jump_data() -> PackedByteArray:
	var duration := 0.22
	var sample_count := int(SAMPLE_RATE * duration)
	var bytes := _empty_audio_bytes(sample_count)
	var state := 55381
	var filtered_noise := 0.0
	for i in range(sample_count):
		var t := float(i) / float(SAMPLE_RATE)
		state = _next_noise_state(state)
		var raw_noise := _noise_value(state)
		filtered_noise = filtered_noise * 0.72 + raw_noise * 0.28
		var lift := sin(TAU * _pitch_slide(t, 150.0, 255.0, 0.17) * t) * _pulse_envelope(t, 0.068, 0.17) * 0.17
		var push := sin(TAU * 310.0 * t) * _decay_envelope(t, 0.006, 33.0) * 0.075
		var cloth := filtered_noise * _pulse_envelope(t, 0.070, 0.145) * 0.060
		var sample := clampf((lift + push + cloth) * _tail_gate(t, duration, 0.050), -0.66, 0.66)
		bytes.encode_s16(i * 2, int(round(sample * 32767.0)))
	return bytes


func _empty_audio_bytes(sample_count: int) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	return bytes


func _next_noise_state(state: int) -> int:
	return int((1103515245 * state + 12345) & 0x7fffffff)


func _noise_value(state: int) -> float:
	return (float(state) / 1073741824.0) - 1.0


func _decay_envelope(t: float, attack: float, decay: float) -> float:
	var attack_gain := clampf(t / maxf(attack, 0.0001), 0.0, 1.0)
	return attack_gain * exp(-t * decay)


func _decay_after(t: float, start: float, attack: float, decay: float) -> float:
	if t < start:
		return 0.0
	return _decay_envelope(t - start, attack, decay)


func _pulse_envelope(t: float, center: float, width: float) -> float:
	var x: float = absf(t - center) / maxf(width, 0.0001)
	return pow(clampf(1.0 - x, 0.0, 1.0), 2.0)


func _pitch_slide(t: float, start_hz: float, end_hz: float, seconds: float) -> float:
	var amount := clampf(t / maxf(seconds, 0.0001), 0.0, 1.0)
	return lerpf(start_hz, end_hz, amount)


func _tail_gate(t: float, duration: float, release_seconds: float) -> float:
	var release_start := duration - release_seconds
	if t <= release_start:
		return 1.0
	return clampf((duration - t) / maxf(duration - release_start, 0.0001), 0.0, 1.0)
