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
	var motion = preload("res://scripts/input/crane_motion.gd")
	assert(motion.analog(Vector2(0.19, 0), 0.2) == Vector2.ZERO)
	assert(motion.analog(Vector2(0.01, 0)).x > 0)
	assert(motion.analog(Vector2(2, 2)).length() <= 1.00001)
	assert(motion.combine(Vector2.RIGHT, Vector2.RIGHT, Vector2.RIGHT) == Vector2.RIGHT)
	assert(motion.velocity(Vector2(20, -20)) == Vector2(220, -130))
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
	await pad(JOY_BUTTON_DPAD_DOWN)
	await pad(JOY_BUTTON_DPAD_LEFT)
	assert(is_equal_approx(lab.sfx.music_volume, 0.95), "Pause D-pad changes actual music volume")
	await pad(JOY_BUTTON_DPAD_DOWN)
	await pad(JOY_BUTTON_DPAD_LEFT)
	assert(is_equal_approx(lab.sfx.effects_volume, 0.95), "Pause D-pad changes actual SFX volume")
	await pad(JOY_BUTTON_DPAD_UP)
	await pad(JOY_BUTTON_DPAD_UP)

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
	var right: Vector2 = touch.global_position + touch.stick_center + Vector2(touch.RADIUS, 0)
	var grip: Vector2 = touch.buttons[&"grip"].get_global_rect().get_center()
	await finger(1, right, true)
	await finger(3, grip, true)
	assert(lab.controls.movement() == Vector2.RIGHT and lab.gripping, "Independent movement and action fingers")
	await finger(3, grip, false)
	assert(lab.gripping, "Release never toggles grip twice")
	var drag := InputEventScreenDrag.new()
	drag.index = 1
	drag.position = touch.global_position + touch.stick_center + Vector2(1, 0)
	root.push_input(drag, true)
	await process_frame
	assert(lab.controls.movement().x > 0 and lab.controls.movement().x < 0.05, "Touch has no deadzone")
	drag.position = touch.global_position + touch.stick_center + Vector2(500, 500)
	root.push_input(drag, true)
	await process_frame
	assert(is_equal_approx(lab.controls.movement().length(), 1.0), "Drag beyond the ring caps diagonal speed")
	await finger(2, right, true)
	assert(touch.stick_finger == 1, "Second finger cannot steal the stick")
	await finger(1, Vector2.ZERO, false, true)
	assert(lab.controls.movement() == Vector2.ZERO)
	await finger(1, right, true)
	lab.toggle_pause()
	assert(touch.fingers.is_empty() and lab.controls.virtual_axes == Vector2.ZERO)
	lab.toggle_pause()
	assert(lab.controls.movement() == Vector2.ZERO, "Pause/resume cannot leave touch movement held")
	await finger(1, right, true)
	root.size = Vector2i(844, 390)
	await settle()
	assert(touch.fingers.is_empty(), "Rotation cancels the old touch ownership")
	touch.mouse_preview = true
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.position = touch.global_position + touch.stick_center
	mouse.pressed = true
	root.push_input(mouse, true)
	var mouse_drag := InputEventMouseMotion.new()
	mouse_drag.position = mouse.position + Vector2(touch.RADIUS * 0.5, 0)
	root.push_input(mouse_drag, true)
	assert(is_equal_approx(lab.controls.movement().x, 0.5), "Linux preview mouse drag is proportional")
	mouse.pressed = false
	mouse.position = Vector2.ZERO
	root.push_input(mouse, true)
	assert(lab.controls.movement() == Vector2.ZERO, "Mouse release outside the ring clears motion")
	touch.mouse_preview = false
	for dimensions in [Vector2i(320,568), Vector2i(390,844), Vector2i(568,320), Vector2i(640,360), Vector2i(844,390), Vector2i(854,480), Vector2i(960,540), Vector2i(1280,720), Vector2i(1920,1080)]:
		root.size = dimensions
		lab.round_state.score = 4320
		lab.round_state.remaining_time = 9
		lab._say("The magnet won't hold rubber. Swap to the claw at the tool stands.", 10)
		await settle()
		var screen := Rect2(Vector2.ZERO, Vector2(dimensions))
		for button in touch.buttons.values():
			assert(screen.encloses(button.get_global_rect()), "Touch controls remain on-screen at %s" % dimensions)
			assert(button.size.x >= 44 and button.size.y >= 44)
		assert(lab.hud.top_panel.get_global_rect().end.x <= dimensions.x - 56, "Header leaves fullscreen target clear at %s: %s" % [dimensions, lab.hud.top_panel.get_global_rect()])
		assert(lab.stage.size.x == dimensions.x, "Overlay reserves no yard column")
		assert(lab.stage.get_rect().end.y == dimensions.y, "Yard extends behind the controls")
		if dimensions.x > dimensions.y:
			assert(lab.stage.position == Vector2.ZERO and lab.stage.size == Vector2(dimensions), "Landscape HUD reserves no game height")
			assert(lab.hud.top_panel.get_theme_stylebox("panel") is StyleBoxEmpty, "Landscape running HUD has no solid panel")
			assert(not lab.hud.music_button.visible and not lab.hud.effects_button.visible, "Landscape running actions keep room for counters")
			assert(lab.hud.pause_button.size.y >= 52)
			for label in [lab.hud.score_label, lab.hud.time_label, lab.hud.progress_label]:
				assert(label.get_theme_font_size("font_size") >= 24 and label.get_theme_constant("outline_size") >= 4, "Counters stay large and outlined over the yard")
				assert(screen.encloses(label.get_global_rect()), "Overlay counters stay on screen")
			assert(lab.hud.score_label.get_global_rect().end.x <= lab.hud.time_label.global_position.x, "Four-digit score leaves the timer clear")
			assert(lab.hud.progress_label.get_global_rect().end.x <= lab.hud.pause_button.global_position.x, "Progress leaves Pause clear")
			assert(lab.hud.time_label.get_theme_color("font_color") == lab.hud.HURRY_COLOR, "Outlined timer preserves the hurry warning")
		else:
			assert(lab.stage.position.y > 0 and lab.hud.music_button.visible, "Portrait restores its existing header")
			assert(lab.hud.score_label.get_theme_constant("outline_size") == 0, "Rotation clears landscape styling")
		assert(screen.has_point(touch.stick_center + Vector2(touch.RADIUS, touch.RADIUS)))
		assert(touch.buttons[&"swap"].position.y < touch.buttons[&"grip"].position.y)
		var running_stage: Rect2 = lab.stage.get_rect()
		lab.toggle_pause()
		await settle()
		assert(lab.hud.music_button.visible and lab.hud.effects_button.visible and lab.hud.audio_settings.visible, "Audio remains accessible in Pause")
		if dimensions.x > dimensions.y: assert(lab.stage.get_rect() == running_stage, "Opening Pause does not shrink the landscape yard")
		assert(screen.encloses(lab.hud.action.get_global_rect()), "Phone modal stays on-screen")
		assert(lab.hud.heading.get_global_rect().position.y >= lab.hud.top_panel.get_global_rect().end.y, "Header cannot cover the modal title at %s" % dimensions)
		lab.toggle_pause()
	root.size = Vector2i(568, 320)
	await settle()
	lab.toggle_pause()
	await settle()
	lab.toggle_pause()
	lab.round_state.tick(241)
	await settle()
	assert(lab.hud.state == "finished")
	assert(is_equal_approx(lab.hud.top_panel.size.y, lab.hud.top_panel.get_combined_minimum_size().y), "Results header has no leftover height")
	assert(lab.hud.heading.global_position.y >= lab.hud.top_panel.get_global_rect().end.y, "Results header shrinks after wrapped landscape feedback hides")
	assert(Rect2(Vector2.ZERO, Vector2(568,320)).encloses(lab.hud.action.get_global_rect()), "Landscape Retry remains reachable")
	lab.free()
	await process_frame
	print("INPUT_TEST_OK controller commands, analog deadzone, real motion, disconnect, multi-touch, cancellation, phone layouts")
	quit()
