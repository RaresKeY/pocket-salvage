class_name ThrownRope
extends RefCounted

signal rejected(point: Vector2)

const GRAVITY := Vector2(0,1050)
const MAX_LENGTH := 760.0
var flying := false
var tip := Vector2.ZERO
var velocity := Vector2.ZERO
var age := 0.0
var impact := 0.0
var points := PackedVector2Array()
var old_points := PackedVector2Array()
var path := preload("res://scripts/rope_path.gd").new()
var terrain_cache: Dictionary = {}
var pins := PackedInt32Array()
var previous_bends := PackedVector2Array()
var render_previous := PackedVector2Array()
var paid_length := 0.0
var previous_tip := Vector2.ZERO
var reject_hook := Callable()
var hook_barrier := Callable()
var rejection_cooldown := 0.0

func configure_terrain(chapter: int, strips: Array, spikes: Array) -> void:
	if not terrain_cache.has(chapter):
		var prepared := preload("res://scripts/rope_path.gd").new()
		prepared.build(strips,spikes)
		terrain_cache[chapter] = prepared
	path = terrain_cache[chapter]
	path.bends.clear()

func launch_velocity(from: Vector2, target: Vector2) -> Vector2:
	var duration := clampf(from.distance_to(target)/550.0,0.22,0.90)
	return ((target-from)/duration-GRAVITY*duration*0.5).limit_length(1000)

func throw_from(from: Vector2, target: Vector2) -> void:
	flying = true
	tip = from
	previous_tip = from
	paid_length = 0.0
	velocity = launch_velocity(from,target)
	age = 0
	rejection_cooldown = 0
	points.clear()
	old_points.clear()
	pins.clear()
	path.bends.clear()
	render_previous.clear()

func release() -> void:
	flying = false
	paid_length = 0.0
	impact = 0.0
	rejection_cooldown = 0
	points.clear()
	old_points.clear()
	pins.clear()
	path.bends.clear()
	render_previous.clear()

func ray(body: PhysicsBody2D, from: Vector2, to: Vector2) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(from,to)
	query.exclude = [body.get_rid()]
	return body.get_world_2d().direct_space_state.intersect_ray(query)

func hook_ray(body: PhysicsBody2D, from: Vector2, to: Vector2) -> Dictionary:
	# Only the metal hook/its preview sees puzzle barriers. Keep the shared
	# terrain ray unchanged for arrows, glowsticks, boots and cable contacts.
	var terrain := ray(body,from,to)
	if not hook_barrier.is_valid(): return terrain
	var barrier: Dictionary = hook_barrier.call(from,to)
	if barrier.is_empty(): return terrain
	if terrain.is_empty() or from.distance_squared_to(barrier.position)<=from.distance_squared_to(terrain.position):
		return barrier
	return terrain

func rejects_hit(hit: Dictionary) -> bool:
	return not hit.is_empty() and (hit.get("hook_blocker",false) or (reject_hook.is_valid() and reject_hook.call(hit.position)))

func step(body: PhysicsBody2D, dt: float) -> Dictionary:
	impact = maxf(0,impact-dt)
	rejection_cooldown = maxf(0,rejection_cooldown-dt)
	previous_tip = tip
	if not flying:
		return {}
	age += dt
	var next := tip+velocity*dt+GRAVITY*dt*dt*0.5
	velocity += GRAVITY*dt
	# A missed throw hangs from its paid-out tether; it never times out.
	var origin: Vector2 = body.call("tether_position")
	path.update(origin,tip)
	var last_contact := path.bends[-1] if not path.bends.is_empty() else origin
	var paid_out := path.length_between(origin,tip)-last_contact.distance_to(tip)
	var available := maxf(2.0,MAX_LENGTH-paid_out)
	var radial := next-last_contact
	if radial.length()>available:
		var normal := radial.normalized()
		next = last_contact+normal*available
		velocity -= normal*maxf(0,velocity.dot(normal))
	var hit := hook_ray(body,tip,next)
	if not hit.is_empty():
		tip = hit.position+hit.normal*2
		if rejects_hit(hit):
			var approach_speed := maxf(0,-velocity.dot(hit.normal))
			velocity = velocity.bounce(hit.normal)*0.38
			# Tiny resting contacts must not become a repeated metallic rattle.
			if approach_speed>=70 and rejection_cooldown<=0:
				rejection_cooldown = 0.18
				rejected.emit(hit.position)
			return {}
		velocity = Vector2.ZERO
		flying = false
		impact = 0.5
		return hit
	tip = next
	return {}

func pay_out(from: Vector2, to: Vector2) -> float:
	# A returning hook cannot wind cable back onto the climber by itself.
	# Preserve the same flight slack when the metal catches; only reeling or
	# player motion can subsequently take it up.
	paid_length = minf(MAX_LENGTH,maxf(paid_length,path.length_between(from,to)+15.0))
	return paid_length

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

func simulate(body: PhysicsBody2D, from: Vector2, to: Vector2, length: float, dt: float) -> void:
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
			points[i] = contact(body,current,proposed,i)
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
					points[i] = contact(body,points[i],points[i]+correction/weight,i)
				if weight_b>0:
					points[i+1] = contact(body,points[i+1],points[i+1]-correction/weight,i+1)
		# Catch link/edge intersections too, not just the particle sweeps.
		for i in range(first+1,last):
			var hit := ray(body,points[i-1],points[i])
			if not hit.is_empty():
				points[i] = hit.position+hit.normal*2
				old_points[i] = points[i]
	if topology_changed: render_previous = points.duplicate()

func contact(body: PhysicsBody2D, from: Vector2, to: Vector2, index: int) -> Vector2:
	if from.distance_squared_to(to)<0.000001: return to
	var hit := ray(body,from,to)
	if hit.is_empty(): return to
	var normal: Vector2 = hit.normal
	var resting: Vector2 = hit.position+normal*2
	# Remove inward velocity and damp sliding so slack cable rests on snow/rock.
	var motion := (resting-old_points[index]).slide(normal)*0.72
	old_points[index] = resting-motion
	return resting

func render_points(fraction: float, harness: Vector2) -> PackedVector2Array:
	var result := points.duplicate()
	if render_previous.size()==points.size():
		for i in points.size(): result[i] = render_previous[i].lerp(points[i],fraction)
	# Only the free harness span follows render-time player motion; terrain
	# contacts must never drift with the character or camera interpolation.
	if not result.is_empty():
		var shift := harness-result[0]
		var end := pins[1] if pins.size()>1 else result.size()-1
		for i in range(end):
			result[i] += shift*(1.0-float(i)/maxi(1,end))
	return result
