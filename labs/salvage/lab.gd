extends Control
## Playable integration fixture. Subsystems retain their independent labs.
const Parts = preload("res://scripts/physics/collision_parts_2d.gd")
const CableBody = preload("res://scripts/crane/cable_body_2d.gd")
const Suspension = preload("res://scripts/crane/suspension_2d.gd")
const Payload = preload("res://labs/salvage/payload.gd")
const Layout = preload("res://scripts/level/yard_layout.gd")
const Backdrop = preload("res://scripts/level/yard_backdrop.gd")
const Ambience = preload("res://scripts/level/yard_ambience.gd")
const Sfx = preload("res://scripts/audio/sfx.gd")
const TICK_SECONDS := 10
var sfx: Node
var ambience: Node2D
var last_tick_second := -1
const Round = preload("res://scripts/round/round_controller.gd")
const Bin = preload("res://scripts/round/sorting_bin.gd")
const HUD = preload("res://scripts/ui/round_hud.gd")
const Burst = preload("res://scripts/fx/burst_2d.gd")
var viewport: SubViewport
var stage: SubViewportContainer
var world: Node2D
var hud: Control
var round_state: Node
var suspension: Node2D
var tip: CableBody
var trolley: Sprite2D
var magnet_sprite: AnimatedSprite2D
var art_scale := 1.0
var reject_landing := Vector2.ZERO
var stage_transform := Transform2D.IDENTITY
var shake := 0.0
const HEAVY_MASS := 1.5
const SHAKE_DECAY := 30.0
var payloads: Array[RigidBody2D] = []
var bins: Array[Node2D] = []
var held_body: RigidBody2D
var magnet_on := false:
	set(value):
		if value != magnet_on and is_instance_valid(magnet_sprite): magnet_sprite.play(&"on" if value else &"off")
		if value != magnet_on and sfx != null and round_state.state == &"running": sfx.play(&"magnet_on" if value else &"magnet_off",-6.0)
		magnet_on = value
var feedback := "Sort copper, rubber and steel into matching bins."
var feedback_left := 0.0
var level_variant := 0
var rebuilding := false
var finish_reason := ""

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("101d24")
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	stage = SubViewportContainer.new()
	stage.stretch = true
	add_child(stage)
	viewport = SubViewport.new()
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	stage.add_child(viewport)
	sfx = Sfx.new()
	add_child(sfx)
	round_state = Round.new()
	add_child(round_state)
	round_state.changed.connect(_state_changed)
	round_state.finished.connect(_finished)
	var hud_layer := CanvasLayer.new()
	add_child(hud_layer)
	hud = HUD.new()
	hud.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	hud_layer.add_child(hud)
	hud.start_requested.connect(start_round)
	hud.restart_requested.connect(restart_round)
	hud.pause_requested.connect(toggle_pause)
	resized.connect(_fit)
	_build_world()
	_fit()
	refresh_hud()

func _fit() -> void:
	if stage == null: return
	stage.position = Vector2(0,100)
	stage.size = Vector2(size.x, maxf(120, size.y - 221))
	var zoom := minf(stage.size.x / 1200.0, stage.size.y / 480.0)
	stage_transform = Transform2D(0,Vector2.ONE * zoom,0,(stage.size - Vector2(1200,480) * zoom)*0.5)
	viewport.canvas_transform = stage_transform

