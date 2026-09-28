extends SceneTree
## Original deterministic PCM assets; execute through the managed Godot runner.
const AudioContext = preload("../../../_audio_context.gd")
var context := AudioContext.new()
var RATE := 44100
func _initialize() -> void:
	if not context.setup("supper-reward"):
		push_error(context.error)
		quit(2)
		return
	RATE = int(context.config.get("rate", 44100))
	for id in context.config.get("cues", {}):
		if context.destination(str(context.config.cues[id].file)).is_empty():
			push_error(context.error)
			quit(2)
			return
	for id in context.config.get("cues", {}):
		generate(id)
	if context.config.has("validation_image"):
		var image := Image.load_from_file(context.path(str(context.config.validation_image)))
		assert(image != null and not image.is_empty())
		print("CHEST_IMAGE size=", image.get_size(), " corner_alpha=", image.get_pixel(0, 0).a)
		assert(image.get_pixel(0, 0).a == 0.0)
	quit()

func generate(id: String) -> void:
	var cue: Dictionary = context.config.cues[id]
	var count := int(float(cue.duration)*RATE)
	var data := PackedByteArray()
	data.resize(count*2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(context.config.get("seed", 93714))
	var peak := 0.0
	for i in count:
		var t := float(i)/RATE
		var sample := 0.0
		if cue.kind == "tick":
			var frequency := float(cue.frequency)
			var decay := float(cue.decay)
			sample = (sin(TAU*frequency*t)*0.38+sin(TAU*frequency*2.7*t)*0.12)*exp(-t*decay)
			sample += rng.randf_range(-1,1)*0.2*exp(-t*250.0)
		else:
			var notes: Array = cue.notes
			for n in notes.size():
				var age := t-0.075-float(n)*0.09
				if age < 0.0: continue
				var envelope := minf(age/0.008,1.0)*exp(-age*float(cue.decay))
				var frequency: float = notes[n]
				sample += (sin(TAU*frequency*age)+0.25*sin(TAU*frequency*2.003*age)+0.08*sin(TAU*frequency*4.01*age))*envelope*0.12
		# Short ramps prevent discontinuities at both file boundaries.
		sample *= minf(1.0,minf(float(i)/44.0,float(count-1-i)/882.0))
		peak = maxf(peak,absf(sample))
		assert(absf(sample) < 0.95)
		data.encode_s16(i*2,int(sample*32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	var target := context.destination(str(cue.file))
	assert(not target.is_empty(), context.error)
	assert(DirAccess.make_dir_recursive_absolute(target.get_base_dir()) == OK)
	assert(stream.save_to_wav(target) == OK)
	print("REWARD_AUDIO_GENERATED ",id," frames=",count," peak=",peak)
