extends HBoxContainer
## Multi-touch controller. Each finger owns its button until release or cancellation.
signal axes_changed(axes: Vector2)
signal command_requested(command: StringName)
const DIRECTIONS := {&"left": Vector2.LEFT, &"right": Vector2.RIGHT, &"up": Vector2.UP, &"down": Vector2.DOWN}
var buttons: Dictionary = {}
var fingers: Dictionary = {}
var enabled := false:
	set(value):
		if value == enabled: return
		enabled = value
		for button in buttons.values(): button.disabled = not enabled
		if not enabled: release_all()

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 8)
	var pad := GridContainer.new()
	pad.columns = 3
	pad.mouse_filter = MOUSE_FILTER_IGNORE
	pad.add_theme_constant_override("h_separation", 4)
	pad.add_theme_constant_override("v_separation", 4)
	add_child(pad)
	for key in [&"", &"up", &"", &"left", &"", &"right", &"", &"down", &""]:
		if key == &"":
			var spacer := Control.new()
			spacer.mouse_filter = MOUSE_FILTER_IGNORE
			spacer.custom_minimum_size = Vector2(44, 44)
			pad.add_child(spacer)
		else: _button(pad, key, {&"up":"↑", &"down":"↓", &"left":"←", &"right":"→"}[key])
	var actions := VBoxContainer.new()
	actions.mouse_filter = MOUSE_FILTER_IGNORE
	actions.add_theme_constant_override("separation", 8)
	actions.size_flags_vertical = SIZE_SHRINK_CENTER
	add_child(actions)
	_button(actions, &"grip", "Grip")
	_button(actions, &"swap", "Swap")
	resized.connect(release_all)

func _button(parent: Node, key: StringName, text: String) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(44 if DIRECTIONS.has(key) else 64, 44)
	button.focus_mode = FOCUS_NONE
	button.mouse_filter = MOUSE_FILTER_IGNORE
	button.toggle_mode = true
	button.disabled = not enabled
	parent.add_child(button)
	buttons[key] = button

func _at(point: Vector2) -> StringName:
	for key in buttons:
		if buttons[key].get_global_rect().has_point(point): return key
	return &""

func _input(event: InputEvent) -> void:
	if not enabled or not is_visible_in_tree(): return
	if event is InputEventScreenTouch:
		if not event.pressed or event.canceled:
			if not fingers.has(event.index): return
			fingers.erase(event.index)
		else:
			var key := _at(event.position)
			if key == &"": return
			fingers[event.index] = key
			if not DIRECTIONS.has(key): command_requested.emit(key)
		_update_axes()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and fingers.has(event.index):
		if DIRECTIONS.has(fingers[event.index]) or fingers[event.index] == &"":
			var key := _at(event.position)
			fingers[event.index] = key if DIRECTIONS.has(key) else &""
			_update_axes()
		get_viewport().set_input_as_handled()

func _update_axes() -> void:
	var axes := Vector2.ZERO
	for key in buttons:
		var pressed := fingers.values().has(key)
		buttons[key].set_pressed_no_signal(pressed)
		if pressed and DIRECTIONS.has(key): axes += DIRECTIONS[key]
	axes_changed.emit(axes)

func release_all() -> void:
	fingers.clear()
	_update_axes()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT: release_all()
