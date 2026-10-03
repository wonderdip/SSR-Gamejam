extends Node2D
class_name GunInstance

var gun_data: GunData
var current_ammo: int

@export var gun_sprite: Sprite2D
@export var bullet_point: Marker2D

var pivot: Marker2D
var can_shoot: bool = true 
var reloading: bool = false
var dead_zone: float = 5.0
var player: Player
var reload_time_left: float = 0.0
var on_cooldown: bool = false

func _ready() -> void:
	pivot = player.gun_pos
	name = (ItemEnums.RARITIES.keys()[gun_data.rarity]
	 + " " + 
	gun_data.item_name)
	print(name)
	current_ammo = gun_data.magazine_size
	
func _process(delta: float):
	if reloading:
		reload_time_left = max(reload_time_left - delta, 0.0)
	call_deferred("update_art")
	
	if player.movement_locked:
		can_shoot = false
	else:
		can_shoot = true
	
	if Input.is_action_just_pressed("reload"):
		reload()
	
	if gun_data.holdable:
		if Input.is_action_pressed("shoot"):
			shoot()
	else:
		if Input.is_action_just_pressed("shoot"):
			shoot()
			
func update_art():
	var mouse_pos = get_global_mouse_position()
	var pivot_pos = pivot.global_position
	
	# Rotate the pivot toward the mouse
	var angle = (mouse_pos - pivot_pos).angle()
	pivot.global_rotation = angle
	
	# Flip sprite
	var delta_x = mouse_pos.x - pivot_pos.x
	if delta_x < -dead_zone:
		pivot.scale.y = -1
	elif delta_x > dead_zone:
		pivot.scale.y = 1

func shoot():
	if player.movement_locked or on_cooldown or reloading:
		return

	if current_ammo <= 0:
		reload()
		return

	on_cooldown = true
	current_ammo -= gun_data.bullet_count

	var base_angle = (get_global_mouse_position() - gun_sprite.global_position).angle()
	base_angle += deg_to_rad(randf_range(-gun_data.accuracy, gun_data.accuracy))

	for i in range(gun_data.bullet_count):
		var new_bullet = BulletInstance.new()
		new_bullet.bullet_data = gun_data.bullet
		new_bullet.global_position = bullet_point.global_position
		new_bullet.damage = gun_data.damage

		if gun_data.bullet_count == 1:
			new_bullet.rotation = base_angle
		else:
			var arc_rad = deg_to_rad(gun_data.shot_radius)
			var increment = arc_rad / (gun_data.bullet_count - 1)
			new_bullet.global_rotation = base_angle + (increment * i - arc_rad / 2)

		call_deferred("add_child", new_bullet)

	ScreenSfx.cam_shake(1, 0.5, 0.1)  # moved out of the loop so shotguns don't stack shakes

	await get_tree().create_timer(gun_data.shot_delay).timeout
	on_cooldown = false

	if current_ammo <= 0:
		reload()
	
func reload():
	if reloading or current_ammo >= gun_data.magazine_size:
		return

	reloading = true
	can_shoot = false
	reload_time_left = gun_data.reload_time

	var reload_timer = get_tree().create_timer(gun_data.reload_time)
	await reload_timer.timeout

	if is_instance_valid(self) and not is_queued_for_deletion():
		current_ammo = gun_data.magazine_size
		reloading = false
		can_shoot = true
		reload_time_left = 0.0
