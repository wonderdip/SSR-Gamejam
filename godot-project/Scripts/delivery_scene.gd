extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export_category("Driving SFX")
@export var driving_sfx_interval: float = 0.5
@export var starting_volume_db: float = -10.0
@export var volume_falloff_per_second: float = -2.0
@export var minimum_volume_db: float = -30.0
@onready var skip_label: Label = $SkipLabel

var car_driving: bool = true
var _driving_elapsed: float = 0.0

func _ready() -> void:
	SceneManager.gameloop_started.emit()
	await get_tree().create_timer(0.5).timeout
	animation_player.play("delivery")
	driving_sound()
	
func sfx(tag: String, volume_db: float = -10.0) -> void:
	AudioManager.play_sfx(tag, volume_db)

func driving_sound() -> void:
	_driving_elapsed = 0.0
	while car_driving:
		var current_volume: float = max(
			starting_volume_db + volume_falloff_per_second * _driving_elapsed,
			minimum_volume_db
		)
		sfx("driving", current_volume)
		await get_tree().create_timer(driving_sfx_interval).timeout
		_driving_elapsed += driving_sfx_interval

func end_driving() -> void:
	car_driving = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if animation_player.is_playing():
				animation_player.seek(4.5)
				skip_label.hide()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "delivery":
		skip_label.hide()
