extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var rolling_counter: RollingCounter = $Floor/RollingCounter
@onready var camera_2d: Camera2D = $Camera2D

var _cam: RoomCamera

func _ready() -> void:
	SceneManager.ascension_started.emit()
	_cam = LevelManager.main_cam as RoomCamera
	if _cam:
		_cam.stop_following()
		_cam.set_enabled(false)  # lets the default view show the world origin
	animation_player.animation_finished.connect(_on_anim_finished)
	rolling_counter.set_value(LevelManager.floor_num - 1, false)
	ScreenSfx.register_cam(camera_2d)
	ScreenSfx.cam_shake(3, 2, 2)

func _on_anim_finished(_anim_name: StringName) -> void:
	await SceneManager.fade_out()
	if _cam:
		_cam.set_enabled(true)  # back on before the new floor snaps the camera
	await LevelManager._build_floor(false)
	SceneManager.ascension_finished.emit()
	SceneManager.remove_scene()
	ScreenSfx.register_cam(_cam)

func sfx(tag: String) -> void:
	AudioManager.play_sfx(tag, -10, randf_range(0.95, 1.05))
