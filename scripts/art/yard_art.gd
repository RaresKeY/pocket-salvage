extends RefCounted
## Where the yard's 8× Bitwright art lives and how it is drawn: one source pixel is `art_scale` world units.
const DIR := "res://assets/bitwright_8x/"
const FACTOR := 8.0
## The original 1x art, used where a texture has to be processed before enlarging.
const SOURCE_DIR := "res://assets/bitwright/"
static var _cut_skies: Dictionary = {}

static func path(name: String) -> String:
	return DIR + name + ".png"

static func exists(name: String) -> bool:
	return ResourceLoader.exists(path(name))

static func texture(name: String) -> Texture2D:
	return load(path(name))

## A texture's size in world units.
static func world_size(art: Texture2D, art_scale: float) -> Vector2:
	return art.get_size() / FACTOR * art_scale

## Scales a node so its 8× texture draws at `art_scale` world units per source pixel, smoothly sampled.
static func fit(node: Node2D, art_scale: float) -> Node2D:
	node.scale = Vector2.ONE * art_scale / FACTOR
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return node

## A skyline tile with its painted sky removed, so tiles drawn side by side share the yard's own sky.
## The sky is the flat bands that fill most of a row and are not the ground colour; silhouettes use other colours.
static func cut_sky(name: String) -> Texture2D:
	if _cut_skies.has(name): return _cut_skies[name]
	var image: Image = load(SOURCE_DIR + name + ".png").get_image()
	image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	var width := image.get_width()
	var ground: Color = _row_mode(image, image.get_height() - 1)[0]
	var bands := {}
	for y in image.get_height():
		var mode: Array = _row_mode(image, y)
		if mode[1] >= width * 0.4 and mode[0] != ground: bands[mode[0]] = true
	for y in image.get_height():
		for x in width:
			if bands.has(image.get_pixel(x, y)): image.set_pixel(x, y, Color(0, 0, 0, 0))
	image.resize(width * int(FACTOR), image.get_height() * int(FACTOR), Image.INTERPOLATE_NEAREST)
	var result := ImageTexture.create_from_image(image)
	result.resource_name = name
	_cut_skies[name] = result
	return result

## [most common colour in row y, how many pixels have it]
static func _row_mode(image: Image, y: int) -> Array:
	var counts := {}
	for x in image.get_width():
		var colour := image.get_pixel(x, y)
		counts[colour] = counts.get(colour, 0) + 1
	var best: Color
	var most := 0
	for colour in counts:
		if counts[colour] > most:
			best = colour
			most = counts[colour]
	return [best, most]

static func sprite(name: String, art_scale: float, at: Vector2 = Vector2.ZERO) -> Sprite2D:
	var result := Sprite2D.new()
	result.texture = texture(name)
	result.position = at
	fit(result, art_scale)
	return result
