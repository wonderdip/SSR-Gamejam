extends Node2D
class_name WeaponTester

@onready var v_box_container: VBoxContainer = $Control/ScrollContainer/VBoxContainer
@onready var dps_label: Label = $Control/Dps  # adjust to your label's actual path
@onready var player: Player = $Player

var current_weapon: ItemData


func _ready() -> void:
	_update_dps_label()
	for weapon in ItemManager._all_weapons:
		var button := Button.new()
		button.text = weapon.item_name
		button.pressed.connect(_on_button_pressed.bind(weapon))
		v_box_container.add_child(button)


func _on_button_pressed(weapon: ItemData) -> void:
	current_weapon = weapon
	_update_dps_label()
	_spawn_pickup(weapon)


func _update_dps_label() -> void:
	if current_weapon == null:
		dps_label.text = "DPS: -"
		return
	dps_label.text = "DPS: %.1f" % _calculate_dps(current_weapon)


func _calculate_dps(weapon: ItemData) -> float:
	# If fire_rate is shots per second:
	if weapon is GunData:
		return ((weapon.damage * weapon.magazine_size) / ((
			weapon.magazine_size * weapon.shot_delay) + weapon.reload_time)
			) * weapon.bullet_count
	elif weapon is MeleeData:
		return (weapon.damage * weapon.swings_before_cd) / ((
			weapon.swings_before_cd / weapon.swing_speed) + weapon.cooldown)
	else: return 0.0
	# If you store a cooldown (seconds between shots) instead:
	# return weapon.damage / weapon.cooldown


func _spawn_pickup(data: ItemData) -> void:
	var pickup := WeaponPickup.new()
	pickup.item_data = data
	pickup.global_position = player.global_position
	add_child(pickup)

	pickup.scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(pickup, "scale", Vector2.ONE, 0.5) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
