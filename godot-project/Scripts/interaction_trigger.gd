extends Area2D

@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var played: bool = false

func _ready() -> void:
	await get_tree().process_frame
	LevelManager.initial_player_spawn()
	
func _on_body_entered(body: Node2D) -> void:
	var player : Player = body if body is Player else null
	if player and not played:
		animation_player.play("first_interaction")
		player.movement_locked = true
		player._update_animation(false, false)
		player.animation_player.play("intro_catch")
		collision_shape_2d.set_deferred("disabled", true)
		animation_player.animation_finished.connect(_on_anim_done)
		played = true

func _on_anim_done(_anim_name: StringName):
	MessageBus.send(["What are you doing?", "Are you here to join our religion?", "If you are I'll ask you to stay in the lobby"])

func sfx(tag: String):
	AudioManager.play_sfx(tag)

func _on_room_transition_trigger_body_entered(body: Node2D) -> void:
	if body is Player:
		collision_shape_2d.set_deferred("disabled", true)
		await LevelManager.main_cam.room_transition_finished
		collision_shape_2d.set_deferred("disabled", false)
