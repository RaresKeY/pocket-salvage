extends SceneTree
const Rope = preload("res://scripts/rope/rope_2d.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var wall := StaticBody2D.new()
	wall.position = Vector2(0, 50)
	var part := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(100, 10)
	part.shape = shape
	wall.add_child(part)
	root.add_child(wall)
	var rope := Rope.new()
	root.add_child(rope)
	rope.reset(Vector2(-20, 0), Vector2(20, 0), 50)
	await physics_frame
	await physics_frame
	rope.step(Vector2(-20, 0), Vector2(20, 0), 50, 1.0/60)
	assert(not rope.solver.ray(Vector2.ZERO, Vector2(0,100)).is_empty())
	assert(rope.solver.ray(Vector2(200,0), Vector2(200,100)).is_empty(), "Ray endpoints refresh for each sweep")
	rope.exclude = [wall.get_rid()]
	rope.step(Vector2(-20, 0), Vector2(20, 0), 50, 1.0/60)
	assert(rope.solver.ray(Vector2.ZERO, Vector2(0,100)).is_empty(), "Changed exclusions take effect on the next step")
	rope.exclude.clear()
	rope.collision_mask = 2
	rope.step(Vector2(-20, 0), Vector2(20, 0), 50, 1.0/60)
	assert(rope.solver.ray(Vector2.ZERO, Vector2(0,100)).is_empty(), "Changed mask takes effect on the next step")
	rope.collision_mask = 1
	rope.step(Vector2(-20, 0), Vector2(20, 0), 50, 1.0/60)
	assert(not rope.solver.ray(Vector2.ZERO, Vector2(0,100)).is_empty())
	rope.free()
	wall.free()
	print("ROPE_SWEEP_TEST_OK reusable queries preserve endpoints, masks and exclusions")
	quit()
