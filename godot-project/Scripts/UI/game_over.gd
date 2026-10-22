extends Control

@onready var enemies: Label = $VBoxContainer/Enemies
@onready var chests: Label = $VBoxContainer/Chests
@onready var floor: Label = $VBoxContainer/Floor

var player: Player
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = SceneManager.player
	enemies.text = "Enemies Killed: " + str(player.enemies_killed)
	chests.text = "Chests Looted: " + str(player.chests_looted)
	floor.text = "Floor Reached: " + str(LevelManager.floor_num) 

func _on_new_run_pressed() -> void:
	SceneManager.goto_packed_scene(load("res://Scenes/World/starting_room.tscn"))
	player.reset()
