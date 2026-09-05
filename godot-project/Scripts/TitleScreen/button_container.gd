extends VBoxContainer

var pointer_positions: Array[int] = [
	83,
	99,
	115
]

var highlight_positions: Array[int] = [
	78,
	93,
	108
]

@onready var play_button: Button = $PlayButton
@onready var settings_button: Button = $SettingsButton
@onready var quit_button: Button = $QuitButton
@onready var pointer: Sprite2D = $"../Pointer"
@onready var highlight: ColorRect = $"../Highlight"

var current_button := -1
var highlight_tween_instance: Tween
var x_position: int = 31

func _ready() -> void:
	play_button.pressed.connect(_on_button_pressed)
	settings_button.pressed.connect(_on_button_pressed)
	quit_button.pressed.connect(_on_button_pressed)
	pointer.hide()
	
func _process(_delta: float) -> void:
	var new_button := -1

	if play_button.is_hovered():
		new_button = 0
	elif settings_button.is_hovered():
		new_button = 1
	elif quit_button.is_hovered():
		new_button = 2

	if new_button == current_button:
		return

	current_button = new_button
	if current_button == -1:
		pointer.hide()
		highlight.hide()
		return
	pointer.global_position.x = x_position
	pointer.global_position.y = pointer_positions[current_button]
	highlight.global_position.y = highlight_positions[current_button]

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
	pass
	
	
