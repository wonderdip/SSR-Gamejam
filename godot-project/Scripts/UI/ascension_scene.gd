extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var last_dir: SceneManager.TRIGGERDIRECTION

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player.animation_finished.connect(_on_anim_finished)

func _on_anim_finished(_anim_name: StringName):
	SceneManager.exiting_level.emit(SceneManager._entry_direction, false)

func sfx(tag: String):
	AudioManager.play_sfx(tag, -10, randf_range(0.95, 1.05))
