extends Node2D
## Animated night scenery around the yard: pure presentation, no collision, keeps moving while paused.
## `far` sits behind the backdrop (sky, stars, moon, clouds); `near` in front of it (lights, gulls, crow, rat, smoke).
const Burst = preload("res://scripts/fx/burst_2d.gd")
const YardArt = preload("res://scripts/art/yard_art.gd")
const Backdrop = preload("res://scripts/level/yard_backdrop.gd")
const Gull = preload("res://scripts/level/yard_gull.gd")
const BULB_SHADER = preload("res://shaders/blood_moon_bulbs.gdshader")

const SKY_TOP := Color("0c0a18")
## The skyline tile's own top row, so the gradient meets it without a seam.
const SKY_BOTTOM := Color("181222")
const BLOOD_SKY_TOP := Color("220912")
const BLOOD_SKY_BOTTOM := Color("391721")
const BLOOD_TINT := Color(1.0, 0.32, 0.27)
const STORM_SKY := Color("07070c")
const STORM_CLOUD := Color(0.32, 0.33, 0.4)
const MOON_HALO := Color(0.85, 0.85, 1.0)
const SKYLINE_ROWS := 32
const SKY_BANDS := 16
const STAR_COUNT := 70
const CLOUD_COUNT := 4
## Map signed weather wind to background cloud speed; calm has no drift.
const CLOUD_WIND := 0.15
const CLOUD_WRAP := 60.0
## The moon's centre as a fraction of the yard's width, and its height.
const MOON_AT := Vector2(0.8, 100)
const LAMP_GLOW := Color(1.0, 0.95, 0.75, 0.16)
const LAMP_INSET := 62.0
const LAMP_SPREAD := 120.0
const BEACON_INSET := 19.0
const BEACON_DARK := Color(0.25, 0.25, 0.3)
const BLACKOUT_ALPHA := 0.82
const BLACKOUT_Z := 15
const MAX_GULLS := 3
## At this gloom the gulls leave and stop coming.
const GULLS_LEAVE := 0.3
const RAIL_TOP := 24.0
const RAIL_PERCHES := [260.0, 520.0, 780.0, 1000.0]
const FENCE_PERCHES := [300.0, 1110.0]
const RAT_SPEED := 120.0
const CROW_HEIGHT := 12
const CROW_RANGE := Vector2(460, 560)
## How often each recurring thing happens, in seconds: name -> [first wait, then a range].
const TIMERS := {&"gull": [4.0, Vector2(10, 24)], &"rat": [12.0, Vector2(18, 30)], &"smoke": [1.0, Vector2(0.8, 1.6)], &"crow": [5.0, Vector2(4, 9)]}

var layout: Dictionary
var art_scale := 1.6
var blood_moon := false
var rng := RandomNumberGenerator.new()
var time := 0.0
## Seconds until each TIMERS entry fires next.
var waits: Dictionary = {}
## Returns world points of the moving crane parts; perched gulls near them take off.
var crane_points: Callable = func() -> Array: return []

## Driven by the round and its events.
var wind := 0.0
var generator_running := true
var left_lamp_level := 1.0
var right_lamp_level := 1.0
## Corner beacon brightness, 0 to 1; power events dim them.
var beacon_level := 1.0:
	set(value):
		beacon_level = value
		for beacon in beacons: beacon.modulate = BEACON_DARK.lerp(Color.WHITE, value)
## 0 to 1: how far a blackout has taken the yard to near black. Lightning flashes draw above it.
var blackout := 0.0:
	set(value):
		blackout = value
		if _dark: _dark.color.a = value * BLACKOUT_ALPHA
## 0 to 1 storm darkness from the storm cycle: sky and clouds darken, the moon fades and the gulls go.
var gloom := 0.0:
	set(value):
		gloom = value
		_retint_clouds()
		if moon: moon.modulate.a = 1.0 - gloom * 0.85
		if gloom >= GULLS_LEAVE:
			for gull in get_tree().get_nodes_in_group(&"yard_gull"): gull.leave()
## Developer tint strengths (see tint_settings.gd); 1 is the shipped Blood Moon look.
var sky_strength := 1.0:
	set(value):
		sky_strength = value
		_retint_clouds()
