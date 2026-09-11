extends Node2D
class_name GunInstance

@export var gun_data: GunData
@export var current_ammo: int

var gun_sprite: Sprite2D
var bullet_point : Marker2D

var pivot: Marker2D
var can_shoot: bool = true 
var reloading: bool = false
var dead_zone: float = 5.0
var player: Player

func _ready() -> void:
	name = (ItemEnums.RARITIES.keys()[gun_data.rarity]
	 + " " + 
	gun_data.item_name)
	
	
	print(name)
	pivot = SceneManager.player.gun_pos
	
	bullet_point = Marker2D.new()
	bullet_point.position = gun_data.bullet_pos
	add_child(bullet_point)
	
	gun_sprite = Sprite2D.new()
	gun_sprite.texture = gun_data.texture
	gun_sprite.z_index = 10
	add_child(gun_sprite)
	
	current_ammo = gun_data.magazine_size
	
func _process(_delta):
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
	# Don't reload if we're already reloading or if the magazine is already full
	if reloading or current_ammo >= gun_data.magazine_size:
		return
	
	# Start reload process
	reloading = true
	can_shoot = false  # Disable shooting while reloading
	
	# Create a timer for reload
	var reload_timer = get_tree().create_timer(gun_data.reload_time)
	
	# Wait for reload time to complete
	await reload_timer.timeout
	
	# Only complete the reload if the gun still exists and hasn't been removed
	if is_instance_valid(self) and not is_queued_for_deletion():
		# Reload complete
		current_ammo = gun_data.magazine_size
		reloading = false
		can_shoot = true
