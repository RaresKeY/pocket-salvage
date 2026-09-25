extends Control
const Motion = preload("res://scripts/input/crane_motion.gd")
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
const Controls = preload("res://scripts/input/salvage_input.gd")
var controls: Node
const DebugOverlay = preload("res://scripts/debug/yard_debug_overlay.gd")
const Levels = preload("res://scripts/level/level_catalog.gd")
var selected_level := 0
const BLOOD_GRADE = preload("res://shaders/blood_moon_grade.gdshader")
const BloodMoon = preload("res://scripts/level/blood_moon.gd")
var blood_cycle: Node
const HUD = preload("res://scripts/ui/round_hud.gd")
const Burst = preload("res://scripts/fx/burst_2d.gd")
const Heads = preload("res://scripts/crane/crane_heads.gd")
const YardArt = preload("res://scripts/art/yard_art.gd")
const Weather = preload("res://scripts/weather/weather.gd")
var weather: Node
## Set before the world is built to fix the weather (tests); empty uses the selected level.
var forced_weather: StringName = &""
var layout: Dictionary
var bin_labels: Array[Label] = []
var power_out_left := 0.0
var _weather_rng := RandomNumberGenerator.new()
const PICKUP_RANGE := 62.0
const MUSIC := &"music_yard"
const MUSIC_DB := -17.0
var music_on := true
const ROUND_SECONDS := 240.0
const STAND_REACH := Vector2(34, 26)
const STAND_GAP := 80.0
## Thrown-back scrap lands this far in front of the first bin, clear of its wall so the head can reach it.
const REJECT_CLEARANCE := 120.0
var viewport: SubViewport
var stage: SubViewportContainer
var world: Node2D
var debug_overlay: Node2D
var hud: Control
var round_state: Node
var suspension: Node2D
var tip: CableBody
var trolley: Sprite2D
var head_sprite: AnimatedSprite2D
var head: Heads.Kind = Heads.Kind.MAGNET
## Each stand: {body, top (world point), holds (Heads.Kind), sprite (spare head or null)}.
var stands: Array[Dictionary] = []
var art_scale := 1.0
var reject_landing := Vector2.ZERO
var stage_transform := Transform2D.IDENTITY
var shake := 0.0
const HEAVY_MASS := 1.5
const SHAKE_DECAY := 30.0
var payloads: Array[RigidBody2D] = []
var bins: Array[Node2D] = []
var held_body: RigidBody2D
var gripping := false:
	set(value):
		if value != gripping and not (value and Heads.closes_on_catch(head)): _engage(value)
		gripping = value
var feedback := "Sort copper, rubber and steel into matching bins."
var feedback_left := 0.0
var level_variant := 0
var rebuilding := false
var finish_reason := ""
var victory := false

func _ready() -> void:
	controls = Controls.new()
	add_child(controls)
	controls.command_requested.connect(_command)
	controls.scheme_changed.connect(func(_scheme): refresh_hud())
	if controls.mobile_touch and OS.has_feature("web"):
		get_window().size_changed.connect(_scale_mobile_ui)
		_scale_mobile_ui()
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
	set_music(music_on)
	round_state = Round.new()
	add_child(round_state)
	round_state.changed.connect(_state_changed)
	round_state.finished.connect(_finished)
	var hud_layer := CanvasLayer.new()
	add_child(hud_layer)
	hud = HUD.new()
	hud.developer_enabled = DebugOverlay.available()
	hud.touch_enabled = controls.mobile_touch
	hud.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	hud_layer.add_child(hud)
	hud.level_selected.connect(select_level)
	hud.levels_requested.connect(show_levels)
	hud.start_requested.connect(start_round)
	hud.restart_requested.connect(finish_action)
	hud.pause_requested.connect(toggle_pause)
	hud.music_requested.connect(func(): set_music(not music_on))
	hud.effects_requested.connect(func(): sfx.set_effects_enabled(not sfx.effects_enabled); refresh_hud())
	hud.volume_requested.connect(func(music: float, effects: float): sfx.set_volumes(music, effects); refresh_hud())
	hud.debug_requested.connect(_set_debug_overlay)
	hud.layout_changed.connect(_fit)
	hud.touch_controls.axes_changed.connect(controls.set_touch_axes)
	hud.touch_controls.command_requested.connect(controls.touch_command)
	controls.controls_released.connect(hud.touch_controls.release_all)
	resized.connect(_fit)
	_weather_rng.randomize()
	_build_world()
	_fit()
	refresh_hud()

