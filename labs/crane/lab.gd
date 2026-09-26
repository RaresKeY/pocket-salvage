extends "res://labs/shared/lab_page.gd"
const CableBody = preload("res://scripts/crane/cable_body_2d.gd")
const Suspension = preload("res://scripts/crane/suspension_2d.gd")
const Parts = preload("res://scripts/physics/collision_parts_2d.gd")
var suspension: Suspension
var tip: CableBody
var payload: RigidBody2D

func _ready() -> void:
	setup("Suspension lab", "A/D move anchor · W/S reel · Space attach/release nearby fixture. Diagnostic geometry; no selected gameplay objects.")
	button("Reset", reset_fixture)
	button("Attach / release", toggle_attachment)
	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(600, 450)
	var floor_shape := RectangleShape2D.new()
	floor_shape.size = Vector2(1200, 20)
	Parts.add_solid(floor_body, floor_shape)
	world.add_child(floor_body)
	var floor_art := Polygon2D.new()
	floor_art.polygon = PackedVector2Array([Vector2(0,440), Vector2(1200,440), Vector2(1200,460), Vector2(0,460)])
	floor_art.color = Color("334953")
	world.add_child(floor_art)
	tip = CableBody.new()
	tip.mass = 3.0
	tip.linear_damp = 0.35
	tip.angular_damp = 1.8
	tip.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	tip.z_index = 2
	tip.collision_layer = 4
	tip.collision_mask = 1
	var circle := CircleShape2D.new()
	circle.radius = 10
	Parts.add_solid(tip, circle)
	world.add_child(tip)
	var tip_art := Polygon2D.new()
	tip_art.polygon = PackedVector2Array([Vector2(-12,-8), Vector2(12,-8), Vector2(12,8), Vector2(-12,8)])
	tip_art.color = Color("a1e8c1")
	tip.add_child(tip_art)
	payload = RigidBody2D.new()
	payload.collision_layer = 2
	payload.collision_mask = 1
	payload.mass = 2
	var shape := RectangleShape2D.new()
	shape.size = Vector2(44, 44)
	Parts.add_solid(payload, shape)
	var art := Polygon2D.new()
	art.polygon = PackedVector2Array([Vector2(-22,-22), Vector2(22,-22), Vector2(22,22), Vector2(-22,22)])
	art.color = Color("ffc36a")
	payload.add_child(art)
	world.add_child(payload)
	suspension = Suspension.new()
	world.add_child(suspension)
	tip.position = Vector2(320, 365)
	suspension.configure(tip, Vector2(320,45), 320)
	reset_fixture()
	capture_when_requested()

func reset_fixture() -> void:
	if suspension == null: return
	suspension.anchor = Vector2(320,45)
	suspension.cable_length = 320
	suspension.reset(Vector2(320,365))
	payload.position = Vector2(320,405)
	payload.rotation = 0
	payload.linear_velocity = Vector2.ZERO
	payload.angular_velocity = 0

func toggle_attachment() -> void:
	if suspension.attached_body != null:
		suspension.detach()
	elif tip.global_position.distance_to(payload.global_position) < 75:
		suspension.attach(payload, Vector2(0,-22))

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo() and event is InputEventKey and event.keycode == KEY_SPACE:
		toggle_attachment()

func _physics_process(delta: float) -> void:
	if suspension == null: return
	var horizontal := float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
	var reel := float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	suspension.anchor.x = clampf(suspension.anchor.x + horizontal * 190 * delta, Layout.RAIL_X.x, Layout.RAIL_X.y)
	suspension.cable_length = clampf(suspension.cable_length + reel * 150 * delta, Layout.CABLE.x, Layout.CABLE.y)
	status.text = "Cable %.0f px · %s · %s" % [suspension.cable_length, "Attached" if suspension.attached_body != null else "Released", "Blocked" if suspension.blocked else "Free"]