var light_strength := 1.0
var bulb_strength := 1.0:
	set(value):
		bulb_strength = value
		for material in bulb_materials: material.set_shader_parameter("strength", value)

var far: Node2D
var near: Node2D
var stars: Array[Dictionary] = []
var moon: Sprite2D
var clouds: Array[Sprite2D] = []
var lamps: Array[Vector2] = []
var lamp_sprites: Array[Sprite2D] = []
var beacons: Array[AnimatedSprite2D] = []
var bulb_materials: Array[ShaderMaterial] = []
var crow: AnimatedSprite2D
var perches: Array[Vector2] = []
## Perch index -> true while a gull holds it.
var taken: Dictionary = {}
var visitors: Array[Dictionary] = []
var _dark: ColorRect

func configure(value: Dictionary, cursed: bool = false) -> void:
	blood_moon = cursed
	layout = value
	art_scale = layout.art_scale
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.seed = 7
	for name in TIMERS: waits[name] = TIMERS[name][0]
	far = _layer(-11, _draw_far)
	near = _layer(-4, _draw_near)
	_build_sky()
	_build_lights()
	_build_perches()
	_dark = YardArt.overlay(layout.bounds, Color(0.02, 0.02, 0.05, 0.0))
	_dark.z_index = BLACKOUT_Z
	add_child(_dark)
	crow = _animated(near, "critter_crow", Vector2(510, fence_top(10) - 0.5 * CROW_HEIGHT * art_scale), 5.0)

func _build_sky() -> void:
	var bounds: Rect2 = layout.bounds
	for index in STAR_COUNT:
		stars.append({"at": Vector2(rng.randf_range(0, bounds.size.x), rng.randf_range(44, layout.ground_top - 140)),
			"size": rng.randf_range(1.0, 2.6), "phase": rng.randf() * TAU, "rate": rng.randf_range(0.8, 2.6)})
	moon = _sprite(far, "backdrop_blood_moon" if blood_moon else "backdrop_moon", _moon_centre())
	if moon: moon.scale *= 1.5
	for index in CLOUD_COUNT:
		var cloud := _sprite(far, "backdrop_cloud", Vector2(rng.randf_range(0, bounds.size.x), rng.randf_range(70, 220)))
		if cloud:
			cloud.modulate = Color(_cloud_tint(), rng.randf_range(0.5, 0.85))
			clouds.append(cloud)

## Floodlight poles (their cones are drawn in _draw_near) and the corner beacons.
func _build_lights() -> void:
	var bounds: Rect2 = layout.bounds
	for x in [LAMP_INSET, bounds.end.x - LAMP_INSET]:
		var pole := _sprite(near, "yard_floodlight", Vector2.ZERO)
		if pole == null: continue
		lamp_sprites.append(pole)
		if blood_moon: pole.material = bulb_material(false)
		var height: float = pole.texture.get_height() * pole.scale.y
		pole.position = Vector2(x, layout.ground_top - height * 0.5)
		lamps.append(pole.position - Vector2(0, height * 0.42))
	for x in [bounds.position.x + BEACON_INSET, bounds.end.x - BEACON_INSET]:
		var beacon := _animated(near, "yard_beacon", Vector2(x, 34), 4.0)
		if beacon == null: continue
		beacons.append(beacon)
		if blood_moon: beacon.material = bulb_material(true)

## Where gulls may land: floodlight tops, the rail, the heap and the fence.
func _build_perches() -> void:
	for pole in lamp_sprites: perches.append(pole.position - Vector2(0, pole.texture.get_height() * pole.scale.y * 0.5))
	for x in RAIL_PERCHES: perches.append(Vector2(x, RAIL_TOP))
	perches.append(Vector2(layout.bounds.size.x * Backdrop.HEAP_SPOTS[0], layout.ground_top - 40))
	for x in FENCE_PERCHES: perches.append(Vector2(x, fence_top(Backdrop.FENCE_SKY_ROWS)))

## Floodlight `index` (0 left, 1 right) brightness; both are dark while the generator is off.
func lamp_level(index: int) -> float:
	if not generator_running: return 0.0
	return right_lamp_level if index == 1 else left_lamp_level

