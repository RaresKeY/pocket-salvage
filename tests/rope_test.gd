extends SceneTree
const Solver = preload("res://scripts/rope/rope_solver.gd")
const Render = preload("res://scripts/rope/rope_render.gd")

func _initialize() -> void:
	var rope := Solver.new()
	var a := Vector2(0, 0)
	var b := Vector2(240, 0)
	rope.reset(a, b, 320)
	for tick in 300: rope.simulate(a, b, 320, 1.0 / 60.0)
	assert(rope.points[0] == a and rope.points[-1] == b)
	assert(rope.points[15].y > 50, "Slack must sag under gravity")
	for point in rope.points: assert(point.is_finite())
	var before := rope.points.duplicate()
	var curve := Render.curve(rope.points)
	assert(rope.points == before, "Rendering must never mutate physics")
	assert(curve[0] == a and curve[-1] == b)
	assert(curve.size() <= 6 * rope.points.size() + 2)
	var taut := rope.constrain_tip(a, Vector2(400,0), Vector2(100,30), 200)
	assert(taut.position.is_equal_approx(Vector2(200,0)))
	assert(taut.velocity.is_equal_approx(Vector2(0,30)), "Keep tangential momentum")
	rope.simulate(a, b, 240, 1.0 / 60.0)
	for point in rope.points: assert(absf(point.y) < 0.01)
	_test_moving_taut_cable()
	var obstacle := PackedVector2Array([Vector2(80,-40),Vector2(160,-40),Vector2(160,100),Vector2(80,100)])
	rope.path.build([obstacle])
	rope.reset(a, b, 350)
	rope.simulate(a, b, 350, 1.0 / 60.0)
	assert(rope.path.bends.size() >= 2, "Rope must route around the obstacle")
	var guides := rope.path.guides(a,b)
	for i in guides.size()-1: assert(rope.path.clear(guides[i], guides[i+1]))
	var contacts := rope.path.bends.duplicate()
	rope.path.update(a, b + Vector2(0,1))
	assert(rope.path.bends == contacts, "Contacts persist until a bypass is clear")
	for pin in rope.pins: assert(rope.points[pin].is_finite())
	rope.path.update(Vector2(0,-80), Vector2(240,-80))
	assert(rope.path.bends.is_empty(), "Clear bypass must unwrap")
	for fixture in [PackedVector2Array(), PackedVector2Array([a]), PackedVector2Array([a,a,a]), PackedVector2Array([a,b,a])]:
		for point in Render.curve(fixture): assert(point.is_finite())
	print("ROPE_TEST_OK")
	quit()

func _test_moving_taut_cable() -> void:
	var rope := Solver.new()
	var a := Vector2.ZERO
	var b := Vector2(0, 240)
	rope.reset(a, b, 240)
	rope.simulate(a, b, 240, 1.0 / 60.0)
	# Translate the suspended cable while reeling it in. Every particle keeps
	# its last position even though the tension constraint makes a straight line.
	for tick in 12:
		var previous := rope.points.duplicate()
		a.x += 2.0
		b.x += 2.0
		b.y -= 1.0
		rope.simulate(a, b, b.y, 1.0 / 60.0)
		assert(rope.old_points == previous, "Taut movement/reeling must retain particle history")
		assert(rope.points.size() == previous.size(), "Moving anchors must not remesh the cable")
		for point in rope.points:
			assert(is_equal_approx(point.x, a.x), "Taut cable remains straight")
	var midpoint := rope.points.size() / 2
	var prior_middle: Vector2 = rope.points[midpoint]
	# Paying out leaves room for the existing transverse velocity to continue.
	rope.simulate(a, b, b.y + 80.0, 1.0 / 60.0)
	assert(rope.points[midpoint].x > prior_middle.x + 1.0,
		"Paying out must preserve sideways motion from the moving hoist")
	assert(rope.points[0] == a and rope.points[-1] == b)
	for tick in 180:
		rope.simulate(a, b, b.y + 80.0, 1.0 / 60.0)
	for point in rope.points:
		assert(point.is_finite())
		assert(point.distance_to(a) < 400.0, "Released cable motion remains bounded")
