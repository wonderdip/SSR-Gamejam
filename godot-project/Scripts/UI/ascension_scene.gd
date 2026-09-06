extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var rolling_counter: RollingCounter = $Floor/RollingCounter

var last_dir: SceneManager.TRIGGERDIRECTION

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player.animation_finished.connect(_on_anim_finished)
	rolling_counter.set_value(SceneManager.floor_num - 1, false)
	
func _on_anim_finished(_anim_name: StringName):
	SceneManager.exiting_level.emit(SceneManager._ascension_direction, false, null)

func sfx(tag: String):
	AudioManager.play_sfx(tag, -10, randf_range(0.95, 1.05))