func fence_top(extra_rows: float = 0.0) -> float:
	return layout.ground_top - YardArt.world_size(Backdrop.FENCE, art_scale).y + extra_rows * art_scale

func _moon_centre() -> Vector2:
	return Vector2(layout.bounds.size.x * MOON_AT.x, MOON_AT.y)

func _layer(z: int, drawer: Callable) -> Node2D:
	var layer := Node2D.new()
	layer.z_index = z
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	layer.draw.connect(drawer.bind(layer))
	add_child(layer)
	return layer

func _sprite(parent: Node2D, name: String, at: Vector2) -> Sprite2D:
	if not YardArt.exists(name): return null
	var sprite := YardArt.sprite(name, art_scale, at)
	parent.add_child(sprite)
	return sprite

func _animated(parent: Node2D, prefix: String, at: Vector2, fps: float) -> AnimatedSprite2D:
	var sprite := Burst.looping_sprite(prefix, fps, art_scale)
	if sprite == null: return null
	sprite.position = at
	sprite.frame = rng.randi_range(0, sprite.sprite_frames.get_frame_count(&"default") - 1)
	parent.add_child(sprite)
	return sprite

## Counts down TIMERS entry `name`; true when it fires and `allowed`, which also starts its next wait.
func _due(name: StringName, delta: float, allowed: bool = true) -> bool:
	waits[name] -= delta
	if waits[name] > 0.0 or not allowed: return false
	var span: Vector2 = TIMERS[name][1]
	waits[name] = rng.randf_range(span.x, span.y)
	return true

func _process(delta: float) -> void:
	if far == null: return
	time += delta
	var width: float = layout.bounds.size.x
	for cloud in clouds:
		cloud.position += Vector2(wind * CLOUD_WIND, 0) * delta
		if cloud.position.x < -CLOUD_WRAP: cloud.position.x = width + CLOUD_WRAP
		elif cloud.position.x > width + CLOUD_WRAP: cloud.position.x = -CLOUD_WRAP
	if _due(&"gull", delta, not blood_moon and gloom < GULLS_LEAVE): _spawn_gulls()
	if _due(&"rat", delta, not blood_moon): _visit(near, "critter_rat", layout.ground_top - 7, RAT_SPEED, 12.0)
	if _due(&"smoke", delta, generator_running and YardArt.exists("fx_smoke_01")): _puff_smoke()
	if _due(&"crow", delta, crow != null):
		crow.flip_h = not crow.flip_h
		crow.position.x = clampf(crow.position.x + rng.randf_range(-40, 40), CROW_RANGE.x, CROW_RANGE.y)
	for visitor in visitors.duplicate():
		var sprite: AnimatedSprite2D = visitor.sprite
		sprite.position.x += visitor.velocity * delta
		if Gull.off_yard(sprite.position.x, width):
			sprite.queue_free()
			visitors.erase(visitor)
	if blood_moon:
		for index in lamp_sprites.size(): lamp_sprites[index].material.set_shader_parameter("power", lamp_level(index))
	far.queue_redraw()
	near.queue_redraw()

## Generator exhaust drifting up from the right of the yard.
func _puff_smoke() -> void:
	var puff := Burst.new("fx_smoke", Vector2(layout.bounds.size.x * 0.9 + rng.randf_range(-12, 12), layout.ground_top - 40), art_scale)
	near.add_child(puff)
	if blood_moon: puff.modulate = BLOOD_TINT
	puff.create_tween().tween_property(puff, "position:y", puff.position.y - 50, 1.2)

## Sometimes one gull, sometimes a loose group of two or three; some of them look for a free perch.
func _spawn_gulls() -> void:
	if blood_moon: return
	var count := 1 if rng.randf() < 0.65 else rng.randi_range(2, 3)
	var from_left := rng.randf() < 0.5
	var altitude := rng.randf_range(70, 210)
	for index in count:
		if get_tree().get_nodes_in_group(&"yard_gull").size() >= MAX_GULLS: return
		var gull := Gull.new()
		gull.add_to_group(&"yard_gull")
		var landing := Vector2.INF
		if rng.randf() < 0.55:
			var free := range(perches.size()).filter(func(i): return not taken.has(i))
			if not free.is_empty():
				var choice: int = free[rng.randi_range(0, free.size() - 1)]
				taken[choice] = true
				landing = perches[choice]
				var release := func(_point = null): taken.erase(choice)
				gull.tree_exiting.connect(release)
				gull.left_perch.connect(release)
		gull.setup(rng, art_scale, layout.bounds.size.x, from_left, altitude + index * rng.randf_range(-25, 25), landing)
		gull.position.x += (-1.0 if from_left else 1.0) * index * rng.randf_range(30, 70)
		gull.is_threatened = _near_crane
		near.add_child(gull)

