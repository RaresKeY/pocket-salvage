extends Node
## Round-owned generator cycle; disables with world simulation while paused.
const STUTTER := [1.0, 0.2, 0.85, 0.0, 0.45, 0.12, 0.7, 0.0]
var context: Node
var rng := RandomNumberGenerator.new()
var wait := 0.0
var age := -1.0
var outage := 0.0
var generator_running := true

func configure(owner_context: Node, seed: int) -> void:
	context = owner_context
	rng.seed = seed
	wait = rng.randf_range(18, 32)

func _physics_process(delta: float) -> void:
	if age < 0:
		wait -= delta
		if wait <= 0:
			age = 0
			outage = rng.randf_range(2, 4)
		return
	age += delta
	if age < 1.6:
		context.ambience.right_lamp_level = STUTTER[mini(int(age / 0.2), STUTTER.size() - 1)]
	elif age < 1.6 + outage:
		if generator_running:
			generator_running = false
			context.ambience.generator_running = false
			context.power_cut(outage)
			context._say("Generator stopped. The claw lost power.", outage)
		context.ambience.right_lamp_level = 0.0
	else:
		generator_running = true
		context.ambience.generator_running = true
		context.ambience.right_lamp_level = 1.0
		age = -1.0
		wait = rng.randf_range(18, 32)
