extends RefCounted
## Caller-owned, deterministic diagnostic layouts. Dimensions are prototype fixtures.
const YardArt = preload("res://scripts/art/yard_art.gd")
const GROUND_TOP := 440.0
const PILE_CENTRE_X := 285.0
const PILE_ROWS := {4: [3, 1], 6: [3, 2, 1], 10: [4, 3, 2, 1], 12: [4, 4, 4]}
const PILE_GAP := 8.0
## Under half the gap, so neighbours never start overlapping.
const PILE_JITTER := [0.0, 3.0, -3.0, 2.0, -2.0, 1.0, 3.0, -1.0, 2.0, -3.0]

static func create_layout(variant: int = 0, scrap_count: int = 10) -> Dictionary:
	assert(PILE_ROWS.has(scrap_count), "Add a bounded pile recipe for this count")
	var types := [
		[&"steel", "scrap_washing_machine", Vector2(44, 50), 1.8],
		[&"rubber", "scrap_tire", Vector2(42, 42), 1.0],
		[&"steel", "scrap_cog", Vector2(40, 40), 1.2],
		[&"copper", "scrap_copper_wire", Vector2(38, 30), 0.8],
		[&"steel", "scrap_hubcap", Vector2(32, 32), 0.8],
		[&"copper", "scrap_copper_wire", Vector2(32, 26), 0.7],
		[&"rubber", "scrap_tire", Vector2(36, 36), 0.9],
		[&"steel", "scrap_spring", Vector2(22, 36), 0.7],
		[&"copper", "scrap_copper_wire", Vector2(28, 22), 0.6],
		[&"steel", "scrap_tin_can", Vector2(24, 24), 0.4],
	]
	var scrap: Array[Dictionary] = []
	var row_top := GROUND_TOP
	var placed := 0
	## Non-overlapping rows with gaps and jitter tumble into Dale's initial pile.
	for row_size in PILE_ROWS[scrap_count]:
		var row: Array = []
		for slot in row_size:
			row.append(types[(placed + slot + posmod(variant, 2) * 5) % types.size()])
		var row_width := 0.0
		var row_height := 0.0
		for item in row:
			row_width += item[2].x + PILE_GAP
			row_height = maxf(row_height, item[2].y)
		var x := PILE_CENTRE_X - row_width * 0.5
		for item in row:
			var jitter := Vector2(PILE_JITTER[placed % PILE_JITTER.size()], 0)
			scrap.append({"id": placed, "material": item[0], "texture": YardArt.path(item[1]),
				"position": Vector2(x + item[2].x * 0.5, row_top - item[2].y * 0.5 - PILE_GAP) + jitter,
				"size": item[2], "mass": item[3]})
			x += item[2].x + PILE_GAP
			placed += 1
		row_top -= row_height + PILE_GAP
	var bins: Array[Dictionary] = []
	var materials := [&"copper", &"rubber", &"steel"]
	for index in materials.size():
		var material: StringName = materials[(index + posmod(variant, 2)) % materials.size()]
		bins.append({"material": material, "position": Vector2(650 + index * (150 - SortingBin.WALL), 390),
			"size": Vector2(150, 100), "texture": YardArt.path("bin_" + String(material))})
	return {"bounds": Rect2(0, 0, 1200, 480), "ground_top": GROUND_TOP, "art_scale": 1.6,
		"crane_anchor": Vector2(200, 45), "scrap": scrap, "bins": bins,
		"variant": posmod(variant, 2), "pickup_bounds": Rect2(150, 240, 270, 200),
		"tool_stand": Vector2(96, GROUND_TOP - 16)}
