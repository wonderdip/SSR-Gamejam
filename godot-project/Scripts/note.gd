extends Area2D
class_name Note

@export_multiline var notes: Array[String] = []
@export_multiline var specific_note: String = ""
@onready var note_ui: CanvasLayer = $NoteUI
@onready var label: Label = $NoteUI/NoteUISprite/Label
@onready var note_ui_sprite: Sprite2D = $NoteUI/NoteUISprite
@onready var small_sprite: Sprite2D = $SmallSprite

var max_font_size: int = 9
var can_open: bool = false
var player: Player = null
var opened: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	note_ui.hide()

	if specific_note.length() > 0:
		label.text = specific_note
	else:
		label.text = notes.pick_random()

	fit_text()

	body_entered.connect(_on_played_entered_interaction_area)
	body_exited.connect(_on_player_exited_interaction_area)
	shine()

func _on_played_entered_interaction_area(body: Node):
	if body is Player:
		player = body
		can_open = true

func _on_player_exited_interaction_area(body: Node):
	if body is Player and body == player:
		player = null
		can_open = false
	
func fit_text() -> void:
	var font := label.get_theme_font("font")
	var font_size := max_font_size
	var max_width := label.size.x

	while font_size > 1:
		var text_size := font.get_multiline_string_size(
			label.text,
			HORIZONTAL_ALIGNMENT_LEFT,
			max_width,
			font_size
		)

		if text_size.y <= label.size.y:
			break
	
		font_size -= 1
	
	label.add_theme_font_size_override("font_size", font_size)
	
func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("interact")
	and not event.is_echo()
	and can_open):
		if opened:
			close_note()
		else:
			open_note()
			small_sprite.modulate = Color.DIM_GRAY
		get_viewport().set_input_as_handled()
		
func open_note():
	player.movement_locked = true
	opened = true
	note_ui_sprite.scale = Vector2(0, 0)
	note_ui.show()
	var tween = create_tween()
	tween.tween_property(note_ui_sprite, "scale", Vector2(1, 1), 0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
func close_note():
	note_ui_sprite.scale = Vector2(1, 1)
	
	var tween = create_tween()
	tween.tween_property(note_ui_sprite, "scale", Vector2(0, 0), 0.4
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	
	await tween.finished
	note_ui.hide()
	player.movement_locked = false
	opened = false
	
func _on_button_pressed() -> void:
	close_note()

func shine():
	var shader_material: ShaderMaterial = small_sprite.material
	
	while true:
		var shine_tween := create_tween()
		
		shader_material.set_shader_parameter("shine_progress", 1.0)
		
		shine_tween.tween_method(
			func(value): shader_material.set_shader_parameter("shine_progress", value),
			1.0,
			0.0,
			2.5
		)
		
		await shine_tween.finished
		
		# Optional delay between shines
		await get_tree().create_timer(1).timeout
