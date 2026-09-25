extends SceneTree
const Scaling = preload("res://scripts/art/pixel_scaling.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280,900)
	var count := 0
	for file in DirAccess.get_files_at("res://assets/bitwright"):
		if not file.ends_with(".png"): continue
		var source_path := "res://assets/bitwright/" + file
		var output_path := "res://assets/bitwright_8x/" + file
		var source := Image.load_from_file(ProjectSettings.globalize_path(source_path))
		var actual := Image.load_from_file(ProjectSettings.globalize_path(output_path))
		assert(actual.get_size() == source.get_size() * 8)
		assert(actual.get_data() == Scaling.enlarge(source, 8).get_data())
		var record = JSON.parse_string(FileAccess.get_file_as_string(output_path + ".json"))
		assert(record.factor == 8 and record.source_sha256 == FileAccess.get_sha256(source_path))
		assert(record.output_sha256 == FileAccess.get_sha256(output_path))
		count += 1
	assert(count == 123)
	var lab = load("res://labs/sprite_playground/lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	await process_frame
	assert(lab.gallery.size() == 47)
	var initial_y: float = lab.prop.position.y
	for frame in 120: await physics_frame
	assert(lab.prop.position.y > initial_y + 100)
	assert(lab.prop.position.y < 440)
	assert(lab.prop.linear_velocity.length() < 15)
	lab.size_control.value = 3.25
	assert(lab.prop.art.scale.is_equal_approx(Vector2.ONE * 3.25 / 8.0))
	assert(lab.prop.solid.shape.size.is_equal_approx(Vector2(22,26) * 3.25))
	assert(lab.prop.scale == Vector2.ONE)
	lab.toggle_filter()
	assert(lab.prop.art.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
	lab.toggle_filter()
	assert(lab.prop.art.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR)
	# Inject actual viewport mouse input at an off-center point on the reset body.
	for frame in 3: await physics_frame
	var point: Vector2 = lab.prop.to_global(Vector2(15,0))
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = lab.viewport.get_parent().global_position + lab.viewport.canvas_transform * point
	Input.parse_input_event(press)
	for frame in 3: await physics_frame
	assert(lab.prop.grabbed)
	assert(lab.prop.anchor.length() > 1)
	var force: Vector2 = lab.prop.grab_force(lab.prop.global_position + Vector2(0,-150))
	assert(force.y < 0 and force.length() <= 5000.01)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	Input.parse_input_event(release)
	for frame in 3: await physics_frame
	assert(not lab.prop.grabbed)
	lab.reset_prop()
	assert(lab.prop.position.is_equal_approx(Vector2(1000,160)))
	print("SPRITE_PLAYGROUND_TEST_OK 123 exact 8x assets, gallery, gravity, floor, size, filtering, mouse grab/release, reset")
	lab.queue_free()
	await process_frame
	quit()