func _fit() -> void:
	if stage == null: return
	var top: float = hud.top_panel.get_global_rect().end.y + 6 if hud != null else 100.0
	var bottom: float = hud.bottom_panel.get_global_rect().position.y - 6 if hud != null else size.y - 121.0
	if hud.touch_enabled: bottom = size.y
	stage.position = Vector2(0, top)
	stage.size = Vector2(maxf(1, size.x - hud.world_right_inset), maxf(1, bottom - top))
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
	gripping = false
	head = Heads.Kind.MAGNET
	stands.clear()
	stage.material = null
	if selected_level == 3:
		var grade := ShaderMaterial.new()
		grade.shader = BLOOD_GRADE
		stage.material = grade
	world = Node2D.new()
	viewport.add_child(world)
	layout = Layout.create_layout(level_variant, Levels.scrap_count(selected_level))
	bin_labels.clear()
	art_scale = layout.art_scale
	reject_landing = Vector2(layout.bins[0].position.x - layout.bins[0].size.x * 0.5 - REJECT_CLEARANCE, layout.ground_top - 25)
	ambience = Ambience.new()
	world.add_child(ambience)
	ambience.configure(layout, selected_level == 3)
	var backdrop := Backdrop.new()
	backdrop.z_index = -10
	backdrop.draw_sky = false
	world.add_child(backdrop)
	if selected_level == 3: backdrop.skylines = Backdrop.skyline_set("backdrop_blood_skyline_tile")
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
		label.theme = hud.theme
		label.text = str(entry.material).to_upper()
		label.position = entry.position - Vector2(70,80)
		label.size.x = 140
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size",20)
		world.add_child(label)
		bin_labels.append(label)
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
	for index in 2:
		_add_stand(layout.tool_stand + Vector2(index * STAND_GAP,0),Heads.Kind.CLAW if index == 0 else Heads.Kind.NONE)
	_fit_head(head)
	trolley = YardArt.sprite("crane_trolley",art_scale)
	trolley.z_index = 2
	world.add_child(trolley)
	suspension = Suspension.new()
	world.add_child(suspension)
	suspension.configure(tip,layout.crane_anchor,160.0)
	trolley.position = suspension.anchor
	ambience.crane_points = func() -> Array: return [trolley.position, tip.global_position]
	weather = Weather.new()
	world.add_child(weather)
	weather.configure(Weather.find(forced_weather) if forced_weather != &"" else Levels.roll_weather(selected_level, _weather_rng),_weather_rng.randi())
	weather.attach(self)
	blood_cycle = null
	if selected_level == 3:
		blood_cycle = BloodMoon.new()
		world.add_child(blood_cycle)
		blood_cycle.configure(self, _weather_rng.randi())
	if DebugOverlay.available():
		if debug_overlay == null:
			debug_overlay = DebugOverlay.new()
			viewport.add_child(debug_overlay)
		debug_overlay.configure(world, hud.hitboxes_check.button_pressed, hud.masks_check.button_pressed)
	world.reset_physics_interpolation()
	finish_reason = ""
	feedback = ""
	feedback_left = 0.0
	victory = false
	round_state.configure(ROUND_SECONDS,payloads.size(),weather.profile.multiplier)
	rebuilding = false
	_state_changed()

## "Storm x1.6", or just "Clear" when the weather has no multiplier.
func weather_label() -> String:
	var profile = weather.profile
	var text: String = profile.label if profile.multiplier <= 1.0 else "%s x%s" % [profile.label,String.num(profile.multiplier,1)]
	if profile.wind != 0 or profile.gust != 0: text += " / " + weather.direction_label()
	return text

func scrap_bodies() -> Array:
	return payloads.filter(func(body): return is_instance_valid(body))

## What wind pushes: the head, and scrap that is loose, not carried and not being thrown back.
func blown_bodies() -> Array:
	return [tip] + scrap_bodies().filter(func(body): return not body.held and not body.delivered and not bins.any(func(bin): return bin.is_thrown(body)))

## The electrically powered role drops its load; Blood Moon assigns that role to the claw.
func power_cut(seconds: float) -> void:
	if Heads.function_kind(head, selected_level == 3) != Heads.Kind.MAGNET: return
	power_out_left = maxf(power_out_left,seconds)
	release_load()
	if is_instance_valid(head_sprite): head_sprite.play(&"open")
	_say("Power cut! The %s lost power." % Heads.SPECS[head].name.to_lower(),2.5)

