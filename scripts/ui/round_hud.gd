extends Control
## Presentation-only round HUD. The caller owns game state and shortcuts.
signal level_selected(index: int)
signal levels_requested
signal start_requested
signal restart_requested
signal pause_requested
signal music_requested
signal effects_requested
signal volume_requested(music: float, effects: float)
signal debug_requested(hitboxes: bool, masks: bool)
signal layout_changed

const Levels = preload("res://scripts/level/level_catalog.gd")
var level_grid: GridContainer
var level_buttons: Array[Button] = []
var levels_button: Button
var selected_level := 0
const TouchController = preload("res://scripts/ui/touch_controller.gd")
var developer_enabled := false
var developer_section: VBoxContainer
var developer_button: Button
var developer_controls: HBoxContainer
var hitboxes_check: CheckButton
var masks_check: CheckButton
var touch_enabled := false
var touch_controls: HBoxContainer
var modal_card: PanelContainer
var modal_center: CenterContainer
var modal_content: VBoxContainer
var footer: BoxContainer
var touch_panel: PanelContainer
var world_right_inset := 0.0
var compact_touch_landscape := false
const YardTheme = preload("res://scripts/ui/yard_theme.gd")
var header_row: BoxContainer
var audio_settings: VBoxContainer
var music_slider: HSlider
var effects_slider: HSlider
var music_value: Label
var effects_value: Label
## Below this height the start card drops the weather tip so Start stays on screen.
const SHORT_SCREEN := 420.0
const HURRY_SECONDS := 10
const HURRY_COLOR := Color("ff6b5b")
const CONTROL_HINTS := "A/D move · W/S lift · Space grip · E swap · P pause · R restart"
var top_panel: PanelContainer
var bottom_panel: PanelContainer
var music_button: Button
var effects_button: Button
var hints_label: Label
var score_label: Label
var time_label: Label
var progress_label: Label
var weather_badge: Label
var magnet_label: Label
var feedback_label: Label
var modal: ColorRect
var heading: Label
var details: Label
var action: Button
var pause_button: Button
var state := ""
var _pending: Dictionary = {}
var _displayed: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = YardTheme.make()
	var top := PanelContainer.new()
	top_panel = top
	top.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	top.offset_left = 8
	top.offset_right = -8
	top.offset_top = 6
	var compact: StyleBoxFlat = theme.get_stylebox("panel", "PanelContainer").duplicate()
	compact.set_content_margin_all(8)
	top.add_theme_stylebox_override("panel", compact)
	add_child(top)
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	top.add_child(header)
	header_row = BoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	header.add_child(header_row)
	var counters := HBoxContainer.new()
	counters.size_flags_horizontal = SIZE_EXPAND_FILL
	counters.add_theme_constant_override("separation", 10)
	header_row.add_child(counters)
	score_label = _label(counters, "Score  0")
	counters.add_child(VSeparator.new())
	time_label = _label(counters, "Time  0:00")
	counters.add_child(VSeparator.new())
	progress_label = _label(counters, "Sorted  0 / 0")
	for label in [score_label, time_label, progress_label]:
		label.size_flags_horizontal = SIZE_EXPAND_FILL
		label.size_flags_vertical = SIZE_SHRINK_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 4)
	header_row.add_child(actions)
	music_button = _audio_button(actions, "Music on", "Toggle music (M). Volume sliders are in Pause.", func(): music_requested.emit())
	effects_button = _audio_button(actions, "SFX on", "Toggle effects. Volume sliders are in Pause.", func(): effects_requested.emit())
	pause_button = Button.new()
	pause_button.text = "Pause"
	pause_button.custom_minimum_size = Vector2(70, 44)
	pause_button.pressed.connect(func(): pause_requested.emit())
	actions.add_child(pause_button)
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 12)
	header.add_child(status_row)
	magnet_label = _label(status_row, "Magnet OFF  ·  Empty")
	magnet_label.size_flags_horizontal = SIZE_EXPAND_FILL
	magnet_label.add_theme_font_size_override("font_size", 16)
	magnet_label.add_theme_color_override("font_color", YardTheme.MUTED)
	weather_badge = _label(status_row, "")
	weather_badge.add_theme_font_size_override("font_size", 16)
	weather_badge.autowrap_mode = TextServer.AUTOWRAP_OFF
	weather_badge.visible = false
	var bottom := PanelContainer.new()
	bottom_panel = bottom
	bottom.add_theme_stylebox_override("panel", compact)
	bottom.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	bottom.grow_vertical = GROW_DIRECTION_BEGIN
	bottom.offset_left = 8
	bottom.offset_right = -8
	bottom.offset_bottom = -28
	add_child(bottom)
	footer = BoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	bottom.add_child(footer)
	var foot := VBoxContainer.new()
	foot.size_flags_horizontal = SIZE_EXPAND_FILL
	foot.size_flags_vertical = SIZE_SHRINK_CENTER
	footer.add_child(foot)
	touch_controls = TouchController.new()
	touch_controls.visible = touch_enabled
	touch_controls.size_flags_horizontal = SIZE_SHRINK_END
	touch_controls.size_flags_vertical = SIZE_SHRINK_CENTER
	footer.add_child(touch_controls)
	touch_panel = PanelContainer.new()
	touch_panel.add_theme_stylebox_override("panel", compact)
	touch_panel.set_anchors_and_offsets_preset(PRESET_BOTTOM_RIGHT)
	touch_panel.grow_horizontal = GROW_DIRECTION_BEGIN
	touch_panel.grow_vertical = GROW_DIRECTION_BEGIN
	touch_panel.offset_right = -12
	touch_panel.offset_bottom = -28
	touch_panel.visible = false
	add_child(touch_panel)
	feedback_label = _label(foot, "")
	feedback_label.add_theme_color_override("font_color", Color("a1e8c1"))
	hints_label = _label(foot, CONTROL_HINTS)
	hints_label.add_theme_font_size_override("font_size", 16)
	modal = ColorRect.new()
	modal.color = Color(0.03, 0.06, 0.08, 0.65)
	modal.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(modal)
	var center := CenterContainer.new()
	modal_center = center
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	center.mouse_filter = MOUSE_FILTER_IGNORE
	modal.add_child(center)
	var card := PanelContainer.new()
	modal_card = card
	card.custom_minimum_size.x = 460
	center.add_child(card)
	var content := VBoxContainer.new()
	modal_content = content
	content.add_theme_constant_override("separation", 10)
	card.add_child(content)
	heading = _label(content, "Pocket Salvage")
	heading.add_theme_font_size_override("font_size", 30)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_build_level_grid(content)
	details = _label(content, "")
	details.custom_minimum_size.x = 0
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action = Button.new()
	action.custom_minimum_size.y = 48
	var primary: StyleBoxFlat = theme.get_stylebox("normal", "Button").duplicate()
	primary.bg_color = Color("355c50")
	action.add_theme_stylebox_override("normal", primary)
	action.pressed.connect(_activate)
	var action_row := HBoxContainer.new()
	content.add_child(action_row)
	action.size_flags_horizontal = SIZE_EXPAND_FILL
	action_row.add_child(action)
	levels_button = Button.new()
	levels_button.text = "Levels"
	levels_button.custom_minimum_size = Vector2(80, 44)
	levels_button.pressed.connect(func(): levels_requested.emit())
	action_row.add_child(levels_button)
	_build_audio_settings(content)
	if developer_enabled: _build_developer_options(content)
	var version := Label.new()
	version.name = "Version"
	version.text = "v" + str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	version.add_theme_font_size_override("font_size", 12)
	version.add_theme_color_override("font_color", Color("b0bdc4"))
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version.set_anchors_and_offsets_preset(PRESET_BOTTOM_RIGHT)
	version.offset_left = -90
	version.offset_right = -12
	version.offset_top = -22
	version.offset_bottom = -4
	add_child(version)
	# Audio controls stay available above the modal on ready, pause and results.
	move_child(top, get_child_count() - 1)
	_ignore_decoration(self)
	modal.mouse_filter = MOUSE_FILTER_STOP
	top.resized.connect(func(): _layout_modal(); layout_changed.emit())
	bottom.resized.connect(func(): layout_changed.emit())
	resized.connect(_responsive_layout)
	# Card text depends on screen height, and unchanged data is cached, so force a rebuild on resize.
	resized.connect(func(): _displayed = {}; present(_pending))
	_responsive_layout()
	present(_pending)

