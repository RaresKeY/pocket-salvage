extends Control
## Presentation-only round HUD. The caller owns game state and shortcuts.
signal start_requested
signal restart_requested
signal pause_requested
signal music_requested
signal effects_requested
signal layout_changed

const TouchController = preload("res://scripts/ui/touch_controller.gd")
var touch_enabled := false
var touch_controls: HBoxContainer
var modal_card: PanelContainer
var modal_center: CenterContainer
var modal_content: VBoxContainer
var footer: BoxContainer
var touch_panel: PanelContainer
var world_right_inset := 0.0
var compact_touch_landscape := false
const ArtLab = preload("res://labs/pixel_scaling/lab.gd")
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
	var art := ArtLab.new()
	theme = art.make_theme()
	art.free()
	var top := PanelContainer.new()
	top_panel = top
	top.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	top.offset_left = 12
	top.offset_right = -12
	top.offset_top = 8
	var compact: StyleBoxFlat = theme.get_stylebox("panel", "PanelContainer").duplicate()
	compact.set_content_margin_all(8)
	top.add_theme_stylebox_override("panel", compact)
	add_child(top)
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 4)
	top.add_child(row)
	score_label = _stat(row, preload("res://assets/bitwright_8x/hud_coin.png"), "Score  0")
	score_label.custom_minimum_size.x = 90
	time_label = _stat(row, preload("res://assets/bitwright_8x/hud_timer.png"), "Time  0:00")
	time_label.custom_minimum_size.x = 94
	progress_label = _label(row, "Sorted  0 / 0")
	progress_label.custom_minimum_size.x = 112
	progress_label.size_flags_horizontal = SIZE_EXPAND_FILL
	music_button = _audio_button(row, "Music on", "Toggle music (M)", func(): music_requested.emit())
	effects_button = _audio_button(row, "SFX on", "Toggle sound effects and crane motors", func(): effects_requested.emit())
	pause_button = Button.new()
	pause_button.text = "Pause"
	pause_button.custom_minimum_size = Vector2(70, 44)
	pause_button.pressed.connect(func(): pause_requested.emit())
	row.add_child(pause_button)
	var bottom := PanelContainer.new()
	bottom_panel = bottom
	bottom.add_theme_stylebox_override("panel", compact)
	bottom.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	bottom.grow_vertical = GROW_DIRECTION_BEGIN
	bottom.offset_left = 12
	bottom.offset_right = -12
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
	magnet_label = _label(foot, "Magnet OFF  ·  Empty")
	magnet_label.add_theme_font_size_override("font_size", 14)
	feedback_label = _label(foot, "")
	feedback_label.add_theme_color_override("font_color", Color("a1e8c1"))
	hints_label = _label(foot, CONTROL_HINTS)
	hints_label.add_theme_font_size_override("font_size", 14)
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
	content.add_theme_constant_override("separation", 16)
	card.add_child(content)
	heading = _label(content, "Pocket Salvage")
	heading.add_theme_font_size_override("font_size", 28)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details = _label(content, "")
	details.custom_minimum_size.x = 0
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action = Button.new()
	action.custom_minimum_size.y = 48
	var primary: StyleBoxFlat = theme.get_stylebox("normal", "Button").duplicate()
	primary.bg_color = Color("355c50")
	action.add_theme_stylebox_override("normal", primary)
	action.pressed.connect(_activate)
	content.add_child(action)
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
	_responsive_layout()
	present(_pending)

func _audio_button(parent: Node, text: String, hint: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = hint
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(78, 44)
	button.add_theme_font_size_override("font_size", 14)
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

func _stat(parent: Node, texture: Texture2D, text: String) -> Label:
	var pair := HBoxContainer.new()
	pair.add_theme_constant_override("separation", 8)
	parent.add_child(pair)
	var icon := TextureRect.new()
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(24, 24)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	pair.add_child(icon)
	return _label(pair, text)

func _ignore_decoration(node: Node) -> void:
	if node is Control and not node is BaseButton:
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
	var held := str(data.get("held_material", ""))
	var grip := str(data.get("grip_label", "Magnet " + ("ON" if data.get("magnet_on", false) else "OFF")))
	magnet_label.text = "%s  ·  %s" % [grip, "Carrying " + held if not held.is_empty() else "Empty"]
	feedback_label.text = str(data.get("feedback", ""))
	feedback_label.visible = not feedback_label.text.is_empty()
	modal.visible = state != "running"
	pause_button.visible = state == "running"
	match state:
		"paused":
			heading.text = "Paused"
			details.text = "Take your time. Your round is waiting."
			action.text = "Resume"
		"finished":
			heading.text = "Round complete"
			var reason := str(data.get("finish_reason", ""))
			details.text = "%s\nScore  %d\nCorrect  %d  ·  Wrong  %d" % [reason, int(data.get("score", 0)), int(data.get("correct", 0)), int(data.get("wrong", 0))]
			var bonus := int(data.get("time_bonus", 0))
			if bonus > 0: details.text += "\nTime bonus  +%d" % bonus
			action.text = "Play again"
		_:
			heading.text = "Pocket Salvage"
			details.text = "10 pieces · 4 minutes\nMagnet lifts steel. Claw lifts copper and rubber.\nPark and swap heads at the left stands.\nSort into matching bins. Wrong bin: −25."
			action.text = "Start round"
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
	var compact_modal := touch_enabled and size.y < 400
	modal_content.add_theme_constant_override("separation", 8 if compact_modal else 16)
	heading.add_theme_font_size_override("font_size", 24 if compact_modal else 28)
	details.add_theme_font_size_override("font_size", 14 if compact_modal else 16)
	_layout_modal()
	modal_card.custom_minimum_size.x = minf(460, maxf(280, size.x - 24))
	score_label.custom_minimum_size.x = 60 if size.x < 600 else 90
	time_label.custom_minimum_size.x = 74 if size.x < 600 else 94
	layout_changed.emit()

func _layout_modal() -> void:
	if modal_center == null: return
	modal_center.offset_top = top_panel.position.y + top_panel.size.y + 8
	modal_center.offset_bottom = -8
