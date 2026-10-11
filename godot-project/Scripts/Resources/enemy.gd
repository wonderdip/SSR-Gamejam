extends CharacterBody2D
class_name Enemy

signal died(enemy: Enemy)

@export var enemy_name: String = ""
@export var health: float = 100
@export var damage: float = 10
@export var speed: float = 80
@export var knockback_resistance: float = 0.0  # 0 = full knockback, 1 = immune
@export var knockback_friction: float = 600.0  # how fast the push fades (px/s²)

@export var movement: MovementTypes
@export var weapon: AttackTypes

@export var sprite: Sprite2D
@export var animation_player: AnimationPlayer

var flash_shader: Shader = preload("res://Shader/hit_flash.gdshader")

enum AttackTypes { GUN, MELEE }
enum MovementTypes { PLAYER, RANDOM, FAR, IDLE }

var floor_multiplier: float = 1.0
var max_health: float
var player_ref: Node2D
var random_target: Vector2
var random_timer: float = 0.0

var knockback_velocity := Vector2.ZERO

func _ready() -> void:
	max_health = health
	player_ref = get_tree().get_first_node_in_group("player")
	_pick_random_target()
	
	sprite.material = ShaderMaterial.new()
	sprite.material.shader = flash_shader
	
func _physics_process(delta: float) -> void:
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)

	var move_velocity := _get_movement_velocity(delta)
	velocity = move_velocity + knockback_velocity
	move_and_slide()
	_update_facing(move_velocity)

	if move_velocity.length() > 0.1:
		animation_player.play("walk")
	else:
		animation_player.play("idle")

func _get_movement_velocity(delta: float) -> Vector2:
	match movement:
		MovementTypes.PLAYER:
			return _seek_player()
		MovementTypes.FAR:
			return _flee_player()
		MovementTypes.RANDOM:
			return _wander(delta)
		MovementTypes.IDLE:
			return Vector2.ZERO
		_:
			return Vector2.ZERO

func _seek_player() -> Vector2:
	if not player_ref:
		return Vector2.ZERO
	return global_position.direction_to(player_ref.global_position) * speed * floor_multiplier

func _flee_player() -> Vector2:
	if not player_ref:
		return Vector2.ZERO
	return player_ref.global_position.direction_to(global_position) * speed * floor_multiplier

func _wander(delta: float) -> Vector2:
	random_timer -= delta
	if random_timer <= 0.0 or global_position.distance_to(random_target) < 8.0:
		_pick_random_target()
	return global_position.direction_to(random_target) * speed * floor_multiplier

func _pick_random_target() -> void:
	random_target = global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
	random_timer = randf_range(1.0, 3.0)

func _update_facing(move_velocity: Vector2) -> void:
	if sprite and move_velocity.length() > 0.1:
		sprite.flip_h = move_velocity.x < 0

func apply_knockback(direction: Vector2, force: float) -> void:
	knockback_velocity = direction.normalized() * force * (1.0 - knockback_resistance)

func take_damage(amount: float, knockback_dir: Vector2 = Vector2.ZERO, knockback_force: float = 0.0) -> void:
	health -= amount
	if knockback_force > 0.0:
		apply_knockback(knockback_dir, knockback_force)
	ScreenSfx.cam_shake(2, 1, 0.2)
	sprite.material.set_shader_parameter("active", true)
	
	if animation_player and animation_player.has_animation("hit"):
		animation_player.play("hit")
		
	if health <= 0:
		die()
		
	await get_tree().create_timer(0.1).timeout
	sprite.material.set_shader_parameter("active", false)
	
func die() -> void:
	died.emit(self)
	queue_free()
