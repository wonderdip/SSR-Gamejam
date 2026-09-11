extends ItemData
class_name AnomalyData

# Override in specific passive .tres via a script, or keep generic stat mods here
@export var speed_mod: float = 0.0
@export var damage_mod: float = 0.0
@export var max_hp_mod: int = 0

func apply_passive(player: Player) -> void:
	player.walk_speed += speed_mod
	player.run_speed += speed_mod
