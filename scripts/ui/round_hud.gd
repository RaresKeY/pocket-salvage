extends Control
## Presentation-only round HUD. The caller owns game state and shortcuts.
const TintSettings = preload("res://scripts/level/tint_settings.gd")
const Levels = preload("res://scripts/level/level_catalog.gd")
const TouchController = preload("res://scripts/ui/touch_controller.gd")
const YardTheme = preload("res://scripts/ui/yard_theme.gd")
const FullscreenControl = preload("res://scripts/ui/fullscreen_control.gd")

signal level_selected(index: int)
signal levels_requested
signal start_requested
signal restart_requested
signal pause_requested
signal music_requested
signal effects_requested
signal volume_requested(music: float, effects: float)
signal debug_requested(hitboxes: bool, masks: bool)
signal tint_requested(key: StringName, value: float)
signal layout_changed

## Below this height the start card drops the weather tip so Start stays on screen.
const SHORT_SCREEN := 420.0
## Below this height (or width, for the level grid) menus go compact.
const COMPACT := 500.0
const TINY_WIDTH := 360.0
const NARROW_WIDTH := 420.0
const MENU_WIDTH := 740.0
const STACKED_HEADER := 760.0
const HURRY_SECONDS := 10
const HURRY_COLOR := Color("ff6b5b")
const HINTS := {
	"keyboard": "A/D move · W/S lift · Space grip · E swap · P pause · R restart",
	"gamepad": "Stick/D-pad move/lift · A grip · X swap · Start pause · Y restart · LB music · RB SFX",
	"touch": "Drag the right stick to move/lift. Left buttons grip/swap.",
}
const CONTROL_HINTS: String = HINTS.keyboard
const DEBUG_TOGGLES := [
	{"text": "Hitboxes", "hint": "Green: physical shapes. Blue: Area2D sensors. Disabled shapes are omitted."},
	{"text": "Masks (art / active)", "hint": "Pink: source art masks, not collision geometry. Orange: active visual occlusion masks."},
]

var developer_enabled := false
var touch_enabled := false
var state := ""
var selected_level := 0
var _pending: Dictionary = {}
var _displayed: Dictionary = {}

var top_panel: PanelContainer
var bottom_panel: PanelContainer
var header_row: BoxContainer
var counters: HBoxContainer
var header_style: StyleBoxFlat
var overlay_style := StyleBoxEmpty.new()
var score_label: Label
var time_label: Label
var progress_label: Label
var music_button: Button
var effects_button: Button
var pause_button: Button
var magnet_label: Label
var weather_badge: Label
var feedback_label: Label
var hints_label: Label
var touch_controls: Control

var modal: ColorRect
var modal_center: CenterContainer
var modal_card: PanelContainer
var modal_content: VBoxContainer
var heading: Label
var details: Label
var action: Button
var levels_button: Button
var level_grid: GridContainer
var level_buttons: Array[Button] = []
var audio_settings: VBoxContainer
var music_slider: HSlider
var effects_slider: HSlider
var music_value: Label
var effects_value: Label
var developer_section: VBoxContainer
var developer_button: Button
var developer_controls: HBoxContainer
var hitboxes_check: CheckButton
var masks_check: CheckButton
var tint_controls: VBoxContainer
## Tint key -> slider, built from TintSettings.SLIDERS.
var tint_sliders: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = YardTheme.make()
	header_style = theme.get_stylebox("panel", "PanelContainer").duplicate()
	header_style.set_content_margin_all(8)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]: overlay_style.set_content_margin(side, 8)
	_build_header()
	_build_footer()
	_build_modal()
	_build_version()
	# Audio controls stay available above the modal on ready, pause and results.
	move_child(top_panel, get_child_count() - 1)
	add_child(FullscreenControl.new())
	_ignore_decoration(self)
	modal.mouse_filter = MOUSE_FILTER_STOP
	top_panel.resized.connect(func(): _layout_modal(); layout_changed.emit())
	top_panel.minimum_size_changed.connect(func(): _fit_header.call_deferred())
	bottom_panel.resized.connect(func(): layout_changed.emit())
	resized.connect(_responsive_layout)
	# Card text depends on screen height, and unchanged data is cached, so force a rebuild on resize.
	resized.connect(func(): _displayed = {}; present(_pending))
	_responsive_layout()
	present(_pending)

