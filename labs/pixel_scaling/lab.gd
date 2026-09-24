extends Control

const Scaling = preload("res://scripts/art/pixel_scaling.gd")
const Preview = preload("res://labs/pixel_scaling/preview.gd")
const MINT := Color("a1e8c1")
const MUTED := Color("a7b9c0")

var picker: OptionButton
var factor: SpinBox
var motion: CheckButton
var status: Label
var command: LineEdit
var grid: GridContainer
var page_scroll: ScrollContainer
var paths: Array[String] = []
var previews: Array[Control] = []
var captions: Array[Label] = []
var descriptions: Array[Label] = []
var source: Image


func _ready() -> void:
	theme = make_theme()
	var backdrop := ColorRect.new()
	backdrop.color = Color("101d24")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		outer.add_theme_constant_override("margin_" + side, 24)
	add_child(outer)
	var scroll := ScrollContainer.new()
	page_scroll = scroll
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 14)
	scroll.add_child(page)
	page.add_child(label("POCKET SALVAGE  /  ART LAB 01", 13, MINT))
	page.add_child(label("Every pixel, intact.", 30))
	page.add_child(label("Compare integer scaling, fractional sampling, and a baked enlargement. Source colors and alpha stay visible.", 16, MUTED, true))
	var controls := HFlowContainer.new()
	controls.add_theme_constant_override("h_separation", 12)
	controls.add_theme_constant_override("v_separation", 8)
	page.add_child(controls)
	picker = OptionButton.new()
	picker.custom_minimum_size = Vector2(240, 42)
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.fit_to_longest_item = false
	picker.tooltip_text = "PNGs beneath assets/. Add art there, then refresh."
	controls.add_child(picker)
	var refresh := Button.new()
	refresh.text = "Refresh art"
	refresh.pressed.connect(refresh_assets)
	controls.add_child(refresh)
	var factor_group := HBoxContainer.new()
	factor_group.add_child(label("Integer scale", 16, MUTED))
	factor = SpinBox.new()
	factor.min_value = 1
	factor.max_value = 32
	factor.step = 1
	factor.value = 10
	factor.custom_minimum_size = Vector2(108, 42)
	factor.suffix = "×"
	factor_group.add_child(factor)
	controls.add_child(factor_group)
	motion = CheckButton.new()
	motion.text = "Motion test"
	motion.toggled.connect(func(enabled: bool) -> void:
		for preview in previews:
			preview.set_motion(enabled)
	)
	controls.add_child(motion)
	status = label("", 15, MINT, true)
	page.add_child(status)
	grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	page.add_child(grid)
	add_panel("01  /  INTEGER · NEAREST", "Equal blocks. Position snaps to screen pixels.")
	add_panel("02  /  FRACTIONAL · NEAREST", "Hard edges, but uneven block widths at half steps.")
	add_panel("03  /  FRACTIONAL · LINEAR", "Same fractional size; neighboring colors blend.")
	add_panel("04  /  BAKED · NEAREST", "Enlarged in memory, drawn 1:1. Compare with 01.")
	page.add_child(label("Export the selected image", 18))
	command = LineEdit.new()
	command.editable = false
	command.add_theme_color_override("font_uneditable_color", Color("dbe5de"))
	command.custom_minimum_size.y = 42
	command.tooltip_text = "Select and copy this command. Exports are created by the tool, not by merely viewing the lab."
	page.add_child(command)
	page.add_child(label("10× means 100× as many output pixels, without new detail. Keep original sprites; integer runtime scaling often makes an enlarged file unnecessary. Scroll inside each preview to inspect large art.", 14, MUTED, true))
	picker.item_selected.connect(load_selected)
	factor.value_changed.connect(func(_value: float) -> void: update_previews())
	resized.connect(update_columns)
	update_columns()
	refresh_assets()
	picker.grab_focus()
	call_deferred("automation")


func label(text: String, font_size: int, color := Color("f1f3eb"), wrap := false) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	if wrap:
		result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return result


