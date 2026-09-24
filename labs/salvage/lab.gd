extends Control
## Playable integration fixture. Subsystems retain their independent labs.
const Parts = preload("res://scripts/physics/collision_parts_2d.gd")
const Suspension = preload("res://scripts/crane/suspension_2d.gd")
const Payload = preload("res://labs/salvage/payload.gd")
const Layout = preload("res://scripts/level/yard_layout.gd")
const Backdrop = preload("res://scripts/level/yard_backdrop.gd")
const Round = preload("res://scripts/round/round_controller.gd")
const Bin = preload("res://scripts/round/sorting_bin.gd")
const HUD = preload("res://scripts/ui/round_hud.gd")
var viewport: SubViewport
var stage: SubViewportContainer
var world: Node2D
var hud: Control
var round_state: Node
var suspension: Node2D
var tip: CharacterBody2D
var trolley: Sprite2D
var magnet_sprite: Sprite2D
var payloads: Array[RigidBody2D] = []
var bins: Array[Node2D] = []
var held_body: RigidBody2D
var magnet_on := false
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
	stage.size = Vector2(size.x, maxf(120, size.y - 205))
	var zoom := minf(stage.size.x / 1200.0, stage.size.y / 480.0)
	viewport.canvas_transform = Transform2D(0,Vector2.ONE * zoom,0,(stage.size - Vector2(1200,480) * zoom)*0.5)

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
	var backdrop := Backdrop.new()
	world.add_child(backdrop)
	backdrop.configure(layout)
	add_wall(Vector2(600,455),Vector2(1200,30))
	add_wall(Vector2(-10,240),Vector2(20,480))
	add_wall(Vector2(1210,240),Vector2(20,480))
	for entry in layout.scrap:
		var body := Payload.new()
		body.configure(entry)
		world.add_child(body)
		payloads.append(body)
	for entry in layout.bins:
		var bin := Bin.new()
		bin.configure(entry.material,entry.position,entry.size)
		world.add_child(bin)
		bin.delivered.connect(_delivered)
		bins.append(bin)
		var label := Label.new()
		label.text = str(entry.material).to_upper()
		label.position = entry.position - Vector2(70,80)
		label.size.x = 140
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size",20)
		world.add_child(label)
	tip = CharacterBody2D.new()
	tip.collision_layer = 4
	tip.collision_mask = 1
	tip.position = layout.crane_anchor + Vector2(0,160)
	var tip_shape := RectangleShape2D.new()
	tip_shape.size = Vector2(52,20)
	Parts.add_solid(tip,tip_shape)
	world.add_child(tip)
	magnet_sprite = Sprite2D.new()
	magnet_sprite.texture = preload("res://assets/bitwright_8x/crane_magnet_01.png")
	magnet_sprite.scale = Vector2.ONE * 0.2
	magnet_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tip.add_child(magnet_sprite)
	trolley = Sprite2D.new()
	trolley.texture = preload("res://assets/bitwright_8x/crane_trolley.png")
	trolley.scale = Vector2.ONE * 0.2
	trolley.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	world.add_child(trolley)
	suspension = Suspension.new()
	world.add_child(suspension)
	suspension.configure(tip,layout.crane_anchor,160.0)
	trolley.position = suspension.anchor
	finish_reason = ""
	round_state.configure(120.0,payloads.size())
	rebuilding = false
	_state_changed()

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
	world.process_mode = Node.PROCESS_MODE_INHERIT if running else Node.PROCESS_MODE_DISABLED
	for bin in bins: bin.enabled = running
	refresh_hud()

func _finished(reason: StringName) -> void:
	finish_reason = "All scrap sorted" if reason == &"all_sorted" else "Time is up"
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
	tip.velocity.x = move_toward(tip.velocity.x,0.0,140.0*delta)
	suspension.anchor.x = clampf(suspension.anchor.x + horizontal * 220 * delta,80,1120)
	suspension.cable_length = clampf(suspension.cable_length + reel * 130 * delta,50,335)
	trolley.position = suspension.anchor

func toggle_magnet() -> void:
	if round_state.state != &"running": return
	magnet_on = not magnet_on
	magnet_sprite.modulate = Color("b8ffdc") if magnet_on else Color.WHITE
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
		var distance := tip.global_position.distance_to(grip)
		if distance >= nearest: continue
		var ray := PhysicsRayQueryParameters2D.create(tip.global_position,grip,1)
		if not world.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): continue
		candidate = body
		nearest = distance
	if candidate != null and suspension.attach(candidate,Vector2(0,-candidate.dimensions.y*0.5)):
		held_body = candidate
		candidate.held = true
		feedback = "Carrying %s — lift above the bin rim, then release." % candidate.material_id
		feedback_left = 5.0

func release_load() -> void:
	if is_instance_valid(held_body): held_body.held = false
	held_body = null
	if suspension != null: suspension.detach()

func _delivered(body: RigidBody2D, material: StringName) -> void:
	if not round_state.accept_delivery(body.item_id,body.material_id,material): return
	feedback = "Correct sort! +100" if body.material_id == material else "Wrong bin. −25"
	feedback_left = 4.0
	body.call_deferred("queue_free")
	refresh_hud()

func refresh_hud() -> void:
	if hud == null or round_state == null: return
	hud.present({"state":round_state.state,"score":round_state.score,"time_left":round_state.remaining_time,"correct":round_state.correct_count,"wrong":round_state.wrong_count,"total":payloads.size(),"delivered":round_state.delivered_count,"magnet_on":magnet_on,"held_material":str(held_body.material_id) if is_instance_valid(held_body) else "","feedback":feedback if feedback_left > 0 else "Copper / rubber / steel — match the labeled bins.","finish_reason":finish_reason,"navigation_hint":"F2 preview"})

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.physical_keycode:
		KEY_SPACE: toggle_magnet()
		KEY_P, KEY_ESCAPE: toggle_pause()
		KEY_R: restart_round()
		KEY_ENTER:
			if round_state.state == &"ready": start_round()
		KEY_F2: get_tree().change_scene_to_file("res://scenes/main.tscn")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and round_state != null and round_state.state == &"running":
		round_state.set_paused(true)
