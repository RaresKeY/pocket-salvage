extends SceneTree
const Weather = preload("res://scripts/weather/weather.gd")

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for index in count: await physics_frame

func run() -> void:
	var all: Array = Weather.profiles()
	var ids := all.map(func(p): return p.id)
	for id in [&"clear", &"fog", &"wind", &"rain", &"storm"]: assert(ids.has(id), "profile %s loads" % id)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var counts := {}
	for index in 10000:
		var chosen = Weather.pick(all, rng)
		counts[chosen.id] = counts.get(chosen.id, 0) + 1
	for profile in all:
		assert(absf(counts.get(profile.id, 0) / 10000.0 - profile.chance) < 0.02, "%s picked at its chance" % profile.id)

	var calm := Weather.new()
	root.add_child(calm)
	calm.configure(Weather.find(&"clear"), 1)
	var strikes := [0]
	calm.lightning.connect(func(_x): strikes[0] += 1)
	await frames(120)
	assert(calm.wind_now() == 0.0 and strikes[0] == 0, "clear has no wind or lightning")

	var windy := Weather.new()
	root.add_child(windy)
	windy.configure(Weather.find(&"wind"), 2)
	var strongest := 0.0
	for frame in 60 * 12:
		await physics_frame
		assert(signf(windy.wind_now()) == windy.direction, "wind keeps its side")
		strongest = maxf(strongest, absf(windy.wind_now()))
	assert(strongest > windy.profile.wind * 1.5, "a gust arrives within twelve seconds")

	var storm := Weather.new()
	root.add_child(storm)
	storm.configure(Weather.find(&"storm"), 3)
	var events := []
	storm.lightning_warning.connect(func(): events.append(["warning", storm.time]))
	storm.lightning.connect(func(_x): events.append(["strike", storm.time]))
	storm.power_cut.connect(func(seconds): events.append(["cut", seconds]))
	for frame in 60 * 26:
		await physics_frame
		if events.size() >= 3: break
	assert(events.size() >= 3 and events[0][0] == "warning" and events[1][0] == "strike" and events[2][0] == "cut", "rumble, then strike, then power cut")
	assert(absf(events[1][1] - events[0][1] - storm.profile.warning) < 0.05, "rumble comes the warning time before the strike")
	assert(is_equal_approx(events[2][1], storm.profile.power_cut))

	storm.process_mode = Node.PROCESS_MODE_DISABLED
	var frozen: float = storm.time
	await frames(30)
	assert(storm.time == frozen, "a paused world pauses the weather")
	storm.queue_free()
	windy.queue_free()
	calm.queue_free()
	var Lab = load("res://labs/salvage/lab.tscn")
	var wet = Lab.instantiate()
	wet.forced_weather = &"rain"
	root.add_child(wet)
	await process_frame
	assert(wet.weather.profile.id == &"rain", "forced weather is used")
	for body in wet.scrap_bodies():
		assert(is_equal_approx(body.physics_material_override.friction, 0.8 * 0.35), "rain makes scrap slick")
	wet.forced_weather = &"clear"
	wet.restart_round()
	for body in wet.scrap_bodies():
		assert(is_equal_approx(body.physics_material_override.friction, 0.8), "clear leaves friction alone")
	assert(wet.round_state.multiplier == 1.0)
	wet.forced_weather = &"storm"
	wet.restart_round()
	assert(wet.round_state.multiplier == 1.6, "the round takes the weather's multiplier")
	wet.queue_free()
	await process_frame
	var breezy = Lab.instantiate()
	breezy.forced_weather = &"wind"
	root.add_child(breezy)
	await process_frame
	breezy.start_round()
	await frames(60)
	var loose: RigidBody2D = breezy.scrap_bodies()[0]
	var resting: RigidBody2D = breezy.scrap_bodies()[1]
	loose.gravity_scale = 0
	PhysicsServer2D.body_set_state(loose.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0, Vector2(600, 150)))
	PhysicsServer2D.body_set_state(loose.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
	loose.sleeping = false
	await frames(3)
	var start_x := loose.global_position.x
	var rest_x := resting.global_position.x
	await frames(90)
	assert(signf(loose.global_position.x - start_x) == breezy.weather.direction and absf(loose.global_position.x - start_x) > 5, "wind drifts airborne scrap downwind")
	assert(absf(resting.global_position.x - rest_x) < 2, "grounded scrap is held by friction")
	var thrown: RigidBody2D = breezy.scrap_bodies()[2]
	thrown.delivered = true
	assert(not breezy.blown_bodies().has(thrown) and breezy.blown_bodies().has(resting), "thrown-back scrap is not blown; resting scrap is offered and friction holds it")
	assert(breezy.ambience.wind == breezy.weather.wind_now(), "clouds follow the wind")
	breezy.queue_free()
	await process_frame
	print("WEATHER_TEST_OK profiles, weighted pick, calm, wind and gusts, lightning sequence, pause, forced weather, grip, multiplier, wind")
	quit()
