extends Area2D
class_name RoomTransitionTrigger

@export_category("Target Room")
@export var target_room: Room ## ignored when ascend_trigger is true
@export var direction: LevelManager.TRIGGERDIRECTION = LevelManager.TRIGGERDIRECTION.DOWN
@export var ascend_trigger: bool = false

@export_category("Trigger")
@export var one_shot: bool = false
var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _triggered and one_shot:
		return
	if not body is Player:
		return

	var player: Player = body
	player._exiting_level()
	await get_tree().create_timer(0.25).timeout

	if ascend_trigger:
		_triggered = true
		LevelManager.ascend_requested.emit()
		return

	if target_room == null:
		push_warning("RoomTransitionTrigger: target_room is not set on %s" % name)
		return

	var camera := get_tree().get_first_node_in_group(&"room_camera") as RoomCamera
	if camera == null:
		push_warning("RoomTransitionTrigger: no node in the 'room_camera' group was found.")
		return

	_triggered = true
	camera.player = player
	camera.transition_to_room(target_room.get_room_center(), target_room.get_room_rect())
	
	await camera.room_transition_finished
	player._entering_level(false)
	LevelManager.set_player_room(target_room)
