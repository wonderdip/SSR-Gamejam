extends Node
class_name Inventory

signal gun_equipped(gun_data: GunData)
signal melee_equipped(item_data: ItemData)
signal anomaly_added(item_data: ItemData)
signal consumable_changed(item_data: ItemData, count: int)

@onready var player: Player = get_parent() as Player

var equipped_gun: GunData
var equipped_melee: ItemData
var anomalies: Array[ItemData] = []
var consumables: Dictionary = {} # ItemData -> int

var gun_instance: GunInstance

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

func _equip_gun(gun_data: GunData) -> void:
	if gun_instance:
		gun_instance.queue_free()

	equipped_gun = gun_data
	gun_instance = GunInstance.new()
	gun_instance.gun_data = gun_data
	player.gun_pos.add_child(gun_instance)
	gun_instance.player = player
	gun_equipped.emit(gun_data)

func _equip_melee(item: ItemData) -> void:
	equipped_melee = item
	melee_equipped.emit(item)
	# TODO: spawn a MeleeInstance once melee combat exists, mirroring _equip_gun

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