func _near_crane(at: Vector2) -> bool:
	for point in crane_points.call():
		if at.distance_to(point) < Gull.SCARE_DISTANCE: return true
	return false

## A critter crosses the whole yard once, from a random side, facing its way.
func _visit(parent: Node2D, prefix: String, y: float, speed: float, fps: float) -> void:
	var sprite := _animated(parent, prefix, Vector2.ZERO, fps)
	if sprite == null: return
	var from_left := rng.randf() < 0.5
	sprite.position = Vector2(Gull.entry_x(from_left, layout.bounds.size.x), y)
	sprite.flip_h = not from_left
	visitors.append({"sprite": sprite, "velocity": speed if from_left else -speed})

func _draw_far(layer: Node2D) -> void:
	var bounds: Rect2 = layout.bounds
	var horizon := fence_top(Backdrop.FENCE_SKY_ROWS) - SKYLINE_ROWS * art_scale
	var sky_top := SKY_TOP.lerp(BLOOD_SKY_TOP, sky_strength) if blood_moon else SKY_TOP
	var sky_bottom := SKY_BOTTOM.lerp(BLOOD_SKY_BOTTOM, sky_strength) if blood_moon else SKY_BOTTOM
	sky_top = sky_top.lerp(STORM_SKY, gloom * 0.7)
	sky_bottom = sky_bottom.lerp(STORM_SKY, gloom * 0.5)
	for band in SKY_BANDS:
		var top := horizon * band / SKY_BANDS
		layer.draw_rect(Rect2(0, top, bounds.size.x, horizon / SKY_BANDS + 1), sky_top.lerp(sky_bottom, float(band) / (SKY_BANDS - 1)))
	layer.draw_rect(Rect2(0, horizon, bounds.size.x, bounds.size.y - horizon), sky_bottom)
	for star in stars:
		var twinkle := (0.35 + 0.65 * absf(sin(time * star.rate + star.phase))) * (1.0 - gloom)
		layer.draw_rect(Rect2(star.at, Vector2.ONE * star.size), Color(0.95, 0.93, 1.0, twinkle))
	var halo := BLOOD_TINT if blood_moon else MOON_HALO
	layer.draw_circle(_moon_centre(), 60, Color(halo, 0.05 * (1.0 - gloom)))
	layer.draw_circle(_moon_centre(), 40, Color(halo, 0.06 * (1.0 - gloom)))

func _draw_near(layer: Node2D) -> void:
	var flicker := 0.9 + 0.1 * sin(time * 17.0) * sin(time * 3.1)
	var glow := Color(BLOOD_TINT, LAMP_GLOW.a * light_strength) if blood_moon else LAMP_GLOW
	var floor_y: float = layout.ground_top
	for index in lamps.size():
		var lamp := lamps[index]
		layer.draw_colored_polygon(PackedVector2Array([lamp + Vector2(-8, 0), lamp + Vector2(8, 0), Vector2(lamp.x + LAMP_SPREAD, floor_y), Vector2(lamp.x - LAMP_SPREAD, floor_y)]),
			Color(glow, glow.a * flicker * lamp_level(index)))

func bulb_material(is_beacon: bool) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = BULB_SHADER
	material.set_shader_parameter("beacon", is_beacon)
	material.set_shader_parameter("tint", BLOOD_TINT)
	material.set_shader_parameter("strength", bulb_strength)
	bulb_materials.append(material)
	return material

func _retint_clouds() -> void:
	for cloud in clouds: cloud.modulate = Color(_cloud_tint(), cloud.modulate.a)

func _cloud_tint() -> Color:
	var base := Color.WHITE.lerp(BLOOD_TINT, sky_strength) if blood_moon else Color.WHITE
	return base.lerp(STORM_CLOUD, gloom)
