extends ItemData
class_name MeleeData

@export_category("Stats")
@export var damage: float = 10
@export var swing_speed: float = 6
@export var swing_arc_degrees: float = 100.0  # total sweep angle

@export_category("Config")
@export var scene: PackedScene

@export_category("Sounds")
@export var swing_sound: String = ""
@export var equip_sound: String = ""
