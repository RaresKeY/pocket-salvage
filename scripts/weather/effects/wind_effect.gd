extends "res://scripts/weather/weather_effect.gd"
## Pushes the head and airborne scrap sideways; the push grows with a piece's size, so light scrap drifts most.
const AREA_SCALE := 0.001
const HEAD_AREA := 52.0 * 20.0

func applies(profile) -> bool:
	return profile.wind != 0.0 or profile.gust != 0.0

func _physics_process(_delta: float) -> void:
	var wind: float = weather.wind_now()
	context.ambience.wind = wind
	var peak: float = absf(weather.profile.wind) + absf(weather.profile.gust)
	context.sfx.set_loop(&"wind_loop", absf(wind) / peak if peak > 0.0 else 0.0, 1.0, -12.0)
	for body in context.blown_bodies():
		var sized: bool = body.get("dimensions") != null
		if sized and body.get_contact_count() > 0: continue
		var area: float = body.dimensions.x * body.dimensions.y if sized else HEAD_AREA
		body.apply_central_force(Vector2(wind * area * AREA_SCALE * body.mass, 0))
