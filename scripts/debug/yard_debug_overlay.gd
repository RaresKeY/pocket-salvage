extends Node2D
## Source-run diagnostics only. Geometry and art masks are read, never modified.
const VisualMask = preload("res://scripts/physics/visual_mask_2d.gd")
var subject: Node2D
var _dirty := false
var hitboxes := false
var masks := false
var shapes: Array[CollisionShape2D] = []
var art_masks: Array[Dictionary] = []
var active_masks: Array[Node2D] = []

static func available() -> bool:
	return OS.has_feature("editor") and not OS.has_feature("standalone") and not OS.has_feature("web")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 4095
	set_process(false)
	get_tree().tree_changed.connect(func(): _dirty = true)

func configure(root_node: Node2D, show_hitboxes: bool, show_masks: bool) -> void:
	subject = root_node
	hitboxes = show_hitboxes and available()
	masks = show_masks and available()
	_refresh()
	visible = hitboxes or masks
	set_process(visible)
	queue_redraw()

func _refresh() -> void:
	shapes.clear()
	art_masks.clear()
	active_masks.clear()
	if is_instance_valid(subject) and (hitboxes or masks): _collect(subject)
	_dirty = false

func _collect(node: Node) -> void:
	if node is CollisionShape2D: shapes.append(node)
	if node is VisualMask: active_masks.append(node)
	if node is Sprite2D and node.texture != null:
		var path: String = node.texture.resource_path.get_basename() + "_mask.png"
		if ResourceLoader.exists(path):
			art_masks.append({"sprite": node, "texture": load(path)})
	for child in node.get_children(): _collect(child)

func _process(_delta: float) -> void:
	if _dirty: _refresh()
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(subject): return
	if masks:
		for entry in art_masks:
			var sprite: Sprite2D = entry.sprite
			if not is_instance_valid(sprite) or not sprite.is_visible_in_tree(): continue
			draw_set_transform_matrix(global_transform.affine_inverse() * sprite.global_transform)
			draw_texture_rect(entry.texture, sprite.get_rect(), false, Color(1.0, 0.3, 0.8, 0.65))
		for mask in active_masks:
			if not is_instance_valid(mask) or not mask.enabled or mask.mask_texture == null: continue
			draw_set_transform_matrix(global_transform.affine_inverse() * mask.global_transform)
			var size: Vector2 = mask.mask_texture.get_size()
			draw_texture_rect(mask.mask_texture, Rect2(-size * 0.5, size), false, Color(1.0, 0.6, 0.1, 0.7))
	if hitboxes:
		for part in shapes:
			if not is_instance_valid(part) or part.disabled or part.shape == null: continue
			draw_set_transform_matrix(global_transform.affine_inverse() * part.global_transform)
			var color := Color(0.2, 1.0, 0.5, 0.55)
			if part.get_parent() is Area2D: color = Color(0.2, 0.65, 1.0, 0.45)
			part.shape.draw(get_canvas_item(), color)
	draw_set_transform_matrix(Transform2D.IDENTITY)
