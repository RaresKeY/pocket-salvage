extends RigidBody2D
## Physical suspended endpoint; caller supplies shape, art and connection offsets.
var integrate_cable := Callable()

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if integrate_cable.is_valid(): integrate_cable.call(state)
