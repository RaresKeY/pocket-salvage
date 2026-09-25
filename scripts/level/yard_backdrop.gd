extends Node2D
## Pure presentation; the integrating caller supplies every collision object.
const Layout = preload("res://scripts/level/yard_layout.gd")
const FLOOR = preload("res://assets/bitwright_8x/ground_dirt_tile.png")
const RAIL = preload("res://assets/bitwright_8x/crane_rail_tile.png")
const FENCE = preload("res://assets/bitwright_8x/backdrop_scrapyard_tile.png")
const TOWER = preload("res://assets/bitwright_8x/crane_tower.png")
const SKY := Color("2e283e")
const TOWER_CAP := 4
const TOWER_PERIOD := 4
const TOWER_FOOT := 16
var layout: Dictionary = Layout.create_layout()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func configure(value: Dictionary) -> void:
	layout = value.duplicate(true)
	queue_redraw()

func _draw() -> void:
	var bounds: Rect2 = layout.bounds
	var floor_y: float = layout.ground_top
	var art_scale: float = layout.art_scale
	draw_rect(bounds, SKY)
	var fence_height := FENCE.get_height() / 8.0 * art_scale
	_tile_row(FENCE, Rect2(bounds.position.x, floor_y - fence_height, bounds.size.x, fence_height))
	var tower_width := TOWER.get_width() / 8.0 * art_scale
	for x in [bounds.position.x, bounds.end.x - tower_width]:
		_tower(Rect2(x, 40, tower_width, floor_y - 40), art_scale)
	for x in range(0, int(bounds.size.x), 40):
		draw_texture_rect(FLOOR, Rect2(x, floor_y, 40, bounds.end.y - floor_y), false)
		draw_texture_rect(RAIL, Rect2(x, 24, 40, 16), false)
	draw_line(Vector2(0, floor_y), Vector2(bounds.end.x, floor_y), Color("b7a477"), 2)

func _tile_row(texture: Texture2D, area: Rect2) -> void:
	var tile_width := area.size.y * texture.get_width() / texture.get_height()
	var x := area.position.x
	while x < area.end.x:
		var width := minf(tile_width, area.end.x - x)
		draw_texture_rect_region(texture, Rect2(x, area.position.y, width, area.size.y),
			Rect2(0, 0, texture.get_width() * width / tile_width, texture.get_height()))
		x += tile_width

## Stretches the lattice by repeating one period between the cap and the foot.
func _tower(area: Rect2, art_scale: float) -> void:
	var rows := TOWER.get_height() / 8
	var cap := TOWER_CAP * art_scale
	var foot := TOWER_FOOT * art_scale
	_tower_slice(Rect2(area.position.x, area.position.y, area.size.x, cap), 0, TOWER_CAP)
	var y := area.position.y + cap
	var period := TOWER_PERIOD * art_scale
	while y < area.end.y - foot:
		var height := minf(period, area.end.y - foot - y)
		_tower_slice(Rect2(area.position.x, y, area.size.x, height), TOWER_CAP, TOWER_PERIOD * height / period)
		y += period
	_tower_slice(Rect2(area.position.x, area.end.y - foot, area.size.x, foot), rows - TOWER_FOOT, TOWER_FOOT)

func _tower_slice(area: Rect2, source_row: float, source_rows: float) -> void:
	draw_texture_rect_region(TOWER, area, Rect2(0, source_row * 8, TOWER.get_width(), source_rows * 8))