func _build_world() -> void:
	rebuilding = true
	if world != null:
		viewport.remove_child(world)
		world.queue_free()
	payloads.clear()
	bins.clear()
	held_body = null
	magnet_on = false
	world = Node2D.new()
	viewport.add_child(world)
	var layout: Dictionary = Layout.create_layout(level_variant)
	art_scale = layout.art_scale
	reject_landing = Vector2(layout.bins[0].position.x - layout.bins[0].size.x * 0.5 - 60, layout.ground_top - 25)
	ambience = Ambience.new()
	world.add_child(ambience)
	ambience.configure(layout)
	var backdrop := Backdrop.new()
	backdrop.z_index = -10
	backdrop.draw_sky = false
	world.add_child(backdrop)
	backdrop.configure(layout)
	add_wall(Vector2(600,455),Vector2(1200,30))
	add_wall(Vector2(-10,240),Vector2(20,480))
	add_wall(Vector2(1210,240),Vector2(20,480))
	for entry in layout.scrap:
		var body := Payload.new()
		body.configure(entry)
		world.add_child(body)
		body.landed.connect(_landed.bind(body))
		payloads.append(body)
	for entry in layout.bins:
		var bin := Bin.new()
		bin.configure(entry.material,entry.position,entry.size)
		world.add_child(bin)
		bin.delivered.connect(_delivered.bind(bin))
		bins.append(bin)
		var label := Label.new()
		label.text = str(entry.material).to_upper()
		label.position = entry.position - Vector2(70,80)
		label.size.x = 140
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size",20)
		world.add_child(label)
	tip = CableBody.new()
	tip.mass = 3.0
	tip.linear_damp = 0.35
	tip.angular_damp = 1.8
	tip.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	tip.z_index = 2
	tip.collision_layer = 4
	tip.collision_mask = 1
	tip.position = layout.crane_anchor + Vector2(0,160)
	var tip_shape := RectangleShape2D.new()
	tip_shape.size = Vector2(52,20)
	Parts.add_solid(tip,tip_shape)
	world.add_child(tip)
	magnet_sprite = _magnet_sprite()
	tip.add_child(magnet_sprite)
	trolley = Sprite2D.new()
	trolley.texture = preload("res://assets/bitwright_8x/crane_trolley.png")
	trolley.scale = Vector2.ONE * art_scale / 8.0
	trolley.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	trolley.z_index = 2
	world.add_child(trolley)
	suspension = Suspension.new()
	world.add_child(suspension)
	suspension.configure(tip,layout.crane_anchor,160.0)
	trolley.position = suspension.anchor
	ambience.crane_points = func() -> Array: return [trolley.position, tip.global_position]
	world.reset_physics_interpolation()
	finish_reason = ""
	round_state.configure(120.0,payloads.size())
	rebuilding = false
	_state_changed()

func _magnet_sprite() -> AnimatedSprite2D:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	Burst.add_frames(frames, &"off", "crane_magnet", [1], 1.0, false)
	Burst.add_frames(frames, &"on", "crane_magnet", range(2, 7), 14.0, false)
	Burst.add_frames(frames, &"hum", "crane_magnet", [5, 6], 6.0, true)
	var result := AnimatedSprite2D.new()
	result.sprite_frames = frames
	result.animation = &"off"
	result.scale = Vector2.ONE * art_scale / 8.0
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	result.animation_finished.connect(func(): if result.animation == &"on": result.play(&"hum"))
	return result

func _landed(at: Vector2, body: RigidBody2D) -> void:
	burst(at,"fx_dust")
	sfx.play(&"land",-2.0 if body.mass >= HEAVY_MASS else -8.0,0.15)
	if body.mass >= HEAVY_MASS: shake = maxf(shake,5.0)

func _process(delta: float) -> void:
	if viewport == null: return
	shake = maxf(0.0,shake - SHAKE_DECAY * delta) if round_state.state == &"running" else 0.0
	var offset := Vector2(randf_range(-shake,shake),randf_range(-shake,shake))
	viewport.canvas_transform = Transform2D(stage_transform.x,stage_transform.y,stage_transform.origin + offset)

func popup(at: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.z_index = 4
	label.add_theme_font_size_override("font_size",24)
	label.add_theme_color_override("font_color",color)
	label.add_theme_color_override("font_outline_color",Color("101d24"))
	label.add_theme_constant_override("outline_size",6)
	label.position = at - Vector2(40,30)
	label.size = Vector2(80,30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	world.add_child(label)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label,"position:y",label.position.y - 50,0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label,"modulate:a",0.0,0.9).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)

func burst(at: Vector2, prefix: String) -> void:
	var fx := Burst.new(prefix, at, art_scale)
	fx.z_index = 3
	world.add_child(fx)

