extends Node

@onready var current_scene_container: Node = %CurrentScene
@onready var hud: CanvasLayer = $HUD
@onready var pause_menu: CanvasLayer = $PauseMenu

func _ready() -> void:
	SceneManager.register_container(current_scene_container)
	
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape") and not event.is_echo():
		pause_menu.show()
