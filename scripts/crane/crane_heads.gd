extends RefCounted
## Swappable crane heads: what each grips, how it animates and what it sounds like. NONE is the bare hook.
const Burst = preload("res://scripts/fx/burst_2d.gd")
const YardArt = preload("res://scripts/art/yard_art.gd")
enum Kind { NONE, MAGNET, CLAW }
const SPECS := {
	Kind.MAGNET: {"name": "Magnet", "prefix": "crane_magnet", "grips": [&"steel"], "open": [1], "closing": [2, 3, 4, 5, 6], "held": [5, 6],
		"on_word": "ON", "off_word": "OFF", "grip_sound": &"magnet_on", "release_sound": &"magnet_off", "closes_on_catch": false},
	Kind.CLAW: {"name": "Claw", "prefix": "crane_claw", "grips": [&"copper", &"rubber"], "open": [4], "closing": [4, 3, 1], "held": [1],
		"on_word": "SHUT", "off_word": "OPEN", "armed_word": "READY", "grip_sound": &"claw_shut", "release_sound": &"claw_open", "closes_on_catch": true},
}

static func function_kind(kind: Kind, reversed: bool = false) -> Kind:
	if not reversed or kind == Kind.NONE: return kind
	return Kind.CLAW if kind == Kind.MAGNET else Kind.MAGNET

static func materials(kind: Kind, reversed: bool = false) -> Array:
	var effective := function_kind(kind, reversed)
	return SPECS[effective].grips if SPECS.has(effective) else []

static func grips(kind: Kind, material: StringName, reversed: bool = false) -> bool:
	return material in materials(kind, reversed)

static func label(kind: Kind, gripping: bool, holding: bool = false) -> String:
	if not SPECS.has(kind): return "Bare hook"
	var spec: Dictionary = SPECS[kind]
	if gripping and spec.closes_on_catch and not holding: return "%s %s" % [spec.name, spec.armed_word]
	return "%s %s" % [spec.name, spec.on_word if gripping else spec.off_word]

## A claw waits open until it catches something; a magnet engages as soon as it is switched on.
static func closes_on_catch(kind: Kind) -> bool:
	return SPECS.has(kind) and SPECS[kind].closes_on_catch

## The head that grips a material, for hints.
static func for_material(material: StringName, reversed: bool = false) -> Kind:
	for kind in SPECS:
		if grips(kind, material, reversed): return kind
	return Kind.NONE

## Animations: `open` at rest, `closing` once when gripping, then `held`. The bare hook is the chain link.
static func sprite(kind: Kind, art_scale: float) -> AnimatedSprite2D:
	var frames := Burst.empty_frames()
	if SPECS.has(kind):
		var spec: Dictionary = SPECS[kind]
		Burst.add_frames(frames, &"open", spec.prefix, spec.open, 1.0, false)
		Burst.add_frames(frames, &"closing", spec.prefix, spec.closing, 14.0, false)
		Burst.add_frames(frames, &"held", spec.prefix, spec.held, 6.0, true)
	else:
		for animation in [&"open", &"closing", &"held"]:
			frames.add_animation(animation)
			frames.add_frame(animation, YardArt.texture("crane_chain_link"))
	var result := Burst.animated(frames, art_scale)
	result.animation = &"open"
	result.animation_finished.connect(func(): if result.animation == &"closing": result.play(&"held"))
	return result