func add_panel(title: String, description: String) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	content.add_child(label(title, 14, MINT))
	var caption := label("", 16)
	content.add_child(caption)
	captions.append(caption)
	var detail := label(description, 14, MUTED, true)
	content.add_child(detail)
	descriptions.append(detail)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 400)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var preview := Preview.new()
	scroll.add_child(preview)
	scroll.get_h_scroll_bar().value_changed.connect(func(_value: float) -> void: preview.queue_redraw())
	scroll.get_v_scroll_bar().value_changed.connect(func(_value: float) -> void: preview.queue_redraw())
	previews.append(preview)


func update_columns() -> void:
	if grid != null:
		grid.columns = 4 if size.x >= 1700 else (2 if size.x >= 1000 else 1)


func scan_pngs(directory: String) -> void:
	for filename in DirAccess.get_files_at(directory):
		if filename.get_extension().to_lower() == "png":
			paths.append(directory.path_join(filename))
	for folder in DirAccess.get_directories_at(directory):
		if not folder.begins_with("."):
			scan_pngs(directory.path_join(folder))


func refresh_assets() -> void:
	var previous := paths[picker.selected] if picker.selected >= 0 and picker.selected < paths.size() else ""
	paths.clear()
	scan_pngs("res://assets")
	paths.sort()
	picker.clear()
	for path in paths:
		picker.add_item(path.trim_prefix("res://assets/"))
	if paths.is_empty():
		source = null
		status.text = "Add a PNG beneath assets/, then refresh."
		update_previews()
		return
	var index := maxi(0, paths.find(previous))
	picker.select(index)
	load_selected(index)


func load_selected(index: int) -> void:
	if index < 0 or index >= paths.size():
		return
	var path := ProjectSettings.globalize_path(paths[index])
	var error := Scaling.png_error(path, 1)
	if not error.is_empty():
		source = null
		clear_previews(error)
		return
	source = Image.load_from_file(path)
	if source != null:
		source.convert(Image.FORMAT_RGBA8)
	update_previews()


func update_previews() -> void:
	if source == null or source.is_empty():
		clear_previews("Cannot decode the selected PNG. Add a valid PNG beneath assets/.")
		return
	var zoom := int(factor.value)
	var error := Scaling.size_error(source.get_width(), source.get_height(), zoom)
	if not error.is_empty():
		clear_previews(error)
		return
	var enlarged := Scaling.enlarge(source, zoom)
	var original := ImageTexture.create_from_image(source)
	var baked := ImageTexture.create_from_image(enlarged)
	previews[0].configure(original, float(zoom), false, true)
	previews[1].configure(original, zoom + 0.5, false, false)
	previews[2].configure(original, zoom + 0.5, true, false)
	previews[3].configure(baked, 1.0, false, true)
	var native_size := "%d × %d" % [source.get_width(), source.get_height()]
	captions[0].text = "%s source  /  %d×" % [native_size, zoom]
	captions[1].text = "%s source  /  %.1f×" % [native_size, zoom + 0.5]
	captions[2].text = captions[1].text
	captions[3].text = "%d × %d baked  /  1×" % [enlarged.get_width(), enlarged.get_height()]
	status.text = "%s  →  %d × %d at %d×  ·  source preserved" % [native_size, enlarged.get_width(), enlarged.get_height(), zoom]
	var source_path := paths[picker.selected].trim_prefix("res://")
	command.text = "./tools/superscale --input '%s' --factor %d --output artifacts/generated/pixel-%dx.png" % [source_path.replace("'", "'\\''"), zoom, zoom]


func clear_previews(message: String) -> void:
	status.text = message
	command.text = ""
	for preview in previews:
		preview.configure(null, 1.0, false, true)
	for caption in captions:
		caption.text = "No preview"


func make_theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 16
	var card := StyleBoxFlat.new()
	card.bg_color = Color("182a33")
	card.set_content_margin_all(16)
	card.set_corner_radius_all(8)
	result.set_stylebox("panel", "PanelContainer", card)
	for node_type in ["Button", "OptionButton", "CheckButton"]:
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("29404c") if state == "hover" else Color("21353f")
			style.set_content_margin_all(10)
			style.set_corner_radius_all(5)
			if state == "focus":
				style.bg_color = Color.TRANSPARENT
				style.border_color = MINT
				style.set_border_width_all(2)
			result.set_stylebox(state, node_type, style)
	return result


