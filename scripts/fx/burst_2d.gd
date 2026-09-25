extends AnimatedSprite2D
## One-shot effect built from numbered 8× frames (`<prefix>_01.png`…); frees itself when done.
const YardArt = preload("res://scripts/art/yard_art.gd")
static var _cache: Dictionary = {}

static func frames_for(prefix: String) -> SpriteFrames:
	if not _cache.has(prefix):
		var result := SpriteFrames.new()
		add_frames(result, &"default", prefix, frame_numbers(prefix), 16.0, false)
		_cache[prefix] = result
	return _cache[prefix]

static func add_frames(frames: SpriteFrames, animation: StringName, prefix: String, numbers: Array, fps: float, loop: bool) -> void:
	if not frames.has_animation(animation): frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, loop)
	for number in numbers:
		frames.add_frame(animation, YardArt.texture("%s_%02d" % [prefix, number]))

static func frame_numbers(prefix: String) -> Array:
	var numbers := []
	while YardArt.exists("%s_%02d" % [prefix, numbers.size() + 1]):
		numbers.append(numbers.size() + 1)
	return numbers

func _init(prefix: String = "fx_sparks", at: Vector2 = Vector2.ZERO, world_per_pixel: float = 1.0) -> void:
	sprite_frames = frames_for(prefix)
	position = at
	YardArt.fit(self, world_per_pixel)
	animation_finished.connect(queue_free)

func _ready() -> void:
	play()
