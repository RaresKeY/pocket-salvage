extends RefCounted
## Where the yard's 8× Bitwright art lives and how it is drawn: one source pixel is `art_scale` world units.
const DIR := "res://assets/bitwright_8x/"
const FACTOR := 8.0
## The original 1x art, used where a texture has to be processed before enlarging.
const SOURCE_DIR := "res://assets/bitwright/"
static var _matched_skies: Dictionary = {}

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

## A skyline tile repainted to share `base`'s sky and ground, row for row, so tiles drawn side by side join
## without seams while keeping their painted sky. The sky palette comes from `base` alone: its row colours from
## the top, each lighter than the last, until a darker (silhouette) colour takes over a row. Silhouette colours
## in other tiles are never touched, even when one happens to fill a row.
static func match_sky(name: String, base: String) -> Texture2D:
	var key := name + ">" + base
	if _matched_skies.has(key): return _matched_skies[key]
	var image := _source_image(name)
	if name != base:
		var reference := _source_image(base)
		var palette := _sky_palette(reference)
		var from := _sky_rows(image, palette)
		var to := _sky_rows(reference, palette)
		var ground_from: Color = _row_mode(image, image.get_height() - 1)[0]
		var ground_to: Color = _row_mode(reference, reference.get_height() - 1)[0]
		for y in image.get_height():
			var row := mini(y, to.size() - 1)
			for x in image.get_width():
				var colour := image.get_pixel(x, y)
				if colour == from[y]: image.set_pixel(x, y, to[row])
				elif colour == ground_from and not palette.has(colour): image.set_pixel(x, y, ground_to)
	image.resize(image.get_width() * int(FACTOR), image.get_height() * int(FACTOR), Image.INTERPOLATE_NEAREST)
	var result := ImageTexture.create_from_image(image)
	result.resource_name = name
	_matched_skies[key] = result
	return result

static func _source_image(name: String) -> Image:
	var image: Image = load(SOURCE_DIR + name + ".png").get_image()
	image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	return image

## The sky's band colours, read down from the top of a known-good tile.
static func _sky_palette(image: Image) -> Dictionary:
	var palette := {}
	var previous := -1.0
	for y in image.get_height():
		var mode: Array = _row_mode(image, y)
		if mode[1] < image.get_width() * 0.4: continue
		var light: float = mode[0].get_luminance()
		if light < previous: break
		palette[mode[0]] = true
		previous = light
	return palette

## The sky colour of each row: whichever palette colour it shows most, or the band above when none shows.
static func _sky_rows(image: Image, palette: Dictionary) -> Array[Color]:
	var rows: Array[Color] = []
	var current: Color = palette.keys()[0]
	for y in image.get_height():
		var counts := {}
		for x in image.get_width():
			var colour := image.get_pixel(x, y)
			if palette.has(colour): counts[colour] = counts.get(colour, 0) + 1
		var most := 0
		for colour in counts:
			if counts[colour] > most:
				current = colour
				most = counts[colour]
		rows.append(current)
	return rows

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
