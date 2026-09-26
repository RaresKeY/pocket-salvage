extends "res://scripts/level/power_event.gd"
## Level 6's electrical storm: now and then a strike takes the yard's power out. Both floodlights and the beacons
## stutter with a crackle for WARNING seconds, then a strike blacks the yard out for 5 to 7 s: lights off, the yard
## near black between lightning flashes, and the magnet dead. The claw is not electric. Runs only while the round runs.
const FIRST_WAIT := Vector2(20, 30)
const WAIT := Vector2(35, 50)
const WARNING := 2.0
const OUTAGE := Vector2(5, 7)
const DARKEN := 0.3
const FADE := 1.0
var phase := &"waiting"
var wait := 0.0
var age := 0.0
var left := 0.0

func _begin() -> void:
	wait = rng.randf_range(FIRST_WAIT.x, FIRST_WAIT.y)

func _physics_process(delta: float) -> void:
	if context.round_state.state != &"running": return
	match phase:
		&"waiting":
			wait -= delta
			if wait <= 0.0: _warn()
		&"warning":
			age += delta
			_set_lights(stutter(age))
			if age >= WARNING: _black_out()
		&"out":
			left -= delta
			context.ambience.blackout = move_toward(context.ambience.blackout, 1.0, delta / DARKEN)
			if left <= 0.0: _recover()
			return
	context.ambience.blackout = move_toward(context.ambience.blackout, 0.0, delta / FADE)

func _set_lights(level: float) -> void:
	context.ambience.left_lamp_level = level
	context.ambience.right_lamp_level = level
	context.ambience.beacon_level = level

func _warn() -> void:
	phase = &"warning"
	age = 0.0
	context.sfx.play(&"crackle", -6.0)
	context._say("The lights are flickering. The power won't hold.", WARNING)

func _black_out() -> void:
	phase = &"out"
	left = rng.randf_range(OUTAGE.x, OUTAGE.y)
	_set_lights(0.0)
	context.weather.lightning.emit(rng.randf_range(200, 1000))
	context.sfx.play(&"power_down", -4.0)
	cut_power(left, "Blackout! The magnet is dead. The claw still works.")

func _recover() -> void:
	phase = &"waiting"
	wait = rng.randf_range(WAIT.x, WAIT.y)
	restore_power()
	_set_lights(1.0)
	context.sfx.play(&"power_up", -6.0)
	context._say("Power's back.", 2.0)
