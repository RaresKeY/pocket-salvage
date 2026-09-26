extends "res://scripts/level/power_event.gd"
## Blood Moon's generator: after 18 to 32 s the right lamp stutters for 1.6 s, then the power is out for 2 to 4 s.
var wait := 0.0
var age := -1.0
var outage := 0.0

func _begin() -> void:
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
		context.ambience.right_lamp_level = stutter(age)
	elif age < 1.6 + outage:
		if generator_running: cut_power(outage, "Generator stopped. The claw lost power.")
		context.ambience.right_lamp_level = 0.0
	else:
		restore_power()
		context.ambience.right_lamp_level = 1.0
		age = -1.0
		wait = rng.randf_range(18, 32)
