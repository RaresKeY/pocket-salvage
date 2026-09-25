extends SceneTree
const Layout = preload("res://scripts/level/yard_layout.gd")
const Ambience = preload("res://scripts/level/yard_ambience.gd")
const Gull = preload("res://scripts/level/yard_gull.gd")

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for index in count: await process_frame

func run() -> void:
	var ambience := Ambience.new()
	root.add_child(ambience)
	ambience.configure(Layout.create_layout())
	ambience.gull_wait = INF
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

	ambience.gull_wait = 0.0
	await frames(3)
	var spawned: Array = get_nodes_in_group(&"yard_gull")
	assert(spawned.size() >= 1 and spawned.size() <= Ambience.MAX_GULLS)
	for spawned_gull in spawned: spawned_gull.queue_free()
	await frames(2)
	assert(ambience.taken.is_empty(), "Perches are released when gulls go")
	ambience.queue_free()
	print("AMBIENCE_TEST_OK gull landing, perching, crane scare, departure, uneven crossing, spawn cap")
	quit()
