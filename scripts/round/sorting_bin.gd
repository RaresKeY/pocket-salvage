class_name SortingBin
extends Node2D
## Prototype authored geometry. Sensor accepts released salvage_scrap bodies.
signal delivered(body: Node2D, bin_material: StringName)
const WALL := 8.0
const YardArt = preload("res://scripts/art/yard_art.gd")
const RIM_PEAK := 10.0
const RIM_NUDGE := Vector2(90, -30)
const RIM_SETTLED_SPEED := 20.0

var material_id: StringName = &"steel"
var enabled: bool = true
var bin_size := Vector2(150, 100)
var sensor: Area2D
var rims: Array[Area2D] = []
var eject_apex := 240.0
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
	rims.clear()
	var sprite := Sprite2D.new()
	if YardArt.exists("bin_%s" % material_id):
		sprite.texture = YardArt.texture("bin_%s" % material_id)
		sprite.scale = bin_size / Vector2(sprite.texture.get_size())
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(sprite)
	var solid := StaticBody2D.new()
	solid.collision_layer = 1
	solid.collision_mask = 2
	add_child(solid)
	_shape(solid, Vector2(bin_size.x, WALL), Vector2(0, (bin_size.y - WALL) * 0.5))
	for side in [-1.0, 1.0]:
		var wall_x: float = side * (bin_size.x - WALL) * 0.5
		_shape(solid, Vector2(WALL, bin_size.y), Vector2(wall_x, 0))
		var peak := CollisionShape2D.new()
		var triangle := ConvexPolygonShape2D.new()
		triangle.points = PackedVector2Array([Vector2(-WALL * 0.5, 0), Vector2(WALL * 0.5, 0), Vector2(0, -RIM_PEAK)])
		peak.shape = triangle
		peak.position = Vector2(wall_x, -bin_size.y * 0.5)
		solid.add_child(peak)
		var rim := Area2D.new()
		rim.collision_layer = 0
		rim.collision_mask = 2
		rim.position.x = wall_x
		add_child(rim)
		_shape(rim, Vector2(WALL + 4, RIM_PEAK + 6), Vector2(0, -(bin_size.y + RIM_PEAK + 6) * 0.5))
		rims.append(rim)
	sensor = Area2D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 2
	add_child(sensor)
	_shape(sensor, bin_size - Vector2.ONE * WALL * 2, Vector2.ZERO)

func _shape(owner_node: Node2D, size: Vector2, at: Vector2) -> void:
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	collision.position = at
	owner_node.add_child(collision)

## Lobs a refused body to `landing` (undamped, so the arc is exact). It stays `delivered` until it leaves.
func eject(body: RigidBody2D, landing: Vector2) -> void:
	var gravity := body.get_gravity().y
	if gravity <= 0.0: gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	var start := body.global_position
	var apex := minf(start.y, landing.y) - eject_apex
	var rise := sqrt(2.0 * gravity * (start.y - apex))
	var flight := (rise + sqrt(2.0 * gravity * (landing.y - apex))) / gravity
	body.sleeping = false
	body.linear_velocity = Vector2((landing.x - start.x) / flight, -rise)
	_ejecting[body] = {"claim": eject_timeout, "flight": flight, "damp": body.linear_damp, "mode": body.linear_damp_mode}
	body.linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	body.linear_damp = 0.0

func _release_ejected(delta: float) -> void:
	var inside := sensor.get_overlapping_bodies()
	for body in _ejecting.keys():
		if not is_instance_valid(body):
			_ejecting.erase(body)
			continue
		var entry: Dictionary = _ejecting[body]
		entry.claim -= delta
		entry.flight -= delta
		if entry.claim > -INF and (not inside.has(body) or entry.claim <= 0.0):
			body.set("delivered", false)
			entry.claim = -INF
		if entry.flight <= 0.0:
			body.linear_damp = entry.damp
			body.linear_damp_mode = entry.mode
			if entry.claim == -INF: _ejecting.erase(body)

## Damped scrap sleeps before it tips, so anything settled on a rim is pushed off, leftward when dead centre.
func _shed_rims() -> void:
	for rim in rims:
		for body in rim.get_overlapping_bodies():
			if not body is RigidBody2D or not body.is_in_group(&"salvage_scrap") or body.get("held") != false:
				continue
			if body.linear_velocity.length() > RIM_SETTLED_SPEED:
				continue
			var side := signf(body.global_position.x - rim.global_position.x)
			if side == 0.0: side = -1.0
			body.sleeping = false
			body.apply_central_impulse(Vector2(RIM_NUDGE.x * side, RIM_NUDGE.y) * body.mass)

func _physics_process(delta: float) -> void:
	if not enabled or not is_instance_valid(sensor):
		return
	_release_ejected(delta)
	_shed_rims()
	for body in sensor.get_overlapping_bodies():
		if not enabled:
			break
		if not body.is_in_group(&"salvage_scrap"):
			continue
		if body.get("held") != false or body.get("delivered") != false:
			continue
		body.set("delivered", true)
		delivered.emit(body, material_id)
