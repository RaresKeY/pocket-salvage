extends RefCounted
## Explicit, caller-authored collision parts. No default sizes, channels or game roles.

static func add_solid(body: PhysicsBody2D, shape: Shape2D, local_transform := Transform2D.IDENTITY) -> CollisionShape2D:
	if body == null or shape == null: return null
	var part := CollisionShape2D.new()
	# Each part owns its shape: tuning one object must not resize another.
	part.shape = shape.duplicate()
	part.transform = local_transform
	body.add_child(part)
	return part

static func add_sensor(parent: Node2D, shape: Shape2D, layer: int, mask: int, local_transform := Transform2D.IDENTITY) -> Area2D:
	if parent == null or shape == null: return null
	var sensor := Area2D.new()
	sensor.collision_layer = layer
	sensor.collision_mask = mask
	sensor.transform = local_transform
	var part := CollisionShape2D.new()
	part.shape = shape.duplicate()
	sensor.add_child(part)
	parent.add_child(sensor)
	return sensor

static func set_solid_enabled(part: CollisionShape2D, enabled: bool) -> void:
	# Safe when invoked from a physics overlap/contact signal.
	if is_instance_valid(part): part.set_deferred("disabled", not enabled)

static func set_sensor_enabled(sensor: Area2D, enabled: bool) -> void:
	if not is_instance_valid(sensor): return
	sensor.set_deferred("monitoring", enabled)
	sensor.set_deferred("monitorable", enabled)
