extends Control
## The playable round: builds the yard for the selected level and runs the crane, scrap, bins, weather and HUD.
## Subsystems keep their own labs.
const Motion = preload("res://scripts/input/crane_motion.gd")
const Parts = preload("res://scripts/physics/collision_parts_2d.gd")
const CableBody = preload("res://scripts/crane/cable_body_2d.gd")
const Suspension = preload("res://scripts/crane/suspension_2d.gd")
const Heads = preload("res://scripts/crane/crane_heads.gd")
const Payload = preload("res://labs/salvage/payload.gd")
const Layout = preload("res://scripts/level/yard_layout.gd")
const Backdrop = preload("res://scripts/level/yard_backdrop.gd")
const Ambience = preload("res://scripts/level/yard_ambience.gd")
const Levels = preload("res://scripts/level/level_catalog.gd")
const TintSettings = preload("res://scripts/level/tint_settings.gd")
const Weather = preload("res://scripts/weather/weather.gd")
const Round = preload("res://scripts/round/round_controller.gd")
const Bin = preload("res://scripts/round/sorting_bin.gd")
const Controls = preload("res://scripts/input/salvage_input.gd")
const HUD = preload("res://scripts/ui/round_hud.gd")
const Sfx = preload("res://scripts/audio/sfx.gd")
const Burst = preload("res://scripts/fx/burst_2d.gd")
const YardArt = preload("res://scripts/art/yard_art.gd")
const DebugOverlay = preload("res://scripts/debug/yard_debug_overlay.gd")
const BLOOD_GRADE = preload("res://shaders/blood_moon_grade.gdshader")

const ROUND_SECONDS := 240.0
const TICK_SECONDS := 10
const MUSIC := &"music_yard"
const MUSIC_DB := -17.0
const BACKGROUND := Color("101d24")
const DEFAULT_TIP := "Copper, rubber and steel each have a bin."
const PICKUP_RANGE := 62.0
const STAND_REACH := Vector2(34, 26)
const STAND_GAP := 80.0
## Thrown-back scrap lands this far in front of the first bin, clear of its wall so the head can reach it.
const REJECT_CLEARANCE := 120.0
const HEAVY_MASS := 1.5
const SHAKE_DECAY := 30.0
const WALL := 20.0
const CABLE_START := 160.0

var selected_level := 0
var level_variant := 0
## Set before the world is built to fix the weather (tests); empty uses the selected level.
var forced_weather: StringName = &""
## Blood Moon tint strengths from the developer options; kept across restarts, session only.
var tint := TintSettings.defaults()
var music_on := true

var controls: Node
var sfx: Node
var hud: Control
var round_state: Node
var viewport: SubViewport
var stage: SubViewportContainer
var stage_transform := Transform2D.IDENTITY
var debug_overlay: Node2D

## Rebuilt with every world.
var world: Node2D
var layout: Dictionary
var art_scale := 1.0
var ambience: Node2D
var weather: Node
## Round-owned level events (Levels "events").
var events: Array[Node] = []
var blood_cycle: Node:
	get: return event(load(Levels.BLOOD_MOON))
var payloads: Array[RigidBody2D] = []
var bins: Array[Node2D] = []
var bin_labels: Array[Label] = []
var reject_landing := Vector2.ZERO
var suspension: Node2D
var tip: CableBody
var trolley: Sprite2D
var head_sprite: AnimatedSprite2D
var head: Heads.Kind = Heads.Kind.MAGNET
## Each stand: {body, top (world point), holds (Heads.Kind), sprite (spare head or null)}.
var stands: Array[Dictionary] = []

## Round state.
var held_body: RigidBody2D
var gripping := false:
	set(value):
		if value != gripping and not (value and Heads.closes_on_catch(head)): _engage(value)
		gripping = value
var power_out_left := 0.0
var magnet_flicker_left := 0.0
var _magnet_restore := false
var feedback := ""
var feedback_left := 0.0
var finish_reason := ""
var victory := false
var rebuilding := false
var shake := 0.0
var last_tick_second := -1
var _weather_rng := RandomNumberGenerator.new()

