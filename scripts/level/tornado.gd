extends Node2D
## A twister: a dust swirl warns at one end of the pile area, then the funnel crosses it at a readable pace,
## lifting and spinning light scrap (heavy scrap stays down) and shoving the crane head. It breaks up at the
## bins' edge and drops what it carries, so scrap stays in play and never lands in a bin.
enum State { WARNING, CROSSING, GONE }
const SoundLoops = preload("res://scripts/audio/sound_loops.gd")
const HUM := &"twister_loop"
const HUM_DB := -10.0
const WARNING := 3.0
const SPEED := 90.0
const RADIUS := 70.0
## Scrap at or under this mass is lifted; heavier scrap only feels the wind.
const LIFT_MASS := 1.0
## Carried scrap circles about this high above the ground.
const LIFT_HEIGHT := 140.0
const SPIN := 900.0
const HEAD_SHOVE := 260.0
## How firmly carried scrap follows its path; higher is snappier.
const FOLLOW := 5.0
const EDGE := 110.0
## Drawn in code so it can snake and spin. The warning is the same twister as a low dust ring; it rises to
## full height when it starts to cross. RADIUS matches the funnel's half width.
const HEIGHT := 300.0
const WARNING_HEIGHT := 50.0
const TOP_WIDTH := 150.0
const TIP_WIDTH := 14.0
const RINGS := 36
const STREAKS := 7
const SWAY := 22.0
const RISE := 0.8
const PIXEL := 2.0
const DUST := [Color("8c7a66"), Color("a89682"), Color("6f6152"), Color("c2b4a2")]
const DEBRIS := 12
var context: Node
var state := State.WARNING
var age := 0.0
var direction := 1.0
var end_x := 0.0
## Body -> true for the scrap it is carrying now.
var carried: Dictionary = {}
var height := 0.0
var _crossing_age := 0.0
var sounds := SoundLoops.new()

func configure(owner_context: Node, from_left: bool) -> void:
	context = owner_context
	var bin: Dictionary = context.layout.bins[0]
	var start := [EDGE, bin.position.x - bin.size.x * 0.5 - EDGE]
	if not from_left: start.reverse()
	direction = signf(start[1] - start[0])
	end_x = start[1]
	position = Vector2(start[0], context.layout.ground_top)
	z_index = 3
	sounds.sfx = context.sfx
	add_child(sounds)
	_hum(0.4)

func _process(_delta: float) -> void:
	queue_redraw()

func _physics_process(delta: float) -> void:
	age += delta
	match state:
		State.WARNING:
			height = WARNING_HEIGHT * minf(age / WARNING, 1.0)
			if age >= WARNING:
				state = State.CROSSING
				_hum(1.0)
		State.CROSSING:
			_crossing_age += delta
			height = lerpf(WARNING_HEIGHT, HEIGHT, smoothstep(0.0, RISE, _crossing_age))
			position.x = move_toward(position.x, end_x, SPEED * delta)
			if position.x == end_x: _break_up()
			else: _apply_forces()

## 0 at the ground, 1 at the top of a full-height funnel.
func _width_at(rise: float) -> float:
	return lerpf(TIP_WIDTH, TOP_WIDTH, pow(rise, 1.4))

## The funnel snakes: its middle and top swing further than its tip.
func _centre_at(rise: float) -> float:
	return sin(age * 2.1 + rise * 4.0) * SWAY * rise + sin(age * 5.3 + rise * 9.0) * 3.0

func _snap(point: Vector2) -> Vector2:
	return (point / PIXEL).floor() * PIXEL

## Rings of short dust streaks going round the funnel; the back half is dimmer, so it reads as turning.
func _draw() -> void:
	if height <= 0.0: return
	for ring in RINGS:
		var y := height * ring / (RINGS - 1.0)
		var rise := y / HEIGHT
		var half := _width_at(rise) * 0.5
		if state == State.WARNING: half = lerpf(24.0, 56.0, y / WARNING_HEIGHT)
		var centre := _centre_at(rise)
		for streak in STREAKS:
			var angle := age * (7.0 - rise * 3.0) * -direction + TAU * streak / STREAKS + ring * 0.9
			var depth := sin(angle)
			var colour: Color = DUST[(ring + streak) % DUST.size()]
			colour.a = lerpf(0.4, 1.0, (depth + 1.0) * 0.5)
			var from := _snap(Vector2(centre + cos(angle) * half, -y + depth * 3.0))
			var to := _snap(Vector2(centre + cos(angle + 0.5) * half, -y + sin(angle + 0.5) * 3.0))
			draw_line(from, to, colour, PIXEL * (1.5 if depth > 0.0 else 1.0))
	for bit in DEBRIS:
		var rise := fmod(bit * 0.37 + age * 0.15, 1.0) * height / HEIGHT
		var angle := age * 5.0 * -direction + bit * 2.4
		var at := _snap(Vector2(_centre_at(rise) + cos(angle) * _width_at(rise) * 0.6, -rise * HEIGHT))
		draw_rect(Rect2(at, Vector2.ONE * PIXEL * (1 + bit % 2)), Color(DUST[bit % DUST.size()], 0.9 if sin(angle) > 0.0 else 0.4))

func _apply_forces() -> void:
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
	for body in context.blown_bodies():
		var offset: float = body.global_position.x - position.x
		if absf(offset) > RADIUS:
			carried.erase(body)
			continue
		if body == context.tip:
			body.apply_central_force(Vector2(direction * HEAD_SHOVE * body.mass, 0))
			continue
		if body.mass > LIFT_MASS: continue
		carried[body] = true
		var height: float = context.layout.ground_top - LIFT_HEIGHT + sin(age * 3.0 + body.item_id) * 30.0
		var want := Vector2(direction * SPEED - offset * 2.0, clampf((height - body.global_position.y) * 2.0, -160.0, 160.0))
		var push: Vector2 = (want - body.linear_velocity) * FOLLOW - Vector2(0, gravity * body.gravity_scale)
		body.apply_central_force(push * body.mass)
		body.apply_torque(direction * SPIN * body.mass)

func _hum(level: float) -> void:
	sounds.loop_sound(HUM, level, HUM_DB)

func _break_up() -> void:
	state = State.GONE
	carried.clear()
	_hum(0.0)
	create_tween().tween_property(self, "modulate:a", 0.0, 1.0).finished.connect(queue_free)
