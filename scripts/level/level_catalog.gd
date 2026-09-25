extends RefCounted
## The first three playable shifts; remaining slots are placeholders, not progression rewards.
const SLOT_COUNT := 12
const TITLES := ["Clear", "Breezy", "Violent"]
const PROFILES := [
	preload("res://data/weather/clear.tres"),
	preload("res://data/levels/breezy.tres"),
	preload("res://data/levels/violent.tres"),
]

static func unlocked(index: int) -> bool:
	return index >= 0 and index < PROFILES.size()

static func title(index: int) -> String:
	return TITLES[index] if unlocked(index) else "Locked"

static func weather(index: int) -> Resource:
	assert(unlocked(index), "Locked levels cannot start")
	return PROFILES[index]
