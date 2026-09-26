extends SceneTree
const Layout = preload("res://scripts/level/yard_layout.gd")
const Ambience = preload("res://scripts/level/yard_ambience.gd")
const Gull = preload("res://scripts/level/yard_gull.gd")

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for index in count: await process_frame

func check_cloud_wind(ambience: Node2D) -> void:
	assert(ambience.clouds.size() == Ambience.CLOUD_COUNT)
	var origin := Vector2(600, 120)
	var displacements: Dictionary = {}
	for speed in [18.0, 36.0, -18.0, -36.0, 0.0]:
		for cloud in ambience.clouds: cloud.position = origin
		ambience.wind = speed
		ambience._process(0.25)
		var dx: float = ambience.clouds[0].position.x - origin.x
		if speed == 0.0:
			assert(is_zero_approx(dx), "Clouds stop in calm wind")
		else:
			assert(signf(dx) == signf(speed), "Even light wind carries clouds downwind")
		for cloud in ambience.clouds:
			assert(cloud.position.is_equal_approx(origin + Vector2(dx, 0)), "All clouds follow horizontal wind")
		displacements[speed] = dx
	assert(is_equal_approx(displacements[36.0], displacements[18.0] * 2), "Cloud speed scales with wind strength")
	assert(is_equal_approx(displacements[-36.0], -displacements[36.0]), "Reversing wind preserves speed")
	for direction in [-1.0, 1.0]:
		ambience.wind = direction * 100
		for cloud in ambience.clouds: cloud.position.x = -59.0 if direction < 0 else 1259.0
		ambience._process(1.0)
		for cloud in ambience.clouds:
			assert(cloud.position.x == (1260.0 if direction < 0 else -60.0), "Clouds wrap at either yard edge")
	ambience.wind = 0.0

func run() -> void:
	var ambience := Ambience.new()
	root.add_child(ambience)
	ambience.configure(Layout.create_layout())
	ambience.waits[&"gull"] = INF
	check_cloud_wind(ambience)
	assert(ambience.perches.size() == 9, "Two floodlights, four rail spots, the heap and two fence spots")
	var crane := []
	ambience.crane_points = func() -> Array: return crane

	var perch: Vector2 = ambience.perches[2]
	var gull := Gull.new()
	gull.setup(ambience.rng, ambience.art_scale, 1200, true, 120, perch)
	gull.is_threatened = ambience._near_crane
	ambience.near.add_child(gull)
	for frame in 1800:
		await process_frame
		if gull.state == Gull.State.PERCHED: break
	assert(gull.state == Gull.State.PERCHED, "Gull lands on its perch")
	assert(gull.position.distance_to(perch - Vector2(0, gull.half_height)) < 0.5)
	assert(gull.sprite.animation == &"perch")
	await frames(30)
	assert(gull.state == Gull.State.PERCHED, "Gull stays put while nothing threatens it")
	crane.append(perch + Vector2(40, 0))
	await frames(2)
	assert(gull.state == Gull.State.LEAVING and gull.sprite.animation == &"fly", "Crane nearby scares it off")
	for frame in 900:
		await process_frame
		if not is_instance_valid(gull): break
	assert(not is_instance_valid(gull), "Leaving gull flies off and frees itself")

	crane.clear()
	var passer := Gull.new()
	passer.setup(ambience.rng, ambience.art_scale, 1200, false, 150, Vector2.INF)
	ambience.near.add_child(passer)
	var lowest := INF
	var highest := -INF
	for frame in 2400:
		await process_frame
		if not is_instance_valid(passer): break
		lowest = minf(lowest, passer.position.y)
		highest = maxf(highest, passer.position.y)
	assert(not is_instance_valid(passer), "Crossing gull leaves the yard")
	assert(highest - lowest > 8.0, "Flight rises and dips rather than running level")

	ambience.waits[&"gull"] = 0.0
	await frames(3)
	var spawned: Array = get_nodes_in_group(&"yard_gull")
	assert(spawned.size() >= 1 and spawned.size() <= Ambience.MAX_GULLS)
	for spawned_gull in spawned: spawned_gull.queue_free()
	await frames(2)
	assert(ambience.taken.is_empty(), "Perches are released when gulls go")
	ambience.queue_free()
	print("AMBIENCE_TEST_OK wind-driven clouds, gull landing, perching, crane scare, departure, uneven crossing, spawn cap")
	quit()
