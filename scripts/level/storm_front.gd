extends Node
## Level 5's storm cycle: calm, building, storm, clearing, round again. Drives the weather's intensity and the
## sky's gloom, warns as each phase starts and sends one twister across at each storm's peak. Runs only while the
## round is running and pauses with the world.
const Tornado = preload("res://scripts/level/tornado.gd")
const CALM_INTENSITY := 0.12
## Phase -> seconds range.
## The round opens with a short calm so the first storm arrives early.
const FIRST_CALM := Vector2(10, 15)
const PHASES := {&"calm": Vector2(30, 40), &"building": Vector2(15, 15), &"storm": Vector2(30, 40), &"clearing": Vector2(10, 10)}
const NEXT := {&"calm": &"building", &"building": &"storm", &"storm": &"clearing", &"clearing": &"calm"}
const WARNINGS := {&"building": "Storm building. Get the light scrap in.", &"storm": "Storm! Lightning flips the magnet.", &"clearing": "The storm is passing."}
## The twister comes this long into the storm, leaving time for it to cross before the storm clears.
const TORNADO_AFTER := Vector2(3, 6)
var context: Node
var rng := RandomNumberGenerator.new()
var phase := &"calm"
var length := 0.0
var left := 0.0
var tornado_in := INF

func configure(owner_context: Node, seed: int) -> void:
	context = owner_context
	rng.seed = seed
	_enter(&"calm", FIRST_CALM)
	_apply()

func _enter(next: StringName, span: Vector2 = PHASES[next]) -> void:
	phase = next
	length = rng.randf_range(span.x, span.y)
	left = length
	tornado_in = rng.randf_range(TORNADO_AFTER.x, TORNADO_AFTER.y) if next == &"storm" else INF
	if WARNINGS.has(next): context._say(WARNINGS[next], 4.0)
	if next == &"building": context.sfx.play(&"thunder", -18.0)

## How far through the current phase, 0 to 1.
func progress() -> float:
	return 1.0 - left / length if length > 0.0 else 1.0

func intensity() -> float:
	match phase:
		&"building": return lerpf(CALM_INTENSITY, 1.0, smoothstep(0.0, 1.0, progress()))
		&"storm": return 1.0
		&"clearing": return lerpf(1.0, CALM_INTENSITY, smoothstep(0.0, 1.0, progress()))
	return CALM_INTENSITY

func _physics_process(delta: float) -> void:
	if context.round_state.state != &"running": return
	tornado_in -= delta
	if tornado_in <= 0.0:
		tornado_in = INF
		var twister := Tornado.new()
		context.world.add_child(twister)
		twister.configure(context, rng.randf() < 0.5)
		context._say("Twister! It carries off light scrap.", 3.0)
	left -= delta
	if left <= 0.0: _enter(NEXT[phase])
	_apply()

func _apply() -> void:
	var level := intensity()
	context.weather.intensity = level
	context.ambience.gloom = inverse_lerp(CALM_INTENSITY, 1.0, level)
