extends "res://labs/shared/lab_page.gd"
const Rope = preload("res://scripts/rope/rope_2d.gd")
var rope: Rope
var anchor := Vector2(260, 70)
var tip := Vector2(950, 100)
var velocity := Vector2.ZERO
var length := 910.0
var paused := false
var reel: HSlider
var marker: Polygon2D
var ticks := 0

func _ready() -> void:
	setup("Rope lab", "Drag the mint endpoint. Reel the cable to see slack, tension and persistent corner contacts. Orange dots mark contacts.")
	button("Reset", reset_rope).grab_focus()
	button("Pause / resume", func() -> void: paused = not paused)
	button("Points", func() -> void: rope.debug_points = not rope.debug_points; rope.queue_redraw())
	button("Curve / raw", func() -> void: rope.smooth = not rope.smooth; rope.queue_redraw())
	button("Pixel lab", func() -> void: get_tree().change_scene_to_file("res://labs/pixel_scaling/lab.tscn"))
	reel = HSlider.new()
	reel.min_value = 350
	reel.max_value = 1150
	reel.value = length
	reel.step = 1
	reel.custom_minimum_size = Vector2(180, 42)
	reel.tooltip_text = "Paid-out rope length; arrow keys adjust while focused."
	reel.value_changed.connect(func(value: float) -> void: length = value)
	controls.add_child(reel)
	var block := PackedVector2Array([Vector2(520, 230), Vector2(680, 230), Vector2(680, 480), Vector2(520, 480)])
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	wall.collision_mask = 0
	var shape := CollisionPolygon2D.new()
	shape.polygon = block
	wall.add_child(shape)
	world.add_child(wall)
	var art := Polygon2D.new()
	art.polygon = block
	art.color = Color("334953")
	world.add_child(art)
	rope = Rope.new()
	rope.debug_points = true
	world.add_child(rope)
	rope.configure([block])
	marker = Polygon2D.new()
	marker.polygon = PackedVector2Array([Vector2(-14,-14), Vector2(14,-14), Vector2(14,14), Vector2(-14,14)])
	marker.color = Color("a1e8c1")
	world.add_child(marker)
	reset_rope()
	capture_when_requested()

func reset_rope() -> void:
	tip = Vector2(950, 100)
	velocity = Vector2.ZERO
	length = 910.0
	reel.value = length
	rope.reset(anchor, tip, length)

func _physics_process(delta: float) -> void:
	if rope == null or paused: return
	var mouse := world.get_global_mouse_position()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Rect2(0,0,1200,480).has_point(mouse):
		tip = Vector2(clampf(mouse.x, 40, 1160), clampf(mouse.y, 30, 440))
		# The draggable diagnostic endpoint stays outside the solid pillar.
		if Rect2(510,220,180,260).has_point(tip): tip.x = 505 if tip.x < 600 else 695
		velocity = Vector2.ZERO
	else:
		velocity.y += 600 * delta
		tip += velocity * delta
		if tip.y > 440: tip.y = 440; velocity.y = 0
	var constraint: Dictionary = rope.constrain_tip(anchor, tip, velocity, length)
	tip = constraint.position
	velocity = constraint.velocity
	rope.step(anchor, tip, length, delta)
	marker.position = tip
	ticks += 1
	if ticks % 6 == 0:
		status.text = "Rope: %d px  /  Routed span: %d px  /  Corner contacts: %d  /  %s" % [length, rope.solver.path.length_between(anchor, tip), rope.solver.path.bends.size(), "Reel blocked by geometry" if constraint.blocked else "Drag or reel to experiment"]
