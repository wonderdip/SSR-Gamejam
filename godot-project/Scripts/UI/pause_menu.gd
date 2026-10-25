extends CanvasLayer

signal main_menu_open

@export var highlight: ColorRect
@export var button_container: ButtonContainer
@onready var pointer: Sprite2D = $ButtonContainer/Pointer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()

func _on_visibility_changed() -> void:
	if visible:
		get_tree().paused = true
		upscale_tween()
		button_container.reset()
	else:
		get_tree().paused = false
		pointer.hide()
		
func upscale_tween():
	var tween = create_tween()
	button_container.scale = Vector2(0, 0)
	tween.tween_property(button_container, "scale", Vector2(1, 1), 0.5
	).set_ease(Tween.EASE_OUT
	).set_trans(Tween.TRANS_SPRING)
	await tween.finished
	pointer.show()
	
func _on_back_button_pressed() -> void:
	await tween_highlight()
	hide()

func _on_settings_button_pressed() -> void:
	pass # Replace with function body.

func _on_main_menu_button_pressed() -> void:
	await tween_highlight()
	MessageBus._message_box.close()
	hide()
	if LevelManager.main_cam: LevelManager.main_cam.set_enabled(false)
	SceneManager.goto_scene("res://Scenes/UI/title_screen.tscn")
	LevelManager.player_pos = SceneManager.player.global_position
	main_menu_open.emit()
	
func tween_highlight():
	AudioManager.play_sfx("select")
	var tween = create_tween()
	tween.tween_property(highlight, "color", Color.WHITE, 0.2
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	await tween.finished
	await get_tree().create_timer(0.1).timeout
