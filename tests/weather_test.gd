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
	var wind_fx = breezy.weather.get_children().filter(func(e): return e.has_method("strength"))[0]
	assert(wind_fx.streaks.emitting and wind_fx.dust.emitting, "wind shows streaks and blowing dust")
	assert(signf(wind_fx.streaks.direction.x) == breezy.weather.direction, "streaks blow the way the wind goes")
	assert(wind_fx.streaks.modulate.a > 0.2 and wind_fx.streaks.modulate.a <= 1.0, "streaks are visible and scale with strength")
	var parked: float = breezy.suspension.anchor.x
	for frame in 120:
		await physics_frame
	assert(signf(breezy.suspension.anchor.x - parked) == breezy.weather.direction and absf(breezy.suspension.anchor.x - parked) > 10, "wind pushes the crane downwind when nobody steers")
	breezy.suspension.anchor.x = 600
	var tilt := 0.0
	for frame in 60 * 10:
		await physics_frame
		tilt = maxf(tilt, absf(breezy.tip.rotation))
	assert(rad_to_deg(tilt) > 6.0, "a gust visibly swings the head (peak %.1f degrees)" % rad_to_deg(tilt))
	breezy.queue_free()
	await process_frame
	var drizzle = Lab.instantiate()
	drizzle.forced_weather = &"rain"
	root.add_child(drizzle)
	await process_frame
	var rain_fx = drizzle.weather.get_children().filter(func(e): return e.has_method("rain_angle"))
	assert(rain_fx.size() == 1 and rain_fx[0].streaks.amount > 0 and rain_fx[0].splashes.amount > 0, "rain shows streaks and splashes")
	drizzle.queue_free()
	var misty = Lab.instantiate()
	misty.forced_weather = &"fog"
	root.add_child(misty)
	await process_frame
	var fog_fx = misty.weather.get_children().filter(func(e): return e.has_method("density_at"))
	var crane_x: float = misty.trolley.position.x
	assert(fog_fx[0].density_at(crane_x) < fog_fx[0].density_at(crane_x + 700), "fog thickens away from the crane")
	for label in misty.bin_labels: assert(label.modulate.a < 0.6, "fog dims bin labels")
	var calm_lab = Lab.instantiate()
	calm_lab.forced_weather = &"clear"
	root.add_child(calm_lab)
	await process_frame
	assert(calm_lab.weather.get_child_count() == 0, "clear creates no effects")
	misty.queue_free()
	calm_lab.queue_free()
	await process_frame
	var stormy = Lab.instantiate()
	stormy.forced_weather = &"storm"
	root.add_child(stormy)
	await process_frame
	stormy.start_round()
	var steel: RigidBody2D = stormy.scrap_bodies().filter(func(b): return b.material_id == &"steel")[0]
	stormy.gripping = true
	stormy.held_body = steel
	steel.held = true
	stormy.suspension.attach(steel)
	stormy.power_cut(1.0)
	assert(stormy.held_body == null and not steel.held and stormy.power_out_left > 0.0, "power cut drops the magnet's load")
	stormy.try_pickup()
	assert(stormy.held_body == null, "a dark magnet picks nothing up")
	stormy.toggle_pause()
	var dark: float = stormy.power_out_left
	for frame in 30: await physics_frame
	assert(stormy.power_out_left == dark, "power cut waits while paused")
	stormy.toggle_pause()
	stormy._fit_head(stormy.Heads.Kind.CLAW)
	assert(stormy.power_out_left == 0.0, "fitting the claw ends the cut for that head")
	var coil: RigidBody2D = stormy.scrap_bodies().filter(func(b): return b.material_id == &"copper")[0]
	stormy.held_body = coil
	coil.held = true
	stormy.suspension.attach(coil)
	stormy.power_cut(1.0)
	assert(stormy.held_body == coil, "the claw holds through a power cut")
	stormy._fit_head(stormy.Heads.Kind.MAGNET)
	stormy.release_load()
	stormy.power_cut(1.0)
	stormy.restart_round()
	assert(stormy.power_out_left == 0.0, "restart gives working power")
	var flashes = stormy.weather.get_children().filter(func(e): return e.has_method("strike"))
	assert(flashes.size() == 1 and stormy.weather.power_cut.is_connected(stormy.power_cut), "storm lightning is wired to the round's power")
	stormy.queue_free()
	await process_frame
	var loud = Lab.instantiate()
	loud.forced_weather = &"storm"
	root.add_child(loud)
	await process_frame
	loud.start_round()
	await frames(5)
	for sound in [&"wind_loop", &"rain_loop", &"thunder"]: assert(load("res://assets/audio/%s.wav" % sound) is AudioStreamWAV, "%s exists" % sound)
	assert(loud.sfx.loop_level(&"rain_loop") == 1.0 and loud.sfx.loops.has(&"wind_loop"), "storm runs rain and wind loops")
	loud.sfx.set_effects_enabled(false)
	assert(loud.sfx.loops[&"rain_loop"].current == 0.0 and loud.sfx.loops[&"wind_loop"].current == 0.0, "SFX off silences rain and wind")
	loud.set_music(false)
	assert(loud.sfx.effects_enabled == false, "music toggle leaves the SFX setting alone")
	loud.queue_free()
	await process_frame
	for id in [&"clear", &"fog", &"wind", &"rain", &"storm"]:
		var each = Lab.instantiate()
		each.forced_weather = id
		root.add_child(each)
		await process_frame
		each.start_round()
		for body in each.scrap_bodies(): each.round_state.accept_delivery(body.item_id, body.material_id, body.material_id)
		var earned: int = each.round_state.score - each.round_state.weather_bonus
		assert(each.round_state.state == &"finished" and each.round_state.weather_bonus == roundi(earned * (each.weather.profile.multiplier - 1.0)), "%s round finishes with its bonus" % id)
		each.refresh_hud()
		assert(each.hud.weather_badge.text.begins_with(each.weather.profile.label), "%s shows on the HUD" % id)
		each.queue_free()
		await process_frame
	print("WEATHER_TEST_OK profiles, weighted pick, calm, wind and gusts, lightning sequence, pause, forced weather, grip, multiplier, wind, rain, fog, lightning and power cuts, sounds, full rounds")
	quit()
