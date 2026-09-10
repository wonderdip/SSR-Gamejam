extends Node2D
class_name GunInstance

@export var gun_data: GunData
@export var current_ammo: int

func _ready() -> void:
	name = (ItemEnums.RARITIES.keys()[gun_data.rarity]
	 + " " + 
	gun_data.item_name)
	
	print(name)
	var sprite : Sprite2D = Sprite2D.new()
	sprite.texture = gun_data.texture
	sprite.z_index = 10
	add_child(sprite)
