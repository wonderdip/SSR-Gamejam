extends CanvasLayer
class_name BossBar

@onready var progress_bar: TextureProgressBar = $BossBar/ProgressBar
@onready var control: Control = $BossBar
@onready var boss_name: Label = $BossBar/BossName
@export var enemy: Enemy

var _tween: Tween
const TITLE_SCENE := "res://Scenes/UI/title_screen.tscn"

func _ready() -> void:
	enemy.damaged.connect(_on_boss_hp_down)
	SceneManager.scene_changed.connect(_on_scene_changed)
	SceneManager.scene_removed.connect(scene_removed)
	# Use health, not max_health: Boss._ready() hasn't run yet, so max_health is still 0.
	progress_bar.max_value = enemy.health
	progress_bar.value = enemy.health
	var modt = create_tween()
	control.modulate.a = 0
	modt.tween_property(control, "modulate:a", 1, 0.5)
	
	match LevelManager.floor_num:
		1: enemy.enemy_name = "Cultist OT I"
		2: enemy.enemy_name = "Priest OT II"
		3: enemy.enemy_name = "Bishop OT III"
		4: enemy.enemy_name = "Cardinal OT IV"
		5: enemy.enemy_name = "Inquisitor OT V"
		6: enemy.enemy_name = "Abomination OT VI"
		7: enemy.enemy_name = "Abomination OT VII"
		8: enemy.enemy_name = "Abomination OT VIII"
		9: enemy.enemy_name = "Abomination OT IX"
		10: enemy.enemy_name = "Abomination OT X"
		_: enemy.enemy_name = "Abomination OT " + str(LevelManager.floor_num)
		
	boss_name.text = enemy.enemy_name
	
func _on_boss_hp_down(_amount) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(progress_bar, "value", maxf(enemy.health, 0.0), 0.25)

func _on_scene_changed(scene: Node) -> void:
	if scene:
		if scene.scene_file_path == TITLE_SCENE:
			visible = false
	else:
		visible = true

func scene_removed():
	visible = true