func _ready() -> void:
	controls = Controls.new()
	add_child(controls)
	controls.command_requested.connect(_command)
	controls.scheme_changed.connect(func(_scheme): refresh_hud())
	if controls.mobile_touch and OS.has_feature("web"):
		get_window().size_changed.connect(_scale_mobile_ui)
		_scale_mobile_ui()
	var bg := ColorRect.new()
	bg.color = BACKGROUND
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
	_build_hud()
	resized.connect(_fit)
	_weather_rng.randomize()
	_build_world()
	_fit()
	refresh_hud()

func _build_hud() -> void:
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
	hud.music_requested.connect(toggle_music)
	hud.effects_requested.connect(toggle_effects)
	hud.volume_requested.connect(func(music: float, effects: float): sfx.set_volumes(music, effects); refresh_hud())
	hud.debug_requested.connect(_set_debug_overlay)
	hud.tint_requested.connect(set_tint)
	hud.layout_changed.connect(_fit)
	hud.touch_controls.axes_changed.connect(controls.set_touch_axes)
	hud.touch_controls.command_requested.connect(controls.touch_command)
	controls.controls_released.connect(hud.touch_controls.release_all)

func _fit() -> void:
	if stage == null: return
	var top: float = hud.top_panel.get_global_rect().end.y + 6 if hud != null else 100.0
	var bottom: float = hud.bottom_panel.get_global_rect().position.y - 6 if hud != null else size.y - 121.0
	if hud.touch_enabled: bottom = size.y
	if hud.landscape_overlay(): top = 0.0
	stage.position = Vector2(0, top)
	stage.size = Vector2(maxf(1, size.x - hud.world_right_inset), maxf(1, bottom - top))
	stage_transform = Layout.fit_transform(stage.size)
	viewport.canvas_transform = stage_transform

## This level's setting `key` from the level catalog.
func level(key: String) -> Variant:
	return Levels.get_value(selected_level, key)

## Throws away the old world and builds the selected level's yard, ready to start.
func _build_world() -> void:
	rebuilding = true
	if world != null:
		viewport.remove_child(world)
		world.queue_free()
	world = Node2D.new()
	viewport.add_child(world)
	layout = Layout.create_layout(level_variant, level("scrap"))
	art_scale = layout.art_scale
	_build_scenery()
	_build_scrap_and_bins()
	_build_crane()
	_build_weather_and_events()
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
	round_state.configure(ROUND_SECONDS, payloads.size(), weather.profile.multiplier)
	rebuilding = false
	_apply_tint()
	_state_changed()

## The level's look: grade, sky and scenery behind the yard, and the yard's walls and floor.
func _build_scenery() -> void:
	var blood_moon: bool = level("look") == &"blood_moon"
	stage.material = null
	if blood_moon:
		stage.material = ShaderMaterial.new()
		stage.material.shader = BLOOD_GRADE
	ambience = Ambience.new()
	world.add_child(ambience)
	ambience.configure(layout, blood_moon)
	var backdrop := Backdrop.new()
	backdrop.z_index = -10
	backdrop.draw_sky = false
	world.add_child(backdrop)
	if blood_moon: backdrop.skylines = Backdrop.skyline_set("backdrop_blood_skyline_tile")
	backdrop.configure(layout)
	var bounds: Rect2 = layout.bounds
	_solid_body(Vector2(bounds.size.x * 0.5, layout.ground_top + 15), Vector2(bounds.size.x, 30))
	for x in [-WALL * 0.5, bounds.size.x + WALL * 0.5]:
		_solid_body(Vector2(x, bounds.size.y * 0.5), Vector2(WALL, bounds.size.y))

func _build_scrap_and_bins() -> void:
	payloads.clear()
	bins.clear()
	bin_labels.clear()
	for entry in layout.scrap:
		var body := Payload.new()
		body.configure(entry)
		world.add_child(body)
		body.landed.connect(_landed.bind(body))
		payloads.append(body)
	for entry in layout.bins:
		var bin := Bin.new()
		bin.configure(entry.material, entry.position, entry.size)
		world.add_child(bin)
		bin.delivered.connect(_delivered.bind(bin))
		bins.append(bin)
		bin_labels.append(_world_label(str(entry.material).to_upper(), 20, entry.position - Vector2(70, 80), 140))
	reject_landing = Vector2(layout.bins[0].position.x - layout.bins[0].size.x * 0.5 - REJECT_CLEARANCE, layout.ground_top - 25)