## Top bar: counters and audio/pause buttons, then the head status and weather.
func _build_header() -> void:
	top_panel = PanelContainer.new()
	top_panel.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	top_panel.offset_left = 8
	top_panel.offset_right = -FullscreenControl.RESERVED_WIDTH
	top_panel.offset_top = 6
	top_panel.add_theme_stylebox_override("panel", header_style)
	add_child(top_panel)
	var header := _box(top_panel, VBoxContainer.new(), 4)
	header_row = _box(header, BoxContainer.new(), 12)
	counters = _box(header_row, HBoxContainer.new(), 10)
	counters.size_flags_horizontal = SIZE_EXPAND_FILL
	score_label = _label(counters, "Score  0")
	counters.add_child(VSeparator.new())
	time_label = _label(counters, "Time  0:00")
	counters.add_child(VSeparator.new())
	progress_label = _label(counters, "Sorted  0 / 0")
	for label in [score_label, time_label, progress_label]:
		label.size_flags_horizontal = SIZE_EXPAND_FILL
		label.size_flags_vertical = SIZE_SHRINK_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
	var actions := _box(header_row, HBoxContainer.new(), 4)
	music_button = _toggle_button(actions, "Music", "Toggle music (M). Volume sliders are in Pause.", func(): music_requested.emit())
	effects_button = _toggle_button(actions, "SFX", "Toggle effects. Volume sliders are in Pause.", func(): effects_requested.emit())
	pause_button = _button(actions, "Pause", Vector2(70, 44), func(): pause_requested.emit())
	var status_row := _box(header, HBoxContainer.new(), 12)
	magnet_label = _label(status_row, "Magnet OFF  ·  Empty")
	magnet_label.size_flags_horizontal = SIZE_EXPAND_FILL
	magnet_label.add_theme_font_size_override("font_size", 16)
	magnet_label.add_theme_color_override("font_color", YardTheme.MUTED)
	weather_badge = _label(status_row, "")
	weather_badge.add_theme_font_size_override("font_size", 16)
	weather_badge.autowrap_mode = TextServer.AUTOWRAP_OFF
	weather_badge.visible = false
	# On touch the feedback line sits in the header, since the footer is hidden.
	feedback_label = _label(header if touch_enabled else null, "")
	feedback_label.add_theme_color_override("font_color", YardTheme.FEEDBACK)
	if touch_enabled: feedback_label.add_theme_font_size_override("font_size", 14)

## Bottom bar: feedback and control hints (hidden on touch), plus the touch controls themselves.
func _build_footer() -> void:
	bottom_panel = PanelContainer.new()
	bottom_panel.add_theme_stylebox_override("panel", header_style)
	bottom_panel.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	bottom_panel.grow_vertical = GROW_DIRECTION_BEGIN
	bottom_panel.offset_left = 8
	bottom_panel.offset_right = -8
	bottom_panel.offset_bottom = -28
	add_child(bottom_panel)
	var foot := _box(bottom_panel, VBoxContainer.new(), 4)
	foot.size_flags_horizontal = SIZE_EXPAND_FILL
	foot.size_flags_vertical = SIZE_SHRINK_CENTER
	touch_controls = TouchController.new()
	touch_controls.visible = touch_enabled
	add_child(touch_controls)
	if not touch_enabled: foot.add_child(feedback_label)
	hints_label = _label(foot, CONTROL_HINTS)
	hints_label.add_theme_font_size_override("font_size", 16)

## The dimmed card for level choice, start, pause and results.
func _build_modal() -> void:
	modal = ColorRect.new()
	modal.color = YardTheme.SCRIM
	modal.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(modal)
	modal_center = CenterContainer.new()
	modal_center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	modal_center.mouse_filter = MOUSE_FILTER_IGNORE
	modal.add_child(modal_center)
	modal_card = PanelContainer.new()
	modal_card.custom_minimum_size.x = 460
	modal_center.add_child(modal_card)
	modal_content = _box(modal_card, VBoxContainer.new(), 10)
	heading = _label(modal_content, "Pocket Salvage")
	heading.add_theme_font_size_override("font_size", 30)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_build_level_grid(modal_content)
	details = _label(modal_content, "")
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var action_row := _box(modal_content, HBoxContainer.new(), 4)
	action = _button(action_row, "", Vector2(0, 48), _activate)
	action.size_flags_horizontal = SIZE_EXPAND_FILL
	var primary: StyleBoxFlat = theme.get_stylebox("normal", "Button").duplicate()
	primary.bg_color = YardTheme.PRIMARY
	action.add_theme_stylebox_override("normal", primary)
	levels_button = _button(action_row, "Levels", Vector2(80, 44), func(): levels_requested.emit())
	_build_audio_settings(modal_content)
	if developer_enabled: _build_developer_options(modal_content)

