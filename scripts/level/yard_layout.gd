extends RefCounted
## Caller-owned, deterministic diagnostic layouts. Dimensions are prototype fixtures.
const ART := "res://assets/bitwright_8x/"

static func create_layout(variant: int = 0) -> Dictionary:
	var types := [
		[&"copper", "scrap_copper_wire", Vector2(38, 32), 0.8],
		[&"rubber", "scrap_tire", Vector2(42, 42), 1.0],
		[&"steel", "scrap_cog", Vector2(40, 40), 1.2],
		[&"copper", "scrap_copper_wire", Vector2(32, 28), 0.7],
		[&"rubber", "scrap_tire", Vector2(36, 36), 0.9],
		[&"steel", "scrap_washing_machine", Vector2(44, 50), 1.8],
	]
	var scrap: Array[Dictionary] = []
	for index in types.size():
		var item: Array = types[(index + posmod(variant, 2) * 3) % types.size()]
		scrap.append({"id": index, "material": item[0],
			"texture": ART + item[1] + ".png", "position": Vector2(110 + index * 60, 410),
			"size": item[2], "mass": item[3]})
	var bins: Array[Dictionary] = []
	var materials := [&"copper", &"rubber", &"steel"]
	for index in materials.size():
		var material: StringName = materials[(index + posmod(variant, 2)) % materials.size()]
		bins.append({"material": material, "position": Vector2(650 + index * (150 - SortingBin.WALL), 390),
			"size": Vector2(150, 100), "texture": ART + "bin_" + String(material) + ".png"})
	return {"bounds": Rect2(0, 0, 1200, 480), "ground_top": 440.0, "art_scale": 1.6,
		"crane_anchor": Vector2(200, 45), "scrap": scrap, "bins": bins,
		"variant": posmod(variant, 2), "pickup_bounds": Rect2(85, 350, 350, 90)}
