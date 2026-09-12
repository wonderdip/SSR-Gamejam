extends Area2D
class_name MeleeInstance

@export var melee_data: MeleeData
var damage: float 

var collision_shape: CollisionShape2D
var sprite: Sprite2D
var particles: GPUParticles2D
var trail_particles: GPUParticles2D
var slash: ColorRect

var pivot: Marker2D
var dead_zone: float = 5.0
var player: Player
var is_swinging: bool = false
var swing_tween: Tween

func _ready() -> void:
	pivot = SceneManager.player.melee_pos
	rotation = deg_to_rad(90)

	set_physics_layers()
	create_collision_shape()
	create_sprite()
	create_trail()
	
	collision_shape.disabled = true
	body_entered.connect(_on_area_2d_body_entered)

func create_collision_shape():
	collision_shape = CollisionShape2D.new()
	collision_shape.shape = melee_data.collision_shape.duplicate()
	collision_shape.position.y = melee_data.y_offset
	add_child(collision_shape)

func create_sprite():
	sprite = Sprite2D.new()
	sprite.texture = melee_data.texture
	sprite.offset.y = melee_data.y_offset
	sprite.z_index = 11
	add_child(sprite)

func set_physics_layers():
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	set_collision_layer_value(4, true)
	
	set_collision_mask_value(3, true)
	set_collision_mask_value(5, true)
	
func create_trail():
	trail_particles = GPUParticles2D.new()
	trail_particles.process_material = melee_data.trail
	trail_particles.texture = melee_data.slash_texture
	trail_particles.local_coords = true
	trail_particles.emitting = false
	trail_particles.amount = 16
	trail_particles.lifetime = 0.5
	trail_particles.z_index = 10
	trail_particles.texture = melee_data.texture
	add_child(trail_particles)
	trail_particles.position = sprite.offset
	
func create_hit_particle():
	particles = GPUParticles2D.new()
	particles.process_material = melee_data.collision_particles
	particles.explosiveness = 1.0
	particles.lifetime = 0.2
	particles.one_shot = true
	particles.emitting = false
	particles.amount = 12
	particles.z_index = 11
	add_child(particles)

func _physics_process(_delta):
	if not is_swinging:
		update_art()

	if Input.is_action_just_pressed("shoot"):
		if not is_swinging:
			swing()

func update_art():
	if is_swinging:
		return
	var mouse_pos = get_global_mouse_position()
	var pivot_pos = pivot.global_position
	pivot.global_rotation = (mouse_pos - pivot_pos).angle()

	sprite.flip_h = mouse_pos.x < pivot_pos.x - dead_zone
	var process_material: ParticleProcessMaterial = trail_particles.process_material
	
	if sprite.flip_h:
		trail_particles.scale.x = -1
	else:
		trail_particles.scale.x = 1
		
func swing():
	is_swinging = true
	collision_shape.disabled = false
	trail_particles.emitting = true
	
	var base_angle := pivot.global_rotation
	var half_arc: float = deg_to_rad(melee_data.swing_arc_degrees) / 2.0
	var duration: float = 1.0 / max(melee_data.swing_speed, 0.01)
	var windup_time: float = duration * 0.15
	var strike_time: float = duration * 0.85
	
	var mouse_pos : Vector2 = get_global_mouse_position()
	var pivot_pos : Vector2 = pivot.global_position
	var facing_left := mouse_pos.x < pivot_pos.x

	var start_angle: float
	var end_angle: float

	if facing_left:
		start_angle = base_angle + half_arc
		end_angle = base_angle - half_arc
	else:
		start_angle = base_angle - half_arc
		end_angle = base_angle + half_arc

	start_angle = base_angle + angle_difference(base_angle, start_angle)
	end_angle = base_angle + angle_difference(base_angle, end_angle)
	
	if swing_tween:
		swing_tween.kill()
	
	swing_tween = create_tween()
	
	swing_tween.tween_method(
		func(angle: float):
			pivot.global_rotation = angle,
		base_angle,
		start_angle,
		windup_time
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	AudioManager.play_sfx(melee_data.swing_sound, 0.0, randf_range(0.95, 1.05))
	
	swing_tween.tween_method(
		func(angle: float):
			pivot.global_rotation = angle,
		start_angle,
		end_angle,
		strike_time
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	
	swing_tween.tween_callback(_end_swing)

func _end_swing():
	is_swinging = false
	collision_shape.disabled = true
	trail_particles.emitting = false
	
func _on_area_2d_body_entered(body: Node):
	#particles.emitting = true
	if body.has_method("take_damage"):
		body.take_damage(melee_data.damage)
