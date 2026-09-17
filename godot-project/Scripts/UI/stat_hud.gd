extends Control
class_name StatHUD

@export var COUNTER_LIT : Color = Color(1, 1, 1, 1)
@export var COUNTER_SPENT : Color = Color(0.15, 0.15, 0.15, 1)

@onready var weapon_icon: TextureRect = $Icon
@onready var panel: NinePatchRect = $Panel
@onready var container: HBoxContainer = $Container

@export var melee_counter_texture: Texture2D
@export var bullet_counter_texture: Texture2D

var player: Player

func _ready() -> void:
	player = SceneManager.player
	player.inventory.melee_equipped.connect(_on_weapon_equipped)
	player.inventory.gun_equipped.connect(_on_weapon_equipped)

	_on_weapon_equipped(player.inventory.equipped_melee)
	_on_weapon_equipped(player.inventory.equipped_gun)

func _on_weapon_equipped(weapon_data: ItemData) -> void:
	weapon_icon.visible = weapon_data != null
	if weapon_data:
		weapon_icon.texture = weapon_data.mini_texture
		match weapon_data.item_type:
			ItemEnums.ITEM_TYPE.GUN:
				_build_counters(container, weapon_data.magazine_size, bullet_counter_texture)
			ItemEnums.ITEM_TYPE.MELEE:
				_build_counters(container, weapon_data.swings_before_cd, melee_counter_texture)

func _build_counters(container: Control, count: int, texture: Texture2D) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

	var separation := container.get_theme_constant("separation")
	var available_width := container.size.x - separation * (count - 1)
	var base_width := floori(available_width / count)
	var remainder := int(available_width) - base_width * count

	for i in count:
		var counter := NinePatchRect.new()
		counter.texture = texture
		counter.custom_minimum_size.x = base_width + (1 if i < remainder else 0)
		counter.patch_margin_bottom = 2
		counter.patch_margin_top = 2
		counter.patch_margin_left = 1
		counter.patch_margin_right = 1
		container.add_child(counter)
	
func _process(_delta: float) -> void:
	_update_counters(container, player.inventory.melee_instance)
	_update_counters(container, player.inventory.gun_instance)

func _update_counters(container: Control, instance: Node) -> void:
	if not instance:
		return
	
	var total: int
	var lit_count: int
	
	if instance is MeleeInstance:
		total = instance.melee_data.swings_before_cd
		if instance.recharging:
			var progress : float = 1.0 - (instance.cooldown_time_left / instance.melee_data.cooldown)
			lit_count = floor(progress * total)
		else:
			lit_count = instance.swings
	elif instance is GunInstance:
		total = instance.gun_data.magazine_size
		if instance.reloading:
			var progress : float = 1.0 - (instance.reload_time_left / instance.gun_data.reload_time)
			lit_count = floor(progress * total)
		else:
			lit_count = instance.current_ammo

	var counters := container.get_children()
	for i in counters.size():
		counters[i].modulate = COUNTER_LIT if i < lit_count else COUNTER_SPENT
