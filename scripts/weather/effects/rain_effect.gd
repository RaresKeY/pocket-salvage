extends "res://scripts/weather/weather_effect.gd"
## Visual rain angled by the wind, floor splashes, a wet sheen and the rain loop. Drops do not collide.
const FALL := 900.0
const Z := 5
const SOUND_TIERS := [&"rain_slight_loop", &"rain_loop", &"rain_violent_loop"]
const MIX_DB := [-22.0, -19.0, -16.0]

static func sound_tier(rate: float) -> int:
	return 0 if rate < 100.0 else (1 if rate < 200.0 else 2)

var streaks: CPUParticles2D
var _tier := 0
var _intensity := 1.0
var splashes: CPUParticles2D

func applies(profile) -> bool:
	return profile.rain > 0.0

func _start() -> void:
	var floor_y: float = context.layout.ground_top
	var width: float = context.layout.bounds.size.x
	streaks = _particles(int(weather.profile.rain * 0.6), Vector2(width * 0.5, -20), Vector2(width * 0.5, 4), Color(0.8, 0.86, 1.0, 0.7), 0.6, Z, YardArt.solid_texture(Vector2i(2, 16)))
	streaks.spread = 2
	streaks.initial_velocity_min = FALL
	streaks.initial_velocity_max = FALL * 1.1
	splashes = _particles(int(weather.profile.rain * 0.25), Vector2(width * 0.5, floor_y), Vector2(width * 0.5, 1), Color(0.8, 0.86, 1.0, 0.5), 0.25, Z, null)
	splashes.direction = Vector2.UP
	splashes.spread = 60
	splashes.gravity = Vector2(0, 400)
	splashes.initial_velocity_min = 30
	splashes.initial_velocity_max = 70
	_add(YardArt.overlay(Rect2(0, floor_y, width, 6), Color(0.55, 0.65, 0.9, 0.12)), 1)
	var tier := sound_tier(weather.profile.rain)
	loop_sound(SOUND_TIERS[tier], 1.0, MIX_DB[tier])
	_tier = tier

func rain_angle() -> float:
	return atan2(weather.wind_now() * 1.5, FALL)

func _process(_delta: float) -> void:
	if weather.intensity != _intensity:
		_intensity = weather.intensity
		for layer in [streaks, splashes]: layer.modulate.a = _intensity
		loop_sound(SOUND_TIERS[_tier], _intensity, MIX_DB[_tier])
	var angle := rain_angle()
	streaks.direction = Vector2(sin(angle), cos(angle))
	streaks.angle_min = -rad_to_deg(angle)
	streaks.angle_max = -rad_to_deg(angle)
