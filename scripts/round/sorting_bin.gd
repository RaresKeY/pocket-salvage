class_name SortingBin
extends Node2D
## Prototype authored geometry. Sensor accepts released salvage_scrap bodies.
signal delivered(body: Node2D, bin_material: StringName)

var material_id: StringName = &"steel"
var enabled: bool = true
var bin_size := Vector2(150, 100)
var sensor: Area2D
var eject_velocity := Vector2(160, -640)
var eject_timeout := 1.5
var _ejecting: Dictionary = {}

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

## Throws a refused body back over the nearer wall; it stays `delivered` until it leaves.
func eject(body: RigidBody2D) -> void:
	var side := 1.0 if body.global_position.x >= global_position.x else -1.0
	body.sleeping = false
	body.linear_velocity = Vector2(eject_velocity.x * side, eject_velocity.y)
	_ejecting[body] = eject_timeout

func _release_ejected(delta: float) -> void:
	var inside := sensor.get_overlapping_bodies()
	for body in _ejecting.keys():
		if not is_instance_valid(body):
			_ejecting.erase(body)
			continue
		_ejecting[body] -= delta
		if not inside.has(body) or _ejecting[body] <= 0.0:
			body.set("delivered", false)
			_ejecting.erase(body)

func _physics_process(delta: float) -> void:
	if not enabled or not is_instance_valid(sensor):
		return
	_release_ejected(delta)
	for body in sensor.get_overlapping_bodies():
		if not enabled:
			break
		if not body.is_in_group(&"salvage_scrap"):
			continue
		if body.get("held") != false or body.get("delivered") != false:
			continue
		body.set("delivered", true)
		delivered.emit(body, material_id)
