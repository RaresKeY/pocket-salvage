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
]
signal lightning_warning
signal lightning(x: float)
signal power_cut(seconds: float)
var profile: Profile
var rng := RandomNumberGenerator.new()
var time := 0.0
var direction := 1.0
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
	return direction * (profile.wind + profile.gust * gust_level) if profile else 0.0

func _physics_process(delta: float) -> void:
	if profile == null: return
	time += delta
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
	_strike_in -= delta
	if not _warned and _strike_in <= profile.warning:
		_warned = true
		lightning_warning.emit()
	if _strike_in <= 0.0:
		_warned = false
		_strike_in = _between(profile.lightning_every)
		lightning.emit(rng.randf_range(100, 1100))
		power_cut.emit(profile.power_cut)
