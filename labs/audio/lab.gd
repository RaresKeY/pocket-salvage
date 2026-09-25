extends Control
const Sfx = preload("res://scripts/audio/sfx.gd")
const ArtLab = preload("res://labs/pixel_scaling/lab.gd")

func _ready() -> void:
	var art := ArtLab.new()
	theme = art.make_theme()
	art.free()
	var sound := Sfx.new()
	add_child(sound)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var grid := GridContainer.new()
	grid.columns = 3
	panel.add_child(grid)
	for cue in [&"ui_click", &"start", &"pickup", &"clank", &"claw_open", &"claw_shut", &"magnet_on", &"magnet_off", &"correct", &"wrong", &"eject", &"land", &"tick", &"finish", &"trolley_loop", &"winch_loop", &"music_yard"]:
		var button := Button.new()
		button.text = String(cue).capitalize()
		button.custom_minimum_size = Vector2(170, 44)
		grid.add_child(button)
		if cue in [&"trolley_loop", &"winch_loop", &"music_yard"]:
			button.toggle_mode = true
			button.toggled.connect(func(on): sound.set_loop(cue, 1.0 if on else 0.0))
		else: button.pressed.connect(func(): sound.play(cue))
	grid.get_child(0).grab_focus()