func _build_level_grid(parent: VBoxContainer) -> void:
	level_grid = GridContainer.new()
	level_grid.columns = 6
	level_grid.add_theme_constant_override("h_separation", 4)
	level_grid.add_theme_constant_override("v_separation", 4)
	parent.add_child(level_grid)
	for index in Levels.SLOT_COUNT:
		var button := Button.new()
		button.text = "%02d" % (index + 1) if Levels.unlocked(index) else "%02d\nLOCKED" % (index + 1)
		button.tooltip_text = Levels.title(index)
		button.disabled = not Levels.unlocked(index)
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(44, 44)
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(func():
			if Levels.unlocked(index): level_selected.emit(index))
		level_grid.add_child(button)
		level_buttons.append(button)

func _unhandled_key_input(event: InputEvent) -> void:
	if state != "ready" or not level_grid.visible: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_LEFT, KEY_RIGHT]:
			settings_command(&"settings_left" if event.physical_keycode == KEY_LEFT else &"settings_right")
			get_viewport().set_input_as_handled()

func _build_audio_settings(parent: VBoxContainer) -> void:
	audio_settings = VBoxContainer.new()
	audio_settings.add_theme_constant_override("separation", 0)
	parent.add_child(audio_settings)
	for name in ["Music", "SFX"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		audio_settings.add_child(row)
		var label := _label(row, name)
		label.custom_minimum_size.x = 55
		label.size_flags_vertical = SIZE_SHRINK_CENTER
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.value = 100
		slider.size_flags_horizontal = SIZE_EXPAND_FILL
		slider.custom_minimum_size = Vector2(90, 36)
		slider.tooltip_text = name + " volume. Left/right adjusts; mute is separate."
		row.add_child(slider)
		var value := _label(row, "100%")
		value.custom_minimum_size.x = 44
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.size_flags_vertical = SIZE_SHRINK_CENTER
		if name == "Music":
			music_slider = slider
			music_value = value
		else:
			effects_slider = slider
			effects_value = value
	for slider in [music_slider, effects_slider]:
		slider.value_changed.connect(func(_value: float):
			_update_volume_labels()
			volume_requested.emit(music_slider.value / 100.0, effects_slider.value / 100.0))

func _update_volume_labels() -> void:
	music_value.text = "%d%%" % int(music_slider.value)
	effects_value.text = "%d%%" % int(effects_slider.value)

func _build_developer_options(parent: VBoxContainer) -> void:
	developer_section = VBoxContainer.new()
	developer_section.add_theme_constant_override("separation", 4)
	parent.add_child(developer_section)
	developer_button = Button.new()
	developer_button.text = "Developer options"
	developer_button.toggle_mode = true
	developer_button.custom_minimum_size.y = 40
	developer_section.add_child(developer_button)
	developer_controls = HBoxContainer.new()
	developer_controls.visible = false
	developer_section.add_child(developer_controls)
	developer_button.toggled.connect(func(open: bool):
		developer_controls.visible = open
		audio_settings.visible = not open and state == "paused")
	hitboxes_check = CheckButton.new()
	hitboxes_check.text = "Hitboxes"
	hitboxes_check.custom_minimum_size.y = 40
	hitboxes_check.size_flags_horizontal = SIZE_EXPAND_FILL
	developer_controls.add_child(hitboxes_check)
	masks_check = CheckButton.new()
	masks_check.text = "Masks (art / active)"
	masks_check.custom_minimum_size.y = 40
	masks_check.size_flags_horizontal = SIZE_EXPAND_FILL
	developer_controls.add_child(masks_check)
	for button in [hitboxes_check, masks_check]:
		button.toggled.connect(func(_on: bool): debug_requested.emit(hitboxes_check.button_pressed, masks_check.button_pressed))
	hitboxes_check.tooltip_text = "Green: physical shapes. Blue: Area2D sensors. Disabled shapes are omitted."
	masks_check.tooltip_text = "Pink: source art masks, not collision geometry. Orange: active visual occlusion masks."

func _audio_button(parent: Node, text: String, hint: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = hint
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(78, 44)
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(func():
		callback.call()
		if state == "running": button.release_focus())
	parent.add_child(button)
	return button

func _label(parent: Node, text: String) -> Label:
	var result := Label.new()
	result.text = text
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(result)
	return result

func _ignore_decoration(node: Node) -> void:
	if node is Control and not node is BaseButton and not node is Range:
		node.mouse_filter = MOUSE_FILTER_IGNORE
	for child in node.get_children(): _ignore_decoration(child)

func present(data: Dictionary) -> void:
	_pending = data.duplicate()
	if not is_node_ready(): return
	var seconds := maxi(0, ceili(float(data.get("time_left", 0.0))))
	_pending["time_left"] = seconds
	var hurry := str(data.get("state", "ready")) == "running" and seconds <= HURRY_SECONDS
	time_label.modulate.a = 0.55 + 0.45 * absf(cos(Time.get_ticks_msec() * 0.006)) if hurry else 1.0
	# Most physics ticks change no displayed value. Avoid rebuilding hidden modal text,
	# button state and theme overrides until a visible value actually changes.
	if _displayed == _pending: return
	_displayed = _pending.duplicate()
	var navigation := str(data.get("navigation_hint", ""))
	var scheme := str(data.get("control_scheme", "keyboard"))
	var hints := CONTROL_HINTS
	if scheme == "gamepad": hints = "Stick/D-pad move/lift · A grip · X swap · Start pause · Y restart · LB music · RB SFX"
	elif touch_enabled: hints = "Hold arrows to move/lift. Tap Grip or Swap."
	hints_label.text = hints + ("   ·   " + navigation if not navigation.is_empty() else "")
	var previous := state
	state = str(data.get("state", "ready"))
	selected_level = int(data.get("selected_level", 0))
	level_grid.visible = state == "ready" and bool(data.get("level_menu", false))
	levels_button.visible = (state == "paused" or (state == "finished" and not bool(data.get("victory", false)))) and bool(data.get("level_menu", false))
	for index in level_buttons.size(): level_buttons[index].set_pressed_no_signal(index == selected_level)
	touch_controls.enabled = state == "running"
	music_button.set_pressed_no_signal(data.get("music_on", true))
	music_button.text = "Music on" if music_button.button_pressed else "Music off"
	effects_button.set_pressed_no_signal(data.get("effects_on", true))
	effects_button.text = "SFX on" if effects_button.button_pressed else "SFX off"
	score_label.text = "Score  %d" % int(data.get("score", 0))
	time_label.text = "Time  %d:%02d" % [seconds / 60, seconds % 60]
	if hurry: time_label.add_theme_color_override("font_color", HURRY_COLOR)
	else: time_label.remove_theme_color_override("font_color")
	progress_label.text = "Sorted  %d / %d" % [int(data.get("delivered", 0)), int(data.get("total", 0))]
	var weather := str(data.get("weather_label", ""))
	weather_badge.text = weather
	weather_badge.visible = not weather.is_empty()
	var held := str(data.get("held_material", ""))
	var grip := str(data.get("grip_label", "Magnet " + ("ON" if data.get("magnet_on", false) else "OFF")))
	magnet_label.text = "%s  ·  %s" % [grip, "Carrying " + held if not held.is_empty() else "Empty"]
	feedback_label.text = str(data.get("feedback", ""))
	feedback_label.visible = not feedback_label.text.is_empty()
	audio_settings.visible = state == "paused" and (developer_button == null or not developer_button.button_pressed)
	music_slider.set_value_no_signal(float(data.get("music_volume", 1.0)) * 100.0)
	effects_slider.set_value_no_signal(float(data.get("effects_volume", 1.0)) * 100.0)
	_update_volume_labels()
	if developer_section != null:
		developer_section.visible = state == "paused"
		if state != "paused":
			developer_button.set_pressed_no_signal(false)
			developer_controls.hide()
	modal.visible = state != "running"
	pause_button.visible = state == "running"
	details.visible = true
	match state:
		"paused":
			heading.text = "Paused"
			details.text = ""
			details.visible = false
			action.text = "Resume"
		"finished":
			heading.text = "Victory!" if bool(data.get("victory", false)) else "Round complete"
			var reason := str(data.get("finish_reason", ""))
			details.text = "%s\nScore  %d\nCorrect  %d  ·  Wrong  %d" % [reason, int(data.get("score", 0)), int(data.get("correct", 0)), int(data.get("wrong", 0))]
			var bonus := int(data.get("time_bonus", 0))
			if bonus > 0: details.text += "\nTime bonus  +%d" % bonus
			var weather_bonus := int(data.get("weather_bonus", 0))
			if weather_bonus > 0: details.text += "\n%s  +%d" % [weather, weather_bonus]
			action.text = "Continue" if bool(data.get("victory", false)) else ("Retry" if bool(data.get("level_menu", false)) else "Play again")
		_:
			heading.text = "Pocket Salvage"
			details.text = "10 pieces · 4 minutes\nMagnet lifts steel. Claw lifts copper and rubber.\nPark and swap heads at the left stands.\nSort into matching bins. Wrong bin: −25."
			if not weather.is_empty():
				if get_viewport_rect().size.y < SHORT_SCREEN: details.text = "%s · %s" % [weather, details.text]
				else: details.text = "%s: %s\n%s" % [weather, str(data.get("weather_tip", "")), details.text]
			action.text = "Start round"
			if level_grid.visible:
				heading.text = "Choose a level"
				details.text = "%02d  %s · %d pieces" % [selected_level + 1, Levels.title(selected_level), Levels.scrap_count(selected_level)]
				if get_viewport_rect().size.y >= 500: details.text += "\n" + str(data.get("weather_tip", ""))
	if previous != state:
		if modal.visible: action.grab_focus()
		else:
			var focused := get_viewport().gui_get_focus_owner()
			if focused != null and is_ancestor_of(focused): focused.release_focus()

func _activate() -> void:
	match state:
		"ready": start_requested.emit()
		"paused": pause_requested.emit()
		"finished": restart_requested.emit()

func _responsive_layout() -> void:
	if modal_card == null: return
	touch_controls.release_all()
	compact_touch_landscape = touch_enabled and size.x > size.y and size.y < 540
	var owner_container: Container = touch_panel if compact_touch_landscape else footer
	if touch_controls.get_parent() != owner_container: touch_controls.reparent(owner_container)
	touch_panel.visible = compact_touch_landscape
	world_right_inset = touch_panel.get_combined_minimum_size().x + 24 if compact_touch_landscape else 0.0
	bottom_panel.offset_right = -12 - world_right_inset
	hints_label.visible = not compact_touch_landscape
	footer.vertical = touch_enabled and size.x < 600
	level_grid.columns = 4 if size.x < 500 else 6
	header_row.vertical = size.x < 760
	var compact_modal := size.y < 500
	for button in level_buttons: button.add_theme_font_size_override("font_size", 14 if compact_modal or size.x < 360 else 16)
	modal_content.add_theme_constant_override("separation", 4 if compact_modal else 10)
	heading.add_theme_font_size_override("font_size", 24 if compact_modal else 30)
	details.add_theme_font_size_override("font_size", 16 if compact_modal else 20)
	_layout_modal()
	modal_card.custom_minimum_size.x = minf(460, maxf(280, size.x - 24))
	score_label.custom_minimum_size.x = 0
	time_label.custom_minimum_size.x = 0
	layout_changed.emit()

func _layout_modal() -> void:
	if modal_center == null: return
	var available_top := get_viewport_rect().size.y - modal_card.get_combined_minimum_size().y - 16
	modal_center.offset_top = maxf(8, minf(top_panel.position.y + top_panel.size.y + 8, available_top))
	modal_center.offset_bottom = -8

## Explicit controller navigation keeps D-pad crane commands out of implicit GUI input.
func settings_command(command: StringName) -> void:
	if state == "ready" and level_grid.visible:
		var step := -1 if command in [&"settings_left", &"settings_up"] else 1
		var next := selected_level + step
		if Levels.unlocked(next): level_selected.emit(next)
		return
	if state != "paused": return
	var choices: Array[Control] = [action]
	if audio_settings.visible: choices.append_array([music_slider, effects_slider])
	if levels_button.visible: choices.append(levels_button)
	if developer_section != null:
		choices.append(developer_button)
		if developer_controls.visible: choices.append_array([hitboxes_check, masks_check])
	var focused := get_viewport().gui_get_focus_owner()
	var index := maxi(0, choices.find(focused))
	if command in [&"settings_up", &"settings_down"]:
		choices[posmod(index + (-1 if command == &"settings_up" else 1), choices.size())].grab_focus()
	elif focused is HSlider:
		focused.value += -5 if command == &"settings_left" else 5

func activate_paused_control() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused is BaseButton and is_ancestor_of(focused) and focused.is_visible_in_tree():
		if focused.toggle_mode: focused.button_pressed = not focused.button_pressed
		focused.pressed.emit()
	elif focused == null:
		pause_requested.emit()
