extends CanvasLayer

@onready var current_item: TextureRect = %CurrentItem
@onready var item_name: Label = %ItemName
@onready var rarity: Label = %Rarity
@onready var gun_details: VBoxContainer = %GunDetails
@onready var gun_dmg: Label = %GunDmg
@onready var mag: Label = %Mag
@onready var reload: Label = %Reload
@onready var melee_details: VBoxContainer = %MeleeDetails
@onready var melee_dmg: Label = %MeleeDmg
@onready var swings: Label = %Swings
@onready var cooldown: Label = %Cooldown
@onready var description: Label = %Description
@onready var rarity_light: PointLight2D = %RarityLight
@onready var left: Button = %Left
@onready var right: Button = %Right
@onready var exit: Button = %Exit


@export var colors: Array[Color]

var player: Player
var items: Array[ItemData] = []
var index: int = 0

func _ready() -> void:
	hide()
	items = ItemManager.get_all_items()
	player = SceneManager.player
	player.inventory.unique_item_obtained.connect(unlocked_inventory)
	player.inventory.active_weapon_changed.connect(unlocked_item)



func unlocked_inventory(item: ItemData) -> void:
	print(item.item_name)
	if item.item_name == "Sciontology 101":
		show()
		
func _on_left_pressed() -> void:
	prev_item()

func _on_right_pressed() -> void:
	next_item()

func prev_item() -> void:
	if items.is_empty():
		return
	index = wrapi(index - 1, 0, items.size())
	_show_item()
	AudioManager.play_sfx("select")
	
func next_item() -> void:
	if items.is_empty():
		return
	index = wrapi(index + 1, 0, items.size())
	_show_item()
	AudioManager.play_sfx("select")
	
func unlocked_item(item: Node):
	if visible:
		_show_item()

func _show_item() -> void:
	if items.is_empty():
		return
	var item: ItemData = items[index]
	var known: bool = item.unlocked

	current_item.texture = item.texture
	current_item.self_modulate = Color.WHITE if known else Color.BLACK

	item_name.text = item.item_name if known else ""
	rarity.text = ItemEnums.RARITIES.keys()[item.rarity] if known else ""
	rarity.add_theme_color_override("font_color", colors.get(item.rarity))
	rarity_light.color = colors.get(item.rarity)
	description.text = item.description if known else ""

	var gun := item as GunData
	var melee := item as MeleeData
	gun_details.visible = known and gun != null
	melee_details.visible = known and melee != null

	if known and gun:
		gun_dmg.text = "Dmg: %d" % gun.damage
		mag.text = "Mag: %d" % gun.magazine_size
		reload.text = "Reload: %.1fs" % gun.reload_time
	elif known and melee:
		melee_dmg.text = "Dmg: %d" % melee.damage
		swings.text = "Swings: %d" % melee.swings_before_cd
		cooldown.text = "Cooldown: %.1fs" % melee.cooldown

func _on_visibility_changed() -> void:
	if visible:
		get_tree().paused = true
		_show_item()
	else:
		get_tree().paused = false

func _on_exit_pressed() -> void:
	hide()
	AudioManager.play_sfx("select")

func _on_left_mouse_entered() -> void:
	AudioManager.play_sfx("button_switch")

func _on_right_mouse_entered() -> void:
	AudioManager.play_sfx("button_switch")

func _on_exit_mouse_entered() -> void:
	AudioManager.play_sfx("button_switch")
