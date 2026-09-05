extends CharacterBody2D
class_name Player

enum Direction { DOWN, UP, LEFT, RIGHT }

@export_category("Movement")
@export var walk_speed: float = 100.0
@export var run_speed: float = 200.0

@export_category("Input")
@export var run_action: StringName = "run"

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _facing: Direction = Direction.DOWN

func _physics_process(_delta: float) -> void:
	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var is_running: bool = Input.is_action_pressed(run_action)
	var speed: float = run_speed if is_running else walk_speed

	velocity = input_vector.normalized() * speed
	move_and_slide()

	var is_moving: bool = input_vector != Vector2.ZERO
	if is_moving:
		_facing = _direction_from_vector(input_vector)

	_update_animation(is_moving, is_running)

func _direction_from_vector(vector: Vector2) -> Direction:
	if abs(vector.x) > abs(vector.y):
		return Direction.RIGHT if vector.x > 0.0 else Direction.LEFT
	else:
		return Direction.DOWN if vector.y > 0.0 else Direction.UP

func _update_animation(is_moving: bool, is_running: bool) -> void:
	var direction_name: String = Direction.keys()[_facing].capitalize()

	var state_name: String
	if not is_moving:
		state_name = "Idle"
	elif is_running:
		state_name = "Run"
	else:
		state_name = "Walk"

	var anim_name: String = state_name + direction_name

	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)
