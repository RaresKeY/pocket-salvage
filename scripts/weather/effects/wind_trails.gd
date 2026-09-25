extends Node2D
## A few drifting, gently bent ribbons. Entirely cosmetic; never consumes weather RNG.
const SEGMENTS := 32
const TRAIL_COUNT := 3
var bounds := Rect2(0, 0, 1200, 440)
var direction := 1.0
var strength := 0.0
var trails: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()

func configure(area: Rect2) -> void:
	bounds = area
	_rng.seed = 90421
	for index in TRAIL_COUNT:
		var trail := _make_trail()
		trail.age = float(index) * 2.0
		trails.append(trail)

func _make_trail() -> Dictionary:
	return {"age": 0.0, "duration": _rng.randf_range(6.5, 9.0), "height": _rng.randf_range(60, minf(290, bounds.size.y * 0.68)), "bend": _rng.randf_range(9, 22), "length": _rng.randf_range(140, 220), "phase": _rng.randf_range(-0.4, 0.4)}

func _process(delta: float) -> void:
	for index in trails.size():
		trails[index].age += delta
		if trails[index].age > trails[index].duration + 1.8:
			trails[index] = _make_trail()
	queue_redraw()

func edge_alpha(x: float) -> float:
	return clampf(minf(x - bounds.position.x, bounds.end.x - x) / 80.0, 0.0, 1.0)

func _draw() -> void:
	for trail in trails:
		var t: float = trail.age / trail.duration
		if t > 1.0: continue
		var travel: float = lerpf(-trail.length, bounds.size.x + trail.length, t)
		var fade := smoothstep(0.0, 0.12, t) * (1.0 - smoothstep(0.85, 1.0, t))
		var points := PackedVector2Array()
		var colors := PackedColorArray()
		for index in SEGMENTS + 1:
			var u := float(index) / SEGMENTS
			var x: float = travel - trail.length * (1.0 - u)
			if direction < 0: x = bounds.size.x - x
			x += bounds.position.x
			var y: float = bounds.position.y + trail.height + sin(u * TAU + trail.phase) * sin(u * PI) * trail.bend
			points.append(Vector2(x, y))
			var alpha: float = sin(u * PI) * fade * edge_alpha(x) * lerpf(0.12, 0.28, strength)
			colors.append(Color(0.72, 0.82, 0.83, alpha))
		draw_polyline_colors(points, colors, 1.6, true)
