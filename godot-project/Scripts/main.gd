extends Node

@onready var current_scene_container: Node = %CurrentScene
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	SceneManager.register_container(current_scene_container)
	hud.hide()
	SceneManager.gameloop_started.connect(_on_gameloop_started)
	
func _on_gameloop_started():
	hud.show()
