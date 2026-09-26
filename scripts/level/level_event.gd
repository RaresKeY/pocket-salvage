extends Node
## Something a level adds to the round (a generator cycle, a storm, blackouts). Listed by path in the level
## catalog's `events`; the round creates one per world build and calls configure(round, seed). Pauses with the world.
var context: Node
var rng := RandomNumberGenerator.new()

func configure(owner_context: Node, seed: int) -> void:
	context = owner_context
	rng.seed = seed
	_begin()

## Set up the first wait or phase; rng is seeded by now.
func _begin() -> void:
	pass

## A random value in `span` (x to y).
func roll(span: Vector2) -> float:
	return rng.randf_range(span.x, span.y)

func running() -> bool:
	return context.round_state.state == &"running"
