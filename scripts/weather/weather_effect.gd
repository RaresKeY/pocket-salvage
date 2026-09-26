extends "res://scripts/audio/sound_loops.gd"
## One weather effect. Reads only the profile fields it needs; `applies` decides whether it is created at all.
const YardArt = preload("res://scripts/art/yard_art.gd")
var weather: Node
var context: Node

func applies(_profile) -> bool:
	return false

func bind(owner_weather: Node, owner_context: Node) -> void:
	weather = owner_weather
	context = owner_context
	sfx = context.sfx
	_start()

func _start() -> void:
	pass

## Adds `node` to the round's world at depth `z`, tinted with the weather's colour.
func _add(node: CanvasItem, z: int) -> CanvasItem:
	node.z_index = z
	node.modulate = weather.profile.tint
	context.world.add_child(node)
	return node

## A particle layer emitting from a rectangle, with no gravity, added to the world.
func _particles(amount: int, at: Vector2, extents: Vector2, color: Color, life: float, z: int, texture: Texture2D) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.amount = maxi(amount, 1)
	particles.lifetime = life
	particles.position = at
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = extents
	particles.color = color
	particles.gravity = Vector2.ZERO
	particles.texture = texture
	return _add(particles, z)
