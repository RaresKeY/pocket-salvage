extends "res://tools/shared/game-dev-tools/tools/pixel-scaling/src/superscale.gd"
const SharedPin = preload("res://tools/shared/game-dev-tools/src/consumer_pin.gd")

func _initialize() -> void:
	if not SharedPin.verify():
		quit(1)
		return
	super._initialize()
