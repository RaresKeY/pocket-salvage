extends SceneTree
const Layout = preload("res://scripts/level/yard_layout.gd")
const Levels = preload("res://scripts/level/level_catalog.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(ProjectSettings.get_setting("application/run/main_scene") == "res://labs/salvage/lab.tscn")
	for level in 4:
		for variant in 2:
			var layout := Layout.create_layout(variant, Levels.scrap_count(level))
			assert(layout.scrap.size() == Levels.scrap_count(level))
			var rects: Array[Rect2] = []
			var materials := {}
			for item in layout.scrap:
				var rect := Rect2(item.position - item.size / 2, item.size)
				assert(layout.pickup_bounds.encloses(rect))
				for previous in rects: assert(not previous.intersects(rect))
				rects.append(rect)
				materials[item.material] = true
			assert(materials.size() == 3)
	var game = load("res://labs/salvage/lab.tscn").instantiate()
	root.add_child(game)
	await process_frame
	assert(game.round_state.state == &"ready" and game.hud.level_grid.visible)
	for level in 4:
		assert(game.selected_level == level)
		var count := Levels.scrap_count(level)
		assert(game.payloads.size() == count and game.round_state.total_items == count)
		game.start_round()
		for body in game.payloads:
			game.round_state.accept_delivery(body.item_id, body.material_id, body.material_id)
		assert(game.round_state.state == &"finished" and game.victory)
		assert(game.hud.heading.text == "Victory!" and game.hud.action.text == "Continue")
		assert(not game.hud.level_grid.visible)
		for size in [Vector2i(1280,720),Vector2i(640,360),Vector2i(390,844)]:
			root.size = size
			for i in 5: await process_frame
			assert(root.get_visible_rect().encloses(game.hud.action.get_global_rect()))
		assert(game.selected_level == level) # victory does not silently skip to another round
		if level % 2 == 0: game.hud.action.pressed.emit()
		else: game._command(&"primary")
		assert(game.round_state.state == &"ready" and game.hud.level_grid.visible)
		assert(game.feedback_left == 0 and game.feedback.is_empty())
		assert(game.selected_level == mini(level + 1, 3))
	game.start_round()
	game.round_state.tick(241)
	assert(not game.victory and game.hud.action.text == "Retry" and game.hud.levels_button.visible)
	game._command(&"primary")
	assert(game.round_state.state == &"running" and game.selected_level == 3)
	game.round_state.tick(241)
	game.hud.levels_button.pressed.emit()
	assert(game.round_state.state == &"ready" and game.selected_level == 3)
	print("LEVEL_PROGRESSION_TEST_OK")
	quit()
