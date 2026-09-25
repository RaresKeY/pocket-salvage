extends RefCounted
## One shared square theme for the game HUD, menus and touch controls.
const FONT = preload("res://assets/fonts/tiny5/Tiny5-Regular.ttf")
const INK := Color("dce7dc")
const MUTED := Color("96aaa5")
const LINE := Color("40534e")
const ACCENT := Color("94c7a5")

static func panel(fill: Color, border := LINE, padding := 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_content_margin_all(padding)
	return style

static func make() -> Theme:
	var result := Theme.new()
	var font := FONT.duplicate() as FontFile
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	result.default_font = font
	result.default_font_size = 20
	result.set_color("font_color", "Label", INK)
	result.set_stylebox("panel", "PanelContainer", panel(Color("142126")))
	for type in ["Button", "CheckButton", "OptionButton"]:
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var fill := Color("1c2d31")
			if state == "hover": fill = Color("2b4140")
			elif state == "pressed" or state == "hover_pressed": fill = Color("365448")
			elif state == "disabled": fill = Color("142126")
			result.set_stylebox(state, type, panel(fill, ACCENT if state == "hover" else LINE, 8))
			result.set_color("font_" + state + "_color", type, INK)
		result.set_color("font_color", type, INK)
		result.set_color("font_disabled_color", type, MUTED)
		var focus := panel(Color.TRANSPARENT, ACCENT, 8)
		focus.draw_center = false
		focus.set_border_width_all(2)
		result.set_stylebox("focus", type, focus)
	var line := StyleBoxLine.new()
	line.color = LINE
	line.thickness = 1
	line.vertical = true
	result.set_stylebox("separator", "VSeparator", line)
	var track := panel(Color("10191d"), LINE, 3)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	result.set_stylebox("slider", "HSlider", track)
	result.set_stylebox("grabber_area", "HSlider", panel(Color("527d65"), ACCENT, 3))
	result.set_stylebox("grabber_area_highlight", "HSlider", panel(ACCENT, ACCENT, 3))
	var knob_image := Image.create(10, 14, false, Image.FORMAT_RGBA8)
	knob_image.fill(ACCENT)
	var knob := ImageTexture.create_from_image(knob_image)
	for state in ["grabber", "grabber_highlight", "grabber_disabled"]:
		result.set_icon(state, "HSlider", knob)
	return result
