extends "res://scripts/weather/weather_effect.gd"
## Pushes the head, the trolley and airborne scrap downwind, and shows it: curved wind trails and occasional lifted dust.
## Scrap is pushed in proportion to its size, so its drift is size over mass: light scrap drifts most.
const SCRAP_PUSH := 0.0008
## The head's sideways acceleration per unit of wind, independent of its mass.
const HEAD_PUSH := 1.04
## Trolley drift in world units per second per unit of wind; the player steers against it.
const CRANE_DRIFT := 0.22
const WindTrails = preload("res://scripts/weather/effects/wind_trails.gd")
var trails: Node2D
var dust_wait := 3.0
var _visual_rng := RandomNumberGenerator.new()
var dust: CPUParticles2D

func applies(profile) -> bool:
	return profile.wind != 0.0 or profile.gust != 0.0

func _start() -> void:
	var bounds: Rect2 = context.layout.bounds
	var floor_y: float = context.layout.ground_top
	_visual_rng.seed = 10873
	trails = _add(WindTrails.new(), 4)
	trails.configure(bounds)
	dust = _particles(7, Vector2(bounds.size.x * 0.5, floor_y - 28), Vector2(55, 8), Color.WHITE, 2.6, 4, YardArt.solid_texture(Vector2i(4, 3)))
	dust.emitting = false
	dust.one_shot = true
	dust.explosiveness = 0.65
	dust.randomness = 0.5
	dust.gravity = Vector2(0, -1.5)
	dust.spread = 8
	dust.scale_amount_min = 0.55
	dust.scale_amount_max = 1.8
	var shades := Gradient.new()
	shades.colors = PackedColorArray([Color("403127"), Color("594333"), Color("6b5039")])
	shades.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	dust.color_initial_ramp = shades
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.15, 0.55, 1.0])
	fade.colors = PackedColorArray([Color(1,1,1,0), Color(1,1,1,0.6), Color(1,1,1,0.35), Color(1,1,1,0)])
	dust.color_ramp = fade

## 0 at calm, 1 at the strongest gust this weather can blow.
func strength() -> float:
	var peak: float = absf(weather.profile.wind) + absf(weather.profile.gust)
	return absf(weather.wind_now()) / peak if peak > 0.0 else 0.0

func _physics_process(delta: float) -> void:
	var wind: float = weather.wind_now()
	var level := strength()
	context.ambience.wind = wind
	loop_sound(&"wind_loop", level, -12.0)
	trails.direction = weather.direction
	trails.strength = level
	trails.modulate.a = absf(weather.direction)
	dust.direction = Vector2(signf(wind), -0.12)
	dust.initial_velocity_min = 12.0 + level * 8.0
	dust.initial_velocity_max = 24.0 + level * 12.0
	dust_wait -= delta
	if dust_wait <= 0.0:
		dust.position.x = _visual_rng.randf_range(100, context.layout.bounds.size.x - 100)
		dust.position.y = context.layout.ground_top - _visual_rng.randf_range(22, 38)
		dust.restart()
		dust.emitting = true
		dust_wait = _visual_rng.randf_range(6.0, 11.0)
	if context.round_state.state == &"running":
		context.drift_crane(wind * CRANE_DRIFT * delta)
	for body in context.blown_bodies():
		if body.get("dimensions") == null:
			body.apply_central_force(Vector2(wind * HEAD_PUSH * body.mass, 0))
		elif body.get_contact_count() == 0:
			body.apply_central_force(Vector2(wind * body.dimensions.x * body.dimensions.y * SCRAP_PUSH, 0))
