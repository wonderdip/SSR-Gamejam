extends Node

var camera2d: Camera2D
var cameraShakeNoise: FastNoiseLite

func _ready():
	cameraShakeNoise = FastNoiseLite.new()

func register_cam(cam: Camera2D):
	camera2d = cam
	
func cam_shake(Max: float, Min: float, Length: float):
	if not camera2d:
		return
	var camera_tween = get_tree().create_tween()
	camera_tween.tween_method(StartCameraShake, Max, Min, Length)
	
func StartCameraShake(intensity: float):
	if not camera2d:
		return
	var cameraOffset = cameraShakeNoise.get_noise_1d(Time.get_ticks_msec()) * intensity
	camera2d.offset.x = cameraOffset
	camera2d.offset.y = cameraOffset

func framefreeze(duration: float, time_scale: float):
	if time_scale > 0:
		Engine.time_scale = time_scale
		await get_tree().create_timer(duration * time_scale, true, false, true).timeout
		Engine.time_scale = 1.0
	else:
		Engine.time_scale = 0
		await get_tree().create_timer(duration, true, false, true).timeout
		Engine.time_scale = 1.0
