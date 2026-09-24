extends RefCounted

# Adapted from White Approach; see vendored/rope_sources/provenance.json.
# Closed static polygons in the same world coordinates as the rope endpoints.
const CLEARANCE := 2.5
var solids: Array[PackedVector2Array] = []
var corners := PackedVector2Array()
var links: Array[PackedInt32Array] = []
var bends := PackedVector2Array()

func build(polygons: Array[PackedVector2Array]) -> void:
	solids = polygons.duplicate(true)
	corners.clear()
	links.clear()
	bends.clear()
	for polygon in solids:
		var area := 0.0
		for i in polygon.size(): area += polygon[i].cross(polygon[(i+1)%polygon.size()])
		var orientation := 1.0 if area>0 else -1.0
		for i in polygon.size():
			var p := polygon[i]
			var incoming := (p-polygon[(i+polygon.size()-1)%polygon.size()]).normalized()
			var outgoing := (polygon[(i+1)%polygon.size()]-p).normalized()
			# Only convex exterior corners can support a taut cable.
			if incoming.cross(outgoing)*orientation<=0.0001: continue
			var n1 := Vector2(incoming.y,-incoming.x)*orientation
			var n2 := Vector2(outgoing.y,-outgoing.x)*orientation
			var bisector := (n1+n2).normalized()
			var candidate := p+bisector*minf(16.0,CLEARANCE/maxf(0.15,bisector.dot(n1)))
			if not inside(candidate): corners.append(candidate)
	links.resize(corners.size())
	for i in corners.size():
		for j in range(i+1,corners.size()):
			if clear(corners[i],corners[j]):
				links[i].append(j)
				links[j].append(i)

func inside(p: Vector2) -> bool:
	for polygon in solids:
		if Geometry2D.is_point_in_polygon(p,polygon): return true
	return false

func clear(a: Vector2, b: Vector2) -> bool:
	if inside((a+b)*0.5): return false
	for polygon in solids:
		for i in polygon.size():
			if Geometry2D.segment_intersects_segment(a,b,polygon[i],polygon[(i+1)%polygon.size()])!=null:
				return false
	return true

func update(from: Vector2, to: Vector2) -> void:
	# Retain contacts until a bypass is actually clear; no framewise shortest-
	# path switching between opposite sides of a spike.
	var i := 0
	while i<bends.size():
		var previous := from if i==0 else bends[i-1]
		var next := to if i==bends.size()-1 else bends[i+1]
		if clear(previous,next): bends.remove_at(i)
		else: i += 1
	var previous := from
	for next in guides(from,to).slice(1):
		if not clear(previous,next):
			find_path(from,to)
			return
		previous = next

func find_path(from: Vector2, to: Vector2) -> void:
	var count := corners.size()
	var distance := PackedFloat32Array()
	var parent := PackedInt32Array()
	var visited := PackedByteArray()
	distance.resize(count)
	distance.fill(INF)
	parent.resize(count)
	parent.fill(-1)
	visited.resize(count)
	for i in count:
		if clear(from,corners[i]): distance[i] = from.distance_to(corners[i])
	var best := INF
	var end := -1
	for iteration in count:
		var current := -1
		var minimum := INF
		for i in count:
			if visited[i]==0 and distance[i]<minimum:
				current = i
				minimum = distance[i]
		if current<0 or minimum>=best: break
		visited[current] = 1
		var total := minimum+corners[current].distance_to(to)
		if total<best and clear(corners[current],to):
			best = total
			end = current
		for neighbor in links[current]:
			var cost := minimum+corners[current].distance_to(corners[neighbor])
			if cost<distance[neighbor]:
				distance[neighbor] = cost
				parent[neighbor] = current
	if end<0: return # Keep existing contacts if an endpoint is temporarily occluded.
	bends.clear()
	while end>=0:
		bends.insert(0,corners[end])
		end = parent[end]

func guides(from: Vector2, to: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array([from])
	result.append_array(bends)
	result.append(to)
	return result

func length_between(from: Vector2, to: Vector2) -> float:
	var result := 0.0
	var previous := from
	for next in guides(from,to).slice(1):
		result += previous.distance_to(next)
		previous = next
	return result

func pull_point(to: Vector2) -> Vector2:
	return bends[0] if not bends.is_empty() else to

func fixed_length(to: Vector2) -> float:
	if bends.is_empty(): return 0.0
	var result := bends[-1].distance_to(to)
	for i in bends.size()-1: result += bends[i].distance_to(bends[i+1])
	return result
