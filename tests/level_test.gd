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
		for index in range(1, layout.bins.size()):
			var gap: float = layout.bins[index].position.x - layout.bins[index - 1].position.x
			assert(is_equal_approx(gap, layout.bins[index].size.x - SortingBin.WALL), "Neighbouring bins share a wall, leaving no gap to jam")
	var altered := Layout.create_layout()
	altered.scrap[0].position = Vector2.ZERO
	assert(Layout.create_layout().scrap[0].position != Vector2.ZERO, "Callers own independent data")
	var Backdrop = load("res://scripts/level/yard_backdrop.gd")
	var plan: Array = Backdrop.skyline_plan([102.0, 204.0, 204.0], 1200.0, 11)
	assert(plan == Backdrop.skyline_plan([102.0, 204.0, 204.0], 1200.0, 11), "Skyline plan is the same every round")
	for i in range(1, plan.size()): assert(plan[i].index != plan[i - 1].index, "Neighbouring skyline tiles are different designs")
	assert(plan.any(func(piece): return piece.flip) and plan.any(func(piece): return not piece.flip), "Some tiles are mirrored")
	var last: Dictionary = plan[-1]
	assert(is_equal_approx(last.x + last.width, 1200.0), "Skyline fills the span exactly")
	var single: Array = Backdrop.skyline_plan([102.0], 500.0, 11)
	for i in range(1, single.size()): assert(single[i].flip != single[i - 1].flip, "A lone design alternates facing")
	call_deferred("_check_lab")

func _check_lab() -> void:
	var lab = load("res://labs/level/main.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	assert(lab.stage.get_child_count() == 29)
	lab._switch_layout()
	await process_frame
	assert(lab.variant == 1 and lab.stage.get_child_count() == 29)
	lab.queue_free()
	await process_frame
	print("LEVEL_TEST_OK deterministic layouts, clear spawn bounds, assets, independent data and lab switching")
	quit()
