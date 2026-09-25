extends SceneTree
## Level 5 Storm: the storm cycle, intensity scaling, the twister and a full round.
const Levels = preload("res://scripts/level/level_catalog.gd")
const StormFront = preload("res://scripts/level/storm_front.gd")
const Tornado = preload("res://scripts/level/tornado.gd")
func _initialize() -> void: call_deferred("run")

func tornado_of(game) -> Node:
	for child in game.world.get_children():
		if child.get_script() == Tornado: return child
	return null

func place(body: RigidBody2D, at: Vector2) -> void:
	PhysicsServer2D.body_set_state(body.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0, at))
	PhysicsServer2D.body_set_state(body.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
	body.sleeping = false

func run() -> void:
	assert(Levels.unlocked(4) and Levels.title(4) == "Storm")
	assert(Levels.scrap_count(4) == 12 and is_equal_approx(Levels.weather(4).multiplier, 1.7))
	assert(Levels.look(4) == &"night" and not Levels.get_value(4, "reversed_heads"))
	assert(Levels.get_value(2, "lightning_flips_magnet") and Levels.get_value(4, "lightning_flips_magnet"))

	var game = load("res://labs/salvage/lab.tscn").instantiate()
	game.selected_level = 4
	root.add_child(game)
	await process_frame
	var storm: Node = game.event(StormFront)
	assert(storm != null and game.blood_cycle == null and not game.ambience.blood_moon)
	assert(game.payloads.size() == 12 and game.weather.profile.id == &"storm")

	# Calm: the dial is low, so the weather is a fraction of its peak and lightning waits.
	game.start_round()
	assert(storm.phase == &"calm" and storm.left >= 40 and storm.left <= 60)
	storm._physics_process(0.1)
	assert(is_equal_approx(game.weather.intensity, StormFront.CALM_INTENSITY))
	var peak_wind: float = absf(game.weather.direction * game.weather.profile.wind)
	assert(absf(game.weather.wind_now()) <= peak_wind * StormFront.CALM_INTENSITY + 0.01, "Calm wind is scaled down")
	var strike_in: float = game.weather._strike_in
	game.weather._tick_lightning(5.0)
	assert(game.weather._strike_in == strike_in, "No lightning outside the storm")
	assert(game.ambience.gloom == 0.0)

	# Building: a warning, a rumble, then the dial climbs.
	game.sfx.played.clear()
	storm._physics_process(storm.left + 0.01)
	assert(storm.phase == &"building" and game.feedback.contains("Storm building"))
	assert(game.sfx.played.has(&"thunder"), "Building storm rumbles")
	storm._physics_process(storm.length * 0.5)
	assert(game.weather.intensity > StormFront.CALM_INTENSITY and game.weather.intensity < 1.0)
	assert(game.ambience.gloom > 0.0 and game.ambience.gloom < 1.0)

	# Storm: full strength, lightning counts down, gulls stay away, one twister comes.
	storm._physics_process(storm.left + 0.01)
	assert(storm.phase == &"storm" and game.feedback.contains("Storm!"))
	storm._physics_process(0.01)
	assert(is_equal_approx(game.weather.intensity, 1.0) and game.ambience.gloom == 1.0)
	strike_in = game.weather._strike_in
	game.weather._tick_lightning(0.5)
	assert(game.weather._strike_in < strike_in, "Lightning counts down in the storm")
	assert(tornado_of(game) == null)
	storm._physics_process(storm.tornado_in + 0.01)
	var twister: Node2D = tornado_of(game)
	assert(twister != null and twister.state == Tornado.State.WARNING and game.feedback.contains("Twister"))
	storm._physics_process(1.0)
	assert(tornado_of(game) == twister, "Only one twister per storm")

	# The twister lifts light scrap in its path, leaves heavy scrap, shoves the head, then goes.
	var light: RigidBody2D
	var heavy: RigidBody2D
	for body in game.payloads:
		if body.mass <= Tornado.LIFT_MASS and light == null: light = body
		elif body.mass > Tornado.LIFT_MASS and heavy == null: heavy = body
	assert(light != null and heavy != null)
	var ground: float = game.layout.ground_top
	twister._physics_process(Tornado.WARNING + 0.01)
	assert(twister.state == Tornado.State.CROSSING)
	var ahead: float = twister.position.x + twister.direction * 20.0
	place(light, Vector2(ahead, ground - light.dimensions.y * 0.5 - 1))
	place(heavy, Vector2(ahead - twister.direction * 55.0, ground - heavy.dimensions.y * 0.5 - 1))
	var heavy_start := heavy.global_position
	var head_start: Vector2 = game.tip.linear_velocity
	var light_low := light.global_position.y
	for i in 30:
		twister.position.x = ahead - twister.direction * 5.0
		game.tip.global_position.x = twister.position.x
		twister._apply_forces()
		await physics_frame
	assert(light.global_position.y < light_low - 20.0, "Light scrap is lifted")
	assert(twister.carried.has(light) and not twister.carried.has(heavy), "Heavy scrap is never lifted")
	assert(heavy.global_position.y >= heavy_start.y - 2.0, "Heavy scrap stays down")
	assert(signf(game.tip.linear_velocity.x - head_start.x) == twister.direction, "The head is shoved along")
	twister._physics_process(1000.0)
	assert(twister.state == Tornado.State.GONE and twister.carried.is_empty(), "It drops everything when it breaks up")
	await create_timer(1.2).timeout
	assert(tornado_of(game) == null, "The twister leaves")

	# Clearing, then calm again.
	storm._physics_process(storm.left + 0.01)
	assert(storm.phase == &"clearing" and game.feedback.contains("passing"))
	storm._physics_process(storm.left + 0.01)
	assert(storm.phase == &"calm")
	storm._physics_process(0.01)
	assert(is_equal_approx(game.weather.intensity, StormFront.CALM_INTENSITY))

	# Other levels keep full-strength weather and no storm.
	game.round_state.tick(241)
	game.show_levels()
	game.select_level(2)
	assert(game.event(StormFront) == null and game.weather.intensity == 1.0 and game.ambience.gloom == 0.0)

	# Level 5 plays to a win like any other.
	game.select_level(4)
	game.start_round()
	for body in game.payloads:
		game.round_state.accept_delivery(body.item_id, body.material_id, body.material_id)
	assert(game.round_state.state == &"finished" and game.victory)
	print("STORM_TEST_OK")
	quit()
