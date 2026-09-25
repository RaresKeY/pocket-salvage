extends SceneTree
const Round = preload("res://scripts/round/round_controller.gd")
const Bin = preload("res://scripts/round/sorting_bin.gd")
const Fixture = preload("res://labs/sorting/scrap_fixture.gd")
var failures: int = 0
var signals_seen: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1

func _run() -> void:
	var round_node := Round.new()
	root.add_child(round_node)
	round_node.configure(10, 3)
	check(round_node.accept_delivery(1, &"steel", &"steel") == Round.Delivery.IGNORED, "ready rejects")
	round_node.start()
	check(round_node.accept_delivery(1, &"steel", &"rubber") == Round.Delivery.WRONG and round_node.score == -25, "wrong penalty shows below zero")
	check(round_node.delivered_count == 0 and round_node.state == &"running", "wrong item stays in play")
	check(round_node.accept_delivery(1, &"steel", &"steel") == Round.Delivery.CORRECT and round_node.score == 75, "wrongly binned item can still be sorted")
	check(round_node.accept_delivery(1, &"steel", &"steel") == Round.Delivery.IGNORED, "duplicate rejects")
	round_node.set_paused(true)
	round_node.tick(20)
	check(round_node.remaining_time == 10 and round_node.accept_delivery(2, &"steel", &"steel") == Round.Delivery.IGNORED, "pause blocks time and delivery")
	round_node.set_paused(false)
	round_node.tick(3.5)
	round_node.accept_delivery(2, &"steel", &"steel")
	round_node.accept_delivery(3, &"rubber", &"steel")
	check(round_node.state == &"running" and round_node.wrong_count == 2, "wrong sorts never finish the round")
	round_node.accept_delivery(3, &"rubber", &"rubber")
	check(round_node.state == &"finished" and round_node.correct_count == 3 and round_node.time_bonus == 35, "all sorted earns whole remaining seconds")
	check(round_node.score == 300 - 50 + 35, "all-sorted finishes scoring")
	check(round_node.accept_delivery(4, &"steel", &"steel") == Round.Delivery.IGNORED, "finished rejects")
	round_node.start()
	check(round_node.score == 0 and round_node.delivered_count == 0 and round_node.time_bonus == 0 and round_node.remaining_time == 10, "restart resets")
	check(round_node.accept_delivery(1, &"steel", &"steel") == Round.Delivery.CORRECT, "restart clears duplicate ids")
	round_node.tick(11)
	check(round_node.state == &"finished" and round_node.time_bonus == 0, "timeout earns no bonus")
	round_node.start()
	round_node.tick(-1)
	check(round_node.remaining_time == 10, "negative tick ignored")
	round_node.tick(11)
	check(round_node.state == &"finished" and round_node.remaining_time == 0, "timeout finishes")
	var bin_node := Bin.new()
	bin_node.configure(&"steel", Vector2(200, 200))
	bin_node.delivered.connect(func(_body: Node2D, _material: StringName): signals_seen += 1)
	root.add_child(bin_node)
	var body := fixture_at(bin_node.position)
	body.held = true
	await frames(6)
	check(bin_node.sensor.get_overlapping_bodies().has(body), "actual area overlap")
	check(signals_seen == 0 and not body.delivered, "held ignored")
	bin_node.enabled = false
	body.held = false
	await frames(4)
	check(signals_seen == 0 and not body.delivered, "disabled rejects released overlap")
	bin_node.enabled = true
	await frames(4)
	check(signals_seen == 1 and body.delivered, "release already inside accepted once")
	await frames(4)
	check(signals_seen == 1, "overlap not redelivered")
	bin_node.eject(body, bin_node.position + Vector2(-300, 0))
	await frames(2)
	check(body.delivered and body.linear_velocity.y < 0, "ejected body launched and still claimed")
	await frames(30)
	check(not bin_node.sensor.get_overlapping_bodies().has(body) and not body.delivered and signals_seen == 1, "ejected body released once clear of the bin")
	var stuck := fixture_at(bin_node.position)
	stuck.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	stuck.freeze = true
	await frames(4)
	check(signals_seen == 2 and stuck.delivered, "second body delivered")
	bin_node.eject(stuck, bin_node.position)
	await frames(30)
	check(stuck.delivered and signals_seen == 2, "stuck ejected body held until timeout")
	await frames(90)
	check(signals_seen == 3, "stuck ejected body released after timeout")
	stuck.queue_free()
	var thrown := fixture_at(bin_node.position)
	thrown.gravity_scale = 1
	thrown.linear_damp = 1.8
	await frames(4)
	var landing := bin_node.position + Vector2(-420, 60)
	bin_node.eject(thrown, landing)
	var landed_x := INF
	for frame in 240:
		await physics_frame
		if thrown.linear_velocity.y > 0 and thrown.global_position.y >= landing.y:
			landed_x = thrown.global_position.x
			break
	check(absf(landed_x - landing.x) < 12, "ejected arc lands on the caller's point (x=%s)" % landed_x)
	await frames(10)
	check(is_equal_approx(thrown.linear_damp, 1.8) and thrown.linear_damp_mode == RigidBody2D.DAMP_MODE_COMBINE, "damping restored after the arc")
	thrown.queue_free()
	body.queue_free()
	bin_node.queue_free()
	round_node.queue_free()
	await process_frame
	var lab = load("res://labs/sorting/lab.tscn").instantiate()
	root.add_child(lab)
	lab._spawn(0)
	await frames(75)
	check(lab.round_state.delivered_count == 1 and lab.round_state.score == 100, "lab falling fixture scores")
	lab._restart()
	check(lab.bodies.is_empty() and lab.round_state.score == 0, "lab restart clears fixtures")
	lab.queue_free()
	await process_frame
	if failures == 0:
		print("ROUND_TEST_OK")
	quit(failures)

func fixture_at(at: Vector2) -> RigidBody2D:
	var body := Fixture.new()
	body.position = at
	body.gravity_scale = 0
	body.collision_layer = 2
	body.collision_mask = 1
	body.add_to_group(&"salvage_scrap")
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(12, 12)
	collision.shape = rectangle
	body.add_child(collision)
	root.add_child(body)
	return body

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