func _fit_head(kind: Heads.Kind) -> void:
	power_out_left = 0.0
	if is_instance_valid(head_sprite): head_sprite.queue_free()
	head = kind
	head_sprite = Heads.sprite(kind,art_scale)
	tip.add_child(head_sprite)

func _add_stand(at: Vector2, holds: Heads.Kind) -> void:
	var art := YardArt.sprite("tool_stand",art_scale)
	var size := YardArt.world_size(art.texture,art_scale)
	var body := StaticBody2D.new()
	body.position = at
	var shape := RectangleShape2D.new()
	shape.size = size
	Parts.add_solid(body,shape)
	body.add_child(art)
	world.add_child(body)
	var stand := {"body": body, "top": at - Vector2(0,size.y * 0.5), "holds": Heads.Kind.NONE, "sprite": null}
	stands.append(stand)
	_set_stand(stand,holds)

func _set_stand(stand: Dictionary, holds: Heads.Kind) -> void:
	if stand.sprite != null: stand.sprite.queue_free()
	stand.holds = holds
	stand.sprite = null
	if holds == Heads.Kind.NONE: return
	var spare := Heads.sprite(holds,art_scale)
	var height: float = YardArt.world_size(spare.sprite_frames.get_frame_texture(&"open",0),art_scale).y
	spare.position = stand.top - Vector2(0,height * 0.5) - stand.body.position
	stand.body.add_child(spare)
	stand.sprite = spare

## The stand under the lowered head, if the head is close enough to sit on it.
func stand_under_head() -> Dictionary:
	var mount := head_mount()
	for stand in stands:
		var offset: Vector2 = mount - stand.top
		if absf(offset.x) <= STAND_REACH.x and absf(offset.y) <= STAND_REACH.y: return stand
	return {}

## E at a stand: park the fitted head on an empty stand, or fit the head waiting on it.
func use_stand() -> bool:
	if round_state.state != &"running" or is_instance_valid(held_body): return false
	var stand := stand_under_head()
	if stand.is_empty():
		_say("Lower the %s onto a tool stand, then use Swap." % ("hook" if head == Heads.Kind.NONE else Heads.SPECS[head].name.to_lower()),4.0)
		return false
	if head != Heads.Kind.NONE and stand.holds == Heads.Kind.NONE:
		gripping = false
		_set_stand(stand,head)
		_fit_head(Heads.Kind.NONE)
		_say("Parked. Fetch the other head from its stand.",4.0)
	elif head == Heads.Kind.NONE and stand.holds != Heads.Kind.NONE:
		var fitted: Heads.Kind = stand.holds
		_set_stand(stand,Heads.Kind.NONE)
		_fit_head(fitted)
		_say("%s fitted. It grips %s." % [Heads.SPECS[fitted].name," and ".join(Heads.materials(fitted, selected_level == 3))],4.0)
	else:
		_say("That stand is taken. Park on the empty one." if head != Heads.Kind.NONE else "That stand is empty.",3.0)
		return false
	sfx.play(&"clank")
	burst(stand.top,"fx_sparks")
	refresh_hud()
	return true

## Plays the head closing or opening, with its sound.
func _engage(closed: bool) -> void:
	if is_instance_valid(head_sprite): head_sprite.play(&"closing" if closed else &"open")
	if sfx != null and round_state.state == &"running" and Heads.SPECS.has(head):
		sfx.play(Heads.SPECS[head].grip_sound if closed else Heads.SPECS[head].release_sound,-6.0)

func set_music(on: bool) -> void:
	music_on = on
	sfx.set_loop(MUSIC,1.0 if on else 0.0,1.0,MUSIC_DB)
	refresh_hud()

func _say(text: String, seconds: float) -> void:
	feedback = text
	feedback_left = seconds

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
	label.theme = hud.theme
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
	_say("Blood Moon: magnet lifts copper/rubber; claw lifts steel. Watch the generator." if selected_level == 3 else "Magnet lifts steel. Swap to the claw at the tool stands for copper and rubber.",7.0)
	refresh_hud()

func restart_round() -> void:
	controls.release_controls()
	_build_world()
	start_round()

func toggle_pause() -> void:
	sfx.play(&"ui_click", -6.0)
	if round_state.state == &"running": round_state.set_paused(true)
	elif round_state.state == &"paused": round_state.set_paused(false)

