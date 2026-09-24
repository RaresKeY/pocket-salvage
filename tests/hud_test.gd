extends SceneTree
const HUD = preload("res://scripts/ui/round_hud.gd")
var starts := 0
var pauses := 0
var restarts := 0

func _initialize() -> void: call_deferred("run")

func run() -> void:
	root.size = Vector2i(768, 480)
	root.notify_mouse_entered()
	var hud := HUD.new()
	hud.present({"state": "ready"})
	root.add_child(hud)
	hud.start_requested.connect(func(): starts += 1)
	hud.pause_requested.connect(func(): pauses += 1)
	hud.restart_requested.connect(func(): restarts += 1)
	await process_frame
	await process_frame
	assert(hud.action.has_focus())
	await click(hud.action)
	assert(starts == 1)
	hud.present({"state": "running", "score": 9999, "time_left": 60.1, "delivered": 3, "total": 6, "magnet_on": true, "held_material": "Metal"})
	assert(not hud.modal.visible and root.gui_get_focus_owner() == null)
	assert(hud.time_label.text == "Time  1:01")
	assert(hud.score_label.text == "Score  9999")
	assert(hud.magnet_label.text.contains("Metal"))
	await process_frame
	await click(hud.pause_button)
	assert(pauses == 1)
	hud.present({"state": "paused"})
	await process_frame
	assert(hud.action.has_focus() and hud.action.text == "Resume")
	await click(hud.action)
	assert(pauses == 2)
	hud.present({"state": "finished", "correct": 4, "wrong": 2, "score": 200, "finish_reason": "All scrap sorted"})
	await process_frame
	assert(hud.details.text.contains("Correct  4") and hud.details.text.contains("Wrong  2"))
	await click(hud.action)
	assert(restarts == 1)
	for dimensions in [Vector2i(768,480), Vector2i(1280,720)]:
		root.size = dimensions
		await process_frame
		await process_frame
		assert(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(hud.action.get_global_rect()))
		assert(hud.action.size.y >= 44)
		var version := hud.get_node("Version") as Label
		assert(version.text == "v" + str(ProjectSettings.get_setting("application/config/version")))
		assert(version.is_visible_in_tree())
		assert(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(version.get_global_rect()))
		assert(not version.get_global_rect().intersects(hud.hints_label.get_global_rect()))
	hud.queue_free()
	await process_frame
	print("HUD_TEST_OK states, signals, real mouse clicks, focus, counters, responsive actions")
	quit()

func click(button: Button) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = button.get_global_rect().get_center()
	root.push_input(motion, true)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = button.get_global_rect().get_center()
		event.global_position = event.position
		event.pressed = pressed
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		root.push_input(event, true)
		await process_frame
