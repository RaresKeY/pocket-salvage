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

func _ready() -> void:
	solver.sweep = _sweep

func configure(polygons: Array[PackedVector2Array]) -> void:
	solver.path.build(polygons)

func reset(anchor: Vector2, tip: Vector2, length: float) -> void:
	solver.reset(anchor, tip, length)
	queue_redraw()

func step(anchor: Vector2, tip: Vector2, length: float, delta: float) -> void:
	solver.simulate(anchor, tip, length, delta)
	queue_redraw()

func constrain_tip(anchor: Vector2, tip: Vector2, velocity: Vector2, length: float) -> Dictionary:
	return solver.constrain_tip(anchor, tip, velocity, length)

func _sweep(from: Vector2, to: Vector2) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(from, to, collision_mask, exclude)
	return get_world_2d().direct_space_state.intersect_ray(query)

func _draw() -> void:
	# Smooth each pinned span separately so corner contacts stay exact.
	for span in range(solver.pins.size() - 1):
		var points := solver.points.slice(solver.pins[span], solver.pins[span + 1] + 1)
		if smooth: points = Render.curve(points)
		for i in points.size(): points[i] = to_local(points[i])
		Render.draw_jacket(points, tint, self)
	if debug_points:
		for point in solver.points: draw_circle(to_local(point), 2.4, Color.WHITE)
		for point in solver.path.bends: draw_circle(to_local(point), 5.0, Color("ffc36a"))
