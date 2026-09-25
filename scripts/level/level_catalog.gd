extends RefCounted
## Every playable shift as one data entry; remaining slots are placeholders, not progression rewards.
## Keys: title, weather, scrap, look (&"night" or &"blood_moon"), reversed_heads, lightning_flips_magnet,
## start_tip, rolls (profile field -> Vector2 range, rolled fresh each round) and events (paths of round-owned
## scripts with configure(context, seed); paths, because preloading them here keeps their art caches alive at exit).
## Missing keys take DEFAULTS.
const SLOT_COUNT := 12
const BLOOD_MOON := "res://scripts/level/blood_moon.gd"
const STORM_FRONT := "res://scripts/level/storm_front.gd"
const DEFAULTS := {"look": &"night", "reversed_heads": false, "lightning_flips_magnet": false, "rolls": {}, "events": [],
	"start_tip": "Magnet lifts steel. Swap to the claw at the tool stands for copper and rubber."}
const LEVELS := [
	{"title": "Clear", "weather": preload("res://data/weather/clear.tres"), "scrap": 4},
	{"title": "Breezy", "weather": preload("res://data/levels/breezy.tres"), "scrap": 6},
	{"title": "Violent", "weather": preload("res://data/levels/violent.tres"), "scrap": 10, "lightning_flips_magnet": true},
	{"title": "Blood Moon", "weather": preload("res://data/levels/blood_moon.tres"), "scrap": 12, "look": &"blood_moon",
		"reversed_heads": true, "events": [BLOOD_MOON],
		"start_tip": "Blood Moon: magnet lifts copper/rubber; claw lifts steel. Watch the generator.",
		"rolls": {"wind": Vector2(16, 40), "gust": Vector2(18, 40), "rain": Vector2(45, 120), "fog": Vector2(0.1, 0.28), "grip": Vector2(0.55, 0.85)}},
	{"title": "Storm", "weather": preload("res://data/levels/storm.tres"), "scrap": 12, "lightning_flips_magnet": true, "events": [STORM_FRONT],
		"start_tip": "Storms roll in and out. Twisters carry off light scrap, so sort it while the sky is calm."},
]

static func unlocked(index: int) -> bool:
	return index >= 0 and index < LEVELS.size()

static func get_value(index: int, key: String) -> Variant:
	assert(unlocked(index), "Locked levels cannot start")
	return LEVELS[index].get(key, DEFAULTS.get(key))

static func title(index: int) -> String:
	return get_value(index, "title") if unlocked(index) else "Locked"

static func weather(index: int) -> Resource:
	return get_value(index, "weather")

static func scrap_count(index: int) -> int:
	return get_value(index, "scrap")

static func look(index: int) -> StringName:
	return get_value(index, "look")

## The level's weather with its `rolls` fields rolled fresh; levels without rolls share their profile.
static func roll_weather(index: int, rng: RandomNumberGenerator) -> Resource:
	var rolls: Dictionary = get_value(index, "rolls")
	if rolls.is_empty(): return weather(index)
	var result = weather(index).duplicate()
	for field in rolls: result.set(field, rng.randf_range(rolls[field].x, rolls[field].y))
	return result
