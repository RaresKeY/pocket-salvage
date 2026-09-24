extends Control
## Presentation-only round HUD. The caller owns game state and shortcuts.
signal start_requested
signal restart_requested
signal pause_requested

const ArtLab = preload("res://labs/pixel_scaling/lab.gd")
const CONTROL_HINTS := "A / D move   ·   W / S raise / lower   ·   Space magnet   ·   P pause   ·   R restart"
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

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	var art := ArtLab.new()
	theme = art.make_theme()
	art.free()
	var top := PanelContainer.new()
	top.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	top.offset_left = 12
	top.offset_right = -12
	top.offset_top = 8
	var compact: StyleBoxFlat = theme.get_stylebox("panel", "PanelContainer").duplicate()
	compact.set_content_margin_all(8)
	top.add_theme_stylebox_override("panel", compact)
	add_child(top)
	var column := VBoxContainer.new()
	top.add_child(column)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	column.add_child(row)
	score_label = _label(row, "Score  0")
	score_label.custom_minimum_size.x = 130
	time_label = _label(row, "Time  0:00")
	time_label.custom_minimum_size.x = 110
	progress_label = _label(row, "Sorted  0 / 0")
	progress_label.size_flags_horizontal = SIZE_EXPAND_FILL
	pause_button = Button.new()
	pause_button.text = "Pause"
	pause_button.custom_minimum_size = Vector2(90, 44)
	pause_button.pressed.connect(func(): pause_requested.emit())
	row.add_child(pause_button)
	magnet_label = _label(column, "Magnet OFF  ·  Holding: nothing")
	var bottom := PanelContainer.new()
	bottom.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	bottom.grow_vertical = GROW_DIRECTION_BEGIN
	bottom.offset_left = 12
	bottom.offset_right = -12
	bottom.offset_bottom = -28
	add_child(bottom)
	var foot := VBoxContainer.new()
	bottom.add_child(foot)
	feedback_label = _label(foot, "")
	feedback_label.add_theme_color_override("font_color", Color("a1e8c1"))
	hints_label = _label(foot, CONTROL_HINTS)
	hints_label.add_theme_font_size_override("font_size", 14)
	modal = ColorRect.new()
	modal.color = Color(0.03, 0.06, 0.08, 0.80)
	modal.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(modal)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	center.mouse_filter = MOUSE_FILTER_IGNORE
	modal.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size.x = 440
	center.add_child(card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	card.add_child(content)
	heading = _label(content, "Pocket Salvage")
	heading.add_theme_font_size_override("font_size", 28)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details = _label(content, "")
	details.custom_minimum_size.x = 400
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action = Button.new()
	action.custom_minimum_size.y = 48
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
	_ignore_decoration(self)
	modal.mouse_filter = MOUSE_FILTER_STOP
	present(_pending)

func _label(parent: Node, text: String) -> Label:
	var result := Label.new()
	result.text = text
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(result)
	return result

func _ignore_decoration(node: Node) -> void:
	if node is Control and not node is BaseButton:
		node.mouse_filter = MOUSE_FILTER_IGNORE
	for child in node.get_children(): _ignore_decoration(child)

func present(data: Dictionary) -> void:
	_pending = data.duplicate()
	if not is_node_ready(): return
	var navigation := str(data.get("navigation_hint", ""))
	hints_label.text = CONTROL_HINTS + ("   ·   " + navigation if not navigation.is_empty() else "")
	var previous := state
	state = str(data.get("state", "ready"))
	var seconds := maxi(0, ceili(float(data.get("time_left", 0.0))))
	score_label.text = "Score  %d" % int(data.get("score", 0))
	time_label.text = "Time  %d:%02d" % [seconds / 60, seconds % 60]
	progress_label.text = "Sorted  %d / %d" % [int(data.get("delivered", 0)), int(data.get("total", 0))]
	var held := str(data.get("held_material", ""))
	magnet_label.text = "Magnet %s  ·  Holding: %s" % ["ON" if data.get("magnet_on", false) else "OFF", held if not held.is_empty() else "nothing"]
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
			action.text = "Play again"
		_:
			heading.text = "Pocket Salvage"
			details.text = "Lift scrap with the magnet.\nRelease it into the matching bin before time runs out."
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
