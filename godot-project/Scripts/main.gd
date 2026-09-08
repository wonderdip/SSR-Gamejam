extends Node

@onready var current_scene_container: Node = %CurrentScene
@onready var hud: CanvasLayer = $HUD
@onready var pause_menu: CanvasLayer = $PauseMenu

func _ready() -> void:
	SceneManager.register_container(current_scene_container)
	SceneManager.scene_changed.connect(_on_main_scene_changed)
	SceneManager.scene_removed.connect(_on_main_scene_removed)
	
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape") and not event.is_echo():
		pause_menu.show()

func _on_main_scene_changed(scene: Node):
	if scene is Room:
		hud.show()
	if scene.name == "TitleScreen": hud.hide()
	

func _on_main_scene_removed():
	hud.show()
