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
	assert(motes.tail_alpha(0) > motes.tail_alpha(0.6) and motes.tail_alpha(1.2) == 0)
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
