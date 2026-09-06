extends Control
class_name DigitReel

@export var digit_width: float = 24.0
@export var digit_height: float = 32.0
@export var digit_spacing: float = 0.0
@export var roll_duration: float = 0.4
@export var font: Font
@export var font_size: int = 24
@export var font_color: Color

var _reel: Control
var _labels: Array[Label] = []
var _current_index: int = 0 # unbounded counter; actual digit is _current_index % 10
var _tween: Tween

func _ready() -> void:
	clip_contents = true
	custom_minimum_size = Vector2(digit_width, digit_height)

	_reel = Control.new()
	add_child(_reel)

	_ensure_labels_up_to(9)
	
func _step_height() -> float:
	return digit_height + digit_spacing

func _ensure_labels_up_to(index: int) -> void:
	while _labels.size() <= index:
		var i: int = _labels.size()
		var label: Label = Label.new()
		label.text = str(i % 10)
		label.position = Vector2(0.0, i * _step_height())
		label.size = Vector2(digit_width, digit_height)
		label.clip_text = true
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if font != null:
			label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", font_color)
		_reel.add_child(label)
		_labels.append(label)

func set_digit(digit: int, animate: bool = true) -> void:
	digit = digit % 10
	var current_digit: int = _current_index % 10

	if _tween != null and _tween.is_running():
		_tween.kill()

	if not animate:
		_current_index = digit
		_reel.position.y = -float(digit) * _step_height()
		return

	if digit == current_digit:
		return

	var steps: int = (digit - current_digit + 10) % 10
	var target_index: int = _current_index + steps
	_ensure_labels_up_to(target_index)

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(_reel, "position:y", -float(target_index) * _step_height(), roll_duration)
	await _tween.finished

	_current_index = target_index
	_collapse_if_needed()

func _collapse_if_needed() -> void:
	# after enough rolls, snap the unbounded index back down to avoid the
	# reel's label list and position growing forever during long sessions
	if _current_index < 100:
		return
	var digit: int = _current_index % 10
	_current_index = digit
	_reel.position.y = -float(digit) * _step_height()
