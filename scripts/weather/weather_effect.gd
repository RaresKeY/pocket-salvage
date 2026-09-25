extends Node
## One weather effect. Reads only the profile fields it needs; `applies` decides whether it is created at all.
var weather: Node
var context: Node
## Looping sounds this effect runs: name -> [level, volume_db]. Silenced while paused and when the round's world goes.
var _loops: Dictionary = {}

func applies(_profile) -> bool:
	return false

func bind(owner_weather: Node, owner_context: Node) -> void:
	weather = owner_weather
	context = owner_context
	_start()

func _start() -> void:
	pass

func _loop(sound: StringName, level: float, volume_db: float) -> void:
	_loops[sound] = [level, volume_db]
	context.sfx.set_loop(sound, level, 1.0, volume_db)

func _notification(what: int) -> void:
	if what != NOTIFICATION_DISABLED and what != NOTIFICATION_ENABLED and what != NOTIFICATION_EXIT_TREE: return
	if not is_instance_valid(context) or not is_instance_valid(context.sfx): return
	var playing := what == NOTIFICATION_ENABLED
	for sound in _loops:
		context.sfx.set_loop(sound, _loops[sound][0] if playing else 0.0, 1.0, _loops[sound][1])
