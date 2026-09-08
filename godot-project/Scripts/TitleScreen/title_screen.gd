extends Node2D

@onready var super_font: Sprite2D = $TitleName/SuperFont
@onready var cross_sprite: Sprite2D = $CrossSprite
@onready var highlight: ColorRect = $Control/Highlight

@export var play_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super_font.hide()
	animate_title()
	cross_sprite.animate_cross()
	
func animate_title():
	var tween: Tween = create_tween()
	super_font.position = Vector2(-54, -79)
	super_font.scale = Vector2(2, 2)
	super_font.show()

	tween.tween_property(super_font, "scale", Vector2(1, 1), 0.5)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_SPRING)

	tween.set_parallel()
	tween.tween_property(super_font, "position", Vector2(-23, -24), 0.5)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_SPRING)
		
	AudioManager.play_sfx("impact", 5, 1)
	AudioManager.play_sfx("crash", -10, 0.6)
	
	await tween.finished
	tween.kill()
	# Rotation loop
	var rotation_tween := create_tween().set_loops()
	rotation_tween.tween_property(super_font, "rotation_degrees", -10, 3.5)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)
	rotation_tween.tween_property(super_font, "rotation_degrees", 5, 3.5)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)
			
func _on_play_button_pressed() -> void:
	await tween_highlight()
	if LevelManager.in_dungeon:
		SceneManager.remove_scene()
		LevelManager.main_cam.set_enabled(true)
		LevelManager._place_player_on_floor()
	elif LevelManager.game_started:
		SceneManager.goto_scene("res://Scenes/World/starting_room.tscn")
	else:
		SceneManager.goto_packed_scene(play_scene)

func _on_settings_button_pressed() -> void:
	pass # Replace with function body.

func _on_quit_button_pressed() -> void:
	await tween_highlight()
	get_tree().quit()

func tween_highlight():
	AudioManager.play_sfx("select")
	var tween = create_tween()
	tween.tween_property(highlight, "color", Color.WHITE, 0.2
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	await tween.finished
	await get_tree().create_timer(0.1).timeout
