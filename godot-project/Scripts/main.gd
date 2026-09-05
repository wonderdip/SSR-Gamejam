extends Node

@onready var current_scene_container: Node = %CurrentScene

func _ready() -> void:
	SceneManager.register_container(current_scene_container)
