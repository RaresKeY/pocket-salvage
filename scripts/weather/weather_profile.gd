class_name WeatherProfile
extends Resource
## One weather as data. Zero values switch the matching effect off.
@export var id: StringName
@export var label := ""
@export var tip := ""
@export var chance := 0.0
@export var multiplier := 1.0
@export var wind := 0.0
@export var gust := 0.0
@export var gust_every := Vector2.ZERO
@export var gust_rise := 1.0
@export var grip := 1.0
@export var fog := 0.0
@export var rain := 0.0
@export var lightning_every := Vector2.ZERO
@export var warning := 1.0
@export var power_cut := 0.0
