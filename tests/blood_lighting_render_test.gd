extends SceneTree
const Art = preload("res://scripts/art/yard_art.gd")
const Ambience = preload("res://scripts/level/yard_ambience.gd")
func _initialize() -> void: call_deferred("run")
func bulb_check(name: String, bulb: Vector2i, metal: Vector2i, beacon: bool) -> void:
	var texture = Art.texture(name)
	var view := SubViewport.new()
	view.size = texture.get_size()
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var factory = Ambience.new()
	sprite.material = factory.bulb_material(beacon)
	factory.free()
	view.add_child(sprite)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var source: Image = texture.get_image()
	var actual := view.get_texture().get_image()
	var light := actual.get_pixelv(bulb)
	assert(light.r > light.b * 2)
	var base := source.get_pixelv(metal)
	var rendered := actual.get_pixelv(metal)
	assert(absf(base.r - rendered.r) < 0.01 and absf(base.g - rendered.g) < 0.01 and absf(base.b - rendered.b) < 0.01)
	sprite.material.set_shader_parameter("power", 0.0)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	actual = view.get_texture().get_image()
	assert(actual.get_pixelv(bulb).r < light.r * 0.2)
	assert(absf(actual.get_pixelv(metal).r - rendered.r) < 0.01)
	view.queue_free()
	await process_frame
func run() -> void:
	await bulb_check("yard_floodlight", Vector2i(12,60), Vector2i(76,164), false)
	await bulb_check("yard_beacon_01", Vector2i(20,12), Vector2i(28,44), true)
	await bulb_check("yard_beacon_04", Vector2i(20,12), Vector2i(28,44), true)
	print("BULB_MASK_GPU_OK")
	quit()
