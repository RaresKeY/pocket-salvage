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
	assert(rope.points[15].y > 20.0, "Reeling must tighten existing slack continuously")
	for tick in 300: rope.simulate(a, b, 240, 1.0 / 60.0)
	assert(rope.points[15].y < 20.0, "Tension must eventually take up slack")
	_test_moving_taut_cable()
	_test_taut_threshold_continuity()
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
	# its last position while the tension constraints propagate endpoint motion.
	for tick in 12:
		var previous := rope.points.duplicate()
		a.x += 2.0
		b.x += 2.0
		b.y -= 1.0
		rope.simulate(a, b, b.y, 1.0 / 60.0)
		assert(rope.old_points == previous, "Taut movement/reeling must retain particle history")
		assert(rope.points.size() == previous.size(), "Moving anchors must not remesh the cable")

	var midpoint := rope.points.size() / 2
	var prior_middle: Vector2 = rope.points[midpoint]
	# Paying out leaves room for the existing transverse velocity to continue.
	rope.simulate(a, b, b.y + 80.0, 1.0 / 60.0)
	assert(absf(rope.points[midpoint].x - prior_middle.x) > 0.01,
		"Paying out must preserve sideways motion from the moving hoist")
	assert(rope.points[0] == a and rope.points[-1] == b)
	for tick in 180:
		rope.simulate(a, b, b.y + 80.0, 1.0 / 60.0)
	for point in rope.points:
		assert(point.is_finite())
		assert(point.distance_to(a) < 400.0, "Released cable motion remains bounded")

func _test_taut_threshold_continuity() -> void:
	var rope := Solver.new()
	var a := Vector2.ZERO
	var b := Vector2(240, 0)
	rope.reset(a, b, 270.0)
	for tick in 180: rope.simulate(a, b, 270.0, 1.0 / 60.0)
	for tick in 14:
		rope.simulate(a, b, maxf(241.2, 270.0 - (tick + 1) * 130.0 / 60.0), 1.0 / 60.0)
	# A reel input used to erase the entire sag in a single frame at length 241.
	# Repeated crossings must retain the same particles and motion history.
	var nearby := Solver.new()
	nearby.reset(a, b, 270.0)
	nearby.points = rope.points.duplicate()
	nearby.old_points = rope.old_points.duplicate()
	rope.simulate(a, b, 240.8, 1.0 / 60.0)
	nearby.simulate(a, b, 241.2, 1.0 / 60.0)
	assert(rope.points[15].distance_to(nearby.points[15]) < 1.0,
		"A subpixel payout difference must not select a different cable shape mode")
	var peak_jump := 0.0
	for tick in 180:
		var previous := rope.points.duplicate()
		var length := 240.8 if tick % 2 == 0 else 241.2
		rope.simulate(a, b, length, 1.0 / 60.0)
		assert(rope.old_points == previous, "Taut transitions must not clear Verlet history")
		assert(rope.points.size() == previous.size())
		peak_jump = maxf(peak_jump, rope.points[15].distance_to(previous[15]))
		assert(rope.points[0] == a and rope.points[-1] == b)
	assert(peak_jump < 12.0, "Threshold crossings must tighten continuously, not snap to a line")
