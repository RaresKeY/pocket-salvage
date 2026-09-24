extends SceneTree
const Rope = preload("res://scripts/rope/rope_2d.gd")
var rope: Node2D
var samples := 0
var ticks := 0
var between_tick_samples := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	assert(ProjectSettings.get_setting("physics/common/physics_interpolation"))
	rope = Rope.new()
	root.add_child(rope)
	rope.reset(Vector2(20,20),Vector2(20,120),140)
	physics_frame.connect(step_rope)
	process_frame.connect(check_render)

func step_rope() -> void:
	ticks += 1
	if ticks > 12: return
	rope.step(Vector2(20+ticks*3,20),Vector2(20+ticks*2,120),140,1.0/60)

func check_render() -> void:
	if ticks < 2: return
	var before: PackedVector2Array = rope.solver.points.duplicate()
	var history: PackedVector2Array = rope.solver.old_points.duplicate()
	var alpha: float = Engine.get_physics_interpolation_fraction()
	var displayed: PackedVector2Array = rope.rendered_points()
	if ticks <= 12:
		assert(displayed[0].is_equal_approx(rope.solver.render_previous[0].lerp(before[0],alpha)), "Rendered cable anchor must follow the native body interpolation fraction")
		assert(displayed[-1].is_equal_approx(rope.solver.render_previous[-1].lerp(before[-1],alpha)), "Rendered cable pivot must follow the same fraction")
		if alpha > 0.05 and alpha < 0.95: between_tick_samples += 1
	else:
		assert(displayed == before, "Paused stepping must not replay an old visual interval")
	assert(rope.solver.points == before and rope.solver.old_points == history, "Rendering must not mutate physics")
	samples += 1
	if ticks < 16: return
	assert(between_tick_samples > 4, "Sample actual render frames between 60 Hz physics ticks")
	rope.reset(Vector2(400,20),Vector2(420,120),140)
	assert(rope.rendered_points(0.25) == rope.solver.points, "Reset cannot leave a streak from the previous world position")
	rope.finish_interpolation()
	assert(rope.rendered_points(0.0) == rope.solver.points)
	print("ROPE_INTERPOLATION_TEST_OK samples=%d intermediate=%d" % [samples,between_tick_samples])
	quit()
