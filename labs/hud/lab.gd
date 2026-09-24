extends Node2D
const HUD = preload("res://scripts/ui/round_hud.gd")
var hud: Control
var data := {"state": "ready", "score": 120, "time_left": 65.2, "correct": 2, "wrong": 1, "delivered": 3, "total": 6, "magnet_on": false, "held_material": "", "feedback": "HUD lab: 1 ready · 2 running · 3 paused · 4 finished", "finish_reason": "Time expired"}

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("101d24"))
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = HUD.new()
	layer.add_child(hud)
	hud.start_requested.connect(func(): show_state("running"))
	hud.restart_requested.connect(func(): show_state("running"))
	hud.pause_requested.connect(func(): show_state("running" if data.state == "paused" else "paused"))
	hud.present(data)
	queue_redraw()
	_capture()

func _draw() -> void:
	for x in range(0, 2000, 40): draw_line(Vector2(x, 0), Vector2(x, 1200), Color("182a33"))
	for y in range(0, 1200, 40): draw_line(Vector2(0, y), Vector2(2000, y), Color("182a33"))

func show_state(value: String) -> void:
	data.state = value
	hud.present(data)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.physical_keycode:
		KEY_1: show_state("ready")
		KEY_2: show_state("running")
		KEY_3: show_state("paused")
		KEY_4: show_state("finished")
		KEY_P: show_state("running" if data.state == "paused" else "paused")
		KEY_R: show_state("ready")

func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.has("--capture"): return
	if args.has("--state"): show_state(args[args.find("--state") + 1])
	for frame in 10: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var result := get_viewport().get_texture().get_image().save_png(args[args.find("--capture") + 1])
	print("HUD_CAPTURE result=%s renderer=%s" % [result, RenderingServer.get_video_adapter_name()])
	get_tree().quit(result)
