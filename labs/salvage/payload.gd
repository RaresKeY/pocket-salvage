extends RigidBody2D
## Prototype adapter; reusable collision components do not select scrap geometry.
const Parts = preload("res://scripts/physics/collision_parts_2d.gd")
const LANDING_SPEED := 160.0
signal landed(at: Vector2)
var item_id := 0
var material_id: StringName = &"steel"
var held := false
var delivered := false
var dimensions := Vector2(40, 40)
var sprite: Sprite2D
var _fall_speed := 0.0

func configure(entry: Dictionary) -> void:
	item_id = entry.id
	material_id = entry.material
	position = entry.position
	dimensions = entry.size
	mass = entry.mass
	collision_layer = 2
	collision_mask = 3
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	contact_monitor = true
	max_contacts_reported = 2
	body_entered.connect(_on_body_entered)
	linear_damp = 1.8
	angular_damp = 3.0
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.friction = 0.8
	physics_material_override.bounce = 0.12
	var shape := RectangleShape2D.new()
	shape.size = dimensions
	Parts.add_solid(self, shape)
	sprite = Sprite2D.new()
	sprite.texture = load(entry.texture)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var scale_factor := minf(dimensions.x / sprite.texture.get_width(), dimensions.y / sprite.texture.get_height())
	sprite.scale = Vector2.ONE * scale_factor
	add_child(sprite)

func _ready() -> void:
	add_to_group("salvage_scrap")

## Where a crane head takes hold: the middle of whichever edge faces up right now, so tumbled scrap is still reachable.
func grip_offset() -> Vector2:
	var half := dimensions * 0.5
	var best := Vector2(0, -half.y)
	for edge in [Vector2(0, half.y), Vector2(-half.x, 0), Vector2(half.x, 0)]:
		if to_global(edge).y < to_global(best).y: best = edge
	return best

func grip_point() -> Vector2:
	return to_global(grip_offset())

func _physics_process(_delta: float) -> void:
	_fall_speed = linear_velocity.y

func _on_body_entered(_other: Node) -> void:
	if _fall_speed > LANDING_SPEED and not held:
		landed.emit(global_position + Vector2(0, dimensions.y * 0.5))
