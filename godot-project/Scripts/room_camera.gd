extends DynamicCamera
class_name RoomCamera

## Adds room-to-room panning and floor-change snapping on top of
## DynamicCamera's screen shake.

@export_category("Transition")
@export var transition_duration: float = 0.6
@export var transition_trans_type: Tween.TransitionType = Tween.TRANS_SINE
@export var transition_ease_type: Tween.EaseType = Tween.EASE_IN_OUT

signal room_transition_started(target_position: Vector2)
signal room_transition_finished(target_position: Vector2)

const _LIMIT_MIN := -10000000
const _LIMIT_MAX := 10000000

var _active_tween: Tween
var player: Player

func _ready() -> void:
	super._ready()
	add_to_group(&"room_camera")

func transition_to_room(target_position: Vector2, bounds: Rect2 = Rect2()) -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()

	# Lift limits for the duration of the tween — Camera2D clamps position to
	# the current limits every frame, so applying the target room's (likely
	# narrower) bounds now would clamp the camera there instantly instead of
	# letting it pan.
	limit_left = _LIMIT_MIN
	limit_top = _LIMIT_MIN
	limit_right = _LIMIT_MAX
	limit_bottom = _LIMIT_MAX

	room_transition_started.emit(target_position)

	_active_tween = create_tween()
	_active_tween.set_trans(transition_trans_type)
	_active_tween.set_ease(transition_ease_type)
	_active_tween.tween_property(self, "global_position", target_position, transition_duration)
	_active_tween.finished.connect(_on_transition_finished.bind(target_position, bounds))
	player.movement_locked = true
	
func _on_transition_finished(target_position: Vector2, bounds: Rect2) -> void:
	_apply_bounds(bounds)
	room_transition_finished.emit(target_position)
	player.movement_locked = false
## Instantly places the camera with no tween — used right after a floor is
## (re)built, where there's nothing meaningful to pan from.
func snap_to_room(target_position: Vector2, bounds: Rect2) -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	global_position = target_position
	_apply_bounds(bounds)

func _apply_bounds(bounds: Rect2) -> void:
	if bounds.size == Vector2.ZERO:
		return
	limit_left = int(bounds.position.x)
	limit_top = int(bounds.position.y)
	limit_right = int(bounds.position.x + bounds.size.x)
	limit_bottom = int(bounds.position.y + bounds.size.y)
