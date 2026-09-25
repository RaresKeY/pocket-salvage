extends RefCounted
## The first four playable shifts; remaining slots are placeholders, not progression rewards.
const SLOT_COUNT := 12
const SCRAP_COUNTS := [4, 6, 10, 12]
const TITLES := ["Clear", "Breezy", "Violent", "Blood Moon"]
const PROFILES := [
	preload("res://data/weather/clear.tres"),
	preload("res://data/levels/breezy.tres"),
	preload("res://data/levels/violent.tres"),
	preload("res://data/levels/blood_moon.tres"),
]

static func unlocked(index: int) -> bool:
	return index >= 0 and index < PROFILES.size()

static func title(index: int) -> String:
	return TITLES[index] if unlocked(index) else "Locked"

static func weather(index: int) -> Resource:
	assert(unlocked(index), "Locked levels cannot start")
	return PROFILES[index]

static func roll_weather(index: int, rng: RandomNumberGenerator) -> Resource:
	if index != 3: return weather(index)
	var result = weather(index).duplicate()
	result.wind = rng.randf_range(16, 40)
	result.gust = rng.randf_range(18, 40)
	result.rain = rng.randf_range(45, 120)
	result.fog = rng.randf_range(0.1, 0.28)
	result.grip = rng.randf_range(0.55, 0.85)
	return result

static func scrap_count(index: int) -> int:
	assert(unlocked(index), "Locked levels have no scrap")
	return SCRAP_COUNTS[index]
