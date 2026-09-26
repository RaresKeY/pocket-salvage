extends SceneTree
const Heads = preload("res://scripts/crane/crane_heads.gd")
const Levels = preload("res://scripts/level/level_catalog.gd")
func _initialize() -> void: call_deferred("run")
func backdrop_of(game) -> Node:
	for child in game.world.get_children():
		if child.get_script() == preload("res://scripts/level/yard_backdrop.gd"): return child
	return null

func moon_of(game) -> Sprite2D:
	for child in game.ambience.far.get_children():
		if child is Sprite2D and child.texture.resource_path.contains("moon"): return child
	return null

func run() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 52
	var winds := {}
	for i in 50:
		var profile = Levels.roll_weather(3, rng)
		assert(profile.wind >= 16 and profile.wind <= 40)
		assert(profile.gust >= 18 and profile.gust <= 40)
		assert(profile.rain >= 45 and profile.rain <= 120)
		winds[profile.wind] = true
	assert(winds.size() > 1 and Levels.weather(3).wind == 28)
	assert(Heads.grips(Heads.Kind.MAGNET, &"copper", true))
	assert(Heads.grips(Heads.Kind.MAGNET, &"rubber", true))
	assert(not Heads.grips(Heads.Kind.MAGNET, &"steel", true))
	assert(Heads.grips(Heads.Kind.CLAW, &"steel", true))
	assert(not Heads.grips(Heads.Kind.NONE, &"steel", true))
	var game = load("res://labs/salvage/lab.tscn").instantiate()
	game.selected_level = 3
	root.add_child(game)
	await process_frame
	assert(game.ambience.blood_moon and game.blood_cycle != null)
	assert(moon_of(game).texture.resource_path.contains("backdrop_blood_moon"), "Blood Moon shows the generated blood moon")
	assert(backdrop_of(game).skylines.all(func(tile): return tile.resource_name.begins_with("backdrop_blood_skyline")), "Blood Moon uses the crimson skylines")
	var Tints = preload("res://scripts/level/tint_settings.gd")
	assert(game.tint == Tints.defaults() and Tints.SLIDERS.size() == 5, "Tints start at the shipped look")
	assert(is_equal_approx(game.stage.material.get_shader_parameter("wash"), 0.02) and is_equal_approx(game.stage.material.get_shader_parameter("edge_tint"), 0.14))
	assert(is_equal_approx(game.ambience.sky_strength, 0.19) and is_equal_approx(game.ambience.light_strength, 1.76) and is_equal_approx(game.ambience.bulb_strength, 1.0), "Approved tint defaults reach the ambience")
	game.set_tint(&"screen", 0.15)
	game.set_tint(&"assets", 0.12)
	game.set_tint(&"bulbs", 0.3)
	game.set_tint(&"sky", 0.0)
	game.set_tint(&"lights", 5.0)
	assert(is_equal_approx(game.stage.material.get_shader_parameter("wash"), 0.15) and is_equal_approx(game.stage.material.get_shader_parameter("edge_tint"), 0.12), "Screen and asset sliders drive the grade")
	assert(game.ambience.bulb_materials.size() > 0 and game.ambience.bulb_materials.all(func(m): return is_equal_approx(m.get_shader_parameter("strength"), 0.3)), "Bulb slider drives every bulb")
	assert(game.ambience.clouds.all(func(c): return is_equal_approx(c.modulate.g, 1.0)), "Sky at 0 leaves clouds untinted")
	assert(game.tint[&"lights"] == 2.0, "Values clamp to the slider range")
	game.restart_round()
	await process_frame
	assert(is_equal_approx(game.stage.material.get_shader_parameter("wash"), 0.15) and game.ambience.sky_strength == 0.0 and game.ambience.bulb_materials.all(func(m): return is_equal_approx(m.get_shader_parameter("strength"), 0.3)), "Tints survive a restart")
	if game.hud.developer_enabled:
		assert(game.hud.tint_sliders.size() == 5)
		game.hud.tint_sliders[&"screen"].value = 0.1
		assert(is_equal_approx(game.tint[&"screen"], 0.1), "The developer slider drives the round")
	for key in Tints.defaults(): game.set_tint(key, Tints.defaults()[key])
	game.ambience._spawn_gulls()
	game.ambience.waits[&"rat"] = 0
	game.ambience._process(1.0)
	assert(get_nodes_in_group(&"yard_gull").is_empty())
	assert(game.ambience.visitors.is_empty() and game.ambience.crow != null)
	var weather = game.weather
	var before: float = weather.direction
	weather.direction_wait = 0
	weather._tick_direction(0.01)
	assert(weather.direction == before and weather.direction_target == -before)
	weather._tick_direction(1.5)
	assert(absf(weather.direction) < 0.001)
	weather._tick_direction(1.5)
	assert(weather.direction == -before)
	for i in 1000:
		weather._physics_process(0.1)
		assert(absf(weather.direction) <= 1 and absf(weather.wind_now()) <= 80)
	game.start_round()
	for kind in [Heads.Kind.MAGNET, Heads.Kind.CLAW]:
		game._fit_head(kind)
		for material in [&"steel", &"copper", &"rubber"]:
			var body = game.payloads.filter(func(item): return item.material_id == material)[0]
			var original: Vector2 = body.position
			body.position = game.head_mount() - body.grip_offset()
			game.gripping = true
			game.try_pickup()
			assert(is_instance_valid(game.held_body) == Heads.grips(kind, material, true))
			game.release_load()
			game.gripping = false
			body.position = original
	game.blood_cycle.wait = 0
	game.blood_cycle._physics_process(0.01)
	game.blood_cycle._physics_process(0.3)
	assert(game.ambience.right_lamp_level < 1)
	game._fit_head(Heads.Kind.CLAW)
	game.blood_cycle._physics_process(1.4)
	assert(not game.blood_cycle.generator_running and not game.ambience.generator_running)
	assert(game.power_out_left > 0)
	var age: float = game.blood_cycle.age
	game.toggle_pause()
	for i in 4: await physics_frame
	assert(game.blood_cycle.age == age)
	game.toggle_pause()
	game.blood_cycle._physics_process(5)
	assert(game.blood_cycle.generator_running and game.ambience.right_lamp_level == 1)
	game.toggle_pause()
	game.show_levels()
	game.select_level(0)
	assert(not game.ambience.blood_moon and game.blood_cycle == null)
	assert(game.weather.profile.tint == Color.WHITE)
	assert(backdrop_of(game).skylines.all(func(tile): return not tile.resource_name.contains("blood")) and not moon_of(game).texture.resource_path.contains("blood"), "Clear restores the normal skylines and moon")
	assert(Heads.grips(Heads.Kind.MAGNET, &"steel"))
	print("BLOOD_MOON_TEST_OK")
	quit()
