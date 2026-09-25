extends Node2D
## One seagull: crosses the yard with uneven flight, or glides down to a perch, idles, and leaves when the crane comes near.
enum State { CROSSING, LANDING, PERCHED, LEAVING }
const Burst = preload("res://scripts/fx/burst_2d.gd")
const YardArt = preload("res://scripts/art/yard_art.gd")
const LAND_RANGE := 180.0
const SCARE_DISTANCE := 90.0
const HEIGHT_PX := 12

var state := State.CROSSING
var sprite: AnimatedSprite2D
var rng: RandomNumberGenerator
var speed := 70.0
var direction := 1.0
var cruise_y := 120.0
var perch := Vector2.INF
var perch_timer := 0.0
var turn_timer := 0.0
var glide_timer := 0.0
var bob_phase := 0.0
var bob_rate := 1.0
var climb := 0.0
var time := 0.0
var width := 1200.0
var half_height := 0.0
## Returns true when something (the crane) is close enough to scare a perched gull.
var is_threatened: Callable = func(_at: Vector2) -> bool: return false
signal left_perch(point: Vector2)

func setup(generator: RandomNumberGenerator, art_scale: float, yard_width: float, from_left: bool, altitude: float, landing_at: Vector2) -> void:
	rng = generator
	width = yard_width
	direction = 1.0 if from_left else -1.0
	speed = rng.randf_range(55, 95)
	cruise_y = altitude
	bob_phase = rng.randf() * TAU
	bob_rate = rng.randf_range(0.6, 1.4)
	perch = landing_at
	half_height = HEIGHT_PX * art_scale * 0.5
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	Burst.add_frames(frames, &"fly", "critter_gull", Burst.frame_numbers("critter_gull"), rng.randf_range(7, 11), true)
	var perched := Burst.frame_numbers("critter_gull_perched")
	if perched.is_empty():
		Burst.add_frames(frames, &"perch", "critter_gull", [2], 1.0, true)
	else:
		Burst.add_frames(frames, &"perch", "critter_gull_perched", perched, 3.0, true)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	YardArt.fit(sprite, art_scale)
	add_child(sprite)
	sprite.play(&"fly")
	sprite.frame = rng.randi_range(0, frames.get_frame_count(&"fly") - 1)
	position = Vector2(-30.0 if from_left else width + 30.0, altitude)
	_face(direction)
	glide_timer = rng.randf_range(1.5, 4.0)

func _face(towards: float) -> void:
	sprite.flip_h = towards < 0.0

func _process(delta: float) -> void:
	if sprite == null: return
	time += delta
	match state:
		State.CROSSING: _cross(delta)
		State.LANDING: _land(delta)
		State.PERCHED: _perch(delta)
		State.LEAVING: _leave(delta)

## Uneven flapping: short glides with the wings held, then flapping again.
func _flap(delta: float) -> void:
	glide_timer -= delta
	if glide_timer <= 0.0:
		if sprite.is_playing():
			sprite.pause()
			glide_timer = rng.randf_range(0.4, 1.1)
		else:
			sprite.play(&"fly")
			glide_timer = rng.randf_range(1.2, 3.5)

func _cross(delta: float) -> void:
	_flap(delta)
	position.x += direction * speed * delta
	position.y = cruise_y + sin(time * bob_rate + bob_phase) * 10.0 + sin(time * 0.31 + bob_phase) * 18.0
	if perch != Vector2.INF and absf(perch.x - position.x) < LAND_RANGE and signf(perch.x - position.x) == direction:
		state = State.LANDING
	elif position.x < -40.0 or position.x > width + 40.0:
		queue_free()

func _land(delta: float) -> void:
	if is_threatened.call(perch):
		_take_off()
		return
	var target := perch - Vector2(0, half_height)
	var to_target := target - position
	if to_target.length() < 2.0:
		position = target
		state = State.PERCHED
		sprite.play(&"perch")
		perch_timer = rng.randf_range(7, 18)
		turn_timer = rng.randf_range(1.5, 4.0)
		return
	if sprite.animation == &"fly" and not sprite.is_playing(): sprite.play(&"fly")
	sprite.speed_scale = 1.4
	var approach := minf(speed, maxf(25.0, to_target.length() * 1.6))
	position += to_target.normalized() * minf(approach * delta, to_target.length())
	_face(to_target.x if absf(to_target.x) > 1.0 else direction)

func _perch(delta: float) -> void:
	perch_timer -= delta
	turn_timer -= delta
	if turn_timer <= 0.0:
		turn_timer = rng.randf_range(1.5, 4.5)
		sprite.flip_h = not sprite.flip_h
	if perch_timer <= 0.0 or is_threatened.call(perch):
		_take_off()

func _take_off() -> void:
	state = State.LEAVING
	sprite.speed_scale = 1.6
	sprite.play(&"fly")
	direction = -1.0 if rng.randf() < 0.5 else 1.0
	_face(direction)
	climb = -rng.randf_range(90, 140)
	left_perch.emit(perch)

func _leave(delta: float) -> void:
	position.x += direction * speed * 1.2 * delta
	position.y += climb * delta
	climb = move_toward(climb, -10.0, 60.0 * delta)
	if sprite.speed_scale > 1.0: sprite.speed_scale = move_toward(sprite.speed_scale, 1.0, delta * 0.5)
	if position.x < -40.0 or position.x > width + 40.0 or position.y < -30.0:
		queue_free()
