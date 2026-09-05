extends Node2D  
signal typing_finished
@onready var dialogue_label: RichTextLabel = $DialogueLabel
@export_multiline() var dialogue: Array[String] = []
@export var characters_per_second: float = 30.0
@export var start_automatically: bool = true
@export var pause_on_punctuation: float = 0.12 
@export var delivery_scene: PackedScene
var _visible_progress: float = 0.0
var _pause_timer: float = 0.0
var _is_typing: bool = false
var current_dialogue: int = 0
# extra seconds to hold after . , ! ?  var _visible_progress: float = 0.0 var _pause_timer: float = 0.0 var _is_typing: bool = false  
# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	dialogue_label.bbcode_enabled = true
	dialogue_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	dialogue_label.install_effect(GlitchShuffleEffect.new())
	dialogue_label.text = dialogue[0]
	dialogue_label.visible_characters = 0
	if start_automatically:
		await get_tree().create_timer(0.25).timeout
		start_typing()

func _process(delta: float) -> void:
	if not _is_typing:
		return

	if _pause_timer > 0.0:
		_pause_timer -= delta
		return

	_visible_progress += characters_per_second * delta
	var next_index: int = int(_visible_progress)
	var total: int = dialogue_label.get_total_character_count()

	if next_index >= total:
		dialogue_label.visible_characters = -1
		_is_typing = false
		typing_finished.emit()
		return

	dialogue_label.visible_characters = next_index

	var plain: String = dialogue_label.get_parsed_text()
	if next_index > 0 and next_index <= plain.length():
		var last_char: String = plain[next_index - 1]
		if last_char in [".", ",", "!", "?"]:
			_pause_timer = pause_on_punctuation

func start_typing() -> void:
	_visible_progress = 0.0
	_pause_timer = 0.0
	dialogue_label.visible_characters = 0
	_is_typing = true

func skip_to_end() -> void:
	_is_typing = false
	dialogue_label.visible_characters = -1
	typing_finished.emit()

func next_dialogue():
	current_dialogue += 1
	dialogue_label.text = dialogue[current_dialogue]
	start_typing()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if not dialogue_label.visible_ratio == 1:
				skip_to_end()
			elif dialogue.size() - 1 > current_dialogue:
				next_dialogue()
			else:
				exit_cutscene()
				
func exit_cutscene():
	SceneManager.goto_packed_scene(delivery_scene)
