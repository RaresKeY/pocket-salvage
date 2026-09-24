@tool
extends Control
## Keep the arranged sprite canvas on whole screen pixels; text stays native-sized.

const ART_SIZE := Vector2(384, 216)

@onready var stage: SubViewportContainer = $Stage
@onready var hud: Control = $Presentation/HUD


func _ready() -> void:
	resized.connect(_fit_stage)
	_fit_stage()


func _fit_stage() -> void:
	var zoom := maxf(1.0, floorf(minf(size.x / ART_SIZE.x, size.y / ART_SIZE.y)))
	var extent := ART_SIZE * zoom
	var origin := ((size - extent) * 0.5).floor()
	stage.position = origin
	stage.scale = Vector2.ONE * zoom
	hud.position = origin
	hud.size = extent
