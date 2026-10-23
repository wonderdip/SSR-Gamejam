extends Control
class_name BossBar

@onready var progress_bar: TextureProgressBar = $ProgressBar
@export var enemy: Enemy

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	enemy.damaged.connect(_on_boss_hp_down)
	progress_bar.max_value = enemy.max_health
	progress_bar.value = progress_bar.max_value
	
func _on_boss_hp_down(_amount: int) -> void:
	create_tween().tween_property(
		progress_bar, 
		"value", 
		maxf(enemy.health, 
		0.0
		), 0.25)
