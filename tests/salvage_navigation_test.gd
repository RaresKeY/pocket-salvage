extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func click(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion,true)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		root.push_input(event,true)
		await process_frame
	await process_frame

func key(code: Key) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		root.push_input(event)
		await process_frame

func run() -> void:
	root.size = Vector2i(768,480)
	root.notify_mouse_entered()
	var preview = load("res://scenes/main.tscn").instantiate()
	root.add_child(preview)
	current_scene = preview
	for frame in 3: await process_frame
	assert(root.get_visible_rect().encloses(preview.play_button.get_global_rect()))
	await click(preview.play_button)
	var lab = current_scene
	assert(lab.scene_file_path == "res://labs/salvage/lab.tscn")
	await click(lab.hud.action)
	assert(lab.round_state.state == &"running")
	await key(KEY_SPACE)
	assert(lab.magnet_on)
	await key(KEY_P)
	assert(lab.round_state.state == &"paused")
	await click(lab.hud.action)
	assert(lab.round_state.state == &"running")
	await key(KEY_R)
	assert(not lab.magnet_on and lab.round_state.score == 0)
	await key(KEY_F2)
	assert(current_scene.scene_file_path == "res://scenes/main.tscn")
	print("SALVAGE_NAVIGATION_TEST_OK main launch, mouse start, keyboard magnet/pause/restart, mouse resume, preview return")
	quit()
