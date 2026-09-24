extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 720)
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.set_process(false)
	assert(scene.viewport.size == root.size)
	assert(scene.stage.scale == Vector2.ONE)
	assert(scene.zoom == 3.0)
	var count := 0
	for node in scene.find_children("*", "Sprite2D", true, false):
		assert(node.texture.resource_path.begins_with("res://assets/bitwright_8x/"))
		assert(node.scale == Vector2(0.125, 0.125))
		count += 1
	assert(count > 25)
	var fence: Sprite2D = scene.get_node("Stage/Viewport/Yard/Environment/Fence")
	assert(fence.region_rect.size * fence.scale == Vector2(384,64))
	var point := Vector2(850,430)
	var before: Vector2 = scene.world_at(point)
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	wheel.position = point
	wheel.factor = 1.0
	root.push_input(wheel)
	assert(scene.target_zoom > scene.zoom)
	var start: float = scene.zoom
	scene.advance_zoom(0.016)
	assert(scene.zoom > start and scene.zoom < scene.target_zoom)
	assert(scene.world_at(point).is_equal_approx(before))
	for step in 120: scene.advance_zoom(0.016)
	assert(is_equal_approx(scene.zoom, scene.target_zoom))
	assert(scene.world_at(point).is_equal_approx(before))
	for button in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE]:
		var press := InputEventMouseButton.new()
		press.button_index = button
		press.pressed = true
		root.push_input(press)
		assert(scene.dragging)
		var old_center: Vector2 = scene.center
		var motion := InputEventMouseMotion.new()
		motion.relative = Vector2(60,-30)
		root.push_input(motion)
		assert(scene.center.is_equal_approx(old_center - motion.relative / scene.zoom))
		press.pressed = false
		root.push_input(press)
		assert(not scene.dragging)
		scene.dragging = true
		scene.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
		assert(not scene.dragging)
	scene.zoom_at(point, 100)
	assert(scene.target_zoom == scene.MAX_ZOOM)
	scene.zoom_at(point, -100)
	assert(scene.target_zoom == scene.MIN_ZOOM)
	var reset := InputEventKey.new()
	reset.physical_keycode = KEY_F
	reset.pressed = true
	root.push_input(reset)
	assert(scene.zoom == 3.0 and scene.center == Vector2(192,108))
	root.size = Vector2i(854,480)
	await process_frame
	await process_frame
	assert(scene.viewport.size == root.size)
	assert(scene.hud.size.x <= root.size.x)
	scene.reset_view()
	assert(scene.zoom == 2.0)
	print("YARD_CAMERA_TEST_OK large textures, regions, native viewport, smooth cursor zoom, bounds, left/middle pan, release/focus, reset, resize")
	scene.queue_free()
	await process_frame
	quit()
