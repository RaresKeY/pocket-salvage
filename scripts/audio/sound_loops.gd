extends Node
## Looping sounds this node runs through the round's `sfx`: name -> [level, volume_db]. Silenced while paused and
## when the node leaves the tree, restored when unpaused.
var sfx: Node
var _loops: Dictionary = {}

func loop_sound(sound: StringName, level: float, volume_db: float) -> void:
	_loops[sound] = [level, volume_db]
	sfx.set_loop(sound, level, 1.0, volume_db)

func _notification(what: int) -> void:
	if what != NOTIFICATION_DISABLED and what != NOTIFICATION_ENABLED and what != NOTIFICATION_EXIT_TREE: return
	if not is_instance_valid(sfx): return
	var playing := what == NOTIFICATION_ENABLED
	for sound in _loops:
		sfx.set_loop(sound, _loops[sound][0] if playing else 0.0, 1.0, _loops[sound][1])
