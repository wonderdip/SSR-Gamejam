extends Control

signal new_run_started

@onready var enemies: Label = $VBoxContainer/Enemies
@onready var chests: Label = $VBoxContainer/Chests
@onready var floor: Label = $VBoxContainer/Floor

var player: Player

func _ready() -> void:
	player = SceneManager.player
	player.inventory.active_weapon_changed.emit(null)
	enemies.text = "Enemies Killed: " + str(player.enemies_killed)
	chests.text = "Chests Looted: " + str(player.chests_looted)
	floor.text = "Floor Reached: " + str(LevelManager.floor_num)
	LevelManager._teardown_current_floor()
	LevelManager._room_type_by_index.clear()
	
func _on_new_run_pressed() -> void:
	SceneManager.goto_packed_scene(load("res://Scenes/World/starting_room.tscn"))
	player.reset()
	new_run_started.emit()
