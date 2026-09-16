extends Area2D
class_name Note

@export_multiline var notes: Array[String] = []
@export_multiline var specific_note: String = ""
@onready var note_ui: CanvasLayer = $NoteUI
@onready var small_sprite: Sprite2D = $SmallSprite

@onready var control: Control = $NoteUI/Control
@onready var note_ui_sprite: TextureRect = $NoteUI/Control/NoteUISprite
@onready var button: Button = $NoteUI/Control/NoteUISprite/Button
@onready var label: Label = $NoteUI/Control/Label

var max_font_size: int = 9
var min_font_size: int = 3
var can_open: bool = false
var player: Player = null
var opened: bool = false

# Called when the node enters the scene tree for the first time.
static var used_notes: Array[String] = []

func _ready() -> void:
	note_ui.hide()
	
	if specific_note.length() > 0:
		label.text = specific_note
		fit_text()
	elif randf() > 0.85:
		get_msg()
	else:
		queue_free()
		
	body_entered.connect(_on_played_entered_interaction_area)
	body_exited.connect(_on_player_exited_interaction_area)
	shine()

func get_msg():
	if specific_note.length() > 0:
		return
	else:
		var available: Array[String] = notes.filter(func(n): return not used_notes.has(n))
		if available.is_empty():
			available = notes  # every option's been used — allow repeats rather than break

		var random_note: String = available.pick_random()
		label.text = random_note
		used_notes.append(random_note)

	fit_text()

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
	var available_height := label.size.y

	label.scale = Vector2.ONE

	var best_font_size := min_font_size
	var best_text_height := 0.0

	for candidate_size in range(min_font_size, max_font_size + 1):
		label.add_theme_font_size_override("font_size", candidate_size)

		var line_height := font.get_height(candidate_size) + label.get_theme_constant("line_spacing")
		var text_height := label.get_line_count() * line_height

		if text_height <= available_height:
			best_font_size = candidate_size
			best_text_height = text_height
		else:
			break

	label.add_theme_font_size_override("font_size", best_font_size)

	var scale_factor := 1.0
	if best_text_height > 0:
		scale_factor = min(available_height / best_text_height, 1.0)

	label.pivot_offset = label.size / 2.0
	label.scale = Vector2.ONE * scale_factor

func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("interact")
	and not event.is_echo()
	and can_open):
		if opened:
			close_note()
		else:
			open_note()
			small_sprite.material = null
			small_sprite.modulate = Color.GRAY
		get_viewport().set_input_as_handled()
		
func open_note():
	player.movement_locked = true
	opened = true
	control.scale = Vector2(0, 0)
	note_ui.show()
	AudioManager.play_sfx("note_open")
	var tween = create_tween()
	tween.tween_property(control, "scale", Vector2(1, 1), 0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
func close_note():
	control.scale = Vector2(1, 1)
	AudioManager.play_sfx("note_close")
	var tween = create_tween()
	tween.tween_property(control, "scale", Vector2(0, 0), 0.4
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
