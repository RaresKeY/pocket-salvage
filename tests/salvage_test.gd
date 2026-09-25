extends SceneTree
const Heads = preload("res://scripts/crane/crane_heads.gd")
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

func settle() -> void:
	for frame in 240:
		await step()
		if absf(lab.tip.linear_velocity.x) < 8 and absf(lab.tip.angular_velocity) < 0.2: break

func lift(item: RigidBody2D) -> RigidBody2D:
	await reel_to(90)
	for frame in 300:
		if item.linear_velocity.length() < 5: break
		await step()
	await move_x(item.position.x)
	await settle()
	if not lab.gripping: lab.toggle_grip()
	for frame in 400:
		lab.try_pickup()
		if is_instance_valid(lab.held_body): break
		await step(0,1 if lab.suspension.cable_length < 335 else 0)
	assert(is_instance_valid(lab.held_body),"Crane must pick a nearby item")
	item = lab.held_body
	await reel_to(80)
	await step(0,0,120)
	assert(item.position.y < 220,"Suspension lifts actual rigid body")
	return item

func carry_and_release(item: RigidBody2D, bin: Node2D) -> void:
	await move_x(bin.position.x)
	for frame in 240:
		await step()
		if absf(item.position.x-bin.position.x)<28 and absf(item.linear_velocity.x)<25: break
	lab.toggle_grip()

## The highest undelivered piece the fitted head can grip, or null when none is left for it.
func next_item() -> RigidBody2D:
	var best: RigidBody2D
	for candidate in lab.payloads:
		if not is_instance_valid(candidate) or candidate.delivered or not Heads.grips(lab.head,candidate.material_id): continue
		if best == null or candidate.position.y < best.position.y: best = candidate
	return best

## Lowers the head onto a stand and presses E there.
func use_stand(stand: Dictionary) -> void:
	await reel_to(90)
	await move_x(stand.top.x)
	await reel_to(335)
	await step(0,0,90)
	assert(lab.stand_under_head() == stand,"Head sits on the stand")
	assert(lab.use_stand(),"Stand accepts the swap")
	await reel_to(90)

func swap_to(kind: Heads.Kind) -> void:
	for stand in lab.stands:
		if stand.holds == Heads.Kind.NONE:
			await use_stand(stand)
			break
	assert(lab.head == Heads.Kind.NONE,"Head parked")
	for stand in lab.stands:
		if stand.holds == kind:
			await use_stand(stand)
			break
	assert(lab.head == kind,"New head fitted")

