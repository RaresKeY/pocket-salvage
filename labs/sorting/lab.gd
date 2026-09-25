extends Node2D
const Round = preload("res://scripts/round/round_controller.gd")
const Bin = preload("res://scripts/round/sorting_bin.gd")
const Fixture = preload("res://labs/sorting/scrap_fixture.gd")
var round_state := Round.new()
var bins: Array[Node2D] = []
var bodies: Array[RigidBody2D] = []
var label: Label

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("192832"))
	add_child(round_state)
	for index in range(3):
		var bin_node := Bin.new()
		bin_node.configure([&"steel", &"copper", &"rubber"][index], Vector2(230 + index * 260, 390))
		bin_node.delivered.connect(_on_delivery.bind(bin_node))
		add_child(bin_node)
		bins.append(bin_node)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	label = Label.new()
	label.position = Vector2(24, 20)
	canvas.add_child(label)
	round_state.changed.connect(_refresh)
	_restart()

func _restart() -> void:
	for body in bodies:
		body.queue_free()
	bodies.clear()
	round_state.configure(45, 6)
	round_state.start()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.keycode == KEY_R:
		_restart()
	elif event.keycode == KEY_P:
		round_state.set_paused(round_state.state != &"paused")
	elif event.keycode in [KEY_1, KEY_2, KEY_3] and round_state.state == &"running" and bodies.size() < 6:
		_spawn(event.keycode - KEY_1)

func _spawn(bin_index: int) -> void:
	var body := Fixture.new()
	body.material_id = [&"steel", &"copper", &"rubber"][bodies.size() % 3]
	body.collision_layer = 2
	body.collision_mask = 1
	body.position = Vector2(bins[bin_index].position.x, 170)
	body.add_to_group(&"salvage_scrap")
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(24, 24)
	shape.shape = rectangle
	body.add_child(shape)
	var art := Polygon2D.new()
	art.polygon = PackedVector2Array([Vector2(-12,-12), Vector2(12,-12), Vector2(12,12), Vector2(-12,12)])
	art.color = [Color.SILVER, Color.CORAL, Color.DIM_GRAY][bodies.size() % 3]
	body.add_child(art)
	add_child(body)
	bodies.append(body)
	_refresh()

func _on_delivery(body: Node2D, material: StringName, bin_node: Node2D) -> void:
	match round_state.accept_delivery(body.get_instance_id(), body.material_id, material):
		Round.Delivery.CORRECT:
			body.set_deferred("freeze", true)
			body.set_deferred("collision_layer", 0)
			body.set_deferred("collision_mask", 0)
		Round.Delivery.WRONG:
			bin_node.eject(body)

func _process(delta: float) -> void:
	round_state.tick(delta)

func _refresh() -> void:
	for bin_node in bins:
		bin_node.enabled = round_state.state == &"running"
	for body in bodies:
		if not body.delivered:
			body.freeze = round_state.state != &"running"
	var next_material: String = ["steel", "copper", "rubber"][bodies.size() % 3] if bodies.size() < 6 else "none"
	label.text = "SORTING LAB — diagnostic geometry\n1 / 2 / 3: drop next item into steel / copper / rubber bin | P pause | R restart\nNext: %s   State: %s   Time: %.1f   Score: %d   Delivered: %d / 6" % [next_material, round_state.state, round_state.remaining_time, round_state.score, round_state.delivered_count]