func _build_crane() -> void:
	held_body = null
	gripping = false
	head = Heads.Kind.MAGNET
	stands.clear()
	tip = CableBody.new()
	tip.mass = 3.0
	tip.linear_damp = 0.35
	tip.angular_damp = 1.8
	tip.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	tip.z_index = 2
	tip.collision_layer = 4
	tip.collision_mask = 1
	tip.position = layout.crane_anchor + Vector2(0, CABLE_START)
	Parts.add_solid(tip, _box(Vector2(52, 20)))
	world.add_child(tip)
	for index in 2:
		_add_stand(layout.tool_stand + Vector2(index * STAND_GAP, 0), Heads.Kind.CLAW if index == 0 else Heads.Kind.NONE)
	_fit_head(head)
	trolley = YardArt.sprite("crane_trolley", art_scale)
	trolley.z_index = 2
	world.add_child(trolley)
	suspension = Suspension.new()
	world.add_child(suspension)
	suspension.configure(tip, layout.crane_anchor, CABLE_START)
	trolley.position = suspension.anchor
	ambience.crane_points = func() -> Array: return [trolley.position, tip.global_position]

func _build_weather_and_events() -> void:
	weather = Weather.new()
	world.add_child(weather)
	weather.configure(Weather.find(forced_weather) if forced_weather != &"" else Levels.roll_weather(selected_level, _weather_rng), _weather_rng.randi())
	weather.attach(self)
	events.clear()
	for path in level("events"):
		var level_event: Node = load(path).new()
		world.add_child(level_event)
		level_event.configure(self, _weather_rng.randi())
		events.append(level_event)

static func _box(dimensions: Vector2) -> RectangleShape2D:
	var shape := RectangleShape2D.new()
	shape.size = dimensions
	return shape

