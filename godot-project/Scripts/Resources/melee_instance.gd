extends Area2D
class_name MeleeInstance

@export var melee_data: MeleeData
var damage: float 

var collision_shape: CollisionShape2D
var sprite: Sprite2D
var particles: GPUParticles2D

var pivot: Marker2D
var dead_zone: float = 5.0
var player: Player

func _ready() -> void:
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	set_collision_layer_value(4, true)
	
	set_collision_mask_value(3, true)
	set_collision_mask_value(5, true)
	
	pivot = SceneManager.player.melee_pos
	
	collision_shape = CollisionShape2D.new()
	collision_shape.shape = melee_data.collision_shape.duplicate()
	add_child(collision_shape)
	
	sprite = Sprite2D.new()
	sprite.texture = melee_data.texture
	sprite.z_index = 11
	add_child(sprite)
	
	position.y = melee_data.y_offset
	
	#particles = GPUParticles2D.new()
	#particles.process_material = melee_data.collision_particles
	#particles.explosiveness = 1.0
	#particles.lifetime = 0.2
	#particles.one_shot = true
	#particles.emitting = false
	#particles.amount = 12
	#particles.z_index = 11
	#add_child(particles)
	
	#body_entered.connect(_on_area_2d_body_entered)
	
func _physics_process(delta):
	var mouse_pos = get_global_mouse_position()
	var pivot_pos = pivot.global_position
	
	# Rotate the pivot toward the mouse
	var angle = (mouse_pos - pivot_pos).angle()
	pivot.global_rotation = angle

func _on_area_2d_body_entered(body: Node):
	particles.emitting = true
