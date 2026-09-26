extends Node
## A round-owned event that can take the yard's power down: the floodlights stutter first, then the lights and the
## electrically powered head stay off until it recovers. Pauses with the world.
const STUTTER := [1.0, 0.2, 0.85, 0.0, 0.45, 0.12, 0.7, 0.0]
const STUTTER_STEP := 0.2
var context: Node
var rng := RandomNumberGenerator.new()
var generator_running := true

func configure(owner_context: Node, seed: int) -> void:
	context = owner_context
	rng.seed = seed
	_begin()

func _begin() -> void:
	pass

## An old bulb failing: lamp level at `age` seconds into the stutter, ending dark.
static func stutter(age: float) -> float:
	return STUTTER[mini(int(age / STUTTER_STEP), STUTTER.size() - 1)]

func cut_power(seconds: float, message: String) -> void:
	generator_running = false
	context.ambience.generator_running = false
	context.power_cut(seconds)
	context._say(message, seconds)

func restore_power() -> void:
	generator_running = true
	context.ambience.generator_running = true
