extends Area2D
class_name LevelTrigger

@export var direction : LevelManager.TRIGGERDIRECTION
@export var first_level_trigger: bool = false
@export var ascend_trigger: bool = false
@export var warning: bool = false
@export_multiline() var warning_msg: String = ""

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var locked: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node2D):
	if body is Player:
		body._exiting_level()
		await get_tree().create_timer(0.25).timeout
		
		if first_level_trigger:
			LevelManager.in_dungeon = false
			LevelManager.game_started = true
			LevelManager.main_cam.set_enabled(false)
			SceneManager.goto_scene("res://Scenes/World/starting_room.tscn")
		else:
			if warning:
				MessageBus.send([warning_msg])
				LevelManager.main_cam.add_trauma(2)
				await MessageBus.message_box_closed
				
			LevelManager.ascend_requested.emit()
			print("ascending")
		locked = true
