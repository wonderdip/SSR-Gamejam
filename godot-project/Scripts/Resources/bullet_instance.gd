extends Area2D
class_name BulletInstance

@export var bullet_data: BulletData
var collision_shape: CollisionShape2D
var damage: float
var travelled_distance = 0
var sprite: Sprite2D

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
	hide_sprite_temporarily()

func hide_sprite_temporarily():
	# Hide sprite immediately when the bullet is created
	sprite.hide()
	await get_tree().create_timer(0.05).timeout
	sprite.show()
	
	
func _physics_process(delta):
	
	var direction = Vector2.RIGHT.rotated(rotation)
	
	# Move the Node2D (root) position
	global_position += direction * bullet_data.speed * delta
	
	travelled_distance += bullet_data.speed * delta
	
	if travelled_distance > bullet_data.max_distance:
		queue_free()

func _on_area_2d_body_entered(body):
	if body is TileMapLayer:
		queue_free()
