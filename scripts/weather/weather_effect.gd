extends Node
## One weather effect. Reads only the profile fields it needs; `applies` decides whether it is created at all.
var weather: Node
var context: Node

func applies(_profile) -> bool:
	return false

func bind(owner_weather: Node, owner_context: Node) -> void:
	weather = owner_weather
	context = owner_context
	_start()

func _start() -> void:
	pass
