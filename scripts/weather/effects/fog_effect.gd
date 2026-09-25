extends "res://scripts/weather/weather_effect.gd"
## Visual only: haze thickens with distance from the crane and bin labels dim, so bins are read by colour.
const CLEAR_RADIUS := 150.0
const FULL_AT := 650.0
const COLUMNS := 48
const HAZE := Color(0.62, 0.64, 0.72)
const LABEL_DIM := 0.6
var layer: Node2D

func applies(profile) -> bool:
	return profile.fog > 0.0

func _start() -> void:
	layer = Node2D.new()
	layer.z_index = 6
	layer.modulate = weather.profile.tint
	layer.draw.connect(_draw_fog)
	context.world.add_child(layer)
	for label in context.bin_labels: label.modulate.a = 1.0 - weather.profile.fog * LABEL_DIM

func density_at(x: float) -> float:
	var distance := absf(x - context.trolley.position.x)
	return weather.profile.fog * clampf((distance - CLEAR_RADIUS) / (FULL_AT - CLEAR_RADIUS), 0.0, 1.0)

func _process(_delta: float) -> void:
	layer.queue_redraw()

## One strip of quads with per-vertex alpha, so the haze is a smooth gradient with no overlapping seams.
func _draw_fog() -> void:
	var bounds: Rect2 = context.layout.bounds
	var step := bounds.size.x / COLUMNS
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	for column in COLUMNS + 1:
		var x := column * step
		var shade := Color(HAZE, density_at(x) * 0.85)
		points.append_array([Vector2(x, 0), Vector2(x, bounds.size.y)])
		colors.append_array([shade, shade])
	for column in COLUMNS:
		var i := column * 2
		layer.draw_polygon(PackedVector2Array([points[i], points[i + 2], points[i + 3], points[i + 1]]), PackedColorArray([colors[i], colors[i + 2], colors[i + 3], colors[i + 1]]))
