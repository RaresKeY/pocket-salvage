extends SceneTree
## Deterministic calibration media, not generated game art.

func _initialize() -> void:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var cream := Color("f6efdc")
	var mint := Color("8ee0b6")
	var coral := Color("f18b78")
	for y in range(2, 14):
		for x in range(2, 14):
			image.set_pixel(x, y, cream if (x + y) % 2 == 0 else Color("243c47"))
	for y in range(2, 14):
		for x in range(18, 30):
			if x - 18 <= y - 2:
				image.set_pixel(x, y, mint)
	for y in range(18, 30):
		for x in range(2, 14):
			if x == 2 or x == 13 or y == 18 or y == 29 or x == 7 or y == 23:
				image.set_pixel(x, y, coral)
	for y in range(18, 30):
		for x in range(18, 30):
			image.set_pixel(x, y, Color(0.55, 0.88, 0.71, float(x - 18) / 11.0))
	var path := "res://assets/pixel_lab/calibration.png"
	if image.save_png(path) != OK:
		quit(1)
		return
	print("FIXTURE_OK 32x32 checker, diagonal, one-pixel lines, and alpha ramp")
	quit(0)
