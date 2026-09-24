extends Node2D
## Reusable world-space rope. The caller owns and moves both endpoints at 60 Hz.
const Solver = preload("res://scripts/rope/rope_solver.gd")
const Render = preload("res://scripts/rope/rope_render.gd")
var solver := Solver.new()
@export_flags_2d_physics var collision_mask: int = 1
@export var tint := Color("a1e8c1")
@export var smooth := true
@export var debug_points := false
var exclude: Array[RID] = []
var _last_step_tick := -1

func _ready() -> void:
	# Particle positions are already in world space; interpolate them exactly once.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	solver.sweep = _sweep

func configure(polygons: Array[PackedVector2Array]) -> void:
	solver.path.build(polygons)

func reset(anchor: Vector2, tip: Vector2, length: float) -> void:
	solver.reset(anchor, tip, length)
	finish_interpolation()

func step(anchor: Vector2, tip: Vector2, length: float, delta: float) -> void:
	solver.simulate(anchor, tip, length, delta)
	_last_step_tick = Engine.get_physics_frames()
	queue_redraw()

func finish_interpolation() -> void:
	# Explicit teleports/pause finish the visual transition without changing physics.
	solver.render_previous = solver.points.duplicate()
	_last_step_tick = -1
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func rendered_points(fraction: float = -1.0) -> PackedVector2Array:
	var current: PackedVector2Array = solver.points.duplicate()
	if not ProjectSettings.get_setting("physics/common/physics_interpolation", false): return current
	if solver.render_previous.size() != current.size(): return current
	if fraction < 0.0:
		# A lab can pause stepping without pausing the scene tree. Do not replay the
		# last interval every new physics tick when that happens.
		if _last_step_tick != Engine.get_physics_frames(): return current
		fraction = Engine.get_physics_interpolation_fraction()
	fraction = clampf(fraction, 0.0, 1.0)
	for i in current.size():
		current[i] = solver.render_previous[i].lerp(current[i], fraction)
	return current

func constrain_tip(anchor: Vector2, tip: Vector2, velocity: Vector2, length: float) -> Dictionary:
	return solver.constrain_tip(anchor, tip, velocity, length)

func _sweep(from: Vector2, to: Vector2) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(from, to, collision_mask, exclude)
	return get_world_2d().direct_space_state.intersect_ray(query)

func _draw() -> void:
	var displayed := rendered_points()
	# Smooth each pinned span separately so corner contacts stay exact.
	for span in range(solver.pins.size() - 1):
		var points := displayed.slice(solver.pins[span], solver.pins[span + 1] + 1)
		if smooth: points = Render.curve(points)
		for i in points.size(): points[i] = to_local(points[i])
		Render.draw_jacket(points, tint, self)
	if debug_points:
		for point in displayed: draw_circle(to_local(point), 2.4, Color.WHITE)
		for point in solver.path.bends: draw_circle(to_local(point), 5.0, Color("ffc36a"))
