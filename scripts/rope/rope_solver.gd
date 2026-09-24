extends RefCounted

# Adapted from White Approach; source snapshots live in vendored/rope_sources/.
var points := PackedVector2Array()
var old_points := PackedVector2Array()
var pins := PackedInt32Array()
var previous_bends := PackedVector2Array()
var render_previous := PackedVector2Array()
var path := preload("res://scripts/rope/rope_path.gd").new()
var sweep := Callable()

func ray(from: Vector2, to: Vector2) -> Dictionary:
	return sweep.call(from, to) if sweep.is_valid() else {}

func reset(from: Vector2, to: Vector2, length: float) -> void:
	path.bends.clear()
	seed_curve(from, to, maxf(length, from.distance_to(to)))
	render_previous = points.duplicate()

func constrain_tip(anchor: Vector2, tip: Vector2, velocity: Vector2, length: float) -> Dictionary:
	path.update(anchor, tip)
	var guides := path.guides(anchor, tip)
	var center := guides[-2]
	var fixed := path.length_between(anchor, tip) - center.distance_to(tip)
	var radius := maxf(2.0, length - fixed)
	var radial := tip - center
	if radial.length() > radius:
		var normal := radial.normalized()
		tip = center + normal * radius
		velocity -= normal * maxf(0.0, velocity.dot(normal))
	return {"position": tip, "velocity": velocity, "blocked": fixed + 2.0 > length}

func seed_curve(from: Vector2, to: Vector2, length: float, slack_direction := Vector2.DOWN) -> void:
	# Seed paid-out slack as a smooth arc, not compressed collinear segments
	# whose constraint corrections buckle into an accordion.
	const COUNT := 30
	var normal := (to-from).orthogonal().normalized()
	if normal.dot(slack_direction)<0: normal = -normal
	var low := 0.0
	var high := length
	for iteration in 12:
		var sag := (low+high)*0.5
		var arc_length := 0.0
		var previous := from
		for i in range(1,COUNT):
			var fraction := i/float(COUNT-1)
			var point := from.lerp(to,fraction)+normal*sin(PI*fraction)*sag
			arc_length += previous.distance_to(point)
			previous = point
		if arc_length<length: low = sag
		else: high = sag
	points.resize(COUNT)
	old_points.resize(COUNT)
	for i in COUNT:
		var fraction := i/float(COUNT-1)
		points[i] = from.lerp(to,fraction)+normal*sin(PI*fraction)*(low+high)*0.5
		old_points[i] = points[i]
	pins = PackedInt32Array([0,COUNT-1]) if path.bends.is_empty() else PackedInt32Array()
	previous_bends.clear()

func simulate(from: Vector2, to: Vector2, length: float, dt: float) -> void:
	if dt <= 0.0: return
	length = maxf(2.0, length)
	path.update(from,to)
	var guides := path.guides(from,to)
	var total := path.length_between(from,to)
	var topology_changed := pins.size()!=guides.size() or previous_bends!=path.bends or points.is_empty()
	if topology_changed:
		points.clear()
		pins.clear()
		points.append(from)
		pins.append(0)
		for span in guides.size()-1:
			var count := maxi(1,int(ceil(29*guides[span].distance_to(guides[span+1])/maxf(total,1))))
			for j in range(1,count+1):
				points.append(guides[span].lerp(guides[span+1],j/float(count)))
			pins.append(points.size()-1)
		old_points = points.duplicate()
		previous_bends = path.bends.duplicate()
	render_previous = points.duplicate()
	# Full extension is piecewise straight through every supporting corner.
	if total>=length-1.0:
		for span in guides.size()-1:
			for i in range(pins[span],pins[span+1]+1):
				points[i] = guides[span].lerp(guides[span+1],float(i-pins[span])/(pins[span+1]-pins[span]))
		old_points = points.duplicate()
		if topology_changed: render_previous = points.duplicate()
		return
	for span in guides.size()-1:
		var first := pins[span]
		var last := pins[span+1]
		var segment := guides[span].distance_to(guides[span+1])*maxf(1.0,length/maxf(total,1))/(last-first)
		points[first] = guides[span]
		points[last] = guides[span+1]
		for i in range(first+1,last):
			var current := points[i]
			var proposed := current+(current-old_points[i])*0.985+Vector2(0,600)*dt*dt
			old_points[i] = current
			points[i] = contact(current,proposed,i)
		for iteration in 8:
			for step_index in last-first:
				var i := first+step_index if iteration%2==0 else last-1-step_index
				var delta := points[i+1]-points[i]
				# Cable carries tension, never compression. Extra paid-out length
				# settles under gravity instead of pushing zigzags into the ground.
				if delta.length()<=segment: continue
				var correction := delta.normalized()*(delta.length()-segment)
				var weight_a := 0.0 if i==first else 1.0
				var weight_b := 0.0 if i+1==last else 1.0
				var weight := weight_a+weight_b
				if weight==0: continue
				if weight_a>0:
					points[i] = contact(points[i],points[i]+correction/weight,i)
				if weight_b>0:
					points[i+1] = contact(points[i+1],points[i+1]-correction/weight,i+1)
		# Catch link/edge intersections too, not just the particle sweeps.
		for i in range(first+1,last):
			var hit := ray(points[i-1],points[i])
			if not hit.is_empty():
				points[i] = hit.position+hit.normal*2
				old_points[i] = points[i]
	if topology_changed: render_previous = points.duplicate()

func contact(from: Vector2, to: Vector2, index: int) -> Vector2:
	if from.distance_squared_to(to)<0.000001: return to
	var hit := ray(from,to)
	if hit.is_empty(): return to
	var normal: Vector2 = hit.normal
	var resting: Vector2 = hit.position+normal*2
	# Remove inward velocity and damp sliding so slack cable rests on snow/rock.
	var motion := (resting-old_points[index]).slide(normal)*0.72
	old_points[index] = resting-motion
	return resting

