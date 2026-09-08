extends Node2D

@onready var room_container: Node2D = %RoomContainer
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

func _ready() -> void:
	LevelManager.register_container(room_container)
	SceneManager.scene_changed.connect(_on_main_scene_changed)
	SceneManager.scene_removed.connect(_main_scene_removed)
	canvas_modulate.hide()
		
func _on_main_scene_changed(scene: Node):
	if scene:
		if scene is Room or scene.name == "DeliveryScene":
			canvas_modulate.show()
		else:
			canvas_modulate.hide()

func _main_scene_removed():
	canvas_modulate.show()
		
		