func _build_version() -> void:
	var version := _label(self, "v" + str(ProjectSettings.get_setting("application/config/version", "0.1.0")))
	version.name = "Version"
	version.autowrap_mode = TextServer.AUTOWRAP_OFF
	version.add_theme_font_size_override("font_size", 12)
	version.add_theme_color_override("font_color", YardTheme.FAINT)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version.set_anchors_and_offsets_preset(PRESET_BOTTOM_RIGHT)
	version.offset_left = -90
	version.offset_right = -12
	version.offset_top = -22
	version.offset_bottom = -4

func _build_level_grid(parent: VBoxContainer) -> void:
	level_grid = GridContainer.new()
	level_grid.columns = 6
	level_grid.add_theme_constant_override("h_separation", 4)
	level_grid.add_theme_constant_override("v_separation", 4)
	parent.add_child(level_grid)
	for index in Levels.SLOT_COUNT:
		var open := Levels.unlocked(index)
		var button := _button(level_grid, "%02d" % (index + 1) if open else "%02d\nLOCKED" % (index + 1), Vector2(44, 44), func():
			if Levels.unlocked(index): level_selected.emit(index))
		button.tooltip_text = Levels.title(index)
		button.disabled = not open
		button.toggle_mode = true
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 16)
		level_buttons.append(button)

func _unhandled_key_input(event: InputEvent) -> void:
	if state != "ready" or not level_grid.visible: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_LEFT, KEY_RIGHT]:
			settings_command(&"settings_left" if event.physical_keycode == KEY_LEFT else &"settings_right")
			get_viewport().set_input_as_handled()

func _build_audio_settings(parent: VBoxContainer) -> void:
	audio_settings = _box(parent, VBoxContainer.new(), 0)
	var music := _slider_row(audio_settings, "Music", 55, 0, 100, 1, 100, "Music volume. Left/right adjusts; mute is separate.")
	var effects := _slider_row(audio_settings, "SFX", 55, 0, 100, 1, 100, "SFX volume. Left/right adjusts; mute is separate.")
	music_slider = music[0]
	music_value = music[1]
	effects_slider = effects[0]
	effects_value = effects[1]
	for slider in [music_slider, effects_slider]:
		slider.value_changed.connect(func(_value: float):
			_update_volume_labels()
			volume_requested.emit(music_slider.value / 100.0, effects_slider.value / 100.0))

## A labelled slider with a readout: [slider, value label]. The caller formats the readout.
func _slider_row(parent: Node, name: String, label_width: float, low: float, high: float, step: float, start: float, hint: String) -> Array:
	var row := _box(parent, HBoxContainer.new(), 10)
	var label := _label(row, name)
	label.custom_minimum_size.x = label_width
	label.size_flags_vertical = SIZE_SHRINK_CENTER
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value = start
	slider.size_flags_horizontal = SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(90, 36)
	slider.tooltip_text = hint
	row.add_child(slider)
	var value := _label(row, "")
	value.custom_minimum_size.x = 44
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_vertical = SIZE_SHRINK_CENTER
	return [slider, value]

func _update_volume_labels() -> void:
	music_value.text = "%d%%" % int(music_slider.value)
	effects_value.text = "%d%%" % int(effects_slider.value)

func _build_developer_options(parent: VBoxContainer) -> void:
	developer_section = _box(parent, VBoxContainer.new(), 4)
	developer_button = _button(developer_section, "Developer options", Vector2(0, 40))
	developer_button.toggle_mode = true
	developer_controls = _box(developer_section, HBoxContainer.new(), 4)
	developer_controls.visible = false
	var checks: Array[CheckButton] = []
	for toggle in DEBUG_TOGGLES:
		var check := CheckButton.new()
		check.text = toggle.text
		check.tooltip_text = toggle.hint
		check.custom_minimum_size.y = 40
		check.size_flags_horizontal = SIZE_EXPAND_FILL
		developer_controls.add_child(check)
		check.toggled.connect(func(_on: bool): debug_requested.emit(hitboxes_check.button_pressed, masks_check.button_pressed))
		checks.append(check)
	hitboxes_check = checks[0]
	masks_check = checks[1]
	tint_controls = _box(developer_section, VBoxContainer.new(), 0)
	tint_controls.visible = false
	_build_tint_sliders()
	developer_button.toggled.connect(func(open: bool):
		developer_controls.visible = open
		tint_controls.visible = open
		_show_audio_settings())