## A static box in the world, centred on `at`.
func _solid_body(at: Vector2, dimensions: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = at
	Parts.add_solid(body, _box(dimensions))
	world.add_child(body)
	return body

## A centred world-space label in the HUD's font.
func _world_label(text: String, font_size: int, at: Vector2, width: float) -> Label:
	var label := Label.new()
	label.theme = hud.theme
	label.text = text
	label.position = at
	label.size.x = width
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	world.add_child(label)
	return label

## "Storm x1.6", or just "Clear" when the weather has no multiplier.
func weather_label() -> String:
	var profile = weather.profile
	var text: String = profile.label if profile.multiplier <= 1.0 else "%s x%s" % [profile.label, String.num(profile.multiplier, 1)]
	if profile.wind != 0 or profile.gust != 0: text += " / " + weather.direction_label()
	return text

## The live event of this level made from `script`, or null.
func event(script: Script) -> Node:
	for level_event in events:
		if is_instance_valid(level_event) and level_event.get_script() == script: return level_event
	return null

## False while a level event has the yard's power out (the Blood Moon generator, an Electric Storm blackout).
func powered() -> bool:
	return events.all(func(level_event): return level_event.get("generator_running") != false)

## Only the electrically powered head needs power; Blood Moon gives that role to the claw.
func head_has_power() -> bool:
	if Heads.function_kind(head, reversed_heads()) != Heads.Kind.MAGNET: return true
	return power_out_left <= 0.0 and powered()

## Blood Moon swaps which head grips which material.
func reversed_heads() -> bool:
	return level("reversed_heads")

func scrap_bodies() -> Array:
	return payloads.filter(func(body): return is_instance_valid(body))

## What wind pushes: the head, and scrap that is loose, not carried and not being thrown back.
func blown_bodies() -> Array:
	return [tip] + scrap_bodies().filter(func(body): return not body.held and not body.delivered and not bins.any(func(bin): return bin.is_thrown(body)))

## Lightning and outages. Levels with lightning_flips_magnet briefly flip the magnet; otherwise the electrically
## powered head (the claw in Blood Moon) drops its load and stays off for `seconds`.
func power_cut(seconds: float) -> void:
	if level("lightning_flips_magnet") and head == Heads.Kind.MAGNET:
		if magnet_flicker_left <= 0.0:
			_magnet_restore = gripping
			gripping = not gripping
			if not gripping: release_load()
		magnet_flicker_left = maxf(magnet_flicker_left, seconds)
		say("Lightning! Magnet briefly switched %s." % ("ON" if gripping else "OFF"), 1.5)
		refresh_hud()
		return
	if Heads.function_kind(head, reversed_heads()) != Heads.Kind.MAGNET: return
	power_out_left = maxf(power_out_left, seconds)
	release_load()
	if is_instance_valid(head_sprite): head_sprite.play(&"open")
	say("Power cut! The %s lost power." % _head_name(head), 2.5)

func _head_name(kind: Heads.Kind) -> String:
	return "hook" if kind == Heads.Kind.NONE else Heads.SPECS[kind].name.to_lower()

func _fit_head(kind: Heads.Kind) -> void:
	magnet_flicker_left = 0.0
	power_out_left = 0.0
	if is_instance_valid(head_sprite): head_sprite.queue_free()
	head = kind
	head_sprite = Heads.sprite(kind, art_scale)
	tip.add_child(head_sprite)

func _add_stand(at: Vector2, holds: Heads.Kind) -> void:
	var art := YardArt.sprite("tool_stand", art_scale)
	var size := YardArt.world_size(art.texture, art_scale)
	var body := _solid_body(at, size)
	body.add_child(art)
	var stand := {"body": body, "top": at - Vector2(0, size.y * 0.5), "holds": Heads.Kind.NONE, "sprite": null}
	stands.append(stand)
	_set_stand(stand, holds)

func _set_stand(stand: Dictionary, holds: Heads.Kind) -> void:
	if stand.sprite != null: stand.sprite.queue_free()
	stand.holds = holds
	stand.sprite = null
	if holds == Heads.Kind.NONE: return
	var spare := Heads.sprite(holds, art_scale)
	var height: float = YardArt.world_size(spare.sprite_frames.get_frame_texture(&"open", 0), art_scale).y
	spare.position = stand.top - Vector2(0, height * 0.5) - stand.body.position
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
		say("Lower the %s onto a tool stand, then use Swap." % _head_name(head), 4.0)
		return false
	if head != Heads.Kind.NONE and stand.holds == Heads.Kind.NONE:
		gripping = false
		_set_stand(stand, head)
		_fit_head(Heads.Kind.NONE)
		say("Parked. Fetch the other head from its stand.", 4.0)
	elif head == Heads.Kind.NONE and stand.holds != Heads.Kind.NONE:
		var fitted: Heads.Kind = stand.holds
		_set_stand(stand, Heads.Kind.NONE)
		_fit_head(fitted)
		say("%s fitted. It grips %s." % [Heads.SPECS[fitted].name, " and ".join(Heads.materials(fitted, reversed_heads()))], 4.0)
	else:
		say("That stand is taken. Park on the empty one." if head != Heads.Kind.NONE else "That stand is empty.", 3.0)
		return false
	sfx.play(&"clank")
	burst(stand.top, "fx_sparks")
	refresh_hud()
	return true

## Plays the head closing or opening, with its sound.
func _engage(closed: bool) -> void:
	if is_instance_valid(head_sprite): head_sprite.play(&"closing" if closed else &"open")
	if sfx != null and round_state.state == &"running" and Heads.SPECS.has(head):
		sfx.play(Heads.SPECS[head].grip_sound if closed else Heads.SPECS[head].release_sound, -6.0)

func set_music(on: bool) -> void:
	music_on = on
	sfx.set_loop(MUSIC, 1.0 if on else 0.0, 1.0, MUSIC_DB)
	refresh_hud()

func toggle_music() -> void:
	set_music(not music_on)

func toggle_effects() -> void:
	sfx.set_effects_enabled(not sfx.effects_enabled)
	refresh_hud()

func say(text: String, seconds: float) -> void:
	feedback = text
	feedback_left = seconds

func _landed(at: Vector2, body: RigidBody2D) -> void:
	burst(at, "fx_dust")
	sfx.play(&"land", -2.0 if body.mass >= HEAVY_MASS else -8.0, 0.15)
	if body.mass >= HEAVY_MASS: shake = maxf(shake, 5.0)

func _process(delta: float) -> void:
	if viewport == null: return
	shake = maxf(0.0, shake - SHAKE_DECAY * delta) if round_state.state == &"running" else 0.0
	var offset := Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	viewport.canvas_transform = Transform2D(stage_transform.x, stage_transform.y, stage_transform.origin + offset)

## A score change that floats up from `at` and fades.
func popup(at: Vector2, text: String, color: Color) -> void:
	var label := _world_label(text, 24, at - Vector2(40, 30), 80)
	label.size.y = 30
	label.z_index = 4
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", BACKGROUND)
	label.add_theme_constant_override("outline_size", 6)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 50, 0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)

