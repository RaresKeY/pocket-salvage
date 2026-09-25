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
	var lab = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(lab)
	current_scene = lab
	for frame in 3: await process_frame
	assert(lab.hud.level_grid.visible and lab.payloads.size() == 4)
	assert(lab.scene_file_path == "res://labs/salvage/lab.tscn")
	await key(KEY_F2)
	assert(current_scene == lab and lab.round_state.state == &"ready")
	assert(not lab.hud.hints_label.text.contains("F2"))
	await click(lab.hud.action)
	assert(lab.round_state.state == &"running")
	await key(KEY_SPACE)
	assert(lab.gripping)
	await key(KEY_P)
	assert(lab.round_state.state == &"paused")
	await key(KEY_F2)
	assert(current_scene == lab and lab.round_state.state == &"paused")
	await click(lab.hud.action)
	assert(lab.round_state.state == &"running")
	await key(KEY_R)
	assert(not lab.gripping and lab.round_state.score == 0)
	await key(KEY_F2)
	assert(current_scene == lab and lab.round_state.state == &"running")
	lab.round_state.tick(241)
	await key(KEY_F2)
	assert(current_scene == lab and lab.round_state.state == &"finished")
	assert(not lab.controls.KEY_COMMANDS.has(KEY_F2))
	print("SALVAGE_NAVIGATION_TEST_OK main launch, mouse start/resume, keyboard controls, F2 inert in every state")
	quit()
