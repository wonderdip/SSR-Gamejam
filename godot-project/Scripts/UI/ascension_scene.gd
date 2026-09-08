extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var rolling_counter: RollingCounter = $Floor/RollingCounter

var room_camera: RoomCamera

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	room_camera = get_tree().get_first_node_in_group("room_camera")
	room_camera.enabled = false
	animation_player.animation_finished.connect(_on_anim_finished)
	rolling_counter.set_value(LevelManager.floor_num - 1, false)
	
func _on_anim_finished(_anim_name: StringName):
	await LevelManager._build_floor(true)
	SceneManager.remove_scene()
	room_camera.enabled = true
	
func sfx(tag: String):
	AudioManager.play_sfx(tag, -10, randf_range(0.95, 1.05))
