extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var rolling_counter: RollingCounter = $Floor/RollingCounter

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player.animation_finished.connect(_on_anim_finished)
	rolling_counter.set_value(LevelManager.floor_num - 1, false)
	ScreenSfx.cam_shake(3,2, 2)
func _on_anim_finished(_anim_name: StringName):
	await LevelManager._build_floor(true)
	SceneManager.remove_scene()
	
func sfx(tag: String):
	AudioManager.play_sfx(tag, -10, randf_range(0.95, 1.05))
