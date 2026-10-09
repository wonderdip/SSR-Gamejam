extends CanvasLayer
class_name HUD

@onready var map: Map = $Map
@onready var weapon_hud: StatHUD = $WeaponHUD
@onready var dungeon_root: Node2D = $"../DungeonRoot"
var player: Player
var ascending := false

func _ready() -> void:
	player = SceneManager.player
	weapon_hud.hide()

	player.inventory.gun_equipped.connect(show_weapon_hud)
	player.inventory.melee_equipped.connect(show_weapon_hud)
	SceneManager.ascension_started.connect(set_ascending.bind(true))
	SceneManager.ascension_finished.connect(set_ascending.bind(false))

func update():
	if dungeon_root.room_container.get_child_count() > 0:
		map.show()
	else:
		map.hide()

func show_weapon_hud(_data: ItemData) -> void:
	if ascending:
		return
	if player.inventory.current_weapon:
		weapon_hud.show()

func set_ascending(value: bool) -> void:
	ascending = value
	if value:
		weapon_hud.hide()
	elif player.inventory.current_weapon:
		weapon_hud.show()
