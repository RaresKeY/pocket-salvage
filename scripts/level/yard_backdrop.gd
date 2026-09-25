extends Node2D
## Pure presentation; the integrating caller supplies every collision object.
const Layout = preload("res://scripts/level/yard_layout.gd")
const YardArt = preload("res://scripts/art/yard_art.gd")
const FLOOR = preload("res://assets/bitwright_8x/ground_dirt_tile.png")
const RAIL = preload("res://assets/bitwright_8x/crane_rail_tile.png")
const FENCE = preload("res://assets/bitwright_8x/backdrop_scrapyard_tile.png")
const TOWER = preload("res://assets/bitwright_8x/crane_tower.png")
const HEAP_SPOTS := [0.9]
const HEAP_TINT := Color(0.55, 0.52, 0.66)
## The fence tile's top rows are opaque sky; the skyline stands on them.
const FENCE_SKY_ROWS := 10
const SKY := Color("2e283e")
const TOWER_CAP := 4
const TOWER_PERIOD := 4
const TOWER_FOOT := 16
const SKYLINE := "backdrop_skyline_tile"
const SKYLINE_VARIANTS := ["", "_b", "_c"]
## Fixed so the skyline looks the same every round.
const SKYLINE_SEED := 11
var layout: Dictionary = Layout.create_layout()
## Off when a caller layers its own animated sky behind this node.
var draw_sky := true
## Held here, not loaded inside _draw: a texture freed after _draw returns renders white.
## Skyline tiles mixed along the horizon; levels may swap in their own set with `skyline_set`.
var skylines: Array[Texture2D] = skyline_set(SKYLINE)
var heap: Texture2D = YardArt.texture("backdrop_junk_heap") if YardArt.exists("backdrop_junk_heap") else null

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func configure(value: Dictionary) -> void:
	layout = value.duplicate(true)
	queue_redraw()

func _draw() -> void:
	var bounds: Rect2 = layout.bounds
	var floor_y: float = layout.ground_top
	var art_scale: float = layout.art_scale
	if draw_sky: draw_rect(bounds, SKY)
	var fence_height := YardArt.world_size(FENCE, art_scale).y
	_tile_row(FENCE, Rect2(bounds.position.x, floor_y - fence_height, bounds.size.x, fence_height))
	if not skylines.is_empty():
		var skyline_height := YardArt.world_size(skylines[0], art_scale).y
		var horizon := floor_y - fence_height + FENCE_SKY_ROWS * art_scale
		_skyline_row(Rect2(bounds.position.x, horizon - skyline_height, bounds.size.x, skyline_height))
	if heap:
		var heap_size := YardArt.world_size(heap, art_scale)
		for spot in HEAP_SPOTS:
			draw_texture_rect(heap, Rect2(Vector2(bounds.size.x * spot - heap_size.x * 0.5, floor_y - heap_size.y), heap_size), false, HEAP_TINT)
	var tower_width := YardArt.world_size(TOWER, art_scale).x
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

## Every variant of a skyline that exists on disk (`name`, `name_b`, `name_c`), sky cut out.
static func skyline_set(name: String) -> Array[Texture2D]:
	var found: Array[Texture2D] = []
	for suffix in SKYLINE_VARIANTS:
		if YardArt.exists(name + suffix): found.append(YardArt.cut_sky(name + suffix))
	return found

## Lays tiles of the given widths across `span`: a seeded shuffle that never repeats a design twice in a row,
## each tile mirrored at random. One design alone just alternates its facing.
static func skyline_plan(widths: Array, span: float, seed: int) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var plan: Array[Dictionary] = []
	var x := 0.0
	var previous := -1
	while x < span:
		var index := 0
		if widths.size() > 1:
			index = rng.randi_range(0, widths.size() - 2)
			if index >= previous and previous >= 0: index += 1
		var flip: bool = rng.randf() < 0.5 if widths.size() > 1 else plan.size() % 2 == 1
		plan.append({"index": index, "flip": flip, "x": x, "width": minf(widths[index], span - x)})
		x += widths[index]
		previous = index
	return plan

func _skyline_row(area: Rect2) -> void:
	var widths := skylines.map(func(tile): return area.size.y * tile.get_width() / tile.get_height())
	for piece in skyline_plan(widths, area.size.x, SKYLINE_SEED):
		var tile: Texture2D = skylines[piece.index]
		var source_width: float = tile.get_width() * piece.width / widths[piece.index]
		var target := Rect2(area.position.x + piece.x, area.position.y, piece.width, area.size.y)
		if piece.flip: target = Rect2(target.end.x, target.position.y, -target.size.x, target.size.y)
		draw_texture_rect_region(tile, target, Rect2(0, 0, source_width, tile.get_height()))

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
