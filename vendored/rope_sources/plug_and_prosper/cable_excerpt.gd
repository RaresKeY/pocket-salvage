# Original game/main.gd, lines 396-396
const CABLE_GRAVITY := 520.0

# Original game/main.gd, lines 437-441
const CABLE_CONSTRAINT_PASSES := 5
const CABLE_SEGMENT_LENGTH := 14.0
const CABLE_RENDER_CURVE_ERROR := 0.30
const CABLE_RENDER_MAX_STEPS := 6
const CABLE_RENDER_ROUND_JOIN_COS_SQUARED := 0.67 # Round turns above about 35°.

# Original game/main.gd, lines 9012-9028
func _reset_customer_cable(customer: Dictionary) -> void:
	var points: Array[Vector2] = []
	var previous: Array[Vector2] = []
	var anchor := _device_anchor(int(customer["slot"]))
	var plug_contact := _customer_initial_plug_contact(customer)
	var plug_anchor := _plug_cable_anchor_from_contact(plug_contact, String(customer["shape"]))
	var loop_radius := CABLE_SEGMENT_LENGTH / (2.0 * sin(PI / 24.0))
	for i in range(25):
		var ratio := float(i) / 24.0
		var p := anchor + Vector2(
			loop_radius * sin(TAU * ratio),
			loop_radius * (1.0 - cos(TAU * ratio))
		) + (plug_anchor - anchor) * ratio
		points.append(p)
		previous.append(p)
	customer["cable_points"] = points
	customer["cable_previous"] = previous

# Original game/main.gd, lines 9120-9163
func _simulate_cable(customer: Dictionary, delta: float) -> void:
	var cable_points: Array = customer["cable_points"]
	var cable_previous: Array = customer["cable_previous"]
	if cable_points.is_empty():
		return
	var anchor := _plug_device_anchor(customer)
	var cable_gravity := _customer_cable_gravity(customer)
	cable_points[0] = anchor
	for i in range(1, cable_points.size()):
		var current: Vector2 = cable_points[i]
		var velocity: Vector2 = (current - cable_previous[i]) * (0.88 if reduced_motion else 0.965)
		cable_previous[i] = current
		cable_points[i] += velocity + cable_gravity * delta * delta
	var shape: String = customer["shape"]
	var adapter_target := _customer_adapter_attachment_target(customer)
	if plug_drag_customer_id == int(customer["id"]):
		cable_points[-1] = _plug_cable_anchor_from_contact(_drag_position(pointer_pos), shape)
	elif customer["connected"]:
		cable_points[-1] = _plug_cable_anchor_from_contact(customer["connection_point"], shape)
	elif not adapter_target.is_empty():
		customer["connection_point"] = adapter_target["pos"]
		cable_points[-1] = _plug_cable_anchor_from_contact(adapter_target["pos"], shape)
	elif _customer_sticky_pad_valid(customer):
		cable_points[-1] = _plug_cable_anchor_from_contact(_customer_sticky_pad_position(customer), shape)
	for pass_index in range(CABLE_CONSTRAINT_PASSES):
		cable_points[0] = anchor
		for i in range(cable_points.size() - 1):
			var a: Vector2 = cable_points[i]
			var b: Vector2 = cable_points[i + 1]
			var diff: Vector2 = b - a
			var distance: float = maxf(0.001, diff.length())
			var correction: Vector2 = diff * ((distance - CABLE_SEGMENT_LENGTH) / distance)
			if i > 0:
				cable_points[i] += correction * 0.5
			cable_points[i + 1] -= correction * 0.5
		if plug_drag_customer_id == int(customer["id"]):
			cable_points[-1] = _plug_cable_anchor_from_contact(_drag_position(pointer_pos), shape)
		elif customer["connected"]:
			cable_points[-1] = _plug_cable_anchor_from_contact(customer["connection_point"], shape)
		elif not adapter_target.is_empty():
			cable_points[-1] = _plug_cable_anchor_from_contact(adapter_target["pos"], shape)
		elif _customer_sticky_pad_valid(customer):
			cable_points[-1] = _plug_cable_anchor_from_contact(_customer_sticky_pad_position(customer), shape)


# Original game/main.gd, lines 14390-14446
func _draw_cable_jacket(points: PackedVector2Array, color: Color, target: CanvasItem = null) -> void:
	var canvas := self if target == null else target
	if points.size() < 2:
		return
	# A near-reversal can have zero radius even on a smooth spline. Split only
	# those joins and cap them, so polyline miters cannot grow triangular spikes.
	var folds: Array[int] = []
	for i in range(1, points.size() - 1):
		var incoming := points[i] - points[i - 1]
		var outgoing := points[i + 1] - points[i]
		var dot := incoming.dot(outgoing)
		if dot < 0.0 or dot * dot < CABLE_RENDER_ROUND_JOIN_COS_SQUARED * incoming.length_squared() * outgoing.length_squared():
			folds.append(i)
	if folds.is_empty():
		canvas.draw_polyline(points, INK, 12.0, true)
		canvas.draw_polyline(points, color, 7.5, true)
		return
	var spans: Array[PackedVector2Array] = []
	var start := 0
	for fold in folds:
		spans.append(points.slice(start, fold + 1))
		start = fold
	spans.append(points.slice(start))
	for layer in range(2):
		var width := 12.0 if layer == 0 else 7.5
		var tint := INK if layer == 0 else color
		for span in spans:
			canvas.draw_polyline(span, tint, width, true)
		for fold in folds:
			canvas.draw_circle(points[fold], width * 0.5, tint, true, -1.0, true)

func _cable_render_polyline(cable_points: Array, _smooth_edges := true) -> PackedVector2Array:
	# Midpoint quadratics share tangent directions at every span boundary.
	# Keep the physical anchors exact; refine only curved spans, with an authored-space error bound.
	var points := PackedVector2Array(cable_points)
	if points.size() < 3:
		return points
	var result := PackedVector2Array([points[0]])
	var start := (points[0] + points[1]) * 0.5
	if result[-1].distance_squared_to(start) > 0.0001:
		result.append(start)
	for i in range(1, points.size() - 1):
		var control := points[i]
		var end := (control + points[i + 1]) * 0.5
		var bend := start - control * 2.0 + end
		# Maximum chord error of this quadratic is |bend| / (4 * steps²).
		var steps := clampi(ceili(sqrt(bend.length() * 0.25 / CABLE_RENDER_CURVE_ERROR)), 1, CABLE_RENDER_MAX_STEPS)
		var tangent := (control - start) * 2.0
		for step in range(1, steps + 1):
			var t := float(step) / steps
			var point := start + tangent * t + bend * t * t
			if result[-1].distance_squared_to(point) > 0.0001:
				result.append(point)
		start = end
	if result[-1] != points[-1]:
		result.append(points[-1])
	return result
