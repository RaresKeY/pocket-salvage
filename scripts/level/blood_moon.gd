extends "res://scripts/level/power_event.gd"
## Blood Moon's generator: after WAIT the right lamp stutters, then the power is out for OUTAGE, then it recovers.
const WAIT := Vector2(18, 32)
const OUTAGE := Vector2(2, 4)
var wait := 0.0
var age := -1.0
var outage := 0.0

func _begin() -> void:
	wait = roll(WAIT)

func _physics_process(delta: float) -> void:
	if age < 0:
		wait -= delta
		if wait <= 0:
			age = 0
			outage = roll(OUTAGE)
		return
	age += delta
	if age < stutter_time():
		context.ambience.right_lamp_level = stutter(age)
	elif age < stutter_time() + outage:
		if generator_running: cut_power(outage, "Generator stopped. The claw lost power.")
		context.ambience.right_lamp_level = 0.0
	else:
		restore_power()
		context.ambience.right_lamp_level = 1.0
		age = -1.0
		wait = roll(WAIT)
