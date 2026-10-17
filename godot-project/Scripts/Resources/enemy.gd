extends CharacterBody2D
class_name Enemy

signal died(enemy: Enemy)
signal damaged(amount: int)

@export var enemy_name: String = ""
@export var health: float = 100
@export var damage: float = 10
@export var speed: float = 80
@export var knockback_resistance: float = 0.0  # 0 = full knockback, 1 = immune
@export var knockback_friction: float = 600.0  # how fast the push fades (px/s²)
@export var no_knockback: bool = false

@export var movement: MovementTypes
@export var weapon: AttackTypes
@export var attack_range: float = 50
@export var sprite: Sprite2D
@export var animation_player: AnimationPlayer
@export var explosion_area: Area2D

var flash_shader: Shader = preload("res://Shader/hit_flash.gdshader")

enum AttackTypes { GUN, MELEE }
enum MovementTypes { PLAYER, RANDOM, FAR, IDLE, SUICIDE }

var floor_multiplier: float = 1.0
var max_health: float
var player_ref: Node2D
var random_target: Vector2
var random_timer: float = 0.0

var knockback_velocity := Vector2.ZERO
var exploding := false
var has_hit := false

func _ready() -> void:
	max_health = health
	player_ref = get_tree().get_first_node_in_group("player")
	_pick_random_target()
	
	sprite.material = ShaderMaterial.new()
	sprite.material.shader = flash_shader
	
	if explosion_area:
		explosion_area.body_entered.connect(_on_explosion_body_entered)
		
func _physics_process(delta: float) -> void:
	if exploding:
		return  # frozen while the explode animation plays

	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)

	var move_velocity := _get_movement_velocity(delta)
	velocity = move_velocity + knockback_velocity
	move_and_slide()
	_update_facing(move_velocity)

	if movement == MovementTypes.SUICIDE and player_ref \
			and global_position.distance_to(player_ref.global_position) <= attack_range:
		die()
		return

	if move_velocity.length() > 0.1:
		if animation_player.has_animation("walk"): animation_player.play("walk")
	else:
		if animation_player.has_animation("idle"): animation_player.play("idle")

func _get_movement_velocity(delta: float) -> Vector2:
	match movement:
		MovementTypes.PLAYER, MovementTypes.SUICIDE:
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
	if no_knockback:
		return
	knockback_velocity = direction.normalized() * force * (1.0 - knockback_resistance)

func take_damage(amount: float, knockback_dir: Vector2 = Vector2.ZERO, knockback_force: float = 0.0) -> void:
	health -= amount
	damaged.emit(amount)
	
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
	if exploding:
		return
	exploding = true
	died.emit(self)

	if movement == MovementTypes.SUICIDE:
		_explode()
		if animation_player.has_animation("explode"):
			animation_player.play("explode")
			await animation_player.animation_finished

	queue_free()

func _explode() -> void:
	$CollisionShape2D.set_deferred("disabled", true)
	ScreenSfx.cam_shake(6, 2, 0.3)
	if explosion_area:
		explosion_area.set_deferred("monitoring", true)

func _on_explosion_body_entered(body: Node2D) -> void:
	if has_hit or not body is Player:
		return
	has_hit = true
	if body.has_method("take_damage"):
		body.take_damage(damage)
