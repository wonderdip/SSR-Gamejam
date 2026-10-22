extends CharacterBody2D
class_name Player

signal player_died

enum Direction { DOWN, UP, LEFT, RIGHT }

@export var max_health: int = 100

@export_category("Movement")
@export var walk_speed: float = 100.0
@export var run_speed: float = 200.0
@export var walk_step_interval: float = 0.266667
@export var run_step_interval: float = 0.2

@export_category("Knockback")
@export var knockback_friction: float = 900.0
@export var knockback_lock_time: float = 0.12  # brief loss of control so the push reads

var knockback_velocity := Vector2.ZERO
var _knockback_lock := 0.0

@export_category("Input")
@export var run_action: StringName = "run"

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player_sprite: Sprite2D = $PlayerSprite
@onready var gun_pos: Marker2D = $GunPos
@onready var melee_pos: Marker2D = $MeleePos
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var blood: ColorRect = $CanvasLayer/Blood
@onready var blood_particles: GPUParticles2D = $BloodParticles

@export_category("Other")
@export var inventory: Inventory
@export var pixelate_shader: Shader
@export var hit_flash_shader: Shader

var facing: Direction = Direction.DOWN
var _is_transitioning: bool = false
var movement_locked: bool = false
var pixel_shader_material: ShaderMaterial
var flash_shader_material: ShaderMaterial
var current_health: int
var _step_timer: float = 0.0
var _blood_tween: Tween
var _blood_on := false

var enemies_killed: int = 0
var chests_looted: int = 0
var dead: bool = false

func _ready() -> void:
	pixel_shader_material = ShaderMaterial.new()
	pixel_shader_material.shader = pixelate_shader
	
	flash_shader_material = ShaderMaterial.new()
	flash_shader_material.shader = hit_flash_shader
	
	add_to_group("player", true)
	LevelManager.ascend_requested.connect(_on_ascending_floor)
	
	current_health = max_health
	blood.hide()
	animation_player.play("RESET")

func reset() -> void:
	current_health = max_health
	movement_locked = false
	set_physics_process(true)
	body_shape.set_deferred("disabled", false)

	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	_knockback_lock = 0.0
	_is_transitioning = false
	player_sprite.material = null

	# blood overlay back to its starting look
	if _blood_tween:
		_blood_tween.kill()
	_blood_on = false
	var mat := blood.material as ShaderMaterial
	mat.set_shader_parameter("radius", 0.67)
	mat.set_shader_parameter("softness", 1.345)
	blood.hide()

	animation_player.play("RESET")
	await animation_player.animation_finished
	animation_player.play("IdleDown")
	inventory._remove_gun()
	inventory._remove_melee()
	inventory.anomalies.clear()
	inventory.consumables.clear()
	enemies_killed = 0
	chests_looted = 0
	dead = false
	
func _physics_process(delta: float) -> void:
	assert(global_position.is_finite() and knockback_velocity.is_finite(), "player pos=%s kb=%s" % [global_position, knockback_velocity])
	if movement_locked:
		return

	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	_knockback_lock = max(_knockback_lock - delta, 0.0)

	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var is_running: bool = Input.is_action_pressed(run_action)

	var speed: float = run_speed if is_running else walk_speed
	var move_velocity := Vector2.ZERO if _knockback_lock > 0.0 else input_vector.normalized() * speed
	velocity = move_velocity + knockback_velocity

	move_and_slide()

	var is_moving: bool = input_vector != Vector2.ZERO and _knockback_lock <= 0.0
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

func take_damage(amount: int, source_pos: Vector2 = Vector2.INF, force: float = 0.0) -> void:
	current_health -= amount
	blood_particles.restart()
	_set_blood(current_health <= 50)
		
	if force > 0.0 and source_pos.is_finite():
		var dir := (center() - source_pos).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.DOWN
		knockback_velocity = dir * force
		_knockback_lock = knockback_lock_time
	
	player_sprite.material = flash_shader_material
	player_sprite.material.set_shader_parameter("active", true)
	
	ScreenSfx.framefreeze(0.08, 0)
	ScreenSfx.cam_shake(2, 1, 0.2)
	
	await get_tree().create_timer(0.1).timeout
	player_sprite.material.set_shader_parameter("active", false)
	player_sprite.material = null
	
	if current_health <= 0:
		die()

func _set_blood(on: bool) -> void:
	if on == _blood_on:
		return
	_blood_on = on
	if _blood_tween:
		_blood_tween.kill()
	var mat := blood.material as ShaderMaterial
	mat.set_shader_parameter("softness", 1.345)
	_blood_tween = create_tween()
	if on:
		mat.set_shader_parameter("radius", 0.67)
		blood.show()
		_blood_tween.tween_property(mat, "shader_parameter/radius", 0.0, 1.0)
	else:
		_blood_tween.tween_property(mat, "shader_parameter/radius", 0.67, 1.0)
		_blood_tween.tween_callback(blood.hide)

func die() -> void:
	if dead:
		return
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	movement_locked = true
	velocity = Vector2.ZERO
	dead = true
	var cam := get_viewport().get_camera_2d()
	var center := cam.get_screen_center_position() - Vector2(8, 8)
	
	var mat := blood.material as ShaderMaterial
	mat.set_shader_parameter("radius", 0.67)
	mat.set_shader_parameter("softness", 1.345)
	var t := create_tween()
	
	if _blood_tween:
		_blood_tween.kill()
	
	blood.show()
	t.set_parallel()
	t.tween_property(mat, "shader_parameter/radius", 0.0, 1.0)
	
	t.tween_property(self, "global_position", center, 1.2)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
	t.set_parallel(false)
	
	t.tween_callback(animation_player.play.bind("Died"))
	
	t.tween_property(mat, "shader_parameter/softness", 0.3, 2)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(0.3)
		
	await t.finished
	player_died.emit()
	
func center() -> Vector2:
	return body_shape.global_position

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("take_damage") and not event.is_echo():
		take_damage(100, Vector2.ONE, 0.5)
