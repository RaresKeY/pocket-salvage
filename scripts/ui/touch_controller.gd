extends Control
## Screen-space analog stick and independent action fingers; never reserves yard space.
signal axes_changed(axes: Vector2)
signal command_requested(command: StringName)
const Motion = preload("res://scripts/input/crane_motion.gd")
## Action buttons: command -> icon and its centre, measured from the screen's bottom-left corner.
const BUTTONS := {
	&"grip": {"icon": preload("res://assets/ui/mobile/grip.png"), "at": Vector2(50, -56)},
	&"swap": {"icon": preload("res://assets/ui/mobile/swap.png"), "at": Vector2(118, -112)},
}
const RADIUS := 56.0
const BUTTON_RADIUS := 30.0
const KNOB_RADIUS := 24.0
const ICON_SIZE := 48.0
## Finger id for the mouse in --mobile-preview.
const MOUSE_FINGER := -2
const NO_FINGER := -1
const RIM := Color(0.81, 0.84, 0.85, 0.4)
const FILL := Color(0.06, 0.09, 0.11, 0.5)
const HELD_FILL := Color(0.25, 0.34, 0.34, 0.7)
var buttons: Dictionary = {}
var fingers: Dictionary = {}
var stick_center := Vector2.ZERO
var axes := Vector2.ZERO
var stick_finger := NO_FINGER
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
	for key in BUTTONS:
		var button := Control.new()
		button.mouse_filter = MOUSE_FILTER_IGNORE
		button.custom_minimum_size = Vector2.ONE * BUTTON_RADIUS * 2
		button.size = button.custom_minimum_size
		add_child(button)
		buttons[key] = button
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	release_all()
	# Screen-relative thumb zones, independent of crane and bin positions.
	stick_center = Vector2(size.x - RADIUS - 22, size.y - RADIUS - 26)
	if buttons.is_empty(): return
	for key in buttons:
		buttons[key].position = Vector2(0, size.y) + BUTTONS[key].at - Vector2.ONE * BUTTON_RADIUS
	queue_redraw()

func _draw() -> void:
	if not enabled: return
	_draw_disc(stick_center, RADIUS, FILL, 64)
	var knob := stick_center + axes * (RADIUS * 0.64)
	draw_circle(knob + Vector2(0, 2), KNOB_RADIUS, Color(0, 0, 0, 0.2), true, -1, true)
	_draw_disc(knob, KNOB_RADIUS, Color(0.77, 0.81, 0.82, 0.22 if stick_finger == NO_FINGER else 0.4), 48)
	for key in buttons:
		var center := _button_center(key)
		var held: bool = fingers.values().has(key)
		_draw_disc(center, BUTTON_RADIUS, HELD_FILL if held else FILL, 48)
		draw_texture_rect(BUTTONS[key].icon, Rect2(center - Vector2.ONE * ICON_SIZE * 0.5, Vector2.ONE * ICON_SIZE), false, Color(1, 1, 1, 0.95 if held else 0.7))

## A filled circle with the shared rim.
func _draw_disc(center: Vector2, radius: float, fill: Color, points: int) -> void:
	draw_circle(center, radius, fill, true, -1, true)
	draw_arc(center, radius, 0, TAU, points, RIM, 1.5, true)

func _button_center(key: StringName) -> Vector2:
	return buttons[key].position + buttons[key].size * 0.5

func _press(index: int, point: Vector2) -> bool:
	point -= global_position
	for key in buttons:
		if point.distance_to(_button_center(key)) <= BUTTON_RADIUS:
			fingers[index] = key
			command_requested.emit(key)
			queue_redraw()
			return true
	if stick_finger == NO_FINGER and point.distance_to(stick_center) <= RADIUS + 12:
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
	if index == stick_finger: _reset_stick()
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
		handled = _press(MOUSE_FINGER, event.position) if event.pressed else _release(MOUSE_FINGER)
	elif mouse_preview and event is InputEventMouseMotion and fingers.has(MOUSE_FINGER):
		if stick_finger == MOUSE_FINGER: _move(event.position - global_position)
		handled = true
	if handled: get_viewport().set_input_as_handled()

func release_all() -> void:
	fingers.clear()
	_reset_stick()
	queue_redraw()

func _reset_stick() -> void:
	stick_finger = NO_FINGER
	axes = Vector2.ZERO
	axes_changed.emit(axes)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT: release_all()
