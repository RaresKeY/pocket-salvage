extends Node2D
## Animated night scenery around the yard: pure presentation, no collision, keeps moving while paused.
## `far` sits behind the backdrop (sky, stars, moon, clouds); `near` in front of it (lights, gulls, crow, rat, smoke).
const Burst = preload("res://scripts/fx/burst_2d.gd")
const YardArt = preload("res://scripts/art/yard_art.gd")
const SKY_TOP := Color("0c0a18")
## The skyline tile's own top row, so the gradient meets it without a seam.
const SKY_BOTTOM := Color("181222")
const SKYLINE_ROWS := 32
const STAR_COUNT := 70
const CLOUD_COUNT := 4
const CLOUD_SPEED := Vector2(-6, 0)
## Weather wind (world units/s², signed) also hurries the clouds along.
const CLOUD_WIND := 0.15
var wind := 0.0
var blood_moon := false
var generator_running := true
var right_lamp_level := 1.0
var lamp_sprites: Array[Sprite2D] = []
const BLOOD_TINT := Color(1.0, 0.32, 0.27)

const Gull = preload("res://scripts/level/yard_gull.gd")
const MAX_GULLS := 3
const RAIL_TOP := 24.0
const RAIL_PERCHES := [260.0, 520.0, 780.0, 1000.0]
const RAT_SPEED := 120.0
const LAMP_GLOW := Color(1.0, 0.95, 0.75, 0.16)
const CROW_HEIGHT := 12
const Backdrop = preload("res://scripts/level/yard_backdrop.gd")

var layout: Dictionary
var art_scale := 1.6
var far: Node2D
var near: Node2D
var rng := RandomNumberGenerator.new()
var stars: Array[Dictionary] = []
var clouds: Array[Sprite2D] = []
var visitors: Array[Dictionary] = []
var lamps: Array[Vector2] = []
var crow: AnimatedSprite2D
var gull_wait := 4.0
var perches: Array[Vector2] = []
var taken: Dictionary = {}
## Returns world points of the moving crane parts; perched gulls near them take off.
var crane_points: Callable = func() -> Array: return []
var rat_wait := 12.0
var smoke_wait := 1.0
var crow_wait := 5.0
var time := 0.0

func configure(value: Dictionary, cursed: bool = false) -> void:
	blood_moon = cursed
	layout = value
	art_scale = layout.art_scale
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.seed = 7
	far = _layer(-11, _draw_far)
	near = _layer(-4, _draw_near)
	var bounds: Rect2 = layout.bounds
	for index in STAR_COUNT:
		stars.append({"at": Vector2(rng.randf_range(0, bounds.size.x), rng.randf_range(44, layout.ground_top - 140)),
			"size": rng.randf_range(1.0, 2.6), "phase": rng.randf() * TAU, "rate": rng.randf_range(0.8, 2.6)})
	var moon := _sprite(far, "backdrop_moon", Vector2(bounds.size.x * 0.8, 100))
	if moon:
		moon.scale *= 1.5
		if blood_moon: moon.modulate = BLOOD_TINT
	for index in CLOUD_COUNT:
		var cloud := _sprite(far, "backdrop_cloud", Vector2(rng.randf_range(0, bounds.size.x), rng.randf_range(70, 220)))
		if cloud:
			cloud.modulate = Color(BLOOD_TINT if blood_moon else Color.WHITE, rng.randf_range(0.5, 0.85))
			clouds.append(cloud)
	for x in [62.0, bounds.end.x - 62.0]:
		var pole := _sprite(near, "yard_floodlight", Vector2.ZERO)
		if pole:
			lamp_sprites.append(pole)
			var height: float = pole.texture.get_height() * pole.scale.y
			pole.position = Vector2(x, layout.ground_top - height * 0.5)
			lamps.append(pole.position - Vector2(0, height * 0.42))
			perches.append(Vector2(x, pole.position.y - height * 0.5))
	for x in RAIL_PERCHES: perches.append(Vector2(x, RAIL_TOP))
	perches.append(Vector2(bounds.size.x * Backdrop.HEAP_SPOTS[0], layout.ground_top - 40))
	for x in [300.0, 1110.0]: perches.append(Vector2(x, fence_top(Backdrop.FENCE_SKY_ROWS)))
	for x in [bounds.position.x + 19.0, bounds.end.x - 19.0]:
		var beacon := _animated(near, "yard_beacon", Vector2(x, 34), 4.0)
		if beacon and blood_moon: beacon.modulate = BLOOD_TINT
	crow = _animated(near, "critter_crow", Vector2(510, fence_top(10) - 0.5 * CROW_HEIGHT * art_scale), 5.0)

func fence_top(extra_rows: float = 0.0) -> float:
	return layout.ground_top - YardArt.world_size(Backdrop.FENCE, art_scale).y + extra_rows * art_scale

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
	var numbers := Burst.frame_numbers(prefix)
	if numbers.is_empty(): return null
	var frames := SpriteFrames.new()
	Burst.add_frames(frames, &"default", prefix, numbers, fps, true)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	YardArt.fit(sprite, art_scale)
	sprite.position = at
	sprite.frame = rng.randi_range(0, numbers.size() - 1)
	parent.add_child(sprite)
	sprite.play()
	return sprite

