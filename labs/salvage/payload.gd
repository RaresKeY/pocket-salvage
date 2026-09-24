extends RigidBody2D
## Prototype adapter; reusable collision components do not select scrap geometry.
const Parts = preload("res://scripts/physics/collision_parts_2d.gd")
var item_id := 0
var material_id: StringName = &"steel"
var held := false
var delivered := false
var dimensions := Vector2(40, 40)
var sprite: Sprite2D

func configure(entry: Dictionary) -> void:
	item_id = entry.id
	material_id = entry.material
	position = entry.position
	dimensions = entry.size
	mass = entry.mass
	collision_layer = 2
	collision_mask = 3
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
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