func _state_changed() -> void:
	if rebuilding or world == null: return
	var running: bool = round_state.state == &"running"
	controls.set_playing(running)
	var next_mode := Node.PROCESS_MODE_INHERIT if running else Node.PROCESS_MODE_DISABLED
	if world.process_mode != next_mode:
		world.reset_physics_interpolation()
		suspension.rope.finish_interpolation()
	world.process_mode = next_mode
	for bin in bins: bin.enabled = running
	if not running:
		sfx.set_loop(&"trolley_loop",0.0)
		sfx.set_loop(&"winch_loop",0.0)
	var second := ceili(round_state.remaining_time)
	if running and second <= TICK_SECONDS and second != last_tick_second: sfx.play(&"tick",-4.0)
	last_tick_second = second
	refresh_hud()

func _finished(reason: StringName) -> void:
	victory = reason == &"all_sorted"
	finish_reason = "All scrap sorted" if reason == &"all_sorted" else "Time is up"
	sfx.play(&"finish" if reason == &"all_sorted" else &"wrong")
	release_load()
	gripping = false
	refresh_hud()

func _physics_process(delta: float) -> void:
	if round_state == null or round_state.state != &"running": return
	var axes: Vector2 = controls.movement()
	move_crane(axes.x, axes.y, delta)
	if power_out_left > 0.0:
		power_out_left = maxf(0.0,power_out_left - delta)
		if power_out_left == 0.0 and gripping: _engage(true)
	if gripping and not is_instance_valid(held_body): try_pickup()
	feedback_left = maxf(0,feedback_left-delta)
	round_state.tick(delta) # changed emits the single current HUD snapshot for this tick.

func move_crane(horizontal: float, reel: float, delta: float) -> void:
	var velocity := Motion.velocity(Vector2(horizontal, reel))
	var before := Vector2(suspension.anchor.x,suspension.cable_length)
	suspension.anchor.x = clampf(suspension.anchor.x + velocity.x * delta,80,1120)
	suspension.cable_length = clampf(suspension.cable_length + velocity.y * delta,50,335)
	trolley.position = suspension.anchor
	if delta <= 0.0: return
	var travel: float = absf(suspension.anchor.x - before.x) / (Motion.SPEED.x * delta)
	var reeled: float = (suspension.cable_length - before.y) / (Motion.SPEED.y * delta)
	sfx.set_loop(&"trolley_loop",travel,1.0,-8.0)
	sfx.set_loop(&"winch_loop",absf(reeled),1.12 if reeled < 0.0 else 0.92,-10.0)

## Wind shoves the trolley along the rail; the player steers against it. Stays within the rail's travel.
func drift_crane(dx: float) -> void:
	suspension.anchor.x = clampf(suspension.anchor.x + dx,80,1120)
	trolley.position = suspension.anchor

func toggle_grip() -> void:
	if round_state.state != &"running": return
	if head == Heads.Kind.NONE:
		_say("No head fitted. Pick one up from a tool stand with Swap.",4.0)
		refresh_hud()
		return
	gripping = not gripping
	if not gripping: release_load()
	else: try_pickup()
	refresh_hud()

func try_pickup() -> void:
	if not gripping or is_instance_valid(held_body) or power_out_left > 0.0: return
	if blood_cycle != null and not blood_cycle.generator_running and Heads.function_kind(head, true) == Heads.Kind.MAGNET: return
	var candidate: RigidBody2D
	var refused: RigidBody2D
	var nearest := PICKUP_RANGE
	for body in payloads:
		if not is_instance_valid(body) or body.delivered or body.held: continue
		if not Heads.grips(head,body.material_id, selected_level == 3):
			if head_mount().distance_to(body.grip_point()) < PICKUP_RANGE: refused = body
			continue
		var grip: Vector2 = body.grip_point()
		var distance := head_mount().distance_to(grip)
		if distance >= nearest: continue
		var ray := PhysicsRayQueryParameters2D.create(head_mount(),grip,1)
		if not world.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): continue
		candidate = body
		nearest = distance
	if candidate != null and suspension.attach(candidate,candidate.grip_offset()):
		held_body = candidate
		candidate.held = true
		if Heads.closes_on_catch(head): _engage(true)
		sfx.play(&"pickup",-3.0,0.1)
		burst(candidate.grip_point(),"fx_sparks")
		_say("Carrying %s. Lift it over the bin rim, then release." % candidate.material_id,5.0)
	elif candidate == null and refused != null and head != Heads.Kind.NONE:
		var needed := Heads.for_material(refused.material_id, selected_level == 3)
		_say("The %s won't hold %s. Swap to the %s at the tool stands." % [Heads.SPECS[head].name.to_lower(),refused.material_id,Heads.SPECS[needed].name.to_lower()],3.0)

