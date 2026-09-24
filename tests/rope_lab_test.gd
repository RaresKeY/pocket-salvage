extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(854, 480)
	var lab = load("res://labs/rope/lab.tscn").instantiate()
	root.add_child(lab)
	for frame in 4: await process_frame
	var transform: Transform2D = lab.viewport.canvas_transform
	var world_end := transform * Vector2(1200,480)
	assert(world_end.x <= lab.viewport.size.x + 1 and world_end.y <= lab.viewport.size.y + 1)
	assert(transform.get_scale().x > 0.5, "World must fill the resized viewport")
	lab.reel.grab_focus()
	var previous_length: float = lab.length
	var press := InputEventKey.new()
	press.keycode = KEY_RIGHT
	press.pressed = true
	root.push_input(press)
	await process_frame
	assert(lab.length > previous_length, "Keyboard slider input must reel the rope")
	press.pressed = false
	root.push_input(press)
	lab.controls.get_child(1).pressed.emit()
	var tick: int = lab.ticks
	for frame in 4: await physics_frame
	assert(lab.ticks == tick, "Pause must stop physics")
	lab.controls.get_child(1).pressed.emit()
	for frame in 4: await physics_frame
	assert(lab.ticks > tick)
	lab.controls.get_child(0).pressed.emit()
	assert(lab.length == 910 and lab.velocity == Vector2.ZERO)
	print("ROPE_LAB_TEST_OK viewport, keyboard reeling, pause, resume, reset")
	quit()
