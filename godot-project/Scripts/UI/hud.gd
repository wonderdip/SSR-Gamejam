extends CanvasLayer
class_name HUD

@onready var pause_menu: CanvasLayer = $"../PauseMenu"
@onready var map: Map = $Map
@onready var weapon_hud: StatHUD = $WeaponHUD
@onready var dungeon_root: Node2D = $"../DungeonRoot"

var player: Player
var ascending := false

func _ready() -> void:
	player = SceneManager.player
	weapon_hud.hide()
	
	player.inventory.active_weapon_changed.connect(show_weapon_hud)
	player.death_anim_started.connect(hide_all)
	SceneManager.ascension_started.connect(set_ascending.bind(true))
	SceneManager.ascension_finished.connect(set_ascending.bind(false))
	pause_menu.main_menu_open.connect(hide_weapon_hud)
	
func update():
	if dungeon_root.room_container.get_child_count() > 0:
		map.show()
	else:
		map.hide()
	
	if player.inventory.current_weapon and (SceneManager.current_scene.name == "StartingRoom" or LevelManager.in_dungeon):
		weapon_hud.show()
	else:
		weapon_hud.hide()

	if player.dead:
		hide_all()

func hide_all():
	weapon_hud.hide()
	map.hide()
	
func hide_weapon_hud():
	weapon_hud.hide()

func show_weapon_hud(_weapon: Node) -> void:
	if ascending:
		return
	if player.inventory.current_weapon:
		weapon_hud.show()
	else:
		weapon_hud.hide()

func set_ascending(value: bool) -> void:
	ascending = value
	if value:
		hide_all()
	elif player.inventory.current_weapon:
		weapon_hud.show()
