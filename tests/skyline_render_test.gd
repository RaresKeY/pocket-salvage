extends SceneTree
## Needs real rendering (not headless): every stretch of the horizon must show skyline, including mirrored tiles.
const Backdrop = preload("res://scripts/level/yard_backdrop.gd")
const Layout = preload("res://scripts/level/yard_layout.gd")
const Art = preload("res://scripts/art/yard_art.gd")
const COLUMN := 8

func _initialize() -> void: call_deferred("run")

func check(set_name: String) -> void:
	var layout := Layout.create_layout()
	var view := SubViewport.new()
	view.size = Vector2i(layout.bounds.size)
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var backdrop := Backdrop.new()
	backdrop.draw_sky = false
	if set_name != Backdrop.SKYLINE: backdrop.skylines = Backdrop.skyline_set(set_name)
	view.add_child(backdrop)
	backdrop.configure(layout)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := view.get_texture().get_image()
	var art_scale: float = layout.art_scale
	var fence_top: float = layout.ground_top - Art.world_size(Backdrop.FENCE, art_scale).y
	var horizon := fence_top + Backdrop.FENCE_SKY_ROWS * art_scale
	var top := int(horizon - Art.world_size(backdrop.skylines[0], art_scale).y) + 1
	var tower := int(Art.world_size(Backdrop.TOWER, art_scale).x) + 2
	for x in range(tower, int(layout.bounds.size.x) - tower, COLUMN):
		var drawn := false
		for y in range(top, int(fence_top) - 1):
			if image.get_pixel(x, y).a > 0.5: drawn = true
		assert(drawn, "%s: skyline missing above x=%d" % [set_name, x])
	view.queue_free()
	await process_frame

func run() -> void:
	await check(Backdrop.SKYLINE)
	await check("backdrop_blood_skyline_tile")
	print("SKYLINE_RENDER_OK")
	quit()
