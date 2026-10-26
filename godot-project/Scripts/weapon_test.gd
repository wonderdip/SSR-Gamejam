extends Node2D
class_name WeaponTester


@onready var v_box_container: VBoxContainer = $Control/ScrollContainer/VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for weapon in ItemManager._all_weapons:
		var button = Button.new()
		if weapon is GunData:
			button.text = weapon.gun_data.item_name
		else:
			button.text = weapon.melee_data.item_name
		button.button_pressed.connect(_on_button_pressed.bind(weapon))
		v_box_container.add_child(button)
		
func _on_button_pressed(weapon: ItemData):
	_spawn_pickup(weapon)
		

func _spawn_pickup(data: ItemData) -> void:
	var pickup := WeaponPickup.new()
	pickup.item_data = data
	add_child(pickup)
	
	pickup.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(pickup, "scale", Vector2(1, 1), 0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
