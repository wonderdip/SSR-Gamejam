extends CharacterBody2D
class_name Player

enum Direction { DOWN, UP, LEFT, RIGHT }

@export_category("Movement")
@export var walk_speed: float = 100.0
@export var run_speed: float = 200.0
@export var walk_step_interval: float = 0.266667
@export var run_step_interval: float = 0.2

@export_category("Input")
@export var run_action: StringName = "run"

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player_sprite: Sprite2D = $PlayerSprite
@onready var gun_pos: Marker2D = $GunPos
@onready var melee_pos: Marker2D = $MeleePos

@export_category("Other")
@export var inventory: Inventory
@export var max_inventory_size: int = 3
@export var pixelate_shader: Shader

var facing: Direction = Direction.DOWN
var _is_transitioning: bool = false
var movement_locked: bool = false
var pixel_shader_material: ShaderMaterial
var _step_timer: float = 0.0

func _ready() -> void:
	pixel_shader_material = ShaderMaterial.new()
	pixel_shader_material.shader = pixelate_shader
	add_to_group("player", true)
	LevelManager.ascend_requested.connect(_on_ascending_floor)
	
func _physics_process(delta: float) -> void:
	if movement_locked:
		return

	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var is_running: bool = Input.is_action_pressed(run_action)
	
	var speed: float = run_speed if is_running else walk_speed
	velocity = input_vector.normalized() * speed
	
	move_and_slide()
	
	var is_moving: bool = input_vector != Vector2.ZERO
	if is_moving:
		facing = _direction_from_vector(input_vector)
		
	_update_animation(is_moving, is_running)
	_update_footsteps(is_moving, is_running, delta)

func _direction_from_vector(vector: Vector2) -> Direction:
	if abs(vector.x) > abs(vector.y):
		return Direction.RIGHT if vector.x > 0.0 else Direction.LEFT
	else:
		return Direction.DOWN if vector.y > 0.0 else Direction.UP

func _update_animation(is_moving: bool, is_running: bool) -> void:
	var direction_name: String = Direction.keys()[facing].capitalize()
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

func _update_footsteps(is_moving: bool, is_running: bool, delta: float) -> void:
	if not is_moving:
		_step_timer = 0.0
		return

	_step_timer -= delta
	if _step_timer <= 0.0:
		AudioManager.play_sfx("step", -20, randf_range(0.95, 1.05))
		_step_timer = run_step_interval if is_running else walk_step_interval

func _exiting_level() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	
func _entering_level(ascending: bool) -> void:
	
	if ascending:
		await _pixelate_in()
		
	movement_locked = false
	player_sprite.material = null
	_is_transitioning = false

func _on_ascending_floor():
	_pixelate_out()
	movement_locked = true
	
func _pixelate_out(duration: float = 0.5, max_pixel_size: float = 8.0) -> void:
	player_sprite.material = pixel_shader_material

	player_sprite.material.set_shader_parameter("pixel_size", 1.0)
	var tween: Tween = create_tween()
	tween.tween_method(
		func(value: float): player_sprite.material.set_shader_parameter("pixel_size", value),
		1.0, max_pixel_size, duration
	)
	await tween.finished
	
func _pixelate_in(duration: float = 0.5, max_pixel_size: float = 8.0) -> void:
	player_sprite.material = pixel_shader_material
	player_sprite.material.set_shader_parameter("pixel_size", max_pixel_size)
	var tween: Tween = create_tween()
	tween.tween_method(
		func(value: float): player_sprite.material.set_shader_parameter("pixel_size", value),
		max_pixel_size, 1.0, duration
	)
	await tween.finished
