extends "res://scripts/level/level_event.gd"
## A level event that can take the yard's power down: the floodlights stutter first, then the lights and the
## electrically powered head stay off until it recovers.
const STUTTER := [1.0, 0.2, 0.85, 0.0, 0.45, 0.12, 0.7, 0.0]
const STUTTER_STEP := 0.2
var generator_running := true

## How long the whole stutter takes before it ends dark.
static func stutter_time() -> float:
	return STUTTER_STEP * STUTTER.size()

## An old bulb failing: lamp level at `age` seconds into the stutter, ending dark.
static func stutter(age: float) -> float:
	return STUTTER[mini(int(age / STUTTER_STEP), STUTTER.size() - 1)]

func cut_power(seconds: float, message: String) -> void:
	generator_running = false
	context.ambience.generator_running = false
	context.power_cut(seconds)
	context.say(message, seconds)

func restore_power() -> void:
	generator_running = true
	context.ambience.generator_running = true