func run() -> void:
	root.size = Vector2i(1280,720)
	lab = load("res://labs/salvage/lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	lab.set_physics_process(false)
	assert(lab.round_state.state == &"ready")
	for sound in [&"magnet_on",&"magnet_off",&"claw_shut",&"claw_open",&"clank",&"pickup",&"land",&"correct",&"wrong",&"eject",&"tick",&"finish",&"start",&"trolley_loop",&"winch_loop"]:
		assert(load("res://assets/audio/%s.wav" % sound) is AudioStreamWAV,"Generated sound %s imports" % sound)
	assert(lab.world.process_mode == Node.PROCESS_MODE_DISABLED and lab.ambience.stars.size() == 70)
	assert(load("res://assets/audio/music_yard.wav") is AudioStreamWAV and lab.sfx.loop_level(lab.MUSIC) == 1.0,"Music plays from the start screen")
	lab.set_music(false)
	assert(lab.sfx.loop_level(lab.MUSIC) == 0.0,"M mutes the music")
	lab.set_music(true)
	var scenery_clock: float = lab.ambience.time
	for frame in 10: await process_frame
	assert(lab.ambience.time > scenery_clock,"Scenery keeps moving on the start screen")
	lab.hud.start_requested.emit()
	assert(lab.round_state.state == &"running")
	await step(0,0,60)
	assert(lab.head == Heads.Kind.MAGNET and lab.payloads.size() == 10)
	var tumbled: RigidBody2D = lab.payloads[0]
	var upright: float = tumbled.rotation
	for turn in [PI, PI * 0.5, -PI * 0.5]:
		tumbled.rotation = upright + turn
		assert(tumbled.grip_point().y < tumbled.global_position.y - 1.0,"Grip is on whichever face points up")
	tumbled.rotation = upright
	assert(not lab.use_stand() and lab.feedback.contains("tool stand"),"Swapping needs the head on a stand")
	var refused: RigidBody2D
	for candidate in lab.payloads:
		if not Heads.grips(lab.head,candidate.material_id) and (refused == null or candidate.position.y < refused.position.y): refused = candidate
	await reel_to(90)
	await move_x(refused.position.x)
	await reel_to(335)
	await step(0,0,90)
	lab.toggle_grip()
	for frame in 30:
		lab.try_pickup()
		assert(lab.held_body == null or lab.held_body.material_id == &"steel","Magnet never lifts copper or rubber")
		await step()
	lab.toggle_grip()
	lab.release_load()
	var swapped := false
	for delivery_index in 10:
		var item := next_item()
		if item == null:
			assert(not swapped,"One swap covers every material")
			await swap_to(Heads.Kind.CLAW)
			swapped = true
			lab.toggle_grip()
			assert(lab.gripping and lab.head_sprite.animation == &"open" and lab.hud.magnet_label.text.begins_with("Claw READY"),"Armed claw waits open")
			lab.toggle_grip()
			item = next_item()
		item = await lift(item)
		assert(Heads.grips(lab.head,item.material_id),"Lifted piece suits the head")
		if lab.head == Heads.Kind.CLAW: assert(lab.head_sprite.animation in [&"closing",&"held"],"Claw shuts once it has caught something")
		if delivery_index == 0:
			lab.toggle_pause()
			var before: Vector2 = item.position
			var before_tip: Vector2 = lab.tip.position
			var time_before: float = lab.round_state.remaining_time
			for frame in 30: await physics_frame
			assert(item.position.is_equal_approx(before) and lab.tip.position.is_equal_approx(before_tip))
			assert(lab.round_state.remaining_time == time_before and lab.held_body == item)
			lab.toggle_pause()
			var wrong_bin: Node2D
			for bin in lab.bins:
				if bin.material_id != item.material_id: wrong_bin = bin
			await carry_and_release(item,wrong_bin)
			for frame in 240:
				await step()
				if lab.round_state.wrong_count == 1: break
			assert(lab.round_state.wrong_count == 1 and lab.round_state.score == -25,"Wrong bin penalises")
			for frame in 240:
				await step()
				if not item.delivered: break
			assert(is_instance_valid(item) and not item.delivered,"Wrong bin throws the item back into play")
			for bin in lab.bins: assert(not bin.sensor.get_overlapping_bodies().has(item))
			assert(lab.round_state.delivered_count == 0 and lab.round_state.wrong_count == 1)
			for frame in 240:
				await step()
				if item.linear_velocity.length() < 5 and item.position.y > 380: break
			var first_bin: Node2D = lab.bins[0]
			assert(item.position.x > 80 and item.position.x < first_bin.position.x - first_bin.bin_size.x * 0.5,"Thrown item lands in front of the bins, within crane reach")
			item = await lift(item)
		var target_bin: Node2D
		for bin in lab.bins:
			if bin.material_id == item.material_id: target_bin = bin
		var before_count: int = lab.round_state.delivered_count
		await carry_and_release(item,target_bin)
		for frame in 240:
			await step()
			if lab.round_state.delivered_count > before_count: break
		assert(lab.round_state.delivered_count == before_count+1,"Released item enters bin")
		print("SALVAGE_DELIVERY count=%d elapsed=%.2f" % [lab.round_state.delivered_count,simulated])
	assert(lab.round_state.state == &"finished")
	assert(swapped and lab.round_state.time_bonus > 0 and lab.round_state.correct_count == 10)
	for sound in [&"start",&"magnet_on",&"claw_shut",&"clank",&"pickup",&"wrong",&"eject",&"correct",&"finish"]:
		assert(lab.sfx.played.has(sound),"Round plays %s" % sound)
	assert(lab.round_state.wrong_count >= 1,"Passengers riding on a lifted piece can land in the wrong bin; the deliberate one always counts")
	assert(lab.round_state.score == 1000 - 25 * lab.round_state.wrong_count + lab.round_state.time_bonus)
	assert(lab.hud.details.text.contains("Time bonus  +%d" % lab.round_state.time_bonus))
	assert(lab.hud.modal.visible)
	lab.hud.restart_requested.emit()
	assert(lab.round_state.state == &"running" and lab.round_state.score == 0)
	assert(lab.payloads.size() == 10 and not lab.gripping and lab.held_body == null)
	assert(lab.head == Heads.Kind.MAGNET and lab.stands[0].holds == Heads.Kind.CLAW and lab.stands[1].holds == Heads.Kind.NONE,"Restart puts the heads back")
	lab.move_crane(1,0,1.0/60.0)
	assert(is_equal_approx(lab.sfx.loop_level(&"trolley_loop"),1.0) and lab.sfx.loop_level(&"winch_loop") == 0.0,"Trolley motor runs while travelling")
	lab.move_crane(0,1,1.0/60.0)
	assert(lab.sfx.loop_level(&"trolley_loop") == 0.0 and is_equal_approx(lab.sfx.loop_level(&"winch_loop"),1.0),"Winch runs while lowering")
	lab.move_crane(0,0,1.0/60.0)
	assert(lab.sfx.loop_level(&"trolley_loop") == 0.0 and lab.sfx.loop_level(&"winch_loop") == 0.0,"Motors fall silent when idle")
	var start_x: float = lab.suspension.anchor.x
	lab.suspension.anchor.x = 1120
	lab.move_crane(1,0,1.0/60.0)
	assert(lab.sfx.loop_level(&"trolley_loop") == 0.0,"No motor noise pushing against the end stop")
	lab.suspension.anchor.x = start_x
	lab.move_crane(-1,0,1.0/60.0)
	lab.toggle_pause()
	assert(lab.sfx.loop_level(&"trolley_loop") == 0.0,"Pausing silences the motors")
	lab.toggle_pause()
	for frame in 4: await physics_frame
	assert(lab.round_state.delivered_count == 0)
	var timeout_load: RigidBody2D = lab.payloads[0]
	lab.held_body = timeout_load
	timeout_load.held = true
	lab.gripping = true
	lab.suspension.attach(timeout_load)
	lab.round_state.tick(lab.ROUND_SECONDS + 1)
	assert(not timeout_load.held and lab.held_body == null and lab.suspension.attached_body == null)
	for bin in lab.bins: assert(not bin.enabled)
	assert(lab.round_state.state == &"finished" and lab.finish_reason == "Time is up")
	print("SALVAGE_TEST_OK ten-piece pile, magnet refuses copper and rubber, head swap at the stands, pause carrying, score, completion, restart, timeout")
	lab.queue_free()
	await process_frame
	quit()
