extends CharacterBody2D
class_name Enemy

signal died(enemy: Enemy)
signal damaged(amount: int)

@export var enemy_name: String = ""
@export var health: float = 100
@export var damage: float = 10
@export var attack_speed: float = 0.5
@export var speed: float = 80
@export var knockback: int = 100
@export var knockback_resistance: float = 0.0  # 0 = full knockback, 1 = immune
@export var knockback_friction: float = 600.0  # how fast the push fades (px/s²)
@export var no_knockback: bool = false

@export var movement: MovementTypes
@export var weapon: AttackTypes
@export var attack_range: float = 50
@export var sprite: Sprite2D
@export var animation_player: AnimationPlayer
@export var explosion_area: Area2D
@export var boss: bool = false

var flash_shader: Shader = preload("res://Shader/hit_flash.gdshader")

enum AttackTypes { GUN, MELEE }
enum MovementTypes { PLAYER, RANDOM, FAR, IDLE, SUICIDE }

var floor_multiplier: float = 1.0
var max_health: float
var player_ref: Player
var random_target: Vector2
var random_timer: float = 0.0

var knockback_velocity := Vector2.ZERO
var exploding := false
var has_hit := false
var can_attack := true
var movement_locked: bool = true

func _ready() -> void:
	max_health = health
	player_ref = SceneManager.player
	_pick_random_target()
	
	sprite.material = ShaderMaterial.new()
	sprite.material.shader = flash_shader
	
	if explosion_area:
		animation_player.play("RESET")
		explosion_area.get_node("CollisionShape2D").shape.radius = 10
		
		explosion_area.body_entered.connect(_on_explosion_body_entered)
	
	player_ref.death_anim_started.connect(_on_player_death)
	if animation_player.has_animation("spawn"): animation_player.play("spawn")
	await animation_player.animation_finished
	movement_locked = false
	
func _physics_process(delta: float) -> void:
	if exploding or movement_locked:
		return

	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)

	var move_velocity := _get_movement_velocity(delta)
	velocity = move_velocity + knockback_velocity
	
	if not (velocity.is_finite() and global_position.is_finite()):
		push_error("%s bad state: vel=%s pos=%s kb=%s move=%s" % [name, velocity, global_position, knockback_velocity, move_velocity])
		velocity = Vector2.ZERO
		knockback_velocity = Vector2.ZERO
	
	move_and_slide()
	_update_facing(move_velocity)
	
	
	if movement == MovementTypes.SUICIDE and player_ref \
			and global_position.distance_to(_player_center()) <= attack_range:
		die()
		return
	
	if weapon == AttackTypes.MELEE and can_attack and is_instance_valid(player_ref) \
			and global_position.distance_to(_player_center()) <= attack_range:
		
		attack()
		
	
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
	return global_position.direction_to(_player_center()) * speed * floor_multiplier

func _flee_player() -> Vector2:
	if not player_ref:
		return Vector2.ZERO
	return global_position.direction_to(_player_center()) * speed * floor_multiplier

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
	if no_knockback or not direction.is_finite():
		return
	if direction.is_zero_approx():
		direction = Vector2.from_angle(randf() * TAU)
	knockback_velocity = direction.normalized() * force * (1.0 - knockback_resistance)

func take_damage(amount: float, knockback_dir: Vector2 = Vector2.ZERO, knockback_force: float = 0.0) -> void:
	health -= amount
	damaged.emit(amount)
	
	if knockback_force > 0.0:
		apply_knockback(knockback_dir, knockback_force)
		
	ScreenSfx.cam_shake(2, 1, 0.2)
	ScreenSfx.framefreeze(0.035, 0)
	
	sprite.material.set_shader_parameter("active", true)
	
	if animation_player and animation_player.has_animation("hit"):
		animation_player.play("hit")
		
	if health <= 0:
		die()
		
	await get_tree().create_timer(0.1).timeout
	sprite.material.set_shader_parameter("active", false)

func _on_player_death():
	queue_free()

func die() -> void:
	if exploding:
		return
		
	exploding = true
	died.emit(self)
	
	player_ref.enemies_killed += 1
	
	if movement == MovementTypes.SUICIDE:
		_explode()
		ScreenSfx.framefreeze(0.08, 0)
		if animation_player.has_animation("explode"):
			animation_player.play("explode")
			await animation_player.animation_finished
	
	queue_free()

func _explode() -> void:
	$CollisionShape2D.set_deferred("disabled", true)
	
	AudioManager.play_sfx("explosion", -5, randf_range(0.95, 1.05))
	ScreenSfx.cam_shake(15, 5, 0.5)
	
	if explosion_area:
		explosion_area.set_deferred("monitoring", true)

func _on_explosion_body_entered(body: Node2D) -> void:
	if has_hit or not body is Player:
		return
	has_hit = true
	attack()


func attack() -> void:
	can_attack = false
	if player_ref.has_method("take_damage"):
		player_ref.take_damage(damage, global_position, knockback)

	await get_tree().create_timer(attack_speed).timeout
	if is_instance_valid(self):
		can_attack = true

func _player_center() -> Vector2:
	return player_ref.center() if is_instance_valid(player_ref) else global_position