## Blood Moon tint strengths, one slider per TintSettings entry; defaults are the shipped look.
func _build_tint_sliders() -> void:
	for entry in TintSettings.SLIDERS:
		var parts := _slider_row(tint_controls, entry.label, 130, entry.min, entry.max, 0.01, entry.default, entry.hint + " Blood Moon only.")
		var slider: HSlider = parts[0]
		var readout: Label = parts[1]
		readout.text = "%.2f" % slider.value
		slider.value_changed.connect(func(value: float):
			readout.text = "%.2f" % value
			tint_requested.emit(entry.key, value))
		tint_sliders[entry.key] = slider
	_button(tint_controls, "Reset tints", Vector2(0, 36), func():
		for entry in TintSettings.SLIDERS: tint_sliders[entry.key].value = entry.default)

## Volume sliders show while paused, unless the developer options are open in their place.
func _show_audio_settings() -> void:
	audio_settings.visible = state == "paused" and (developer_button == null or not developer_button.button_pressed)

## Adds `container` to `parent` with `separation` between its children.
func _box(parent: Node, container: Container, separation: int) -> Container:
	container.add_theme_constant_override("separation", separation)
	parent.add_child(container)
	return container

func _button(parent: Node, text: String, min_size: Vector2, on_press := Callable()) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	if on_press.is_valid(): button.pressed.connect(on_press)
	parent.add_child(button)
	return button

## An on/off button labelled "<name> on" or "<name> off"; see _set_toggle.
func _toggle_button(parent: Node, name: String, hint: String, on_press: Callable) -> Button:
	var button := _button(parent, name + " on", Vector2(78, 44), on_press)
	button.set_meta("name", name)
	button.tooltip_text = hint
	button.toggle_mode = true
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(func(): if state == "running": button.release_focus())
	return button

func _set_toggle(button: Button, on: bool) -> void:
	button.set_pressed_no_signal(on)
	button.text = "%s %s" % [button.get_meta("name"), "on" if on else "off"]

## A word-wrapping label, added to `parent` unless it is null.
func _label(parent: Node, text: String) -> Label:
	var result := Label.new()
	result.text = text
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if parent != null: parent.add_child(result)
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
	var previous := state
	state = str(data.get("state", "ready"))
	if previous != state: _layout_header()
	selected_level = int(data.get("selected_level", 0))
	var scheme := "touch" if touch_enabled and data.get("control_scheme", "keyboard") != "gamepad" else str(data.get("control_scheme", "keyboard"))
	hints_label.text = HINTS.get(scheme, CONTROL_HINTS)
	touch_controls.enabled = state == "running"
	_present_counters(data, seconds, hurry)
	_present_audio(data)
	_present_developer()
	_present_modal(data)
	if previous != state:
		if modal.visible: action.grab_focus()
		else:
			var focused := get_viewport().gui_get_focus_owner()
			if focused != null and is_ancestor_of(focused): focused.release_focus()
	_fit_header.call_deferred()

func _present_counters(data: Dictionary, seconds: int, hurry: bool) -> void:
	var gap := " " if touch_enabled else "  "
	score_label.text = "Score%s%d" % [gap, int(data.get("score", 0))]
	time_label.text = "Time%s%d:%02d" % [gap, seconds / 60, seconds % 60]
	if hurry: time_label.add_theme_color_override("font_color", HURRY_COLOR)
	else: time_label.remove_theme_color_override("font_color")
	progress_label.text = ("Sorted %d/%d" if touch_enabled else "Sorted  %d / %d") % [int(data.get("delivered", 0)), int(data.get("total", 0))]
	var weather := str(data.get("weather_label", ""))
	weather_badge.text = weather
	weather_badge.visible = not weather.is_empty()
	var held := str(data.get("held_material", ""))
	var grip := str(data.get("grip_label", "Magnet " + ("ON" if data.get("magnet_on", false) else "OFF")))
	magnet_label.text = "%s  ·  %s" % [grip, "Carrying " + held if not held.is_empty() else "Empty"]
	feedback_label.text = str(data.get("feedback", ""))
	feedback_label.visible = not feedback_label.text.is_empty() and (not landscape_overlay() or state == "running")

func _present_audio(data: Dictionary) -> void:
	_set_toggle(music_button, data.get("music_on", true))
	_set_toggle(effects_button, data.get("effects_on", true))
	_show_audio_settings()
	music_slider.set_value_no_signal(float(data.get("music_volume", 1.0)) * 100.0)
	effects_slider.set_value_no_signal(float(data.get("effects_volume", 1.0)) * 100.0)
	_update_volume_labels()

