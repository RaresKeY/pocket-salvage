extends "res://scripts/weather/weather_effect.gd"
## Pushes the head, the trolley and airborne scrap downwind, and shows it: gust streaks in the sky, dust along the ground.
## The scrap push grows with a piece's size rather than its mass, so light scrap drifts most.
const AREA_SCALE := 0.001
const HEAD_AREA := 52.0 * 20.0
## Trolley drift in world units per second per unit of wind; the player steers against it.
const CRANE_DRIFT := 0.22
var streaks: CPUParticles2D
var dust: CPUParticles2D

func applies(profile) -> bool:
	return profile.wind != 0.0 or profile.gust != 0.0

func _start() -> void:
	var bounds: Rect2 = context.layout.bounds
	var floor_y: float = context.layout.ground_top
	streaks = _particles(70, Vector2(bounds.size.x * 0.5, 190), Vector2(bounds.size.x * 0.5, 150), Color(0.88, 0.92, 1.0, 0.7), 1.0, Vector2(36, 2))
	dust = _particles(110, Vector2(bounds.size.x * 0.5, floor_y - 16), Vector2(bounds.size.x * 0.5, 14), Color(0.86, 0.76, 0.6, 0.85), 1.3, Vector2(5, 3))
	dust.gravity = Vector2(0, 30)

func _particles(amount: int, at: Vector2, extents: Vector2, color: Color, life: float, size: Vector2) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.amount = amount
	particles.lifetime = life
	particles.position = at
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = extents
	particles.color = color
	particles.gravity = Vector2.ZERO
	particles.spread = 4
	particles.z_index = 4
	var image := Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	particles.texture = ImageTexture.create_from_image(image)
	context.world.add_child(particles)
	return particles

## 0 at calm, 1 at the strongest gust this weather can blow.
func strength() -> float:
	var peak: float = absf(weather.profile.wind) + absf(weather.profile.gust)
	return absf(weather.wind_now()) / peak if peak > 0.0 else 0.0

func _physics_process(delta: float) -> void:
	var wind: float = weather.wind_now()
	var level := strength()
	context.ambience.wind = wind
	context.sfx.set_loop(&"wind_loop", level, 1.0, -12.0)
	for particles in [streaks, dust]:
		particles.direction = Vector2(signf(wind) if wind != 0.0 else 1.0, 0)
		particles.initial_velocity_min = absf(wind) * 3.0
		particles.initial_velocity_max = absf(wind) * 4.0
		particles.modulate.a = 0.35 + 0.65 * level
	if context.round_state.state == &"running":
		context.drift_crane(wind * CRANE_DRIFT * delta)
	for body in context.blown_bodies():
		var sized: bool = body.get("dimensions") != null
		if sized and body.get_contact_count() > 0: continue
		var area: float = body.dimensions.x * body.dimensions.y if sized else HEAD_AREA
		body.apply_central_force(Vector2(wind * area * AREA_SCALE * body.mass, 0))
