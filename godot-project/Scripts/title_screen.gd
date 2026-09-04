extends Control

@onready var super_font: Sprite2D = $TitleName/SuperFont
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var cross_sprite: Sprite2D = $CrossSprite


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player.play("title_in")
	super_font.hide()
	await animation_player.animation_finished
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
			
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_button_pressed() -> void:
	pass # Replace with function body.

func _on_settings_button_pressed() -> void:
	pass # Replace with function body.

func _on_quit_button_pressed() -> void:
	get_tree().quit()