func burst(at: Vector2, prefix: String) -> void:
	var fx := Burst.new(prefix, at, art_scale)
	fx.z_index = 3
	world.add_child(fx)

func start_round() -> void:
	if round_state.state != &"ready": return
	round_state.start()
	sfx.play(&"start")
	say(level("start_tip"), 7.0)
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
		sfx.set_loop(&"trolley_loop", 0.0)
		sfx.set_loop(&"winch_loop", 0.0)
	var second := ceili(round_state.remaining_time)
	if running and second <= TICK_SECONDS and second != last_tick_second: sfx.play(&"tick", -4.0)
	last_tick_second = second
	refresh_hud()

func _finished(reason: StringName) -> void:
	magnet_flicker_left = 0.0
	victory = reason == &"all_sorted"
	finish_reason = "All scrap sorted" if victory else "Time is up"
	sfx.play(&"finish" if victory else &"wrong")
	release_load()
	gripping = false
	refresh_hud()

func _physics_process(delta: float) -> void:
	if round_state == null or round_state.state != &"running": return
	var axes: Vector2 = controls.movement()
	move_crane(axes.x, axes.y, delta)
	if magnet_flicker_left > 0.0:
		magnet_flicker_left = maxf(0.0, magnet_flicker_left - delta)
		if magnet_flicker_left == 0.0:
			gripping = _magnet_restore
			if not gripping: release_load()
	if power_out_left > 0.0:
		power_out_left = maxf(0.0, power_out_left - delta)
		if power_out_left == 0.0 and gripping: _engage(true)
	if gripping and not is_instance_valid(held_body): try_pickup()
	feedback_left = maxf(0, feedback_left - delta)
	round_state.tick(delta) # changed emits the single current HUD snapshot for this tick.

func move_crane(horizontal: float, reel: float, delta: float) -> void:
	var velocity := Motion.velocity(Vector2(horizontal, reel))
	var before := Vector2(suspension.anchor.x, suspension.cable_length)
	drift_crane(velocity.x * delta)
	suspension.cable_length = clampf(suspension.cable_length + velocity.y * delta, Layout.CABLE.x, Layout.CABLE.y)
	if delta <= 0.0: return
	var travel: float = absf(suspension.anchor.x - before.x) / (Motion.SPEED.x * delta)
	var reeled: float = (suspension.cable_length - before.y) / (Motion.SPEED.y * delta)
	sfx.set_loop(&"trolley_loop", travel, 1.0, -8.0)
	sfx.set_loop(&"winch_loop", absf(reeled), 1.12 if reeled < 0.0 else 0.92, -10.0)

## Moves the trolley along the rail, within its travel. The player drives it; wind shoves it.
func drift_crane(dx: float) -> void:
	suspension.anchor.x = clampf(suspension.anchor.x + dx, Layout.RAIL_X.x, Layout.RAIL_X.y)
	trolley.position = suspension.anchor

func toggle_grip() -> void:
	if round_state.state != &"running": return
	if head == Heads.Kind.NONE:
		say("No head fitted. Pick one up from a tool stand with Swap.", 4.0)
		refresh_hud()
		return
	magnet_flicker_left = 0.0 # An explicit player toggle supersedes automatic restoration.
	gripping = not gripping
	if not gripping: release_load()
	else: try_pickup()
	refresh_hud()

func try_pickup() -> void:
	if not gripping or is_instance_valid(held_body) or not head_has_power(): return
	var candidate: RigidBody2D
	var refused: RigidBody2D
	var nearest := PICKUP_RANGE
	for body in payloads:
		if not is_instance_valid(body) or body.delivered or body.held: continue
		var grip: Vector2 = body.grip_point()
		var distance := head_mount().distance_to(grip)
		if not Heads.grips(head, body.material_id, reversed_heads()):
			if distance < PICKUP_RANGE: refused = body
			continue
		if distance >= nearest: continue
		var ray := PhysicsRayQueryParameters2D.create(head_mount(), grip, 1)
		if not world.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): continue
		candidate = body
		nearest = distance
	if candidate != null and suspension.attach(candidate, candidate.grip_offset()):
		held_body = candidate
		candidate.held = true
		if Heads.closes_on_catch(head): _engage(true)
		sfx.play(&"pickup", -3.0, 0.1)
		burst(candidate.grip_point(), "fx_sparks")
		say("Carrying %s. Lift it over the bin rim, then release." % candidate.material_id, 5.0)
	elif candidate == null and refused != null and head != Heads.Kind.NONE:
		var needed := Heads.for_material(refused.material_id, reversed_heads())
		say("The %s won't hold %s. Swap to the %s at the tool stands." % [_head_name(head), refused.material_id, _head_name(needed)], 3.0)

