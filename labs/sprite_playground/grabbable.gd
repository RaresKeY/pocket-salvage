extends RigidBody2D
## Spring grab keeps collisions and angular motion active.
const Parts = preload("res://scripts/physics/collision_parts_2d.gd")
var grabbed := false
var anchor := Vector2.ZERO
var target := Vector2.ZERO
var display_factor := 2.0
var art: Sprite2D
var solid: CollisionShape2D

func _ready() -> void:
	input_pickable = true
	mass = 1.0
	linear_damp = 1.5
	angular_damp = 2.0
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 0.25
	art = Sprite2D.new()
	art.texture = preload("res://assets/bitwright_8x/scrap_washing_machine.png")
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(art)
	solid = Parts.add_solid(self, RectangleShape2D.new())
	set_display_factor(display_factor)
	input_event.connect(_on_input_event)

func set_display_factor(value: float) -> void:
	display_factor = clampf(value, 1.0, 4.0)
	if art == null: return
	art.scale = Vector2.ONE * display_factor / 8.0
	# Authored lab approximation, independent of the texture's transparent mask.
	(solid.shape as RectangleShape2D).size = Vector2(22, 26) * display_factor
	grabbed = false
	sleeping = false

func _on_input_event(_viewport: Node, event: InputEvent, _shape: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		begin_grab(get_global_mouse_position())

func begin_grab(point: Vector2) -> void:
	anchor = to_local(point)
	target = point
	grabbed = true
	sleeping = false

func grab_force(point: Vector2) -> Vector2:
	var offset := anchor.rotated(rotation)
	var velocity_at_anchor := linear_velocity + Vector2(-offset.y, offset.x) * angular_velocity
	return ((point - global_position - offset) * 90.0 - velocity_at_anchor * 16.0).limit_length(5000.0)

func _physics_process(_delta: float) -> void:
	if grabbed:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			grabbed = false
			return
		target = get_global_mouse_position().clamp(Vector2(835, 45), Vector2(1165, 405))
		apply_force(grab_force(target), anchor.rotated(rotation))
		if Input.is_physical_key_pressed(KEY_Q): apply_torque(-2200.0)
		if Input.is_physical_key_pressed(KEY_E): apply_torque(2200.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		grabbed = false
