extends RefCounted
## Shared normalized input contract; only physical analog sticks have a deadzone.
const DEADZONE := 0.2
const SPEED := Vector2(220, 130)

static func analog(value: Vector2, deadzone: float = 0.0) -> Vector2:
	var strength := minf(value.length(), 1.0)
	if strength <= deadzone: return Vector2.ZERO
	return value.normalized() * (strength - deadzone) / (1.0 - deadzone)

static func combine(digital: Vector2, stick: Vector2, touch: Vector2) -> Vector2:
	# Strongest axis wins: holding two input devices must not amplify their speed.
	var result := digital.clamp(-Vector2.ONE, Vector2.ONE)
	for value in [analog(stick, DEADZONE), analog(touch)]:
		if absf(value.x) > absf(result.x): result.x = value.x
		if absf(value.y) > absf(result.y): result.y = value.y
	return result

static func velocity(value: Vector2) -> Vector2:
	return value.clamp(-Vector2.ONE, Vector2.ONE) * SPEED
