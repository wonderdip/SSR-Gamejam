extends ItemData
class_name GunData

@export_category("Stats")
@export var damage: int = 1
@export var magazine_size: int = 10
@export var bullet_count: int = 1
@export var reload_time: float = 1.0
@export var accuracy: int = 2 #lower is better

@export_range(0, 360) var shot_radius: float = 0
@export_range(0, 10) var shot_delay: float = 0.1

@export_category("Config")
@export var bullet: BulletData
@export var scene: PackedScene

@export_category("Sounds")
@export var shot_sound: String = ""
