extends Node2D
## Massless tension-only cable acting at a caller-owned rigid body's pivot.
const Rope = preload("res://scripts/rope/rope_2d.gd")
const CableBody = preload("res://scripts/crane/cable_body_2d.gd")
var rope: Rope
var endpoint: CableBody
var anchor := Vector2.ZERO
var cable_length := 200.0
var pivot_local := Vector2(0,-16)
var load_mount_local := Vector2(0,16)
var angle_limit := deg_to_rad(35.0)
var spring := 90.0
var damping := 15.0
var max_force := 12000.0
var max_tension := 60000.0
var attached_body: RigidBody2D
var attachment_offset := Vector2.ZERO
var blocked := false
var tension := 0.0
var _previous_anchor := Vector2.ZERO
var _previous_length := 200.0
var enabled := true:
	set(value):
		enabled = value
		if not enabled: detach()

signal attachment_changed(body: RigidBody2D)

func configure(tip: CableBody, start: Vector2, length: float, polygons: Array[PackedVector2Array] = []) -> void:
	if is_instance_valid(endpoint): endpoint.integrate_cable = Callable()
	endpoint = tip
	anchor = start
	cable_length = maxf(2,length)
	_previous_anchor = anchor
	_previous_length = cable_length
	endpoint.integrate_cable = _integrate_endpoint
	if rope == null:
		rope = Rope.new()
		add_child(rope)
	rope.configure(polygons)
	rope.exclude = [tip.get_rid()]
	rope.reset(anchor,pivot_world(),cable_length)

func pivot_world() -> Vector2:
	return endpoint.to_global(pivot_local)

func attach(body: RigidBody2D, local_offset := Vector2.ZERO) -> bool:
	if not enabled or not is_instance_valid(body) or body == endpoint or body.freeze: return false
	detach()
	attached_body = body
	attachment_offset = local_offset
	body.sleeping = false
	endpoint.sleeping = false
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
	endpoint.rotation = 0
	endpoint.linear_velocity = Vector2.ZERO
	endpoint.angular_velocity = 0
	endpoint.sleeping = false
	_previous_anchor = anchor
	_previous_length = cable_length
	rope.reset(anchor,pivot_world(),cable_length)

func _integrate_endpoint(state: PhysicsDirectBodyState2D) -> void:
	var dt := state.step
	if dt <= 0: return
	var angle := wrapf(state.transform.get_rotation(),-PI,PI)
	var limit := clampf(angle_limit,0.0,PI)
	# A physical hard stop bounds tilt; ordinary swing is never repositioned.
	if absf(angle) > limit:
		angle = clampf(angle,-limit,limit)
		state.transform = Transform2D(angle,state.transform.origin)
		if state.angular_velocity * angle > 0: state.angular_velocity = 0
	var lever := pivot_local.rotated(angle)
	var pivot := state.transform.origin + lever
	var anchor_velocity := (anchor-_previous_anchor) / dt
	var reel_velocity := clampf((cable_length-_previous_length)/dt,-2000,2000)
	_previous_anchor = anchor
	_previous_length = cable_length
	# Wrapping guides, when supplied, are shared with the visual solver.
	rope.solver.path.update(anchor,pivot)
	var guides := rope.solver.path.guides(anchor,pivot)
	var support: Vector2 = guides[-2]
	var fixed_length: float = rope.solver.path.length_between(anchor,pivot) - support.distance_to(pivot)
	var radius := maxf(2,cable_length-fixed_length)
	var radial := pivot-support
	var distance := radial.length()
	blocked = fixed_length+2 > cable_length or distance > radius+8
	tension = 0.0
	if distance < 0.001: return
	var normal := radial/distance
	var error := distance-radius
	var support_velocity := anchor_velocity if guides.size()==2 else Vector2.ZERO
	var arm := lever-state.center_of_mass_local.rotated(angle)
	var point_velocity := state.linear_velocity + Vector2(-arm.y,arm.x)*state.angular_velocity
	# Predict default gravity (Godot integrates standard forces after this callback).
	var outward := (point_velocity + state.total_gravity*dt - support_velocity).dot(normal)-reel_velocity
	var bias := error * (0.25 if error>0 else 1.0) / dt
	var effective_inverse_mass := state.inverse_mass + pow(arm.cross(normal),2)*state.inverse_inertia
	if effective_inverse_mass > 0:
		var impulse := clampf((outward+bias)/effective_inverse_mass,0,max_tension*dt)
		state.apply_impulse(-normal*impulse,lever)
		tension = impulse/dt
	# Anticipatory angular stop prevents most overshoot before the hard cap.
	state.angular_velocity = clampf(state.angular_velocity,(-limit-angle)/dt,(limit-angle)/dt)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(endpoint) or rope == null: return
	endpoint.sleeping = false
	rope.step(anchor,pivot_world(),cable_length,delta)
	if not enabled: return
	if is_instance_valid(attached_body):
		attached_body.sleeping = false
		var offset := attachment_offset.rotated(attached_body.global_rotation)
		var point := attached_body.global_position+offset
		var mount := load_mount_local.rotated(endpoint.global_rotation)
		var target := endpoint.global_position+mount
		var point_velocity := attached_body.linear_velocity+Vector2(-offset.y,offset.x)*attached_body.angular_velocity
		var target_velocity := endpoint.linear_velocity+Vector2(-mount.y,mount.x)*endpoint.angular_velocity
		var force := ((target-point)*spring-(point_velocity-target_velocity)*damping)*attached_body.mass
		force = force.limit_length(max_force)
		attached_body.apply_force(force,offset)
		endpoint.apply_force(-force,mount)
	elif attached_body != null:
		attached_body = null
		attachment_changed.emit(null)

func _exit_tree() -> void:
	if is_instance_valid(endpoint): endpoint.integrate_cable = Callable()
