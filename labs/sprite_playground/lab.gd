extends "res://labs/shared/lab_page.gd"
const Grabbable = preload("res://labs/sprite_playground/grabbable.gd")
const Parts = preload("res://scripts/physics/collision_parts_2d.gd")
var prop: Grabbable
var gallery: Array[Sprite2D] = []
var smooth := true
var size_control: SpinBox

func _ready() -> void:
	setup("Sprite playground", "8× enlarged originals, drawn smaller in real time. Drag and release the washing machine to toss it. Hold Q / E while grabbing to turn it.")
	viewport.physics_object_picking = true
	button("Reset object", reset_prop)
	button("Linear / nearest", toggle_filter)
	var label := Label.new()
	label.text = "Object size (× original)"
	controls.add_child(label)
	size_control = SpinBox.new()
	size_control.min_value = 1.0
	size_control.max_value = 4.0
	size_control.step = 0.25
	size_control.value = 2.0
	controls.add_child(size_control)
	size_control.value_changed.connect(func(_value: float) -> void: reset_prop(); update_status())
	button("Scaling comparison", func() -> void: get_tree().change_scene_to_file("res://labs/pixel_scaling/lab.tscn"))
	caption("ART COLLECTION", Vector2(12, 0), 19)
	caption("GRAB & TOSS", Vector2(865, 0), 19)
	var files := DirAccess.get_files_at("res://assets/bitwright_8x")
	var index := 0
	for file in files:
		if not file.ends_with(".png") or "_mask" in file: continue
		var sprite := Sprite2D.new()
		sprite.texture = load("res://assets/bitwright_8x/" + file)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var cell := Vector2(12 + (index % 8) * 99, 30 + (index / 8) * 72)
		sprite.position = cell + Vector2(44, 24)
		var fit := minf(78.0 / sprite.texture.get_width(), 43.0 / sprite.texture.get_height())
		sprite.scale = Vector2.ONE * minf(0.25, fit)
		world.add_child(sprite)
		gallery.append(sprite)
		caption(file.trim_suffix(".png").trim_prefix("scrap_").trim_prefix("conveyor_").trim_prefix("backdrop_"), cell + Vector2(0, 48), 10)
		index += 1
	add_wall(Vector2(1000, 450), Vector2(370, 20))
	add_wall(Vector2(815, 245), Vector2(16, 410))
	add_wall(Vector2(1185, 245), Vector2(16, 410))
	add_wall(Vector2(1000, 40), Vector2(370, 12))
	reset_prop()
	caption("Release to drop • collisions stay active", Vector2(835, 463), 13)
	update_status()
	capture_when_requested()

func reset_prop() -> void:
	if is_instance_valid(prop):
		world.remove_child(prop)
		prop.queue_free()
	prop = Grabbable.new()
	prop.display_factor = size_control.value
	prop.position = Vector2(1000, 160)
	prop.rotation = -0.18
	world.add_child(prop)
	prop.art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if smooth else CanvasItem.TEXTURE_FILTER_NEAREST

func toggle_filter() -> void:
	smooth = not smooth
	var mode := CanvasItem.TEXTURE_FILTER_LINEAR if smooth else CanvasItem.TEXTURE_FILTER_NEAREST
	for sprite in gallery: sprite.texture_filter = mode
	prop.art.texture_filter = mode
	update_status()

func update_status() -> void:
	status.text = "Texture: 192 × 224  /  Object: %.1f × %.1f world units  /  Filtering: %s  /  48 art previews; masks kept separately" % [24 * size_control.value, 28 * size_control.value, "linear" if smooth else "nearest"]

func caption(text: String, position: Vector2, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.position = position
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	world.add_child(label)

func add_wall(position: Vector2, dimensions: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.position = position
	var shape := RectangleShape2D.new()
	shape.size = dimensions
	Parts.add_solid(wall, shape)
	var visual := Polygon2D.new()
	var half := dimensions * 0.5
	visual.polygon = PackedVector2Array([Vector2(-half.x,-half.y),Vector2(half.x,-half.y),half,Vector2(-half.x,half.y)])
	visual.color = Color("527d70")
	wall.add_child(visual)
	world.add_child(wall)
