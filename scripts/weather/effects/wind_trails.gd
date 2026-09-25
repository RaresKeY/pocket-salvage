extends Node2D
## Moving wind motes with short path-history tails. Cosmetic RNG never changes weather rolls.
const TRAIL_COUNT := 3
const TAIL_SECONDS := 1.2
const SAMPLE_SECONDS := 1.0 / 30.0
const MAX_POINTS := 40
const COLOR := Color(0.72, 0.82, 0.83)
var bounds := Rect2(0, 0, 1200, 440)
var direction := 1.0
var strength := 0.0
var trails: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()

func configure(area: Rect2) -> void:
	bounds = area
	_rng.seed = 90421
	trails.clear()
	for index in TRAIL_COUNT:
		trails.append(_make_trail(bounds.position.x + bounds.size.x * (index + 0.5) / TRAIL_COUNT))

func _make_trail(x: float) -> Dictionary:
	var trail := {"age": 0.0, "sample": 0.0, "x": x,
		"height": _rng.randf_range(65, minf(280, bounds.size.y * 0.65)),
		"bend": _rng.randf_range(10, 28), "frequency": _rng.randf_range(0.009, 0.018),
		"phase": _rng.randf() * TAU, "phase2": _rng.randf() * TAU,
		"speed": _rng.randf_range(0.8, 1.2), "radius": _rng.randf_range(1.5, 2.1), "points": []}
	trail.at = point_at(trail, x)
	trail.points.append({"at": trail.at, "time": 0.0})
	return trail

func point_at(trail: Dictionary, x: float) -> Vector2:
	var curve := sin(x * trail.frequency + trail.phase) + 0.35 * sin(x * trail.frequency * 0.43 + trail.phase2)
	return Vector2(x, bounds.position.y + trail.height + curve * trail.bend)

func _process(delta: float) -> void:
	for index in trails.size():
		var trail := trails[index]
		trail.age += delta
		trail.x += clampf(direction, -1, 1) * lerpf(110, 180, clampf(strength, 0, 1)) * trail.speed * delta
		if trail.x < bounds.position.x - 80 or trail.x > bounds.end.x + 80:
			trails[index] = _make_trail(bounds.end.x + 60 if direction < 0 else bounds.position.x - 60)
			continue
		trail.at = point_at(trail, trail.x)
		trail.sample += delta
		if trail.sample >= SAMPLE_SECONDS:
			trail.sample = fmod(trail.sample, SAMPLE_SECONDS)
			trail.points.append({"at": trail.at, "time": trail.age})
		while not trail.points.is_empty() and (trail.age - trail.points[0].time > TAIL_SECONDS or trail.points.size() > MAX_POINTS):
			trail.points.pop_front()
	queue_redraw()

func edge_alpha(x: float) -> float:
	return clampf(minf(x - bounds.position.x, bounds.end.x - x) / 80.0, 0.0, 1.0)

func tail_alpha(age: float) -> float:
	return pow(clampf(1.0 - age / TAIL_SECONDS, 0, 1), 2)

func _draw() -> void:
	for trail in trails:
		var points := PackedVector2Array()
		var colors := PackedColorArray()
		var opacity := lerpf(0.24, 0.42, clampf(strength, 0, 1))
		for sample in trail.points:
			points.append(sample.at)
			colors.append(Color(COLOR, tail_alpha(trail.age - sample.time) * edge_alpha(sample.at.x) * opacity))
		points.append(trail.at)
		colors.append(Color(COLOR, edge_alpha(trail.at.x) * opacity))
		if points.size() > 1: draw_polyline_colors(points, colors, 1.3, true)
		draw_circle(trail.at, trail.radius, Color(COLOR, edge_alpha(trail.at.x) * 0.7), true, -1, true)