## The underside of the fitted head, where it meets scrap or a stand.
func head_mount() -> Vector2:
	return tip.to_global(suspension.load_mount_local)

func release_load() -> void:
	if is_instance_valid(held_body): held_body.held = false
	held_body = null
	if suspension != null: suspension.detach()

func _delivered(body: RigidBody2D, material: StringName, bin: Node2D) -> void:
	match round_state.accept_delivery(body.item_id,body.material_id,material):
		Round.Delivery.CORRECT:
			sfx.play(&"correct")
			_say("Correct sort! +%d" % Round.CORRECT_POINTS,4.0)
			burst(body.global_position,"fx_sparks")
			popup(body.global_position,"+%d" % Round.CORRECT_POINTS,Color("f6d44a"))
			body.call_deferred("queue_free")
		Round.Delivery.WRONG:
			sfx.play(&"wrong")
			sfx.play(&"eject",-6.0)
			_say("That %s bin won't take %s. −%d" % [material,body.material_id,Round.WRONG_PENALTY],4.0)
			popup(body.global_position,"−%d" % Round.WRONG_PENALTY,Color("ff6b5b"))
			bin.eject(body,reject_landing)
		_: return
	refresh_hud()

func refresh_hud() -> void:
	if hud == null or round_state == null: return
	hud.present({"level_menu":true,"victory":victory,"selected_level":selected_level,"state":round_state.state,"score":round_state.score,"time_left":round_state.remaining_time,"correct":round_state.correct_count,"wrong":round_state.wrong_count,"total":payloads.size(),"delivered":round_state.delivered_count,"magnet_on":gripping,"grip_label":Heads.label(head,gripping,is_instance_valid(held_body)),"held_material":str(held_body.material_id) if is_instance_valid(held_body) else "","feedback":feedback if feedback_left > 0 else "Copper, rubber and steel each have a bin.","finish_reason":finish_reason,"time_bonus":round_state.time_bonus,"weather_label":weather_label(),"weather_tip":weather.profile.tip,"weather_bonus":round_state.weather_bonus,"music_on":music_on,"effects_on":sfx.effects_enabled,"music_volume":sfx.music_volume,"effects_volume":sfx.effects_volume,"control_scheme":controls.scheme})

func _command(command: StringName) -> void:
	match command:
		&"settings_up", &"settings_down", &"settings_left", &"settings_right": hud.settings_command(command)
		&"primary":
			match round_state.state:
				&"ready": start_round()
				&"paused": hud.activate_paused_control()
				&"finished": finish_action()
				&"running": toggle_grip()
		&"menu":
			if round_state.state in [&"running", &"paused"]: toggle_pause()
			else: _command(&"primary")
		&"grip": toggle_grip()
		&"swap": use_stand()
		&"music": set_music(not music_on)
		&"effects": sfx.set_effects_enabled(not sfx.effects_enabled); refresh_hud()
		&"pause": toggle_pause()
		&"restart": restart_round()

func _scale_mobile_ui() -> void:
	# Keep touch targets in CSS pixels even on high-DPI phone canvases.
	var css_width = JavaScriptBridge.eval("document.getElementById('canvas').clientWidth")
	if css_width != null and float(css_width) > 0.0:
		var factor := maxf(1.0, get_window().size.x / float(css_width))
		if not is_equal_approx(get_window().content_scale_factor, factor): get_window().content_scale_factor = factor

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and controls != null: controls.release_controls()
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and round_state != null and round_state.state == &"running":
		round_state.set_paused(true)

func _set_debug_overlay(hitboxes: bool, masks: bool) -> void:
	if debug_overlay != null: debug_overlay.configure(world, hitboxes, masks)

func select_level(index: int) -> void:
	if not Levels.unlocked(index) or round_state.state != &"ready": return
	selected_level = index
	controls.release_controls()
	_build_world()

func show_levels() -> void:
	if round_state.state not in [&"paused", &"finished"]: return
	controls.release_controls()
	_build_world()

func finish_action() -> void:
	if round_state.state != &"finished": return
	if not victory:
		restart_round()
		return
	if Levels.unlocked(selected_level + 1): selected_level += 1
	show_levels()
