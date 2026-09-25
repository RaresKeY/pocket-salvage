extends AnimatedSprite2D
## One-shot effect built from numbered 8× frames (`<prefix>_01.png`…); frees itself when done.
const ART := "res://assets/bitwright_8x/"
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
		frames.add_frame(animation, load(ART + "%s_%02d.png" % [prefix, number]))

static func frame_numbers(prefix: String) -> Array:
	var numbers := []
	while ResourceLoader.exists(ART + "%s_%02d.png" % [prefix, numbers.size() + 1]):
		numbers.append(numbers.size() + 1)
	return numbers

func _init(prefix: String = "fx_sparks", at: Vector2 = Vector2.ZERO, world_per_pixel: float = 1.0) -> void:
	sprite_frames = frames_for(prefix)
	position = at
	scale = Vector2.ONE * world_per_pixel / 8.0
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	animation_finished.connect(queue_free)

func _ready() -> void:
	play()
