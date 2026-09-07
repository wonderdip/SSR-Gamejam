extends Node

@onready var current_scene_container: Node = %CurrentScene
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	SceneManager.register_container(current_scene_container)
	
