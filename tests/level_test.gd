extends SceneTree
const Layout = preload("res://scripts/level/yard_layout.gd")

func _initialize() -> void:
	for variant in 2:
		var layout := Layout.create_layout(variant)
		assert(layout == Layout.create_layout(variant), "Layout must be deterministic")
		var rectangles: Array[Rect2] = []
		var ids: Array[int] = []
		var materials: Array[StringName] = []
		for item in layout.scrap:
			var rectangle := Rect2(item.position - item.size * 0.5, item.size)
			assert(layout.pickup_bounds.encloses(rectangle))
			assert(rectangle.end.y <= layout.ground_top)
			assert(item.mass > 0 and not ids.has(item.id))
			assert(ResourceLoader.exists(item.texture))
			ids.append(item.id)
			materials.append(item.material)
			for previous in rectangles: assert(not previous.intersects(rectangle))
			rectangles.append(rectangle)
		for material in [&"copper", &"rubber", &"steel"]: assert(materials.has(material))
		for bin in layout.bins:
			var rectangle := Rect2(bin.position - bin.size * 0.5, bin.size)
			assert(layout.bounds.encloses(rectangle))
			assert(is_equal_approx(rectangle.end.y, layout.ground_top))
			assert(rectangle.position.y > layout.crane_anchor.y + 100)
			assert(ResourceLoader.exists(bin.texture))
			for previous in rectangles: assert(not previous.intersects(rectangle))
			rectangles.append(rectangle)
	var altered := Layout.create_layout()
	altered.scrap[0].position = Vector2.ZERO
	assert(Layout.create_layout().scrap[0].position != Vector2.ZERO, "Callers own independent data")
	call_deferred("_check_lab")

func _check_lab() -> void:
	var lab = load("res://labs/level/main.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	assert(lab.stage.get_child_count() == 21)
	lab._switch_layout()
	await process_frame
	assert(lab.variant == 1 and lab.stage.get_child_count() == 21)
	lab.queue_free()
	await process_frame
	print("LEVEL_TEST_OK deterministic layouts, clear spawn bounds, assets, independent data and lab switching")
	quit()