func add_wall(position: Vector2, dimensions: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.position = position
	var shape := RectangleShape2D.new()
	shape.size = dimensions
	Parts.add_solid(wall,shape)
	world.add_child(wall)

func start_round() -> void:
	if round_state.state != &"ready": return
	round_state.start()
	sfx.play(&"start")
	feedback = "Lower the magnet over scrap, press Space, then lift."
	feedback_left = 6.0
	refresh_hud()

func restart_round() -> void:
	_build_world()
	start_round()

func toggle_pause() -> void:
	if round_state.state == &"running": round_state.set_paused(true)
	elif round_state.state == &"paused": round_state.set_paused(false)

func _state_changed() -> void:
	if rebuilding or world == null: return
	var running: bool = round_state.state == &"running"
	var next_mode := Node.PROCESS_MODE_INHERIT if running else Node.PROCESS_MODE_DISABLED
	if world.process_mode != next_mode:
		world.reset_physics_interpolation()
		suspension.rope.finish_interpolation()
	world.process_mode = next_mode
	for bin in bins: bin.enabled = running
	var second := ceili(round_state.remaining_time)
	if running and second <= TICK_SECONDS and second != last_tick_second: sfx.play(&"tick",-4.0)
	last_tick_second = second
	refresh_hud()

func _finished(reason: StringName) -> void:
	finish_reason = "All scrap sorted" if reason == &"all_sorted" else "Time is up"
	sfx.play(&"finish" if reason == &"all_sorted" else &"wrong")
	release_load()
	magnet_on = false
	refresh_hud()

func _physics_process(delta: float) -> void:
	if round_state == null or round_state.state != &"running": return
	var horizontal := float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	var reel := float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	move_crane(horizontal,reel,delta)
	if magnet_on and not is_instance_valid(held_body): try_pickup()
	round_state.tick(delta)
	feedback_left = maxf(0,feedback_left-delta)
	refresh_hud()

func move_crane(horizontal: float, reel: float, delta: float) -> void:
	suspension.anchor.x = clampf(suspension.anchor.x + horizontal * 220 * delta,80,1120)
	suspension.cable_length = clampf(suspension.cable_length + reel * 130 * delta,50,335)
	trolley.position = suspension.anchor

func toggle_magnet() -> void:
	if round_state.state != &"running": return
	magnet_on = not magnet_on
	if not magnet_on: release_load()
	else: try_pickup()
	refresh_hud()

func try_pickup() -> void:
	if not magnet_on or is_instance_valid(held_body): return
	var candidate: RigidBody2D
	var nearest := 62.0
	for body in payloads:
		if not is_instance_valid(body) or body.delivered or body.held: continue
		var grip: Vector2 = body.to_global(Vector2(0,-body.dimensions.y*0.5))
		var distance := tip.to_global(suspension.load_mount_local).distance_to(grip)
		if distance >= nearest: continue
		var ray := PhysicsRayQueryParameters2D.create(tip.to_global(suspension.load_mount_local),grip,1)
		if not world.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): continue
		candidate = body
		nearest = distance
	if candidate != null and suspension.attach(candidate,Vector2(0,-candidate.dimensions.y*0.5)):
		held_body = candidate
		candidate.held = true
		sfx.play(&"pickup",-3.0,0.1)
		burst(candidate.to_global(Vector2(0,-candidate.dimensions.y*0.5)),"fx_sparks")
		feedback = "Carrying %s. Lift it over the bin rim, then release." % candidate.material_id
		feedback_left = 5.0

func release_load() -> void:
	if is_instance_valid(held_body): held_body.held = false
	held_body = null
	if suspension != null: suspension.detach()

func _delivered(body: RigidBody2D, material: StringName, bin: Node2D) -> void:
	match round_state.accept_delivery(body.item_id,body.material_id,material):
		Round.Delivery.CORRECT:
			sfx.play(&"correct")
			feedback = "Correct sort! +%d" % Round.CORRECT_POINTS
			burst(body.global_position,"fx_sparks")
			popup(body.global_position,"+%d" % Round.CORRECT_POINTS,Color("f6d44a"))
			body.call_deferred("queue_free")
		Round.Delivery.WRONG:
			sfx.play(&"wrong")
			sfx.play(&"eject",-6.0)
			feedback = "That %s bin won't take %s. −%d" % [material,body.material_id,Round.WRONG_PENALTY]
			popup(body.global_position,"−%d" % Round.WRONG_PENALTY,Color("ff6b5b"))
			bin.eject(body,reject_landing)
		_: return
	feedback_left = 4.0
	refresh_hud()

func refresh_hud() -> void:
	if hud == null or round_state == null: return
	hud.present({"state":round_state.state,"score":round_state.score,"time_left":round_state.remaining_time,"correct":round_state.correct_count,"wrong":round_state.wrong_count,"total":payloads.size(),"delivered":round_state.delivered_count,"magnet_on":magnet_on,"held_material":str(held_body.material_id) if is_instance_valid(held_body) else "","feedback":feedback if feedback_left > 0 else "Copper, rubber and steel each have a bin.","finish_reason":finish_reason,"time_bonus":round_state.time_bonus,"navigation_hint":"" if OS.has_feature("standalone") else "F2 preview"})

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.physical_keycode:
		KEY_SPACE: toggle_magnet()
		KEY_P, KEY_ESCAPE: toggle_pause()
		KEY_R: restart_round()
		KEY_ENTER:
			if round_state.state == &"ready": start_round()
		KEY_F2:
			if not OS.has_feature("standalone"): get_tree().change_scene_to_file("res://scenes/main.tscn")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and round_state != null and round_state.state == &"running":
		round_state.set_paused(true)
