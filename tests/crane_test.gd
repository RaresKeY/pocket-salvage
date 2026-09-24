extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var lab = load("res://labs/crane/lab.tscn").instantiate()
	root.add_child(lab)
	for frame in 10: await physics_frame
	lab.toggle_attachment()
	assert(lab.suspension.attached_body == lab.payload, "Nearby diagnostic payload must attach")
	var initial_y: float = lab.payload.position.y
	lab.suspension.cable_length = 170
	for frame in 150: await physics_frame
	assert(lab.payload.position.y < initial_y - 100, "Spring must lift physical load")
	assert(lab.tip.global_position.distance_to(lab.suspension.anchor) <= 171, "Tip respects rope length")
	lab.suspension.detach()
	assert(lab.suspension.attached_body == null)
	for frame in 120: await physics_frame
	assert(lab.payload.position.y > initial_y - 40, "Released load must fall")
	lab.suspension.attach(lab.payload)
	lab.suspension.enabled = false
	assert(lab.suspension.attached_body == null, "Disable releases attachment")
	assert(not lab.suspension.attach(lab.payload), "Disabled controller cannot reattach")
	print("CRANE_TEST_OK pickup, lift, rope length, release, disable")
	quit()
