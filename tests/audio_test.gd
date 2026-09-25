extends SceneTree
const Sfx = preload("res://scripts/audio/sfx.gd")
const CUES := [&"ui_click", &"start", &"pickup", &"clank", &"claw_open", &"claw_shut", &"magnet_on", &"magnet_off", &"correct", &"wrong", &"eject", &"land", &"tick", &"finish", &"thunder"]

func _initialize() -> void: call_deferred("run")

func run() -> void:
	assert(Sfx.playback_mode(true) == AudioServer.PLAYBACK_TYPE_SAMPLE, "Web audio must not depend on main-thread streamed mixing")
	assert(Sfx.playback_mode(false) == AudioServer.PLAYBACK_TYPE_STREAM)
	AudioServer.set_bus_mute(0, true) # Mixer evidence without desktop noise.
	AudioServer.add_bus(1)
	AudioServer.set_bus_name(1, "Verification")
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 2.0
	AudioServer.add_bus_effect(1, capture)
	var sound := Sfx.new()
	sound.output_bus = &"Verification"
	root.add_child(sound)
	for voice in sound._voices:
		assert(voice.playback_type == Sfx.playback_mode(), "Players use the platform audio policy")
	var real := "--require-pulse" in OS.get_cmdline_user_args()
	if real: assert(AudioServer.get_driver_name() == "PulseAudio", "Real driver required")
	for cue in CUES + [&"trolley_loop", &"winch_loop", &"wind_loop", &"rain_loop", &"music_yard"]:
		var stream = load("res://assets/audio/%s.wav" % cue)
		assert(stream is AudioStreamWAV and stream.get_length() > 0.03)
		var playback = stream.instantiate_playback()
		playback.start()
		var peak := 0.0
		for batch in 8:
			for frame in playback.mix_audio(1.0, 8192): peak = maxf(peak, maxf(absf(frame.x), absf(frame.y)))
		playback.stop()
		assert(peak > 0.00001 and peak < 1.0, "Non-silent unclipped decoded audio: %s" % cue)
	for cue in CUES:
		for voice in sound._voices: voice.stop()
		if real: await create_timer(0.08).timeout
		capture.clear_buffer()
		sound.play(cue)
		assert(sound.played.back() == cue)
		if real:
			await create_timer(0.18).timeout
			check_mix(capture, cue)
	for cue in [&"trolley_loop", &"winch_loop", &"wind_loop", &"rain_loop", &"music_yard"]:
		for voice in sound._voices: voice.stop()
		if real: await create_timer(0.08).timeout
		capture.clear_buffer()
		sound.set_loop(cue, 1.0)
		if real:
			await create_timer(0.4).timeout
			check_mix(capture, cue)
		sound.set_loop(cue, 0.0)
		await create_timer(0.2).timeout
	sound.set_loop(&"music_yard", 1.0)
	sound.set_effects_enabled(false)
	var before: int = sound.played.size()
	sound.play(&"pickup")
	assert(sound.played.size() == before and sound.loop_level(&"music_yard") == 1.0, "SFX mute leaves music enabled")
	sound.set_effects_enabled(true)
	sound.play(&"pickup")
	assert(sound.played.back() == &"pickup")
	sound.set_volumes(0.25, 0.5)
	assert(sound.music_volume == 0.25 and sound.effects_volume == 0.5)
	assert(is_equal_approx(Sfx._gain_db(0.5), -6.0206))
	assert(is_equal_approx(sound._voices[0].volume_db, float(sound._voices[0].get_meta("base_volume_db", 0.0)) - 6.0206), "Live voices retain their base mix and apply the SFX level")
	sound.set_effects_enabled(false)
	sound.set_effects_enabled(true)
	assert(sound.effects_volume == 0.5 and sound.music_volume == 0.25, "Mute does not discard slider levels")
	sound.set_volumes(0.25, 0.0)
	before = sound.played.size()
	sound.play(&"pickup")
	assert(sound.played.size() == before, "Zero SFX volume is silent")
	sound.set_volumes(-1.0, 2.0)
	assert(sound.music_volume == 0.0 and sound.effects_volume == 1.0, "Volume API clamps values")
	sound.free()
	root.size = Vector2i(854, 480)
	var lab = load("res://labs/audio/lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	await process_frame
	var grid: GridContainer = lab.get_child(1).get_child(0).get_child(0)
	assert(grid.get_child_count() == 17, "Audio lab exposes every cue and loop")
	for button in grid.get_children():
		assert(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(button.get_global_rect()))
	lab.free()
	AudioServer.remove_bus(1)
	print("AUDIO_TEST_OK driver=", AudioServer.get_driver_name())
	quit()

func check_mix(capture: AudioEffectCapture, cue: StringName) -> void:
	var frames := capture.get_buffer(capture.get_frames_available())
	var peak := 0.0
	for frame in frames: peak = maxf(peak, maxf(absf(frame.x), absf(frame.y)))
	assert(frames.size() > 0 and peak > 0.00001 and peak < 1.0, "Actual mixer output: %s" % cue)
	print("AUDIO_MIX cue=%s frames=%d peak=%f" % [cue, frames.size(), peak])
