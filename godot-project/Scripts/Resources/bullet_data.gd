extends ItemData
class_name BulletData 

@export var speed: int = 1000
@export var max_distance = 1200
@export var knockback: int = 100
@export var piercing: bool = false          # passes through enemies
@export_range(0.0, 0.9) var speed_variance: float = 0.0   # 0.25 = ±25% speed per bullet
@export var end_scale: float = 1.0          # size at max_distance (>1 widens into a cone)
@export var fade_out: bool = false

@export var area_shape: Shape2D
@export var area_rotation: float
@export var area_grow: bool = false
@export var grow_speed: float = 0.5
@export var windup: float = 0.2
@export var offset: Vector2i
@export var collision_particles: ParticleProcessMaterial
@export var animated: bool = false
@export var delete_on_anim_done: bool = false
@export var hframes: int = 1
@export var vframes: int = 1
@export var fps: int = 12
@export var random_frame_range: Vector2i

@export var material: ShaderMaterial
@export var end_scene: PackedScene
