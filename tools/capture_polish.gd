extends SceneTree
## Opt-in diagnostic capture of the real scene; synthetic results are presentation fixtures.
func _initialize() -> void: call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	assert(args.has("--output"))
	var output := args[args.find("--output") + 1]
	DirAccess.make_dir_recursive_absolute(output)
	var lab = load("res://labs/salvage/lab.tscn").instantiate()
	root.add_child(lab)
	await snap(lab, output, "ready")
	lab.start_round()
	for frame in 80: await physics_frame
	lab.set_physics_process(false)
	await snap(lab, output, "running")
	lab.toggle_pause()
	await snap(lab, output, "paused")
	lab.round_state.score = 1350
	lab.round_state.correct_count = 10
	lab.round_state.delivered_count = 10
	lab.round_state.time_bonus = 350
	lab.round_state.finish(&"all_sorted")
	await snap(lab, output, "finished")
	lab.free()
	quit()

func snap(lab: Node, output: String, mode: String) -> void:
	lab.refresh_hud()
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output + "/%s.png" % mode) == OK)
	print("POLISH_CAPTURE mode=%s size=%s renderer=%s" % [mode, root.size, RenderingServer.get_video_adapter_name()])
