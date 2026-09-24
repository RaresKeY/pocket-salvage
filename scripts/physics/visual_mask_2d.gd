@tool
extends Node2D
## Independent world-space occluder. Assign a target Sprite2D in the same canvas.
## Mask alpha=1 hides target pixels; alpha=0 leaves them visible. No physics writes.
const MaskShader = preload("res://shaders/occlusion_mask.gdshader")
@export var mask_texture: Texture2D:
	set(value):
		mask_texture = value
		_sync_mask()
@export var enabled := true:
	set(value):
		enabled = value
		_sync_mask()
@export var target: Sprite2D:
	set(value):
		_detach()
		target = value
		if is_inside_tree(): _attach()
var _material: ShaderMaterial
var _previous_material: Material
var _bound_target: Sprite2D

func _enter_tree() -> void:
	set_notify_transform(true)
	_attach()

func _exit_tree() -> void:
	_detach()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED: _sync_mask()

func _attach() -> void:
	if not is_instance_valid(target): return
	_bound_target = target
	_previous_material = target.material
	_material = ShaderMaterial.new()
	_material.shader = MaskShader
	target.material = _material
	_sync_mask()

func _detach() -> void:
	if is_instance_valid(_bound_target) and _bound_target.material == _material:
		_bound_target.material = _previous_material
	_bound_target = null
	_material = null
	_previous_material = null

func _sync_mask() -> void:
	if _material == null or not is_inside_tree(): return
	var usable := enabled and mask_texture != null and absf(global_transform.determinant()) > 0.000001
	_material.set_shader_parameter("mask_enabled", usable)
	if not usable: return
	_material.set_shader_parameter("occlusion_texture", mask_texture)
	_material.set_shader_parameter("mask_size", mask_texture.get_size())
	var inverse := global_transform.affine_inverse()
	_material.set_shader_parameter("mask_axis_x", inverse.x)
	_material.set_shader_parameter("mask_axis_y", inverse.y)
	_material.set_shader_parameter("mask_origin", inverse.origin)
