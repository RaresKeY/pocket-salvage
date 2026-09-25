extends RefCounted
## The Blood Moon look split into separately tunable strengths for the developer options. Defaults are the shipped look.
const SLIDERS := [
	{"key": &"screen", "label": "Screen wash", "min": 0.0, "max": 0.2, "default": 0.05, "hint": "Red wash over the whole yard view."},
	{"key": &"assets", "label": "Asset edges", "min": 0.0, "max": 0.2, "default": 0.05, "hint": "Red light picked up on asset edges."},
	{"key": &"sky", "label": "Sky", "min": 0.0, "max": 1.0, "default": 1.0, "hint": "How far the sky and clouds go from night blue to blood red."},
	{"key": &"lights", "label": "Light cones", "min": 0.0, "max": 2.0, "default": 1.0, "hint": "Strength of the floodlight beams."},
	{"key": &"bulbs", "label": "Bulbs", "min": 0.0, "max": 1.0, "default": 1.0, "hint": "Red glow on masked bulbs and beacon lenses."},
]

static func defaults() -> Dictionary:
	var values := {}
	for slider in SLIDERS: values[slider.key] = slider.default
	return values

static func clamp_value(key: StringName, value: float) -> float:
	for slider in SLIDERS:
		if slider.key == key: return clampf(value, slider.min, slider.max)
	return value
