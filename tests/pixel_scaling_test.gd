extends SceneTree

const Scaling = preload("res://scripts/art/pixel_scaling.gd")
var failures := 0


func _initialize() -> void:
	var source := Image.create(3, 2, false, Image.FORMAT_RGBA8)
	var colors := [Color.RED, Color(0.2, 0.4, 0.8, 0.5), Color(0.8, 0.1, 0.3, 0), Color.GREEN, Color.BLUE, Color.WHITE]
	for index in range(colors.size()):
		source.set_pixel(index % 3, index / 3, colors[index])
	var original := source.get_data()
	for factor in [1, 2, 10]:
		var enlarged := Scaling.enlarge(source, factor)
		check(enlarged.get_size() == Vector2i(3 * factor, 2 * factor), "exact output dimensions")
		for y in range(enlarged.get_height()):
			for x in range(enlarged.get_width()):
				check(enlarged.get_pixel(x, y) == source.get_pixel(x / factor, y / factor), "each output block preserves RGBA")
		var path := "user://pixel-roundtrip.png"
		check(enlarged.save_png(path) == OK, "PNG write")
		var loaded := Image.load_from_file(path)
		loaded.convert(Image.FORMAT_RGBA8)
		check(loaded.get_data() == enlarged.get_data(), "PNG round trip preserves RGBA bytes")
		DirAccess.remove_absolute(path)
	check(source.get_data() == original, "source was not mutated")
	check(Scaling.enlarge(source, 0) == null, "zero factor rejected")
	check(Scaling.enlarge(source, -1) == null, "negative factor rejected")
	check(Scaling.enlarge(source, 33) == null, "oversized factor rejected")
	check(not Scaling.size_error(4096, 4096, 2).is_empty(), "allocation guard")
	check(not Scaling.size_error(16385, 1, 1).is_empty(), "edge guard")
	if failures == 0:
		print("PIXEL_SCALING_TEST_OK block identity, alpha, PNG round-trip, source preservation, and limits")
	quit(0 if failures == 0 else 1)


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + message)
