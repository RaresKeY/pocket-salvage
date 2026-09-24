extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var lab = load("res://labs/crane/lab.tscn").instantiate()
	root.add_child(lab)
	lab.set_physics_process(false)
	for frame in 60: await physics_frame
	assert(lab.tip is RigidBody2D)
	var initial: Vector2 = lab.tip.position
	var peak_angle := 0.0
	var peak_lag := 0.0
	for frame in 90:
		lab.suspension.anchor.x += 2.0
		await physics_frame
		peak_angle = maxf(peak_angle,absf(lab.tip.rotation))
		peak_lag = maxf(peak_lag,absf(lab.suspension.anchor.x-lab.suspension.pivot_world().x))
	assert(peak_lag > 15,"Physical magnet must lag the moving hoist")
	assert(peak_angle > deg_to_rad(3),"Top pivot must produce actual rigid-body tilt")
	await physics_frame
	assert(lab.tip.linear_velocity.length() > 1,"Stopping the hoist must retain swing")
	assert(lab.tip.position.distance_to(initial)>30)
	lab.tip.apply_torque_impulse(3000)
	for frame in 180:
		await physics_frame
		peak_angle = maxf(peak_angle,absf(lab.tip.rotation))
		assert(absf(lab.tip.rotation) <= lab.suspension.angle_limit + deg_to_rad(2),"Magnet tilt must remain capped")
	# Pay out into slack: tension cannot push and state must keep falling naturally.
	var old_y: float = lab.tip.position.y
	lab.suspension.cable_length += 80
	for frame in 4: await physics_frame
	assert(lab.suspension.tension < 1,"Slack cable carries no compression")
	assert(lab.tip.position.y > old_y)
	# A lateral impulse to the payload must feed back into the suspended endpoint.
	lab.reset_fixture()
	for frame in 20: await physics_frame
	lab.toggle_attachment()
	lab.suspension.cable_length = 160
	for frame in 180: await physics_frame
	var before: Vector2 = lab.tip.position
	lab.payload.apply_central_impulse(Vector2(500,0))
	for frame in 25: await physics_frame
	assert(lab.tip.position.x > before.x + 1,"Load reaction must move magnet")
	lab.queue_free()
	await process_frame
	var game = load("res://labs/salvage/lab.tscn").instantiate()
	root.add_child(game)
	await process_frame
	assert(game.tip.z_index > game.suspension.rope.z_index)
	assert(game.trolley.z_index > game.suspension.rope.z_index)
	assert(game.suspension.pivot_world().distance_to(game.tip.to_global(game.suspension.pivot_local))<0.01)
	print("PHYSICAL_SUSPENSION_TEST_OK pivot tilt, angular stops, inertial swing, slack, load reaction, cable draw order peak_degrees=%.2f lag=%.2f" % [rad_to_deg(peak_angle),peak_lag])
	game.queue_free()
	await process_frame
	quit()
