extends Node2D
## Pure presentation; the integrating caller supplies every collision object.
const Layout = preload("res://scripts/level/yard_layout.gd")
const FLOOR = preload("res://assets/bitwright_8x/ground_dirt_tile.png")
const RAIL = preload("res://assets/bitwright_8x/crane_rail_tile.png")
var layout: Dictionary = Layout.create_layout()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func configure(value: Dictionary) -> void:
	layout = value.duplicate(true)
	queue_redraw()

func _draw() -> void:
	var bounds: Rect2 = layout.bounds
	var floor_y: float = layout.ground_top
	draw_rect(bounds, Color("263844"))
	for x in range(0, int(bounds.size.x), 80):
		draw_line(Vector2(x, 100), Vector2(x, floor_y), Color("304650"), 1)
	for x in range(0, int(bounds.size.x), 40):
		draw_texture_rect(FLOOR, Rect2(x, floor_y, 40, bounds.end.y - floor_y), false)
		draw_texture_rect(RAIL, Rect2(x, 24, 40, 16), false)
	draw_line(Vector2(0, floor_y), Vector2(bounds.end.x, floor_y), Color("b7a477"), 2)
