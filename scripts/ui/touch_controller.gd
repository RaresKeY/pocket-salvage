extends Control
## Screen-space analog stick and independent action fingers; never reserves yard space.
signal axes_changed(axes: Vector2)
signal command_requested(command: StringName)
const Motion = preload("res://scripts/input/crane_motion.gd")
const ICONS := {&"grip": preload("res://assets/ui/mobile/grip.png"), &"swap": preload("res://assets/ui/mobile/swap.png")}
const RADIUS := 56.0
var buttons: Dictionary = {}
var fingers: Dictionary = {}
var stick_center := Vector2.ZERO
var axes := Vector2.ZERO
var stick_finger := -1
var mouse_preview := false
var enabled := false:
	set(value):
		if value == enabled: return
		enabled = value
		if not enabled: release_all()
		queue_redraw()

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	texture_filter = TEXTURE_FILTER_LINEAR
	mouse_preview = OS.get_cmdline_user_args().has("--mobile-preview")
	for key in ICONS:
		var button := Control.new()
		button.mouse_filter = MOUSE_FILTER_IGNORE
		button.custom_minimum_size = Vector2(60, 60)
		button.size = Vector2(60, 60)
		button.tooltip_text = String(key).capitalize()
		add_child(button)
		buttons[key] = button
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	release_all()
	# Screen-relative thumb zones, independent of crane and bin positions.
	stick_center = Vector2(size.x - RADIUS - 22, size.y - RADIUS - 26)
	if buttons.is_empty(): return
	buttons[&"grip"].position = Vector2(20, size.y - 86)
	buttons[&"swap"].position = Vector2(88, size.y - 142)
	queue_redraw()

func _draw() -> void:
	if not enabled: return
	var rim := Color(0.81, 0.84, 0.85, 0.4)
	var fill := Color(0.06, 0.09, 0.11, 0.5)
	draw_circle(stick_center, RADIUS, fill, true, -1, true)
	draw_arc(stick_center, RADIUS, 0, TAU, 64, rim, 1.5, true)
	var knob := stick_center + axes * (RADIUS * 0.64)
	draw_circle(knob + Vector2(0, 2), 24, Color(0, 0, 0, 0.2), true, -1, true)
	draw_circle(knob, 24, Color(0.77, 0.81, 0.82, 0.22 if stick_finger == -1 else 0.4), true, -1, true)
	draw_arc(knob, 24, 0, TAU, 48, rim, 1.5, true)
	for key in buttons:
		var center: Vector2 = buttons[key].position + buttons[key].size * 0.5
		var held: bool = fingers.values().has(key)
		draw_circle(center, 30, Color(0.25, 0.34, 0.34, 0.7) if held else fill, true, -1, true)
		draw_arc(center, 30, 0, TAU, 48, rim, 1.5, true)
		draw_texture_rect(ICONS[key], Rect2(center - Vector2(24, 24), Vector2(48, 48)), false, Color(1, 1, 1, 0.95 if held else 0.7))

func _press(index: int, point: Vector2) -> bool:
	point -= global_position
	for key in buttons:
		if point.distance_to(buttons[key].position + buttons[key].size * 0.5) <= 30:
			fingers[index] = key
			command_requested.emit(key)
			queue_redraw()
			return true
	if stick_finger == -1 and point.distance_to(stick_center) <= RADIUS + 12:
		stick_finger = index
		fingers[index] = &"stick"
		_move(point)
		return true
	return false

func _move(point: Vector2) -> void:
	axes = Motion.analog((point - stick_center) / RADIUS)
	axes_changed.emit(axes)
	queue_redraw()

func _release(index: int) -> bool:
	if not fingers.has(index): return false
	fingers.erase(index)
	if index == stick_finger:
		stick_finger = -1
		axes = Vector2.ZERO
		axes_changed.emit(axes)
	queue_redraw()
	return true

func _input(event: InputEvent) -> void:
	if not enabled or not is_visible_in_tree(): return
	var handled := false
	if event is InputEventScreenTouch:
		handled = _press(event.index, event.position) if event.pressed and not event.canceled else _release(event.index)
	elif event is InputEventScreenDrag and fingers.has(event.index):
		if event.index == stick_finger: _move(event.position - global_position)
		handled = true
	elif mouse_preview and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION:
		handled = _press(-2, event.position) if event.pressed else _release(-2)
	elif mouse_preview and event is InputEventMouseMotion and fingers.has(-2):
		if stick_finger == -2: _move(event.position - global_position)
		handled = true
	if handled: get_viewport().set_input_as_handled()

func release_all() -> void:
	fingers.clear()
	stick_finger = -1
	axes = Vector2.ZERO
	axes_changed.emit(axes)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT: release_all()
