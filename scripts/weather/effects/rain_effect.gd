extends "res://scripts/weather/weather_effect.gd"
## Visual rain angled by the wind, floor splashes, a wet sheen and the rain loop. Drops do not collide.
const FALL := 900.0
static var _line: Texture2D
var streaks: CPUParticles2D
var splashes: CPUParticles2D

func applies(profile) -> bool:
	return profile.rain > 0.0

func _start() -> void:
	var floor_y: float = context.layout.ground_top
	var width: float = context.layout.bounds.size.x
	streaks = _particles(int(weather.profile.rain * 0.6), Vector2(width * 0.5, -20), Vector2(width * 0.5, 4), Color(0.8, 0.86, 1.0, 0.7), 0.6)
	streaks.texture = _line_texture()
	streaks.spread = 2
	streaks.initial_velocity_min = FALL
	streaks.initial_velocity_max = FALL * 1.1
	splashes = _particles(int(weather.profile.rain * 0.25), Vector2(width * 0.5, floor_y), Vector2(width * 0.5, 1), Color(0.8, 0.86, 1.0, 0.5), 0.25)
	splashes.direction = Vector2.UP
	splashes.spread = 60
	splashes.gravity = Vector2(0, 400)
	splashes.initial_velocity_min = 30
	splashes.initial_velocity_max = 70
	var sheen := ColorRect.new()
	sheen.color = Color(0.55, 0.65, 0.9, 0.12)
	sheen.position = Vector2(0, floor_y)
	sheen.size = Vector2(width, 6)
	sheen.z_index = 1
	sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	context.world.add_child(sheen)
	_loop(&"rain_loop", 1.0, -14.0)

func _particles(amount: int, at: Vector2, extents: Vector2, color: Color, life: float) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.amount = maxi(amount, 1)
	particles.lifetime = life
	particles.position = at
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = extents
	particles.color = color
	particles.gravity = Vector2.ZERO
	particles.z_index = 5
	context.world.add_child(particles)
	return particles

static func _line_texture() -> Texture2D:
	if _line == null:
		var image := Image.create(2, 16, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		_line = ImageTexture.create_from_image(image)
	return _line

func rain_angle() -> float:
	return atan2(weather.wind_now() * 1.5, FALL)

func _process(_delta: float) -> void:
	var angle := rain_angle()
	streaks.direction = Vector2(sin(angle), cos(angle))
	streaks.angle_min = -rad_to_deg(angle)
	streaks.angle_max = -rad_to_deg(angle)
