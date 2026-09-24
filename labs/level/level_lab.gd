extends Node2D
const Layout = preload("res://scripts/level/yard_layout.gd")
const Backdrop = preload("res://scripts/level/yard_backdrop.gd")
var variant := 0
var stage: Node2D
var status: Label

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var overlay := CanvasLayer.new()
	add_child(overlay)
	var panel := VBoxContainer.new()
	panel.position = Vector2(16, 12)
	overlay.add_child(panel)
	var title := Label.new()
	title.text = "YARD LAYOUT LAB · Prototype geometry"
	panel.add_child(title)
	status = Label.new()
	panel.add_child(status)
	var button := Button.new()
	button.text = "Switch layout [Tab]"
	button.pressed.connect(_switch_layout)
	panel.add_child(button)
	get_viewport().size_changed.connect(_fit)
	_build()

func _switch_layout() -> void:
	variant = 1 - variant
	_build()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		_switch_layout()
		get_viewport().set_input_as_handled()

func _build() -> void:
	if is_instance_valid(stage):
		remove_child(stage)
		stage.queue_free()
	stage = Node2D.new()
	add_child(stage)
	var layout := Layout.create_layout(variant)
	var backdrop := Backdrop.new()
	backdrop.configure(layout)
	stage.add_child(backdrop)
	for bin in layout.bins:
		_add_sprite(bin.texture, bin.position, bin.size)
		_add_label(String(bin.material).to_upper(), bin.position + Vector2(-60, -76))
	for item in layout.scrap:
		_add_sprite(item.texture, item.position, item.size)
		_add_label(String(item.material), item.position + Vector2(-23, -55))
	_add_label("PICKUP AREA", Vector2(170, 320))
	_add_label("Lift above the rims · clearance is a playtest question", Vector2(560, 280))
	status.text = "Layout %d · 6 pieces / 3 materials · static fixtures, no physics" % (variant + 1)
	_fit()

func _add_sprite(path: String, center: Vector2, box: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(path)
	sprite.position = center
	var ratio := minf(box.x / sprite.texture.get_width(), box.y / sprite.texture.get_height())
	sprite.scale = Vector2.ONE * ratio
	stage.add_child(sprite)

func _add_label(value: String, point: Vector2) -> void:
	var label := Label.new()
	label.text = value
	label.position = point
	label.add_theme_font_size_override("font_size", 14)
	stage.add_child(label)

func _fit() -> void:
	if not is_instance_valid(stage): return
	var available := get_viewport_rect().size - Vector2(32, 130)
	var ratio := minf(available.x / 1200.0, available.y / 480.0)
	stage.scale = Vector2.ONE * ratio
	stage.position = Vector2((get_viewport_rect().size.x - 1200 * ratio) * 0.5, 115)
