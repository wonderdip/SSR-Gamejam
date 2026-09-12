extends ItemData
class_name MeleeData

@export var damage: float = 10
@export var swing_speed: float = 6
@export var swing_arc_degrees: float = 100.0  # total sweep angle

@export var collision_shape: Shape2D
@export var y_offset: int = -24

@export var particle: ParticleProcessMaterial
@export var trail: ParticleProcessMaterial
@export var slash_texture: Texture
@export var swing_sound: String = ""
@export var equip_sound: String = ""
