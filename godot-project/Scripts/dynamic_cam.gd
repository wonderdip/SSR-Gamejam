extends Camera2D
class_name DynamicCamera

@export_category("Shake")
@export var max_offset: Vector2 = Vector2(16.0, 16.0)
@export var max_roll: float = 0.1 # radians
@export var trauma_power: float = 2.0
@export var trauma_decay: float = 1.5 # trauma lost per second
@export var noise_speed: float = 20.0

var trauma: float = 0.0

var _noise: FastNoiseLite = FastNoiseLite.new()
var _noise_seed_offset: float = 0.0

func _ready() -> void:
	_noise.seed = randi()
	_noise_seed_offset = randf() * 1000.0

func add_trauma(amount: float) -> void:
	trauma = clamp(trauma + amount, 0.0, 1.0)

func _process(delta: float) -> void:
	trauma = max(trauma - trauma_decay * delta, 0.0)

	if trauma <= 0.0:
		offset = Vector2.ZERO
		rotation = 0.0
		return

	var shake: float = pow(trauma, trauma_power)
	var time: float = Time.get_ticks_msec() / 1000.0 * noise_speed

	offset = Vector2(
		max_offset.x * shake * _noise.get_noise_2d(time, _noise_seed_offset),
		max_offset.y * shake * _noise.get_noise_2d(time, _noise_seed_offset + 100.0)
	)
	rotation = max_roll * shake * _noise.get_noise_2d(time, _noise_seed_offset + 200.0)
