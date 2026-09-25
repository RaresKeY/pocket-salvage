class_name SalvageRound
extends Node
## Manually clocked round state; callers own scene, pause and body lifecycle.
signal changed
signal finished(reason: StringName)

enum Delivery { IGNORED, CORRECT, WRONG }
const CORRECT_POINTS := 100
const WRONG_PENALTY := 25
const TIME_BONUS_PER_SECOND := 5

var duration: float = 90.0
var total_items: int = 0
var state: StringName = &"ready"
var score: int = 0
var remaining_time: float = 90.0
var correct_count: int = 0
var wrong_count: int = 0
var delivered_count: int = 0
var time_bonus: int = 0
var _delivered: Dictionary = {}

func configure(seconds: float = 90.0, item_count: int = 0) -> void:
	duration = maxf(seconds, 0.0)
	total_items = maxi(item_count, 0)
	state = &"ready"
	_reset()
	changed.emit()

func _reset() -> void:
	score = 0
	remaining_time = duration
	correct_count = 0
	wrong_count = 0
	delivered_count = 0
	time_bonus = 0
	_delivered.clear()

func start() -> void:
	_reset()
	state = &"running"
	changed.emit()
	if remaining_time <= 0.0:
		finish(&"timeout")

func tick(delta: float) -> void:
	if state != &"running" or delta <= 0.0 or not is_finite(delta):
		return
	remaining_time = maxf(remaining_time - delta, 0.0)
	if remaining_time <= 0.0:
		finish(&"timeout")
	else:
		changed.emit()

func set_paused(value: bool) -> void:
	if value and state == &"running":
		state = &"paused"
		changed.emit()
	elif not value and state == &"paused":
		state = &"running"
		changed.emit()

func accept_delivery(item_id: int, material: StringName, bin_material: StringName) -> Delivery:
	if state != &"running" or _delivered.has(item_id):
		return Delivery.IGNORED
	if material != bin_material:
		wrong_count += 1
		score -= WRONG_PENALTY
		changed.emit()
		return Delivery.WRONG
	_delivered[item_id] = true
	delivered_count += 1
	correct_count += 1
	score += CORRECT_POINTS
	changed.emit()
	if total_items > 0 and delivered_count >= total_items:
		time_bonus = ceili(remaining_time) * TIME_BONUS_PER_SECOND
		score += time_bonus
		finish(&"all_sorted")
	return Delivery.CORRECT

func finish(reason: StringName = &"manual") -> void:
	if state != &"running" and state != &"paused":
		return
	state = &"finished"
	changed.emit()
	finished.emit(reason)
