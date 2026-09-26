extends RefCounted
## One shared square theme for the game HUD, menus and touch controls.
const FONT = preload("res://assets/fonts/tiny5/Tiny5-Regular.ttf")
const INK := Color("dce7dc")
const MUTED := Color("96aaa5")
const LINE := Color("40534e")
const ACCENT := Color("94c7a5")
const PANEL := Color("142126")
const PRIMARY := Color("355c50")
const FEEDBACK := Color("a1e8c1")
const FAINT := Color("b0bdc4")
const ICON := Color("cdd2d4")
const OUTLINE := Color("081014")
## Dims the yard behind menus.
const SCRIM := Color(0.03, 0.06, 0.08, 0.65)
## Button fill per state; hover also gets the accent border.
const BUTTON_FILLS := {"normal": Color("1c2d31"), "hover": Color("2b4140"), "pressed": Color("365448"), "hover_pressed": Color("365448"), "disabled": PANEL}

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
	result.set_type_variation("YardOverlayLabel", "Label")
	result.set_color("font_outline_color", "YardOverlayLabel", OUTLINE)
	result.set_constant("outline_size", "YardOverlayLabel", 6)
	result.set_stylebox("panel", "PanelContainer", panel(PANEL))
	for type in ["Button", "CheckButton", "OptionButton"]:
		for state in BUTTON_FILLS:
			result.set_stylebox(state, type, panel(BUTTON_FILLS[state], ACCENT if state == "hover" else LINE, 8))
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
