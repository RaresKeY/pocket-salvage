@tool
extends Control
## Native-resolution rendering of enlarged textures with an inspectable camera.
const ART_SIZE := Vector2(384, 216)
const MIN_ZOOM := 0.5
const MAX_ZOOM := 32.0
const ZOOM_SPEED := 14.0

@onready var stage: SubViewportContainer = $Stage
@onready var viewport: SubViewport = $Stage/Viewport
@onready var hud: Control = $Presentation/HUD
var zoom := 1.0
var target_zoom := 1.0
var center := ART_SIZE * 0.5
var anchor_screen := Vector2.ZERO
var anchor_world := ART_SIZE * 0.5
var dragging := false
var drag_button := MOUSE_BUTTON_NONE
var initialized := false
var play_button: Button

func _ready() -> void:
	resized.connect(_fit_stage)
	_fit_stage()
	set_process(not Engine.is_editor_hint())
	set_process_input(not Engine.is_editor_hint())
	if not Engine.is_editor_hint():
		play_button = Button.new()
		play_button.text = "Play prototype"
		play_button.custom_minimum_size = Vector2(132,40)
		play_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://labs/salvage/lab.tscn"))
		var row := $Presentation/HUD/Header/Row
		row.add_child(play_button)
		row.move_child(play_button,1)

func _fit_stage() -> void:
	stage.position = Vector2.ZERO
	stage.scale = Vector2.ONE
	stage.size = size
	var fit := maxf(1.0, floorf(minf(size.x / ART_SIZE.x, size.y / ART_SIZE.y)))
	var extent := ART_SIZE * fit
	hud.position = ((size - extent) * 0.5).floor()
	hud.size = extent
	if not initialized or Engine.is_editor_hint():
		reset_view()
	else:
		anchor_screen = size * 0.5
		anchor_world = center
		_apply_camera()
	initialized = true

func reset_view() -> void:
	zoom = clampf(floorf(minf(size.x / ART_SIZE.x, size.y / ART_SIZE.y)), MIN_ZOOM, MAX_ZOOM)
	target_zoom = zoom
	center = ART_SIZE * 0.5
	anchor_screen = size * 0.5
	anchor_world = center
	dragging = false
	_apply_camera()

func world_at(screen: Vector2) -> Vector2:
	return center + (screen - size * 0.5) / zoom

func zoom_at(screen: Vector2, steps: float) -> void:
	anchor_world = world_at(screen)
	anchor_screen = screen
	target_zoom = clampf(target_zoom * pow(1.18, steps), MIN_ZOOM, MAX_ZOOM)

func _process(delta: float) -> void:
	advance_zoom(delta)

func advance_zoom(delta: float) -> void:
	if is_equal_approx(zoom, target_zoom): return
	zoom = lerpf(zoom, target_zoom, 1.0 - exp(-ZOOM_SPEED * delta))
	if absf(zoom - target_zoom) < 0.0001: zoom = target_zoom
	center = anchor_world - (anchor_screen - size * 0.5) / zoom
	_apply_camera()

func _apply_camera() -> void:
	viewport.canvas_transform = Transform2D(0.0, Vector2.ONE * zoom, 0.0, size * 0.5 - center * zoom)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and is_instance_valid(play_button) and play_button.get_global_rect().has_point(event.position): return
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			zoom_at(event.position, (1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0) * event.factor)
			get_viewport().set_input_as_handled()
		elif event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE]:
			if event.pressed:
				dragging = true
				drag_button = event.button_index
				target_zoom = zoom
			elif event.button_index == drag_button:
				dragging = false
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and dragging:
		center -= event.relative / zoom
		anchor_world = world_at(anchor_screen)
		_apply_camera()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F:
		reset_view()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		dragging = false
