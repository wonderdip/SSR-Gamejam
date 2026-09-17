extends CharacterBody2D
class_name Enemy

signal died(enemy: Enemy)

@export var enemy_name: String = ""
@export var health: float = 100
@export var damage: float = 10
@export var speed: float = 80
@export var movement: MovementTypes
@export var weapon: AttackTypes

@export var sprite: Sprite2D
@export var animation_player: AnimationPlayer

enum AttackTypes { GUN, MELEE }
enum MovementTypes { PLAYER, RANDOM, FAR, IDLE }

var floor_multiplier: float = 1.0
var max_health: float
var player_ref: Node2D
var random_target: Vector2
var random_timer: float = 0.0

func _ready() -> void:
	max_health = health
	player_ref = get_tree().get_first_node_in_group("player")
	_pick_random_target()

func _physics_process(delta: float) -> void:
	velocity = _get_movement_velocity(delta)
	move_and_slide()
	_update_facing()

	if velocity.length() > 0.1:
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

func _update_facing() -> void:
	if sprite and velocity.length() > 0.1:
		sprite.flip_h = velocity.x < 0

func take_damage(amount: float) -> void:
	health -= amount
	if animation_player and animation_player.has_animation("hit"):
		animation_player.play("hit")
	if health <= 0:
		die()

func die() -> void:
	died.emit(self)
	queue_free()
