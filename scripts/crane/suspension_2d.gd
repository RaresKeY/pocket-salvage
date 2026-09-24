extends Node2D
## Caller-owned endpoint, collision geometry, controls, and attachment selection.
const Rope = preload("res://scripts/rope/rope_2d.gd")
var rope: Rope
var endpoint: CharacterBody2D
var anchor := Vector2.ZERO
var cable_length := 200.0
var gravity := 600.0
var spring := 90.0
var damping := 15.0
var max_force := 12000.0
var attached_body: RigidBody2D
var attachment_offset := Vector2.ZERO
var blocked := false
var enabled := true:
	set(value):
		enabled = value
		if not enabled: detach()

signal attachment_changed(body: RigidBody2D)

func configure(tip: CharacterBody2D, start: Vector2, length: float, polygons: Array[PackedVector2Array] = []) -> void:
	endpoint = tip
	anchor = start
	cable_length = length
	if rope == null:
		rope = Rope.new()
		add_child(rope)
	rope.configure(polygons)
	rope.exclude = [tip.get_rid()]
	rope.reset(anchor, endpoint.global_position, cable_length)

func attach(body: RigidBody2D, local_offset := Vector2.ZERO) -> bool:
	if not enabled or not is_instance_valid(body) or body.freeze: return false
	detach()
	attached_body = body
	attachment_offset = local_offset
	body.sleeping = false
	attachment_changed.emit(body)
	return true

func detach() -> void:
	if attached_body != null:
		if is_instance_valid(attached_body): attached_body.sleeping = false
		attached_body = null
		attachment_changed.emit(null)

func reset(tip_position: Vector2) -> void:
	detach()
	if not is_instance_valid(endpoint): return
	endpoint.global_position = tip_position
	endpoint.velocity = Vector2.ZERO
	rope.reset(anchor, tip_position, cable_length)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(endpoint) or rope == null: return
	endpoint.velocity.y += gravity * delta
	endpoint.move_and_slide()
	var constraint: Dictionary = rope.constrain_tip(anchor, endpoint.global_position, endpoint.velocity, cable_length)
	endpoint.velocity = constraint.velocity
	var correction: Vector2 = constraint.position - endpoint.global_position
	if correction.length_squared() > 0.0001:
		endpoint.move_and_collide(correction)
	blocked = constraint.blocked or endpoint.global_position.distance_to(constraint.position) > 1.0
	rope.step(anchor, endpoint.global_position, cable_length, delta)
	if not enabled: return
	if is_instance_valid(attached_body):
		attached_body.sleeping = false
		var offset := attachment_offset.rotated(attached_body.global_rotation)
		var point := attached_body.global_position + offset
		var point_velocity := attached_body.linear_velocity + Vector2(-offset.y, offset.x) * attached_body.angular_velocity
		var force := ((endpoint.global_position - point) * spring - (point_velocity - endpoint.velocity) * damping) * attached_body.mass
		attached_body.apply_force(force.limit_length(max_force), offset)
	elif attached_body != null:
		attached_body = null
		attachment_changed.emit(null)
