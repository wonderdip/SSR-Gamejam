extends Node2D
class_name GunInstance

@export var gun_data: GunData
@export var current_ammo: int

@onready var gun_sprite: Sprite2D = $GunSprite
@onready var bullet_point: Marker2D = $BulletPoint

var pivot: Marker2D
var can_shoot: bool = true 
var reloading: bool = false
var dead_zone: float = 5.0
var player: Player
var reload_time_left: float = 0.0

func _ready() -> void:
	pivot = player.gun_pos
	name = (ItemEnums.RARITIES.keys()[gun_data.rarity]
	 + " " + 
	gun_data.item_name)
	print(name)
	current_ammo = gun_data.magazine_size
	
func _process(_delta):
	if reloading:
		reload_time_left = max(reload_time_left - _delta, 0.0)
	call_deferred("update_art")
	
	if Input.is_action_just_pressed("reload"):
		reload()
	
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
	
	reloading = false
	can_shoot = true

func shoot():
	if not can_shoot or reloading:
		return  # Don't shoot if already reloading or on cooldown
	
	if current_ammo <= 0:
		reload()
		return
		
	# Handle bullet spread
	var angle = (get_global_mouse_position() - gun_sprite.global_position).angle()
	var random_offset = randf_range(-gun_data.accuracy, gun_data.accuracy)
	angle += deg_to_rad(random_offset)
	
	can_shoot = false  # Prevent instant re-shooting
	current_ammo -= gun_data.bullet_count  # Subtract ONE bullet per shot (not bullet_count)
	
	for i in range(gun_data.bullet_count):
		var new_bullet = BulletInstance.new()
		new_bullet.bullet_data = gun_data.bullet
		new_bullet.global_position = bullet_point.global_position
		new_bullet.damage = gun_data.damage
		
		if gun_data.bullet_count == 1:
			new_bullet.rotation = angle
		else:
			var arc_rad = deg_to_rad(gun_data.shot_radius)
			var increment = arc_rad / (gun_data.bullet_count - 1)
			new_bullet.global_rotation = angle + (increment * i - arc_rad / 2)
		
		call_deferred("add_child", new_bullet)
		
	await get_tree().create_timer(gun_data.shot_delay).timeout  # Apply shot delay
	# If out of bullets, start reload automatically
	if current_ammo <= 0:
		reload()
	else:
		can_shoot = true  # Otherwise, allow shooting again
	
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
