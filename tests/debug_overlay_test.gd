extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var plain_hud = load("res://scripts/ui/round_hud.gd").new()
	root.add_child(plain_hud)
	assert(plain_hud.developer_section == null, "Normal HUD has no developer controls")
	root.remove_child(plain_hud)
	plain_hud.free()
	var game = load("res://labs/salvage/lab.tscn").instantiate()
	game.forced_weather = &"clear"
	root.add_child(game)
	await process_frame
	assert(not game.hud.developer_section.visible, "Options belong only to pause")
	game.start_round()
	game.toggle_pause()
	assert(game.hud.developer_section.visible)
	game.hud.developer_button.button_pressed = true
	game.hud.hitboxes_check.button_pressed = true
	game.hud.masks_check.button_pressed = true
	assert(game.debug_overlay.shapes.size() > 10)
	assert(game.debug_overlay.art_masks.size() > 0)
	assert(game.debug_overlay.is_processing())
	var position_before: Vector2 = game.tip.position
	await process_frame
	assert(game.tip.position == position_before, "Overlay cannot advance paused physics")
	var extra := CollisionShape2D.new()
	extra.shape = RectangleShape2D.new()
	game.tip.add_child(extra)
	await process_frame
	await process_frame
	assert(extra in game.debug_overlay.shapes, "New head/body geometry is collected while enabled")
	extra.free()
	game.toggle_pause()
	assert(not game.hud.developer_section.visible)
	game.restart_round()
	assert(game.debug_overlay.subject == game.world)
	game.hud.hitboxes_check.button_pressed = false
	game.hud.masks_check.button_pressed = false
	assert(not game.debug_overlay.is_processing())
	root.remove_child(game)
	game.free()
	print("DEVELOPER_TEST_OK")
	quit()
