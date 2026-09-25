extends "res://scripts/weather/weather_effect.gd"
## Rumble, then a flash and a bolt, then the round loses power for a moment.
const FLASH := 0.7
const BOLT_BOTTOM := 300.0
var flash: ColorRect

func applies(profile) -> bool:
	return profile.lightning_every != Vector2.ZERO

func _start() -> void:
	flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.modulate = weather.profile.tint
	flash.size = context.layout.bounds.size
	flash.z_index = 20
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	context.world.add_child(flash)
	weather.lightning_warning.connect(func(): context.sfx.play(&"thunder", -14.0))
	weather.lightning.connect(strike)
	weather.power_cut.connect(context.power_cut)

func strike(x: float) -> void:
	context.sfx.play(&"thunder", -4.0)
	flash.color.a = FLASH
	flash.create_tween().tween_property(flash, "color:a", 0.0, 0.35)
	var bolt := Line2D.new()
	bolt.width = 3
	bolt.modulate = weather.profile.tint
	bolt.default_color = Color(0.9, 0.95, 1.0)
	bolt.z_index = 19
	var point := Vector2(x, 0)
	while point.y < BOLT_BOTTOM:
		bolt.add_point(point)
		point += Vector2(weather.rng.randf_range(-22, 22), weather.rng.randf_range(30, 55))
	context.world.add_child(bolt)
	bolt.create_tween().tween_property(bolt, "modulate:a", 0.0, 0.3).finished.connect(bolt.queue_free)
