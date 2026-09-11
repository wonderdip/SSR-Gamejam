extends Area2D
class_name BulletInstance

@export var bullet_data: BulletData
var collision_shape: CollisionShape2D
var damage: float
var travelled_distance = 0
var sprite: Sprite2D
var particles: GPUParticles2D
var can_move: bool = true
var has_hit: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	set_collision_layer_value(4, true)
	
	set_collision_mask_value(3, true)
	set_collision_mask_value(5, true)
	
	collision_shape = CollisionShape2D.new()
	collision_shape.shape = bullet_data.area_shape.duplicate()
	add_child(collision_shape)
	
	sprite = Sprite2D.new()
	sprite.texture = bullet_data.texture
	sprite.z_index = 11
	add_child(sprite)
	
	top_level = true
	
	particles = GPUParticles2D.new()
	particles.process_material = bullet_data.collision_particles
	particles.explosiveness = 1.0
	particles.lifetime = 0.2
	particles.one_shot = true
	particles.emitting = false
	particles.amount = 12
	particles.z_index = 11
	add_child(particles)
	hide_sprite_temporarily()
	
	body_entered.connect(_on_area_2d_body_entered)
	
func hide_sprite_temporarily():
	# Hide sprite immediately when the bullet is created
	sprite.hide()
	await get_tree().create_timer(0.05).timeout
	sprite.show()
	
func _physics_process(delta):
	if can_move:
		var direction = Vector2.RIGHT.rotated(rotation)
		
		# Move the Node2D (root) position
		global_position += direction * bullet_data.speed * delta
		
		travelled_distance += bullet_data.speed * delta
		
		if travelled_distance > bullet_data.max_distance:
			queue_free()

func _on_area_2d_body_entered(body: Node):
	if has_hit or not body is TileMapLayer:
		return
	has_hit = true
	can_move = false
	sprite.hide()
	particles.emitting = true
	await get_tree().create_timer(particles.lifetime).timeout
	queue_free()
