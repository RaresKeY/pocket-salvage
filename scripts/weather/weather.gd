extends Node
## Rolls one weather and runs its clock. Lives in the game world so it pauses with it.
const Profile = preload("res://scripts/weather/weather_profile.gd")
const DIR := "res://data/weather/"
## Each effect enables itself only for profiles that use it; adding one is a file plus a line here.
const EFFECTS := [
	preload("res://scripts/weather/effects/grip_effect.gd"),
	preload("res://scripts/weather/effects/wind_effect.gd"),
	preload("res://scripts/weather/effects/rain_effect.gd"),
	preload("res://scripts/weather/effects/fog_effect.gd"),
	preload("res://scripts/weather/effects/lightning_effect.gd"),
]
signal lightning_warning
signal lightning(x: float)
signal power_cut(seconds: float)
var profile: Profile
## 0 to 1 scale on the profile's strength, set by level events such as the storm cycle. Lightning only strikes at STRIKE_INTENSITY and above.
var intensity := 1.0
const STRIKE_INTENSITY := 0.8
var rng := RandomNumberGenerator.new()
var time := 0.0
var direction := 1.0
var direction_target := 1.0
var direction_wait := INF
var _direction_from := 1.0
var _direction_age := 0.0
var gust_level := 0.0
var _gust_in := 0.0
var _gust_age := -1.0
var _strike_in := INF
var _warned := false

## Every profile in data/weather/. list_directory follows export remaps, so adding a weather is one file.
static func profiles() -> Array:
	var found := []
	for file in ResourceLoader.list_directory(DIR):
		if file.ends_with(".tres") or file.ends_with(".res"): found.append(load(DIR + file))
	return found

static func find(id: StringName) -> Profile:
	for candidate in profiles():
		if candidate.id == id: return candidate
	return null

static func pick(list: Array, generator: RandomNumberGenerator) -> Profile:
	var total := 0.0
	for candidate in list: total += candidate.chance
	var roll := generator.randf() * total
	for candidate in list:
		roll -= candidate.chance
		if roll <= 0.0: return candidate
	return list[-1]

func configure(chosen: Profile, seed: int) -> void:
	profile = chosen
	rng.seed = seed
	direction = -1.0 if rng.randf() < 0.5 else 1.0
	direction_target = direction
	_direction_from = direction
	_direction_age = profile.direction_transition
	direction_wait = _between(profile.direction_every)
	_gust_in = _between(profile.gust_every)
	_strike_in = _between(profile.lightning_every) if profile.lightning_every != Vector2.ZERO else INF

func _between(span: Vector2) -> float:
	return rng.randf_range(span.x, span.y) if span != Vector2.ZERO else INF

## Creates the effects this profile uses, acting on `owner_context` (the round; see specs/weather.md).
func attach(owner_context: Node) -> void:
	for script in EFFECTS:
		var effect: Node = script.new()
		if not effect.applies(profile):
			effect.free()
			continue
		add_child(effect)
		effect.bind(self, owner_context)

func wind_now() -> float:
	if profile == null: return 0.0
	var value := direction * (profile.wind + profile.gust * gust_level) * intensity
	return clampf(value, -profile.wind_cap, profile.wind_cap) if profile.wind_cap > 0 else value

func _physics_process(delta: float) -> void:
	if profile == null: return
	time += delta
	_tick_direction(delta)
	_tick_gust(delta)
	_tick_lightning(delta)

## A gust builds over gust_rise, holds briefly, then eases off.
func _tick_gust(delta: float) -> void:
	if _gust_age < 0.0:
		_gust_in -= delta
		if _gust_in <= 0.0: _gust_age = 0.0
		return
	_gust_age += delta
	var rise := maxf(profile.gust_rise, 0.05)
	var hold := 0.6
	if _gust_age < rise: gust_level = _gust_age / rise
	elif _gust_age < rise + hold: gust_level = 1.0
	elif _gust_age < rise * 2.0 + hold: gust_level = 1.0 - (_gust_age - rise - hold) / rise
	else:
		gust_level = 0.0
		_gust_age = -1.0
		_gust_in = _between(profile.gust_every)

func _tick_lightning(delta: float) -> void:
	if intensity < STRIKE_INTENSITY: return
	_strike_in -= delta
	if not _warned and _strike_in <= profile.warning:
		_warned = true
		lightning_warning.emit()
	if _strike_in <= 0.0:
		_warned = false
		_strike_in = _between(profile.lightning_every)
		lightning.emit(rng.randf_range(100, 1100))
		power_cut.emit(profile.power_cut)

func _tick_direction(delta: float) -> void:
	if profile.direction_every == Vector2.ZERO: return
	if _direction_age < profile.direction_transition:
		_direction_age = minf(_direction_age + delta, profile.direction_transition)
		var blend := smoothstep(0.0, profile.direction_transition, _direction_age)
		direction = clampf(lerpf(_direction_from, direction_target, blend), -1.0, 1.0)
		return
	direction_wait -= delta
	if direction_wait <= 0.0:
		_direction_from = direction
		direction_target = -direction_target
		_direction_age = 0.0
		direction_wait = _between(profile.direction_every)

func direction_label() -> String:
	if absf(wind_now()) < 1.0: return "Wind calm"
	return "Wind left" if wind_now() < 0 else "Wind right"
