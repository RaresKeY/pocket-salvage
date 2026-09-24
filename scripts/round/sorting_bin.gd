class_name SortingBin
extends Node2D
## Prototype authored geometry. Sensor accepts released salvage_scrap bodies.
signal delivered(body: Node2D, bin_material: StringName)

var material_id: StringName = &"steel"
var enabled: bool = true
var bin_size := Vector2(150, 100)
var sensor: Area2D

func configure(material: StringName, at: Vector2, size: Vector2 = Vector2(150, 100)) -> void:
	material_id = material
	position = at
	bin_size = Vector2(maxf(size.x, 24), maxf(size.y, 24))
	if is_inside_tree():
		_build()

func _ready() -> void:
	_build()

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var sprite := Sprite2D.new()
	var path := "res://assets/bitwright_8x/bin_%s.png" % material_id
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
		sprite.scale = bin_size / Vector2(sprite.texture.get_size())
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(sprite)
	var solid := StaticBody2D.new()
	solid.collision_layer = 1
	solid.collision_mask = 2
	add_child(solid)
	_shape(solid, Vector2(bin_size.x, 8), Vector2(0, bin_size.y * 0.5 - 4))
	_shape(solid, Vector2(8, bin_size.y), Vector2(-bin_size.x * 0.5 + 4, 0))
	_shape(solid, Vector2(8, bin_size.y), Vector2(bin_size.x * 0.5 - 4, 0))
	sensor = Area2D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 2
	add_child(sensor)
	_shape(sensor, bin_size - Vector2(16, 16), Vector2.ZERO)

func _shape(owner_node: Node2D, size: Vector2, at: Vector2) -> void:
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	collision.position = at
	owner_node.add_child(collision)

func _physics_process(_delta: float) -> void:
	if not enabled or not is_instance_valid(sensor):
		return
	for body in sensor.get_overlapping_bodies():
		if not enabled:
			break
		if not body.is_in_group(&"salvage_scrap"):
			continue
		if body.get("held") != false or body.get("delivered") != false:
			continue
		body.set("delivered", true)
		delivered.emit(body, material_id)
