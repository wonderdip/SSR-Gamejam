extends Area2D
class_name LevelTrigger

@export var direction : SceneManager.TRIGGERDIRECTION
@export var forced_room: PackedScene
@export var first_level_trigger: bool = false
@export var ascend_trigger: bool = false

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
			SceneManager.goto_scene("res://Scenes/World/starting_room.tscn")
		else:
			SceneManager.exiting_level.emit(direction, ascend_trigger, forced_room)