func _present_developer() -> void:
	if developer_section == null: return
	developer_section.visible = state == "paused"
	if state != "paused":
		developer_button.set_pressed_no_signal(false)
		developer_controls.hide()

func _present_modal(data: Dictionary) -> void:
	var menu := bool(data.get("level_menu", false))
	var won := bool(data.get("victory", false))
	var weather := str(data.get("weather_label", ""))
	level_grid.visible = state == "ready" and menu
	levels_button.visible = (state == "paused" or (state == "finished" and not won)) and menu
	for index in level_buttons.size(): level_buttons[index].set_pressed_no_signal(index == selected_level)
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
			heading.text = "Victory!" if won else "Round complete"
			details.text = "%s\nScore  %d\nCorrect  %d  ·  Wrong  %d" % [str(data.get("finish_reason", "")), int(data.get("score", 0)), int(data.get("correct", 0)), int(data.get("wrong", 0))]
			var bonus := int(data.get("time_bonus", 0))
			if bonus > 0: details.text += "\nTime bonus  +%d" % bonus
			var weather_bonus := int(data.get("weather_bonus", 0))
			if weather_bonus > 0: details.text += "\n%s  +%d" % [weather, weather_bonus]
			action.text = "Continue" if won else ("Retry" if menu else "Play again")
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
				if get_viewport_rect().size.y >= COMPACT: details.text += "\n" + str(data.get("weather_tip", ""))

func _activate() -> void:
	match state:
		"ready": start_requested.emit()
		"paused": pause_requested.emit()
		"finished": restart_requested.emit()

func _responsive_layout() -> void:
	if modal_card == null: return
	touch_controls.release_all()
	bottom_panel.visible = not touch_enabled
	hints_label.visible = not touch_enabled
	level_grid.columns = 4 if size.x < COMPACT else 6
	_layout_header()
	var compact_modal := size.y < COMPACT
	for button in level_buttons: button.add_theme_font_size_override("font_size", 14 if compact_modal or size.x < TINY_WIDTH else 16)
	modal_content.add_theme_constant_override("separation", 4 if compact_modal else 10)
	heading.add_theme_font_size_override("font_size", 24 if compact_modal else 30)
	details.add_theme_font_size_override("font_size", 16 if compact_modal else 20)
	_layout_modal()
	modal_card.custom_minimum_size.x = minf(460, maxf(280, size.x - 24))
	layout_changed.emit()

## Mobile landscape fits the yard to the entire screen, even behind menu overlays.
func landscape_overlay() -> bool:
	return touch_enabled and size.x > size.y

## Header text size outside the playing-yard overlay: smaller in landscape menus and on narrow screens.
func _menu_font_size(compact_menu: bool, narrow_below: float) -> int:
	if compact_menu: return 18
	return 14 if size.x < narrow_below else 20

func _layout_header() -> void:
	var landscape := landscape_overlay()
	var overlay := landscape and state == "running"
	var compact_menu := landscape and not overlay and size.x < MENU_WIDTH
	top_panel.add_theme_stylebox_override("panel", overlay_style if overlay else header_style)
	header_row.vertical = size.x < STACKED_HEADER and not landscape
	# During play, Pause provides access to audio without consuming the counter row.
	music_button.visible = not overlay
	effects_button.visible = not overlay
	for child in counters.get_children():
		if child is VSeparator: child.visible = not overlay
	for label in [score_label, time_label, progress_label, magnet_label, weather_badge, feedback_label]:
		label.theme_type_variation = &"YardOverlayLabel" if overlay else &""
	for label in [score_label, time_label, progress_label]:
		label.add_theme_font_size_override("font_size", (24 if size.x < MENU_WIDTH else 28) if overlay else _menu_font_size(compact_menu, NARROW_WIDTH))
	for label in [magnet_label, weather_badge]:
		label.add_theme_font_size_override("font_size", 20 if overlay else 16)
	magnet_label.add_theme_color_override("font_color", YardTheme.INK if overlay else YardTheme.MUTED)
	if touch_enabled: feedback_label.add_theme_font_size_override("font_size", 18 if overlay else 14)
	for button in [music_button, effects_button, pause_button]:
		button.add_theme_font_size_override("font_size", 24 if overlay else _menu_font_size(compact_menu, TINY_WIDTH))
	pause_button.custom_minimum_size = Vector2(80, 52) if overlay else Vector2(70, 44)

# PanelContainer grows to fit wrapped text but does not shrink its previous height
# when feedback hides. Preserve anchored width while returning to content height.
func _fit_header() -> void:
	top_panel.size.y = top_panel.get_combined_minimum_size().y

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
