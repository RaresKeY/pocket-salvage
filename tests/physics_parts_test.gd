extends SceneTree
const Parts = preload("res://scripts/physics/collision_parts_2d.gd")
const Mask = preload("res://scripts/physics/visual_mask_2d.gd")

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for tick in 3: await physics_frame
	await process_frame

func run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var body := StaticBody2D.new()
	body.position = Vector2(100,100)
	body.collision_layer = 2
	body.collision_mask = 0
	world.add_child(body)
	assert(body.get_child_count() == 0, "No implicit collision geometry")
	var authored := RectangleShape2D.new()
	authored.size = Vector2(40,40)
	var solid := Parts.add_solid(body, authored)
	assert(solid.shape != authored)
	authored.size = Vector2(80,80)
	assert(solid.shape.size == Vector2(40,40), "Keep caller shape ownership separate")
	var sensor := Parts.add_sensor(world, authored, 0, 2, Transform2D(0,Vector2(100,100)))
	var excluded := Parts.add_sensor(world, authored, 0, 4, Transform2D(0,Vector2(100,100)))
	await settle()
	assert(sensor.get_overlapping_bodies().has(body))
	assert(excluded.get_overlapping_bodies().is_empty(), "Sensor mask must filter bodies")
	var query := PhysicsRayQueryParameters2D.create(Vector2(50,100),Vector2(150,100),2)
	assert(not world.get_world_2d().direct_space_state.intersect_ray(query).is_empty())
	var sprite := Sprite2D.new()
	var previous := CanvasItemMaterial.new()
	sprite.material = previous
	body.add_child(sprite)
	var mask := Mask.new()
	mask.target = sprite
	world.add_child(mask)
	var own_material := sprite.material
	mask.enabled = false
	mask.position = Vector2(800,900)
	await settle()
	assert(solid.shape.size == Vector2(40,40) and not solid.disabled)
	assert(sensor.get_overlapping_bodies().has(body), "Visual masks must not affect overlaps")
	assert(not world.get_world_2d().direct_space_state.intersect_ray(query).is_empty())
	Parts.set_sensor_enabled(sensor,false)
	await settle()
	assert(not sensor.monitoring and not sensor.monitorable)
	assert(not solid.disabled, "Sensor disable must not disable solid collision")
	Parts.set_sensor_enabled(sensor,true)
	await settle()
	assert(sensor.get_overlapping_bodies().has(body))
	Parts.set_solid_enabled(solid,false)
	await settle()
	assert(world.get_world_2d().direct_space_state.intersect_ray(query).is_empty())
	Parts.set_solid_enabled(solid,true)
	await settle()
	assert(not world.get_world_2d().direct_space_state.intersect_ray(query).is_empty())
	mask.queue_free()
	await process_frame
	assert(sprite.material == previous and sprite.material != own_material, "Restore material on detach")
	assert(Parts.add_solid(body,null) == null)
	print("PHYSICS_PARTS_TEST_OK shape ownership, collision filtering, independent sensors/masks, detach")
	quit()