func automation() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.has("--self-test"):
		# The headless display starts at 64x64 unless the test supplies a viewport.
		get_window().size = Vector2i(1280, 900)
		for frame in range(3):
			await get_tree().process_frame
		factor.value = 2
		assert(previews[0].zoom == 2.0 and previews[1].zoom == 2.5)
		assert(Vector2i(previews[3].texture.get_size()) == source.get_size() * 2)
		motion.button_pressed = true
		assert(previews[0].is_processing())
		motion.button_pressed = false
		refresh_assets()
		assert(not paths.is_empty())
		factor.value = 10
		await get_tree().process_frame
		picker.grab_focus()
		var tab := InputEventKey.new()
		tab.keycode = KEY_TAB
		tab.pressed = true
		get_viewport().push_input(tab)
		await get_tree().process_frame
		assert(get_viewport().gui_get_focus_owner() != null and get_viewport().gui_get_focus_owner() != picker)
		var pointer := InputEventMouseMotion.new()
		pointer.position = motion.get_global_rect().get_center()
		pointer.global_position = pointer.position
		get_viewport().notify_mouse_entered()
		get_viewport().push_input(pointer, true)
		await get_tree().process_frame
		for pressed in [true, false]:
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.position = motion.get_global_rect().get_center()
			click.global_position = click.position
			click.pressed = pressed
			click.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
			get_viewport().push_input(click, true)
			await get_tree().process_frame
		await get_tree().process_frame
		assert(motion.button_pressed, "Mouse toggle failed at %s in viewport %s" % [motion.get_global_rect(), get_viewport_rect()])
		motion.button_pressed = false
		print("PIXEL_LAB_TEST_OK asset loading, scale control, baked size, motion, refresh, keyboard focus, mouse toggle")
		get_tree().quit(0)
		return
	var capture_index := arguments.find("--capture")
	if capture_index >= 0 and capture_index + 1 < arguments.size():
		for frame in range(5):
			await get_tree().process_frame
		if arguments.has("--capture-bottom"):
			page_scroll.scroll_vertical = int(page_scroll.get_v_scroll_bar().max_value)
			for frame in range(3):
				await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var path := arguments[capture_index + 1]
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var screenshot := get_viewport().get_texture().get_image()
		var comparison_checked := false
		var identical := false
		var source_rect := Rect2i(previews[0].global_position + Vector2(32, 32), source.get_size() * int(factor.value))
		var baked_rect := Rect2i(previews[3].global_position + Vector2(32, 32), source.get_size() * int(factor.value))
		var screen_rect := Rect2i(Vector2i.ZERO, screenshot.get_size())
		var source_clip := Rect2i(previews[0].get_parent().get_global_rect())
		var baked_clip := Rect2i(previews[3].get_parent().get_global_rect())
		if screen_rect.encloses(source_rect) and screen_rect.encloses(baked_rect) and source_clip.encloses(source_rect) and baked_clip.encloses(baked_rect):
			comparison_checked = true
			identical = screenshot.get_region(source_rect).get_data() == screenshot.get_region(baked_rect).get_data()
		var error := screenshot.save_png(path)
		var evidence := {"size": [screenshot.get_width(), screenshot.get_height()], "renderer": RenderingServer.get_video_adapter_name(), "integer_vs_baked_checked": comparison_checked, "integer_vs_baked_identical": identical}
		var record := FileAccess.open(path + ".json", FileAccess.WRITE)
		if record != null:
			record.store_string(JSON.stringify(evidence, "\t", true) + "\n")
		print("PIXEL_LAB_CAPTURE size=%s renderer=%s result=%d integer_vs_baked=%s" % [get_viewport_rect().size, RenderingServer.get_video_adapter_name(), error, str(identical) if comparison_checked else "offscreen"])
		get_tree().quit(0 if error == OK and (not comparison_checked or identical) else 1)
