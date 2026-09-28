extends SceneTree
const AudioContext = preload("../../../_audio_context.gd")
var context := AudioContext.new()
## Deterministic quiet noise bed; run only through managed Godot.
func _initialize() -> void:
	if not context.setup("supper-simmer"):
		push_error(context.error)
		quit(2)
		return
	var target := context.destination(str(context.config.get("file", "simmer.wav")))
	if target.is_empty():
		push_error(context.error)
		quit(2)
		return
	assert(DirAccess.make_dir_recursive_absolute(target.get_base_dir()) == OK)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(context.config.get("rate", 22050))
	var count := int(float(context.config.get("duration", 2.0))*stream.mix_rate)
	var data := PackedByteArray()
	data.resize(count*2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(context.config.get("seed", 87234))
	var filtered := 0.0
	for i in count:
		var t := float(i)/float(stream.mix_rate)
		filtered = lerpf(filtered,rng.randf_range(-1.0,1.0),0.32)
		var envelope := (0.11+0.035*sin(TAU*t*3.0)) * minf(1.0,minf(i/220.0,(count-1-i)/220.0))
		var sample := int(clampf(filtered*envelope,-1,1)*32767)
		data.encode_s16(i*2,sample)
	stream.data = data
	assert(stream.save_to_wav(target) == OK)
	print("KITCHEN_SIMMER_GENERATED frames=",count)
	quit()
