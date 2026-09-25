extends SceneTree
const HUD = preload("res://scripts/ui/round_hud.gd")
var starts := 0
var pauses := 0
var restarts := 0
var music_changes := 0
var effects_changes := 0

func _initialize() -> void: call_deferred("run")

func run() -> void:
	root.size = Vector2i(768, 480)
	root.notify_mouse_entered()
	var hud := HUD.new()
	hud.present({"state": "ready"})
	root.add_child(hud)
	hud.start_requested.connect(func(): starts += 1)
	hud.pause_requested.connect(func(): pauses += 1)
	hud.music_requested.connect(func(): music_changes += 1)
	hud.effects_requested.connect(func(): effects_changes += 1)
	hud.restart_requested.connect(func(): restarts += 1)
	await process_frame
	await process_frame
	assert(hud.action.has_focus())
	await click(hud.music_button)
	await click(hud.effects_button)
	assert(music_changes == 1 and effects_changes == 1, "Audio controls work above ready modal")
	await click(hud.action)
	assert(starts == 1)
	hud.present({"state": "running", "score": 9999, "time_left": 60.1, "delivered": 3, "total": 6, "magnet_on": true, "held_material": "Metal"})
	assert(not hud.modal.visible and root.gui_get_focus_owner() == null)
	assert(hud.time_label.text == "Time  1:01")
	assert(hud.score_label.text == "Score  9999")
	await click(hud.music_button)
	assert(root.gui_get_focus_owner() == null, "Audio click returns Space to crane controls")
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
	for dimensions in [Vector2i(768,480), Vector2i(854,480), Vector2i(960,540), Vector2i(1280,720), Vector2i(1920,1080)]:
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
		for button in [hud.music_button, hud.effects_button, hud.pause_button]:
			if button.visible:
				assert(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(button.get_global_rect()))
				assert(button.size.y >= 44)
		assert(not hud.music_button.get_global_rect().intersects(hud.effects_button.get_global_rect()))
		assert(hud.top_panel.get_global_rect().end.y < hud.bottom_panel.position.y)
	hud.present({"state":"running", "time_left":9, "score":-25, "total":10, "grip_label":"Claw READY", "music_on":false, "effects_on":false})
	assert(hud.time_label.get_theme_color("font_color") == hud.HURRY_COLOR)
	assert(hud.time_label.modulate.a >= 0.55 and hud.time_label.modulate.a <= 1.0)
	assert(hud.music_button.text == "Music off" and hud.effects_button.text == "SFX off")
	assert(hud.magnet_label.text.begins_with("Claw READY") and hud.score_label.text == "Score  -25")
	# Time normalization must not freeze the warning animation or suppress other updates.
	hud.present({"state":"running", "time_left":8.9, "score":-25})
	var pulse_before: float = hud.time_label.modulate.a
	await create_timer(0.1).timeout
	hud.present({"state":"running", "time_left":8.8, "score":-25})
	assert(hud.time_label.text == "Time  0:09" and hud.time_label.modulate.a != pulse_before)
	hud.present({"state":"running", "time_left":8.7, "score":75})
	assert(hud.score_label.text == "Score  75", "A score change within the same displayed second appears immediately")
	hud.present({"state":"paused", "time_left":9})
	assert(hud.time_label.modulate.a == 1.0, "Pulse stops outside running")
	hud.present({"state": "ready", "weather_label": "Storm x1.6", "weather_tip": "Gusts, slick ground and lightning."})
	assert(hud.details.text.contains("Storm x1.6") and hud.details.text.contains("Gusts") and hud.weather_badge.text == "Storm x1.6" and hud.weather_badge.visible)
	await process_frame
	assert(hud.weather_badge.get_line_count() == 1 and hud.top_panel.size.y < 90, "weather badge stays on one line and the top bar stays compact")
	hud.present({"state": "finished", "score": 500, "weather_label": "Storm x1.6", "weather_bonus": 188})
	assert(hud.details.text.contains("Storm x1.6  +188"))
	hud.present({"state": "running"})
	assert(not hud.weather_badge.visible, "no badge without weather data")
	hud.queue_free()
	await process_frame
	print("HUD_TEST_OK states, signals, real mouse clicks, focus, counters, responsive actions, weather")
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
