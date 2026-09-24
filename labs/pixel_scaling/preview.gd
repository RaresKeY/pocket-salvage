extends Control

var texture: Texture2D
var zoom := 1.0
var snap_motion := true
var moving := false
var phase := 0.0


func configure(value: Texture2D, scale_factor: float, linear: bool, snapped: bool) -> void:
	texture = value
	zoom = scale_factor
	snap_motion = snapped
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if linear else CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	update_minimum_size()
	queue_redraw()


func _get_minimum_size() -> Vector2:
	return Vector2(64, 64) if texture == null else texture.get_size() * zoom + Vector2(64, 64)


func set_motion(enabled: bool) -> void:
	moving = enabled
	set_process(enabled)
	if not enabled:
		phase = 0.0
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(moving)


func _process(delta: float) -> void:
	phase += delta
	queue_redraw()


func _draw() -> void:
	if texture == null:
		return
	# Only draw the visible checker region, even for large scrollable textures.
	var clip := Rect2(-position, get_parent().size).intersection(Rect2(Vector2.ZERO, size))
	for y in range(int(clip.position.y / 16), int(ceil(clip.end.y / 16))):
		for x in range(int(clip.position.x / 16), int(ceil(clip.end.x / 16))):
			var color := Color("23343c") if (x + y) % 2 == 0 else Color("2c4049")
			draw_rect(Rect2(x * 16, y * 16, 16, 16), color)
	var offset := Vector2(32 + sin(phase * 1.5) * 12, 32)
	if snap_motion:
		offset = offset.round()
	draw_texture_rect(texture, Rect2(offset, texture.get_size() * zoom), false)