## The underside of the fitted head, where it meets scrap or a stand.
func head_mount() -> Vector2:
	return tip.to_global(suspension.load_mount_local)

func release_load() -> void:
	if is_instance_valid(held_body): held_body.held = false
	held_body = null
	if suspension != null: suspension.detach()

func _delivered(body: RigidBody2D, material: StringName, bin: Node2D) -> void:
	match round_state.accept_delivery(body.item_id, body.material_id, material):
		Round.Delivery.CORRECT:
			sfx.play(&"correct", -3.0)
			say("Correct sort! +%d" % Round.CORRECT_POINTS, 4.0)
			burst(body.global_position, "fx_sparks")
			popup(body.global_position, "+%d" % Round.CORRECT_POINTS, Color("f6d44a"))
			body.call_deferred("queue_free")
		Round.Delivery.WRONG:
			sfx.play(&"wrong")
			sfx.play(&"eject", -6.0)
			say("That %s bin won't take %s. −%d" % [material, body.material_id, Round.WRONG_PENALTY], 4.0)
			popup(body.global_position, "−%d" % Round.WRONG_PENALTY, Color("ff6b5b"))
			bin.eject(body, reject_landing)
		_: return
	refresh_hud()

## One snapshot of everything the HUD shows.
func refresh_hud() -> void:
	if hud == null or round_state == null: return
	var holding := is_instance_valid(held_body)
	hud.present({
		"level_menu": true, "victory": victory, "selected_level": selected_level, "state": round_state.state,
		"score": round_state.score, "time_left": round_state.remaining_time,
		"correct": round_state.correct_count, "wrong": round_state.wrong_count,
		"total": payloads.size(), "delivered": round_state.delivered_count,
		"magnet_on": gripping, "grip_label": Heads.label(head, gripping, holding),
		"held_material": str(held_body.material_id) if holding else "",
		"feedback": feedback if feedback_left > 0 else DEFAULT_TIP,
		"finish_reason": finish_reason, "time_bonus": round_state.time_bonus,
		"weather_label": weather_label(), "weather_tip": weather.profile.tip, "weather_bonus": round_state.weather_bonus,
		"music_on": music_on, "effects_on": sfx.effects_enabled, "music_volume": sfx.music_volume, "effects_volume": sfx.effects_volume,
		"control_scheme": controls.scheme,
	})

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
		&"music": toggle_music()
		&"effects": toggle_effects()
		&"pause": toggle_pause()
		&"restart": restart_round()

func _scale_mobile_ui() -> void:
	# Keep touch targets in CSS pixels even on high-DPI phone canvases.
	var css_width = JavaScriptBridge.eval("document.getElementById('canvas').clientWidth")
	if css_width != null and float(css_width) > 0.0:
		var factor := maxf(1.0, get_window().size.x / float(css_width))
		if not is_equal_approx(get_window().content_scale_factor, factor): get_window().content_scale_factor = factor

func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_WINDOW_FOCUS_OUT: return
	if controls != null: controls.release_controls()
	if round_state != null and round_state.state == &"running": round_state.set_paused(true)

func set_tint(key: StringName, value: float) -> void:
	tint[key] = TintSettings.clamp_value(key, value)
	_apply_tint()

func _apply_tint() -> void:
	if stage.material is ShaderMaterial:
		stage.material.set_shader_parameter("wash", tint[&"screen"])
		stage.material.set_shader_parameter("edge_tint", tint[&"assets"])
	ambience.sky_strength = tint[&"sky"]
	ambience.light_strength = tint[&"lights"]
	ambience.bulb_strength = tint[&"bulbs"]

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
