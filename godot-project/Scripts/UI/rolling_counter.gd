extends HBoxContainer
class_name RollingCounter

@export var digit_count: int = 6
@export var digit_width: float = 24.0
@export var digit_height: float = 32.0
@export var digit_spacing: float = 0.0
@export var digit_gap: float = 0.0
@export var roll_duration: float = 0.4
@export var font: Font
@export var font_size: int = 24
@export var font_color: Color

var _reels: Array[DigitReel] = []
var _value: int = 0

func _ready() -> void:
	add_theme_constant_override("separation", int(digit_gap))

	for i in range(digit_count):
		var reel: DigitReel = DigitReel.new()
		reel.digit_width = digit_width
		reel.digit_height = digit_height
		reel.digit_spacing = digit_spacing
		reel.roll_duration = roll_duration
		reel.font = font
		reel.font_size = font_size
		reel.font_color = font_color
		add_child(reel)
		_reels.append(reel)
	_apply_value(_value, false)

func increase_floor():
	set_value(SceneManager.floor_num)

func set_value(new_value: int, animate: bool = true) -> void:
	_value = new_value
	_apply_value(_value, animate)

func _apply_value(value: int, animate: bool) -> void:
	var max_value: int = int(pow(10, digit_count)) - 1
	var clamped: int = clamp(value, 0, max_value)

	var digits_str: String = str(clamped)
	while digits_str.length() < digit_count:
		digits_str = "0" + digits_str

	for i in range(digit_count):
		var digit: int = int(digits_str[i])
		_reels[i].set_digit(digit, animate)
