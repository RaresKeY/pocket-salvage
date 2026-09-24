extends SceneTree
var lab
var simulated := 0.0

func _initialize() -> void:
	call_deferred("run")

func step(horizontal := 0.0, reel := 0.0, frames := 1) -> void:
	for frame in frames:
		await physics_frame
		if lab.round_state.state == &"running":
			lab.move_crane(horizontal,reel,1.0/60.0)
			lab.round_state.tick(1.0/60.0)
			simulated += 1.0/60.0

func move_x(target: float) -> void:
	for frame in 400:
		var delta: float = target - lab.suspension.anchor.x
		if absf(delta) < 0.1: break
		await step(clampf(delta / (220.0/60.0),-1,1))

func reel_to(target: float) -> void:
	for frame in 200:
		var delta: float = target - lab.suspension.cable_length
		if absf(delta) < 0.1: break
		await step(0,clampf(delta / (130.0/60.0),-1,1))

func run() -> void:
	root.size = Vector2i(1280,720)
	lab = load("res://labs/salvage/lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	lab.set_physics_process(false)
	assert(lab.round_state.state == &"ready")
	lab.hud.start_requested.emit()
	assert(lab.round_state.state == &"running")
	await step(0,0,60)
	for delivery_index in 6:
		var item: RigidBody2D
		for candidate in lab.payloads:
			if is_instance_valid(candidate) and not candidate.delivered:
				item = candidate
				break
		await reel_to(90)
		await move_x(item.position.x)
		await reel_to(335)
		await step(0,0,90)
		if not lab.magnet_on: lab.toggle_magnet()
		for frame in 180:
			lab.try_pickup()
			if is_instance_valid(lab.held_body): break
			await step()
		assert(is_instance_valid(lab.held_body),"Crane must pick a nearby item")
		item = lab.held_body
		await reel_to(80)
		await step(0,0,120)
		assert(item.position.y < 220,"Suspension lifts actual rigid body")
		if delivery_index == 0:
			lab.toggle_pause()
			var before: Vector2 = item.position
			var before_tip: Vector2 = lab.tip.position
			var time_before: float = lab.round_state.remaining_time
			for frame in 30: await physics_frame
			assert(item.position.is_equal_approx(before) and lab.tip.position.is_equal_approx(before_tip))
			assert(lab.round_state.remaining_time == time_before and lab.held_body == item)
			lab.toggle_pause()
		var target_bin: Node2D
		for bin in lab.bins:
			if bin.material_id == item.material_id: target_bin = bin
		await move_x(target_bin.position.x)
		for frame in 240:
			await step()
			if absf(item.position.x-target_bin.position.x)<28 and absf(item.linear_velocity.x)<25: break
		var before_count: int = lab.round_state.delivered_count
		lab.toggle_magnet()
		for frame in 240:
			await step()
			if lab.round_state.delivered_count > before_count: break
		assert(lab.round_state.delivered_count == before_count+1,"Released item enters bin")
		assert(lab.round_state.wrong_count == 0)
		print("SALVAGE_DELIVERY count=%d elapsed=%.2f" % [lab.round_state.delivered_count,simulated])
	assert(lab.round_state.state == &"finished")
	assert(lab.round_state.score == 600 and lab.round_state.correct_count == 6)
	assert(lab.hud.modal.visible)
	lab.hud.restart_requested.emit()
	assert(lab.round_state.state == &"running" and lab.round_state.score == 0)
	assert(lab.payloads.size() == 6 and not lab.magnet_on and lab.held_body == null)
	for frame in 4: await physics_frame
	assert(lab.round_state.delivered_count == 0)
	var timeout_load: RigidBody2D = lab.payloads[0]
	lab.held_body = timeout_load
	timeout_load.held = true
	lab.magnet_on = true
	lab.suspension.attach(timeout_load)
	lab.round_state.tick(121)
	assert(not timeout_load.held and lab.held_body == null and lab.suspension.attached_body == null)
	for bin in lab.bins: assert(not bin.enabled)
	assert(lab.round_state.state == &"finished" and lab.finish_reason == "Time is up")
	print("SALVAGE_TEST_OK full six-item physics round, pause carrying, score, completion, restart, timeout")
	lab.queue_free()
	await process_frame
	quit()
