extends Node

@onready var current_scene_container: Node = %CurrentScene
@onready var hud: CanvasLayer = $HUD
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var inventory: CanvasLayer = $Inventory
@onready var dungeon_root: Node2D = $DungeonRoot


func _ready() -> void:
	SceneManager.register_container(current_scene_container)
	SceneManager.scene_changed.connect(_on_main_scene_changed)
	SceneManager.scene_removed.connect(_on_main_scene_removed)
	hud.update()
	
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape") and not event.is_echo():
		var scene: Node = SceneManager.current_scene
		if scene != null:
			if scene.name == "TitleScreen":
				return
			elif scene.name == "GameOver":
				return
			elif scene.name == "AscensionScene":
				return
			elif scene.name == "StartingRoom" and SceneManager.player.dead:
				return
				
			pause_menu.show()
		elif scene == null and not SceneManager.player.dead:
			pause_menu.show()
			
			
	if event.is_action_pressed("inventory") and not event.is_echo():
		if SceneManager.player.inventory.unique_items.has(load("res://Resources/Items/sciontology_101.tres")):
			inventory.show()
	
func _on_main_scene_changed(scene: Node):
	if scene is Room:
		hud.update()
	if scene.name == "TitleScreen": 
		scene.restart_game.connect(restart_game)
		hud.hide_all()
		dungeon_root.process_mode = Node.PROCESS_MODE_DISABLED
	if scene.name == "GameOver": hud.update()
	
	AudioManager.music_player.stop()
	
func restart_game():
	dungeon_root.process_mode = Node.PROCESS_MODE_INHERIT

func _on_main_scene_removed():
	hud.update()
