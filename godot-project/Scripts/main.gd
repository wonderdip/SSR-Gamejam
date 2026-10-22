extends Node

@onready var current_scene_container: Node = %CurrentScene
@onready var hud: CanvasLayer = $HUD
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var inventory: CanvasLayer = $Inventory


func _ready() -> void:
	SceneManager.register_container(current_scene_container)
	SceneManager.scene_changed.connect(_on_main_scene_changed)
	SceneManager.scene_removed.connect(_on_main_scene_removed)
	hud.update()
	
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape") and not event.is_echo():
		if SceneManager.current_scene:
			if SceneManager.current_scene.name != "TitleScreen":
				pause_menu.show()
		elif SceneManager.current_scene == null:
			pause_menu.show()
	if event.is_action_pressed("inventory") and not event.is_echo():
		if SceneManager.player.inventory.unique_items.has(load("res://Resources/Items/sciontology_101.tres")):
			inventory.show()
	
func _on_main_scene_changed(scene: Node):
	if scene is Room:
		hud.update()
	if scene.name == "TitleScreen": hud.update()
	
func _on_main_scene_removed():
	hud.update()
