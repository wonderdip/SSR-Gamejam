extends Control
class_name ButtonContainer

@export var pointer_positions: Array[int] = [
	83,
	99,
	115
]

@export var highlight_positions: Array[int] = [
	78,
	93,
	108
]

@export var first_button: Button
@export var second_button: Button
@export var third_button: Button
@export var pointer: Sprite2D
@export var highlight: ColorRect

var current_button := -1
var highlight_tween_instance: Tween
var highlight_base_color: Color

@export var x_position: int = 31

var pressed: bool

func _ready() -> void:
	first_button.pressed.connect(_on_button_pressed)
	second_button.pressed.connect(_on_button_pressed)
	third_button.pressed.connect(_on_button_pressed)
	pointer.hide()
	pressed = false
	highlight_base_color = highlight.color
	
func reset():
	pointer.hide()
	pressed = false
	highlight.color = highlight_base_color
	
func _process(_delta: float) -> void:
	if not pressed:
		var new_button := -1
		
		if first_button.is_hovered():
			new_button = 0
			
		elif second_button.is_hovered():
			new_button = 1
			
		elif third_button.is_hovered():
			new_button = 2
		
		if new_button == current_button:
			return
		
		AudioManager.play_sfx("button_switch", - 10, randf_range(0.95, 1.05))
		
		current_button = new_button
		if current_button == -1:
			pointer.hide()
			highlight.hide()
			return
		pointer.global_position.x = x_position
		pointer.global_position.y = pointer_positions[current_button]
		highlight.position.y = highlight_positions[current_button]

		pointer.show()
		highlight.show()

		highlight_tween()

func highlight_tween() -> void:
	if highlight_tween_instance:
		highlight_tween_instance.kill()

	highlight.size = Vector2(1, 12)

	highlight_tween_instance = create_tween()

	highlight_tween_instance.tween_property(
		highlight,
		"size",
		Vector2(91, 12),
		0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)

func _on_button_pressed():
	pressed = true
	
	
