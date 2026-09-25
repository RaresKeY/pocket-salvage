extends SceneTree
const Motes = preload("res://scripts/weather/effects/wind_trails.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var motes = Motes.new()
	root.add_child(motes)
	motes.set_process(false)
	motes.configure(Rect2(0,0,1200,440))
	var before: Vector2 = motes.trails[1].at
	for i in 30: motes._process(1.0/60.0)
	var after: Vector2 = motes.trails[1].at
	assert(after.x > before.x and after.y != before.y)
	var old_points: Array = motes.trails[1].points.duplicate(true)
	motes.direction = -1
	motes._process(1.0/60.0)
	assert(motes.trails[1].at.x < after.x and motes.trails[1].at.distance_to(after) < 5)
	assert(motes.trails[1].points[0].at == old_points[0].at)
	assert(motes.tail_alpha(0) > motes.tail_alpha(Motes.TAIL_SECONDS * 0.5) and motes.tail_alpha(Motes.TAIL_SECONDS) == 0)
	assert(Motes.TAIL_SECONDS >= 4.0, "Tail is substantially longer than the former 1.2 seconds")
	assert(motes.tail_width(0, 5) == 5 and motes.tail_width(Motes.TAIL_SECONDS, 5) == 0)
	assert(motes.tail_width(1, 5) > motes.tail_width(2, 5))
	motes.strength = 1.0
	assert(motes.opacity() <= 0.12, "Even strong wind remains faint")
	var arrays: Array = motes.ribbon_arrays(motes.trails[1])
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var count := vertices.size()
	assert(is_equal_approx(vertices[count-2].y - vertices[count-3].y, motes.trails[1].head_width), "Front and tail share one width")
	assert(vertices[count-2].x == vertices[count-3].x, "Leading edge is vertical")
	for color in colors: assert(color.a <= Motes.MAX_OPACITY)
	for index in arrays[Mesh.ARRAY_INDEX]: assert(index >= 0 and index < count)
	var exiting: Dictionary = motes.trails[1].duplicate()
	exiting.at = Vector2(1201, exiting.at.y)
	for color in motes.ribbon_arrays(exiting)[Mesh.ARRAY_COLOR]:
		assert(color.a == 0.0, "Long tails fade before an offscreen wrap resets history")
	motes.direction = 0
	before = motes.trails[1].at
	motes._process(0.2)
	assert(motes.trails[1].at == before)
	motes.direction = 1
	var phase: float = motes.trails[1].phase
	for i in 1200: motes._process(1.0/60.0)
	assert(motes.trails[1].phase != phase)
	for trail in motes.trails:
		assert(trail.points.size() <= Motes.MAX_POINTS)
		for point in trail.points: assert(trail.age - point.time <= Motes.TAIL_SECONDS)
	assert(motes.edge_alpha(0) == 0 and motes.edge_alpha(1200) == 0)
	print("WIND_MOTES_TEST_OK")
	quit()
