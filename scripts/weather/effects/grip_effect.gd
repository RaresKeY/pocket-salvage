extends "res://scripts/weather/weather_effect.gd"
## Wet scrap: scales each piece's own friction once, when the round's world is built.
func applies(profile) -> bool:
	return profile.grip != 1.0

func _start() -> void:
	for body in context.scrap_bodies():
		body.physics_material_override.friction *= weather.profile.grip
