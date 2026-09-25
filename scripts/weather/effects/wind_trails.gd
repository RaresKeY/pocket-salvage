extends Node2D
## Faint tapered wind ribbons with flat vertical fronts and long path-history tails. Cosmetic RNG never changes weather rolls.
const TRAIL_COUNT := 3
const TAIL_SECONDS := 4.5
const SAMPLE_SECONDS := 1.0 / 30.0
const MAX_POINTS := 144
const MIN_OPACITY := 0.055
const MAX_OPACITY := 0.12
const FEATHER := 0.7
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
		"speed": _rng.randf_range(0.8, 1.2), "head_width": _rng.randf_range(4.0, 5.5), "points": [], "mesh": ArrayMesh.new()}
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

func tail_width(age: float, head_width: float) -> float:
	return head_width * pow(clampf(1.0 - age / TAIL_SECONDS, 0, 1), 0.8)

func opacity() -> float:
	return lerpf(MIN_OPACITY, MAX_OPACITY, clampf(strength, 0, 1))

func ribbon_arrays(trail: Dictionary) -> Array:
	# Vertical cross-sections give the head and attached trail exactly the same width.
	# Indexed triangles also remain valid when Blood Moon reverses over old history.
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var samples: Array = trail.points.duplicate()
	samples.append({"at": trail.at, "time": trail.age})
	for sample in samples:
		var age: float = trail.age - sample.time
		var half_width := tail_width(age, trail.head_width) * 0.5
		var alpha := tail_alpha(age) * edge_alpha(sample.at.x) * edge_alpha(trail.at.x) * opacity()
		for offset in [-half_width - FEATHER, -half_width, half_width, half_width + FEATHER]:
			vertices.append(Vector3(sample.at.x, sample.at.y + offset, 0))
		colors.append(Color(COLOR, 0))
		colors.append(Color(COLOR, alpha))
		colors.append(Color(COLOR, alpha))
		colors.append(Color(COLOR, 0))
	for i in range(samples.size() - 1):
		for band in 3:
			var start := i * 4 + band
			indices.append_array(PackedInt32Array([start, start + 1, start + 4, start + 1, start + 5, start + 4]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	return arrays

func _draw() -> void:
	for trail in trails:
		var mesh: ArrayMesh = trail.mesh
		mesh.clear_surfaces()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, ribbon_arrays(trail))
		draw_mesh(mesh, null)
		# The old bright dot is now the ribbon's thin vertical leading edge.
		var half_head := Vector2(0, trail.head_width * 0.5)
		draw_line(trail.at - half_head, trail.at + half_head, Color(COLOR, edge_alpha(trail.at.x) * opacity() * 0.5), 0.8, true)
