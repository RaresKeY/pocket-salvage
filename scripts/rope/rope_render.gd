extends RefCounted

# Adaptive midpoint curves and round fold joins from Plug & Prosper.
const INK := Color("101d24")
const CURVE_ERROR := 0.30
const MAX_STEPS := 6
const ROUND_JOIN_COS_SQUARED := 0.67

static func draw_jacket(points: PackedVector2Array, color: Color, canvas: CanvasItem) -> void:
	if points.size() < 2:
		return
	# A near-reversal can have zero radius even on a smooth spline. Split only
	# those joins and cap them, so polyline miters cannot grow triangular spikes.
	var folds: Array[int] = []
	for i in range(1, points.size() - 1):
		var incoming := points[i] - points[i - 1]
		var outgoing := points[i + 1] - points[i]
		var dot := incoming.dot(outgoing)
		if dot < 0.0 or dot * dot < ROUND_JOIN_COS_SQUARED * incoming.length_squared() * outgoing.length_squared():
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

static func curve(cable_points: PackedVector2Array) -> PackedVector2Array:
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
		var steps := clampi(ceili(sqrt(bend.length() * 0.25 / CURVE_ERROR)), 1, MAX_STEPS)
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
