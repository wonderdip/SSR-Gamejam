extends Node2D

@onready var room_container: Node2D = %RoomContainer

func _ready() -> void:
	LevelManager.register_container(room_container)
