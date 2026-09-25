extends SceneTree
const Controls = preload("res://scripts/input/salvage_input.gd")
var lab: Control

func _initialize() -> void: call_deferred("run")

func pad(button: JoyButton, pressed: bool = true) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame
	if pressed: await pad(button, false)

func axis(which: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = which
	event.axis_value = value
	Input.parse_input_event(event)
	await process_frame

func finger(index: int, point: Vector2, pressed: bool, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	event.canceled = canceled
	root.push_input(event, true)
	await process_frame

func settle() -> void:
	for frame in 5: await process_frame

func run() -> void:
	assert(Controls.wants_touch(true, true, false))
	assert(Controls.wants_touch(true, false, true))
	assert(not Controls.wants_touch(true, false, false))
	assert(not Controls.wants_touch(false, true, false))
	root.min_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	lab = load("res://labs/salvage/lab.tscn").instantiate()
	root.add_child(lab)
	await settle()
	assert(lab.controls.mobile_touch and lab.hud.touch_controls.visible)
	await pad(JOY_BUTTON_A)
	assert(lab.round_state.state == &"running" and not lab.gripping, "A starts once without also gripping")
	await axis(JOY_AXIS_LEFT_X, 0.12)
	assert(lab.controls.movement().x == 0, "Stick drift is inside the deadzone")
	var before: float = lab.suspension.anchor.x
	await axis(JOY_AXIS_LEFT_X, 0.8)
	for frame in 8: await physics_frame
	assert(lab.suspension.anchor.x > before + 5, "Analog stick moves the actual trolley")
	assert(lab.controls.movement().x > 0 and lab.controls.movement().x < 1)
	await axis(JOY_AXIS_LEFT_X, 0)
	await pad(JOY_BUTTON_DPAD_DOWN, false)
	var down := InputEventJoypadButton.new()
	down.button_index = JOY_BUTTON_DPAD_DOWN
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	assert(lab.controls.movement().y == 1)
	await pad(JOY_BUTTON_DPAD_DOWN, false)
	await pad(JOY_BUTTON_A)
	assert(lab.gripping)
	await pad(JOY_BUTTON_X)
	assert(lab.feedback.contains("tool stand"), "X reaches the real stand interaction")
	await pad(JOY_BUTTON_LEFT_SHOULDER)
	assert(not lab.music_on)
	await pad(JOY_BUTTON_RIGHT_SHOULDER)
	assert(not lab.sfx.effects_enabled)
	await pad(JOY_BUTTON_START)
	assert(lab.round_state.state == &"paused")
	await pad(JOY_BUTTON_A)
	assert(lab.round_state.state == &"running" and lab.gripping)
	await pad(JOY_BUTTON_Y)
	assert(lab.round_state.state == &"running" and not lab.gripping)
	await pad(JOY_BUTTON_B)
	assert(lab.round_state.state == &"paused")
	await pad(JOY_BUTTON_B)
	assert(lab.round_state.state == &"running")
	lab.round_state.finish(&"timeout")
	await pad(JOY_BUTTON_A)
	assert(lab.round_state.state == &"running" and lab.round_state.score == 0, "A replays after results")
	await axis(JOY_AXIS_LEFT_X, 0.9)
	lab.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	assert(lab.round_state.state == &"paused")
	await pad(JOY_BUTTON_A)
	assert(lab.controls.movement() == Vector2.ZERO, "Focus loss requires stick neutral before moving again")
	await axis(JOY_AXIS_LEFT_X, 0)
	lab.controls.movement()
	await axis(JOY_AXIS_LEFT_X, -0.8)
	assert(lab.controls.movement().x < 0)
	Input.joy_connection_changed.emit(0, false)
	assert(lab.round_state.state == &"paused", "Disconnect pauses an active controller round")
	await axis(JOY_AXIS_LEFT_X, 0)
	lab.controls.movement()
	lab.toggle_pause()
	await settle()
	var touch = lab.hud.touch_controls
	var right: Vector2 = touch.buttons[&"right"].get_global_rect().get_center()
	var lower: Vector2 = touch.buttons[&"down"].get_global_rect().get_center()
	var grip: Vector2 = touch.buttons[&"grip"].get_global_rect().get_center()
	await finger(1, right, true)
	await finger(2, lower, true)
	await finger(3, grip, true)
	assert(lab.controls.movement() == Vector2.ONE and lab.gripping, "Three simultaneous touches move, reel and grip")
	await finger(3, grip, false)
	assert(lab.gripping, "Touch release never toggles grip a second time")
	var drag := InputEventScreenDrag.new()
	drag.index = 1
	drag.position = Vector2.ZERO
	root.push_input(drag, true)
	await process_frame
	assert(lab.controls.movement() == Vector2.DOWN, "Dragging outside releases only that finger's direction")
	await finger(2, Vector2.ZERO, false, true)
	assert(lab.controls.movement() == Vector2.ZERO)
	await finger(1, right, false)
	await finger(1, right, true)
	lab.toggle_pause()
	assert(touch.fingers.is_empty() and lab.controls.virtual_axes == Vector2.ZERO)
	lab.toggle_pause()
	assert(lab.controls.movement() == Vector2.ZERO, "Pause/resume cannot leave touch movement held")
	await finger(1, right, true)
	root.size = Vector2i(844, 390)
	await settle()
	assert(touch.fingers.is_empty(), "Rotation cancels the old touch ownership")
	for dimensions in [Vector2i(320,568), Vector2i(390,844), Vector2i(844,390), Vector2i(854,480), Vector2i(960,540), Vector2i(1280,720), Vector2i(1920,1080)]:
		root.size = dimensions
		await settle()
		var screen := Rect2(Vector2.ZERO, Vector2(dimensions))
		for button in touch.buttons.values():
			assert(screen.encloses(button.get_global_rect()), "Touch controls remain on-screen at %s" % dimensions)
			assert(button.size.x >= 44 and button.size.y >= 44)
		assert(lab.hud.top_panel.get_global_rect().end.y < lab.hud.bottom_panel.get_global_rect().position.y)
		assert(lab.stage.get_rect().end.y <= lab.hud.bottom_panel.get_global_rect().position.y)
		if lab.hud.compact_touch_landscape:
			assert(lab.stage.get_rect().end.x < lab.hud.touch_panel.get_global_rect().position.x)
			assert(lab.stage.size.x > dimensions.x * 0.6, "Landscape yard keeps most of the screen width")
		lab.toggle_pause()
		await settle()
		assert(screen.encloses(lab.hud.action.get_global_rect()), "Phone modal stays on-screen")
		assert(lab.hud.heading.get_global_rect().position.y >= lab.hud.top_panel.get_global_rect().end.y, "Header cannot cover the modal title")
		lab.toggle_pause()
	lab.free()
	await process_frame
	print("INPUT_TEST_OK controller commands, analog deadzone, real motion, disconnect, multi-touch, cancellation, phone layouts")
	quit()
