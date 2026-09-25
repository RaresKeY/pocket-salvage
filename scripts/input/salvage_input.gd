extends Node
## Keyboard/gamepad movement and device-neutral commands for the playable scene.
signal command_requested(command: StringName)
signal scheme_changed(scheme: StringName)
signal controls_released

const DEADZONE := 0.2
const DIRECTIONS := [&"salvage_left", &"salvage_right", &"salvage_up", &"salvage_down"]
const PAD_COMMANDS := {
	JOY_BUTTON_A: &"primary", JOY_BUTTON_X: &"swap", JOY_BUTTON_Y: &"restart",
	JOY_BUTTON_START: &"menu", JOY_BUTTON_B: &"pause",
	JOY_BUTTON_LEFT_SHOULDER: &"music", JOY_BUTTON_RIGHT_SHOULDER: &"effects",
	JOY_BUTTON_DPAD_UP: &"settings_up", JOY_BUTTON_DPAD_DOWN: &"settings_down",
	JOY_BUTTON_DPAD_LEFT: &"settings_left", JOY_BUTTON_DPAD_RIGHT: &"settings_right",
}
const KEY_COMMANDS := {
	KEY_SPACE: &"grip", KEY_E: &"swap", KEY_R: &"restart", KEY_M: &"music",
	KEY_P: &"pause", KEY_ESCAPE: &"pause", KEY_ENTER: &"primary", KEY_F2: &"preview",
}
var scheme: StringName = &"keyboard"
var mobile_touch := false
var playing := false
var virtual_axes := Vector2.ZERO
var active_pad := -1
var _neutral_required := false

static func wants_touch(web: bool, android: bool, ios: bool) -> bool:
	return web and (android or ios)

func _ready() -> void:
	mobile_touch = wants_touch(OS.has_feature("web"), OS.has_feature("web_android"), OS.has_feature("web_ios"))
	# iPadOS can identify as a Mac when requesting desktop sites.
	if OS.has_feature("web") and not mobile_touch:
		mobile_touch = bool(JavaScriptBridge.eval("/Android|iPhone|iPad|iPod/i.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)"))
	mobile_touch = mobile_touch or OS.get_cmdline_user_args().has("--touch-controls")
	if mobile_touch: scheme = &"touch"
	install_movement_actions()
	Input.joy_connection_changed.connect(_connection_changed)

static func install_movement_actions() -> void:
	var keys := [[KEY_A, KEY_LEFT], [KEY_D, KEY_RIGHT], [KEY_W, KEY_UP], [KEY_S, KEY_DOWN]]
	var buttons := [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN]
	for index in DIRECTIONS.size():
		var action: StringName = DIRECTIONS[index]
		if InputMap.has_action(action): continue
		InputMap.add_action(action, DEADZONE)
		for code in keys[index]:
			var key := InputEventKey.new()
			key.physical_keycode = code
			InputMap.action_add_event(action, key)
		var button := InputEventJoypadButton.new()
		button.device = -1
		button.button_index = buttons[index]
		InputMap.action_add_event(action, button)
		var axis := InputEventJoypadMotion.new()
		axis.device = -1
		axis.axis = JOY_AXIS_LEFT_X if index < 2 else JOY_AXIS_LEFT_Y
		axis.axis_value = -1.0 if index % 2 == 0 else 1.0
		InputMap.action_add_event(action, axis)

func set_playing(value: bool) -> void:
	if value == playing: return
	playing = value
	if not playing: release_controls()

func release_controls() -> void:
	virtual_axes = Vector2.ZERO
	_neutral_required = true
	controls_released.emit()

func set_touch_axes(value: Vector2) -> void:
	virtual_axes = value if playing else Vector2.ZERO
	if value != Vector2.ZERO: _set_scheme(&"touch")

func touch_command(command: StringName) -> void:
	_set_scheme(&"touch")
	command_requested.emit(command)

func movement() -> Vector2:
	var physical := Vector2(Input.get_axis(DIRECTIONS[0], DIRECTIONS[1]), Input.get_axis(DIRECTIONS[2], DIRECTIONS[3]))
	if _neutral_required:
		if physical.length_squared() < 0.0001: _neutral_required = false
		else: return Vector2.ZERO
	if not playing: return Vector2.ZERO
	return (physical + virtual_axes).clamp(Vector2(-1, -1), Vector2.ONE)

func _set_scheme(value: StringName) -> void:
	if value == scheme: return
	scheme = value
	scheme_changed.emit(scheme)

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion and absf(event.axis_value) > DEADZONE:
		active_pad = event.device
		_set_scheme(&"gamepad")
	elif event is InputEventJoypadButton:
		if event.pressed:
			active_pad = event.device
			_set_scheme(&"gamepad")
			if PAD_COMMANDS.has(event.button_index): command_requested.emit(PAD_COMMANDS[event.button_index])
		# Gamepad commands and D-pad belong to the crane, not implicit GUI focus movement.
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed:
		_set_scheme(&"keyboard")

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and KEY_COMMANDS.has(event.physical_keycode):
		get_viewport().set_input_as_handled()
		command_requested.emit(KEY_COMMANDS[event.physical_keycode])

func _connection_changed(device: int, connected: bool) -> void:
	if connected or device != active_pad: return
	release_controls()
	active_pad = -1
	if playing and scheme == &"gamepad": command_requested.emit(&"pause")
	_set_scheme(&"touch" if mobile_touch else &"keyboard")
