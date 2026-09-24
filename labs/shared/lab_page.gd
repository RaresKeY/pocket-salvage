extends Control
## Responsive diagnostic page, sharing the art lab's existing theme.
const ArtLab = preload("res://labs/pixel_scaling/lab.gd")
var controls: HFlowContainer
var status: Label
var viewport: SubViewport
var world: Node2D
var body: VBoxContainer

func setup(title: String, help: String) -> void:
	var art := ArtLab.new()
	theme = art.make_theme()
	art.free()
	var background := ColorRect.new()
	background.color = Color("101d24")
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	background.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	margin.add_child(body)
	var heading := Label.new()
	heading.text = "Pocket Salvage / " + title
	heading.add_theme_font_size_override("font_size", 26)
	body.add_child(heading)
	var description := Label.new()
	description.text = help
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(description)
	controls = HFlowContainer.new()
	controls.add_theme_constant_override("h_separation", 10)
	body.add_child(controls)
	var container := SubViewportContainer.new()
	container.stretch = true
	container.size_flags_vertical = SIZE_EXPAND_FILL
	container.custom_minimum_size.y = 120
	body.add_child(container)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1200, 480)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)
	world = Node2D.new()
	viewport.add_child(world)
	viewport.size_changed.connect(_fit_world)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_color_override("font_color", Color("a1e8c1"))
	body.add_child(status)
	call_deferred("_fit_world")

func _fit_world() -> void:
	var available := Vector2(viewport.size)
	var zoom := minf(available.x / 1200.0, available.y / 480.0)
	viewport.canvas_transform = Transform2D(0.0, Vector2.ONE * zoom, 0.0, (available - Vector2(1200, 480) * zoom) * 0.5)

func button(title: String, action: Callable) -> Button:
	var control := Button.new()
	control.text = title
	control.custom_minimum_size.y = 42
	control.pressed.connect(action)
	controls.add_child(control)
	return control

func capture_when_requested() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.has("--capture"): return
	Input.warp_mouse(Vector2(2, get_viewport_rect().size.y - 2))
	for frame in 150: await get_tree().physics_frame
	if not await verify_visuals():
		push_error("Lab visual verification failed")
		get_tree().quit(1)
		return
	await RenderingServer.frame_post_draw
	var path := args[args.find("--capture") + 1]
	var error := get_viewport().get_texture().get_image().save_png(path)
	print("LAB_CAPTURE result=%s renderer=%s" % [error, RenderingServer.get_video_adapter_name()])
	get_tree().quit(error)

func verify_visuals() -> bool:
	return true
