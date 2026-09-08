extends CanvasLayer

@export var highlight: ColorRect
@export var button_container: VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()

func _on_visibility_changed() -> void:
	if visible:
		get_tree().paused = true
		button_container.reset()
	else:
		get_tree().paused = false

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

func tween_highlight():
	AudioManager.play_sfx("select")
	var tween = create_tween()
	tween.tween_property(highlight, "color", Color.WHITE, 0.2
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	await tween.finished
	await get_tree().create_timer(0.1).timeout
