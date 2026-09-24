extends "res://labs/shared/lab_page.gd"
## All geometry here is diagnostic. The reusable components supply no boxes.
const Parts = preload("res://scripts/physics/collision_parts_2d.gd")
const Mask = preload("res://scripts/physics/visual_mask_2d.gd")
var mask: Mask
var solid: CollisionShape2D
var sensor: Area2D
var moving: CharacterBody2D
var elapsed := 0.0
var sensor_hits := 0
var contacts := 0
var motion := true
var last_direction := 1.0
var sample: Sprite2D

func _ready() -> void:
	setup("Mask & collision parts", "A visual mask hides the striped sample. The solid boundary and amber sensor are independent. All shapes here are lab fixtures.")
	button("Mask on / off", func() -> void: mask.enabled = not mask.enabled; update_status()).grab_focus()
	button("Solid on / off", func() -> void: Parts.set_solid_enabled(solid, solid.disabled); call_deferred("update_status"))
	button("Sensor on / off", func() -> void: Parts.set_sensor_enabled(sensor, not sensor.monitoring); call_deferred("update_status"))
	button("Pause / resume", func() -> void: motion = not motion)
	button("Rope lab", func() -> void: get_tree().change_scene_to_file("res://labs/rope/lab.tscn"))
	# Pure render fixture; no collision shapes derive from this texture or mask.
	sample = Sprite2D.new()
	sample.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var pixels := Image.create(240, 150, false, Image.FORMAT_RGBA8)
	for y in 150:
		for x in 240:
			pixels.set_pixel(x,y, Color("a1e8c1") if (x / 12 + y / 12) % 2 == 0 else Color("527d70"))
	sample.texture = ImageTexture.create_from_image(pixels)
	sample.position = Vector2(285,245)
	world.add_child(sample)
	mask = Mask.new()
	mask.mask_texture = preload("res://assets/bitwright/bin_steel_mask.png")
	mask.position = sample.position
	mask.scale = Vector2(5,5)
	mask.target = sample
	world.add_child(mask)
	var guide := Sprite2D.new()
	guide.texture = mask.mask_texture
	guide.position = mask.position
	guide.scale = mask.scale
	guide.modulate = Color(1,0.76,0.42,0.22)
	guide.z_index = -1
	world.add_child(guide)
	caption("VISUAL OCCLUSION", Vector2(140,95))
	caption("Opaque mask pixels hide the sample", Vector2(90,385))
	caption("SOLID + SENSOR", Vector2(780,95))
	caption("The probe bounces; the sensor only detects", Vector2(690,385))
	var wall := StaticBody2D.new()
	wall.position = Vector2(1050,245)
	wall.collision_layer = 1
	wall.collision_mask = 0
	world.add_child(wall)
	var wall_shape := RectangleShape2D.new()
	wall_shape.size = Vector2(16,180)
	solid = Parts.add_solid(wall, wall_shape)
	var wall_line := Line2D.new()
	wall_line.points = PackedVector2Array([Vector2(1050,155),Vector2(1050,335)])
	wall_line.width = 8
	wall_line.default_color = Color("a1e8c1")
	world.add_child(wall_line)
	var sensor_shape := RectangleShape2D.new()
	sensor_shape.size = Vector2(70,180)
	sensor = Parts.add_sensor(world, sensor_shape, 0, 2, Transform2D(0, Vector2(870,245)))
	sensor.body_entered.connect(func(_body: Node2D) -> void: sensor_hits += 1; update_status())
	var outline := Line2D.new()
	outline.points = PackedVector2Array([Vector2(835,155),Vector2(905,155),Vector2(905,335),Vector2(835,335),Vector2(835,155)])
	outline.width = 2
	outline.default_color = Color("ffc36a")
	world.add_child(outline)
	moving = CharacterBody2D.new()
	moving.position = Vector2(740,245)
	moving.collision_layer = 2
	moving.collision_mask = 1
	world.add_child(moving)
	var probe := RectangleShape2D.new()
	probe.size = Vector2(28,28)
	Parts.add_solid(moving, probe)
	var probe_art := Polygon2D.new()
	probe_art.polygon = PackedVector2Array([Vector2(-14,-14),Vector2(14,-14),Vector2(14,14),Vector2(-14,14)])
	probe_art.color = Color("a1e8c1")
	moving.add_child(probe_art)
	update_status()
	capture_when_requested()

func caption(text: String, position: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = position
	label.add_theme_font_size_override("font_size", 20)
	world.add_child(label)

func _physics_process(delta: float) -> void:
	if moving == null or not motion: return
	elapsed += delta
	var hit := moving.move_and_collide(Vector2(last_direction * 190 * delta, 0))
	if hit != null:
		last_direction = -1
		contacts += 1
		update_status()
	if moving.position.x < 720: last_direction = 1
	if moving.position.x > 1140: last_direction = -1

func update_status() -> void:
	if mask == null or solid == null or sensor == null: return
	status.text = "Visual mask: %s  /  Solid: %s  /  Sensor: %s  /  Contacts: %d  /  Sensor entries: %d" % ["on" if mask.enabled else "off", "off" if solid.disabled else "on", "on" if sensor.monitoring else "off", contacts, sensor_hits]

func verify_visuals() -> bool:
	# Compare actual GPU pixels at an opaque mask texel, then move the mask away.
	motion = false
	var source := mask.mask_texture.get_image()
	var opaque := Vector2.ZERO
	for y in range(4, source.get_height() - 4):
		for x in range(4, source.get_width() - 4):
			if source.get_pixel(x,y).a > 0.99:
				opaque = Vector2(x + 0.5,y + 0.5) - Vector2(source.get_size()) * 0.5
				break
		if opaque != Vector2.ZERO: break
	var point := Vector2i(viewport.canvas_transform * mask.to_global(opaque))
	mask.enabled = false
	for frame in 2: await RenderingServer.frame_post_draw
	var visible := viewport.get_texture().get_image().get_pixelv(point)
	mask.enabled = true
	for frame in 2: await RenderingServer.frame_post_draw
	var hidden := viewport.get_texture().get_image().get_pixelv(point)
	var original := mask.position
	mask.position += Vector2(400,0)
	for frame in 2: await RenderingServer.frame_post_draw
	var moved := viewport.get_texture().get_image().get_pixelv(point)
	mask.position = original
	update_status()
	for frame in 2: await RenderingServer.frame_post_draw
	var ok := visible.a > 0.95 and hidden.a < 0.3 and moved.is_equal_approx(visible) and not solid.disabled and contacts > 0 and sensor_hits > 0
	print("MASK_GPU_TEST_%s hidden_alpha=%.2f visible_alpha=%.2f contacts=%d sensor_entries=%d" % ["OK" if ok else "FAILED", hidden.a, visible.a, contacts, sensor_hits])
	return ok
