extends SceneTree
## Level 6 Electric Storm: blackouts warn, cut the lights and the magnet (not the claw), then recover.
const Levels = preload("res://scripts/level/level_catalog.gd")
const Heads = preload("res://scripts/crane/crane_heads.gd")
func _initialize() -> void: call_deferred("run")

func run() -> void:
	assert(Levels.unlocked(5) and Levels.title(5) == "Electric Storm" and Levels.scrap_count(5) == 12)
	assert(not Levels.get_value(5, "lightning_flips_magnet"), "Electric Storm lightning cuts power rather than flipping the magnet")
	var game = load("res://labs/salvage/lab.tscn").instantiate()
	game.selected_level = 5
	root.add_child(game)
	await process_frame
	var blackout: Node = game.event(load(Levels.BLACKOUT))
	assert(blackout != null and game.blood_cycle == null and game.weather.profile.id == &"electric_storm")
	game.start_round()
	assert(blackout.phase == &"waiting" and blackout.wait >= 20 and blackout.wait <= 30)
	assert(game.powered() and game.ambience.blackout == 0.0)

	# Warning: both floodlights and the beacons stutter, with a crackle.
	game.sfx.played.clear()
	blackout._physics_process(blackout.wait + 0.01)
	assert(blackout.phase == &"warning" and game.sfx.played.has(&"crackle"))
	assert(game.feedback.contains("flickering"))
	blackout._physics_process(0.3)
	assert(game.ambience.left_lamp_level < 1.0 and game.ambience.right_lamp_level < 1.0 and game.ambience.beacon_level < 1.0)
	assert(game.powered(), "Power holds through the warning")

	# Blackout: the yard goes dark, a strike lands and the magnet drops its load and cannot grip.
	var load_body: RigidBody2D
	for body in game.payloads:
		if Heads.grips(Heads.Kind.MAGNET, body.material_id): load_body = body
	game.gripping = true
	game.held_body = load_body
	load_body.held = true
	game.sfx.played.clear()
	blackout._physics_process(blackout.WARNING + 0.01)
	assert(blackout.phase == &"out" and not game.powered() and not game.ambience.generator_running)
	assert(game.sfx.played.has(&"thunder") and game.sfx.played.has(&"power_down"))
	assert(not is_instance_valid(game.held_body) and not load_body.held, "The magnet drops what it holds")
	assert(game.feedback.contains("Blackout"))
	blackout._physics_process(0.5)
	assert(game.ambience.blackout > 0.5)
	assert(not game.head_has_power(), "The magnet has no power")
	game._fit_head(Heads.Kind.CLAW)
	assert(game.head_has_power(), "The claw is not electric")
	game._fit_head(Heads.Kind.MAGNET)
	assert(not game.head_has_power(), "Swapping back does not bring the magnet's power back")

	# Recovery: lights and magnet return, the dark fades, and the next blackout is further off.
	game.sfx.played.clear()
	blackout._physics_process(blackout.left + 0.01)
	assert(blackout.phase == &"waiting" and game.powered() and game.ambience.generator_running)
	assert(game.sfx.played.has(&"power_up") and blackout.wait >= 35 and blackout.wait <= 50)
	assert(game.ambience.left_lamp_level == 1.0 and game.ambience.right_lamp_level == 1.0 and game.ambience.beacon_level == 1.0)
	assert(game.head_has_power())
	blackout._physics_process(2.0)
	assert(game.ambience.blackout == 0.0)

	# Pausing holds the blackout clock.
	game.round_state.set_paused(true)
	var wait: float = blackout.wait
	blackout._physics_process(5.0)
	assert(blackout.wait == wait)
	game.round_state.set_paused(false)

	# Level 6 plays to a win.
	game.round_state.tick(241)
	game.show_levels()
	game.select_level(5)
	game.start_round()
	for body in game.payloads:
		game.round_state.accept_delivery(body.item_id, body.material_id, body.material_id)
	assert(game.round_state.state == &"finished" and game.victory)
	print("BLACKOUT_TEST_OK")
	quit()
