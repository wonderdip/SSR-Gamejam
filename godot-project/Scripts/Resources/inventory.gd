extends Node
class_name Inventory

signal gun_equipped(gun_data: GunData)
signal melee_equipped(item_data: MeleeData)
signal weapon_dropped(item_data: ItemData)
signal anomaly_added(item_data: ItemData)
signal consumable_changed(item_data: ItemData, count: int)

@export var player: Player

var equipped_gun: GunData
var equipped_melee: MeleeData
var anomalies: Array[ItemData] = []
var consumables: Dictionary = {}

var gun_instance: GunInstance
var melee_instance: MeleeInstance
var current_weapon: Node = null   # whichever one is active

func add_item(item: ItemData) -> void:
	match item.item_type:
		ItemEnums.ITEM_TYPE.GUN:
			_equip_gun(item)
		ItemEnums.ITEM_TYPE.MELEE:
			_equip_melee(item)
		ItemEnums.ITEM_TYPE.ANOMALY:
			_add_passive(item)
		ItemEnums.ITEM_TYPE.CONSUMABLE:
			_add_consumable(item)
		_:
			push_warning("Inventory: unhandled item_type for " + item.item_name)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("drop") and not event.is_echo():
		drop_weapon()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			switch_weapon()
			

func _equip_gun(gun_data: GunData) -> void:
	if gun_instance:
		_spawn_pickup(equipped_gun)
		_remove_gun()

	equipped_gun = gun_data
	gun_instance = gun_data.scene.instantiate() as GunInstance
	gun_instance.gun_data = gun_data
	gun_instance.player = player
	player.gun_pos.add_child(gun_instance)
	_set_active(gun_instance)
	gun_equipped.emit(gun_data)

func _equip_melee(melee_data: MeleeData) -> void:
	if melee_instance:
		_spawn_pickup(equipped_melee)
		_remove_melee()

	equipped_melee = melee_data
	melee_instance = melee_data.scene.instantiate() as MeleeInstance
	melee_instance.melee_data = melee_data
	melee_instance.player = player
	player.melee_pos.add_child(melee_instance)
	_set_active(melee_instance)
	melee_equipped.emit(melee_data)

func drop_weapon() -> void:
	if current_weapon == null:
		return

	if current_weapon == gun_instance:
		_spawn_pickup(equipped_gun)
		_remove_gun()
		_set_active(melee_instance)
	elif current_weapon == melee_instance:
		_spawn_pickup(equipped_melee)
		_remove_melee()
		_set_active(gun_instance)

func switch_weapon() -> void:
	if gun_instance and melee_instance:
		_set_active(melee_instance if current_weapon == gun_instance else gun_instance)

func _set_active(weapon: CanvasItem) -> void:
	for w: Node in [gun_instance, melee_instance]:
		if w == null:
			continue
		var active := (w == weapon)
		w.visible = active
		w.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	current_weapon = weapon

func _remove_gun() -> void:
	gun_instance.get_parent().remove_child(gun_instance)
	gun_instance.queue_free()
	gun_instance = null
	equipped_gun = null

func _remove_melee() -> void:
	melee_instance.get_parent().remove_child(melee_instance)
	melee_instance.queue_free()
	melee_instance = null
	equipped_melee = null

func _spawn_pickup(item: ItemData) -> void:
	var pickup := WeaponPickup.new()
	pickup.item_data = item
	player.get_parent().add_child(pickup)   # same parent as the player, so layering matches
	pickup.global_position = current_weapon.global_position
	weapon_dropped.emit(item)
	
func _add_passive(item: ItemData) -> void:
	anomalies.append(item)
	if item.has_method("apply_passive"):
		item.apply_passive(player)
	anomaly_added.emit(item)

func _add_consumable(item: ItemData) -> void:
	consumables[item] = consumables.get(item, 0) + 1
	consumable_changed.emit(item, consumables[item])

func use_consumable(item: ItemData) -> bool:
	if consumables.get(item, 0) <= 0:
		return false

	consumables[item] -= 1
	if item.has_method("apply"):
		item.apply(player)

	consumable_changed.emit(item, consumables[item])
	if consumables[item] <= 0:
		consumables.erase(item)
	return true

func has_passive(item: ItemData) -> bool:
	return anomalies.has(item)
