extends SceneTree
const Lab = preload("res://labs/salvage/lab.tscn")
const Rain = preload("res://scripts/weather/effects/rain_effect.gd")
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for i in count: await physics_frame
func run() -> void:
	assert(Rain.sound_tier(70) == 0 and Rain.sound_tier(160) == 1 and Rain.sound_tier(260) == 2)
	var game = Lab.instantiate()
	game.selected_level = 2
	root.add_child(game)
	await process_frame
	game.start_round()
	game.weather.set_process(false)
	assert(game.sfx.loop_level(&"rain_violent_loop") == 1.0)
	game.gripping = true
	var steel = game.scrap_bodies().filter(func(b): return b.material_id == &"steel")[0]
	game.held_body = steel
	steel.held = true
	game.suspension.attach(steel)
	game.weather.power_cut.emit(game.weather.profile.power_cut)
	assert(not game.gripping and game.held_body == null and not steel.held, "ON flips OFF and drops the held load")
	assert(game.hud.magnet_label.text.contains("OFF"), "HUD shows the real switch state")
	game.toggle_pause()
	var remaining: float = game.magnet_flicker_left
	await frames(10)
	assert(game.magnet_flicker_left == remaining)
	game.toggle_pause()
	await frames(35)
	assert(game.gripping and game.magnet_flicker_left == 0.0, "Switch returns ON after a brief flicker")
	game.toggle_grip()
	game.weather.power_cut.emit(0.45)
	assert(game.gripping and game.power_out_left == 0, "OFF flips ON, with power available")
	game.weather.power_cut.emit(0.45)
	assert(game.gripping, "Overlapping strikes extend rather than invert twice")
	await frames(35)
	assert(not game.gripping and game.held_body == null, "OFF is restored and any briefly caught load released")
	game.power_cut(0.45)
	game.toggle_grip()
	await frames(35)
	assert(not game.gripping, "Explicit player toggle supersedes restoration")
	game.power_cut(0.45)
	game._fit_head(game.Heads.Kind.CLAW)
	assert(game.magnet_flicker_left == 0.0, "Head swap cancels stale magnet restoration")
	game.power_cut(0.45)
	assert(game.magnet_flicker_left == 0.0 and game.power_out_left == 0.0, "Mechanical claw is unaffected")
	game._fit_head(game.Heads.Kind.MAGNET)
	game.power_cut(0.45)
	game.restart_round()
	assert(game.magnet_flicker_left == 0.0 and not game.gripping)
	game.free()
	await process_frame
	print("LIGHTNING_FLICKER_TEST_OK inverse/restore, load release, overlap, pause, manual override, head swap, restart, rain tiers")
	quit()