func _process(delta: float) -> void:
	if far == null: return
	time += delta
	var width: float = layout.bounds.size.x
	for cloud in clouds:
		cloud.position += (CLOUD_SPEED + Vector2(wind * CLOUD_WIND, 0)) * delta
		if cloud.position.x < -60: cloud.position.x = width + 60
		elif cloud.position.x > width + 60: cloud.position.x = -60
	gull_wait -= delta
	if gull_wait <= 0.0 and not blood_moon:
		gull_wait = rng.randf_range(10, 24)
		_spawn_gulls()
	rat_wait -= delta
	if rat_wait <= 0.0 and not blood_moon:
		rat_wait = rng.randf_range(18, 30)
		_visit(near, "critter_rat", layout.ground_top - 7, RAT_SPEED, 12.0)
	smoke_wait -= delta
	if generator_running and smoke_wait <= 0.0 and YardArt.exists("fx_smoke_01"):
		smoke_wait = rng.randf_range(0.8, 1.6)
		var puff := Burst.new("fx_smoke", Vector2(width * 0.9 + rng.randf_range(-12, 12), layout.ground_top - 40), art_scale)
		near.add_child(puff)
		if blood_moon: puff.modulate = BLOOD_TINT
		puff.create_tween().tween_property(puff, "position:y", puff.position.y - 50, 1.2)
	for visitor in visitors.duplicate():
		var sprite: AnimatedSprite2D = visitor.sprite
		sprite.position.x += visitor.velocity * delta
		if sprite.position.x < -40 or sprite.position.x > width + 40:
			sprite.queue_free()
			visitors.erase(visitor)
	crow_wait -= delta
	if crow and crow_wait <= 0.0:
		crow_wait = rng.randf_range(4, 9)
		crow.flip_h = not crow.flip_h
		crow.position.x = clampf(crow.position.x + rng.randf_range(-40, 40), 460, 560)
	for index in lamp_sprites.size():
		var level := (right_lamp_level if index == 1 else 1.0) if generator_running else 0.0
		lamp_sprites[index].modulate = (BLOOD_TINT if blood_moon else Color.WHITE) * Color(0.2 + level * 0.8, 0.2 + level * 0.8, 0.2 + level * 0.8, 1)
	far.queue_redraw()
	near.queue_redraw()

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
	var width: float = layout.bounds.size.x
	sprite.position = Vector2(-30.0 if from_left else width + 30.0, y)
	sprite.flip_h = not from_left
	visitors.append({"sprite": sprite, "velocity": speed if from_left else -speed})

func _draw_far(layer: Node2D) -> void:
	var bounds: Rect2 = layout.bounds
	var horizon := fence_top(Backdrop.FENCE_SKY_ROWS) - SKYLINE_ROWS * art_scale
	var bands := 16
	var sky_top := Color("220912") if blood_moon else SKY_TOP
	var sky_bottom := Color("391721") if blood_moon else SKY_BOTTOM
	for band in bands:
		var top := horizon * band / bands
		layer.draw_rect(Rect2(0, top, bounds.size.x, horizon / bands + 1), sky_top.lerp(sky_bottom, float(band) / (bands - 1)))
	layer.draw_rect(Rect2(0, horizon, bounds.size.x, bounds.size.y - horizon), sky_bottom)
	for star in stars:
		var twinkle := 0.35 + 0.65 * absf(sin(time * star.rate + star.phase))
		layer.draw_rect(Rect2(star.at, Vector2.ONE * star.size), Color(0.95, 0.93, 1.0, twinkle))
	layer.draw_circle(Vector2(bounds.size.x * 0.8, 100), 60, Color(BLOOD_TINT if blood_moon else Color(0.85, 0.85, 1.0), 0.05))
	layer.draw_circle(Vector2(bounds.size.x * 0.8, 100), 40, Color(BLOOD_TINT if blood_moon else Color(0.85, 0.85, 1.0), 0.06))

func _draw_near(layer: Node2D) -> void:
	var flicker := 0.9 + 0.1 * sin(time * 17.0) * sin(time * 3.1)
	for index in lamps.size():
		var lamp := lamps[index]
		var level := (right_lamp_level if index == 1 else 1.0) if generator_running else 0.0
		var glow := Color(BLOOD_TINT, LAMP_GLOW.a) if blood_moon else LAMP_GLOW
		var floor_y: float = layout.ground_top
		var spread := 120.0
		layer.draw_colored_polygon(PackedVector2Array([lamp + Vector2(-8, 0), lamp + Vector2(8, 0), Vector2(lamp.x + spread, floor_y), Vector2(lamp.x - spread, floor_y)]),
			Color(glow, glow.a * flicker * level))
