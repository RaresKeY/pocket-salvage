extends RefCounted
## Where the yard's 8× Bitwright art lives and how it is drawn: one source pixel is `art_scale` world units.
const DIR := "res://assets/bitwright_8x/"
const FACTOR := 8.0

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

static func sprite(name: String, art_scale: float, at: Vector2 = Vector2.ZERO) -> Sprite2D:
	var result := Sprite2D.new()
	result.texture = texture(name)
	result.position = at
	fit(result, art_scale)
	return result
