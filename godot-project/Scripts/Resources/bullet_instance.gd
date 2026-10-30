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

var anim_timer: float = 0.0
var speed: float
var hit_bodies: Array[Node] = []
var animated: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	set_collision_layer_value(4, true)
	
	set_collision_mask_value(3, true)
	set_collision_mask_value(5, true)
	
	collision_shape = CollisionShape2D.new()
	collision_shape.shape = bullet_data.area_shape.duplicate()
	collision_shape.rotation_degrees = bullet_data.area_rotation
	collision_shape.position = bullet_data.offset
	add_child(collision_shape)
	
	sprite = Sprite2D.new()
	sprite.texture = bullet_data.texture
	sprite.z_index = 11
	if bullet_data.animated:
		sprite.hframes = bullet_data.hframes
		sprite.vframes = bullet_data.vframes
	sprite.material = bullet_data.material
	sprite.position = bullet_data.offset
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
	
	body_entered.connect(_on_area_2d_body_entered)
	speed = bullet_data.speed * randf_range(1.0 - bullet_data.speed_variance, 1.0 + bullet_data.speed_variance)
	
	animated = bullet_data.animated
	
	if animated:
		sprite.frame = randi_range(bullet_data.random_frame_range.x, bullet_data.random_frame_range.y)
		
	sprite.flip_v = randf() < 0.5 
	
	if bullet_data.area_grow:
		var shape: RectangleShape2D = bullet_data.area_shape.duplicate()
		collision_shape.shape = shape
		var full_length: float = bullet_data.area_shape.size.y
		shape.size.y = 0.0
		collision_shape.position.x = 0.0
		
		await get_tree().create_timer(bullet_data.windup).timeout
		
		var area_tween = create_tween()
		area_tween.tween_method(
			func(length: float):
				shape.size.y = length
				collision_shape.position.x = length / 2.0,
			0.0, full_length, bullet_data.grow_speed
		)
	
func _physics_process(delta):
	if animated and not has_hit:
		var last_frame = bullet_data.hframes * bullet_data.vframes - 1
		if sprite.frame >= last_frame and bullet_data.delete_on_anim_done:
			await get_tree().create_timer(1.0 / bullet_data.fps).timeout
			delete_bullet()
		
		if sprite.frame >= last_frame and not bullet_data.anim_loop:
			animated = false
			
		anim_timer += delta
		var frame_duration := 1.0 / bullet_data.fps
		if anim_timer >= frame_duration:
			anim_timer -= frame_duration
			sprite.frame = (sprite.frame + 1) % (bullet_data.hframes * bullet_data.vframes)
		
	if can_move:
		var direction = Vector2.RIGHT.rotated(rotation)
		global_position += direction * speed * delta
		travelled_distance += speed * delta

		var t := clampf(travelled_distance / bullet_data.max_distance, 0.0, 1.0)
		var s := lerpf(1.0, bullet_data.end_scale, t)
		sprite.scale = Vector2.ONE * s
		collision_shape.scale = Vector2.ONE * s    # hitbox grows with the visual
		if bullet_data.fade_out:
			sprite.modulate.a = 1.0 - t

		if travelled_distance > bullet_data.max_distance:
			delete_bullet()

func _on_area_2d_body_entered(body: Node):
	if has_hit:
		return
	
	if body is Enemy:
		if body in hit_bodies:
			return
		hit_bodies.append(body)
		body.take_damage(damage, Vector2.RIGHT.rotated(rotation), bullet_data.knockback)
		if not bullet_data.piercing:
			has_hit = true
			delete_bullet()
			
	elif body is TileMapLayer and not bullet_data.piercing:
		has_hit = true
		delete_bullet()

func delete_bullet():
	can_move = false
	sprite.hide()

	if bullet_data.end_scene:
		var scene : Node2D = bullet_data.end_scene.instantiate()
		if LevelManager.game_started:
			LevelManager._room_container.call_deferred("add_child", scene)
		else:
			get_parent().get_parent(
			).get_parent().get_parent().call_deferred("add_child", scene)
		scene.global_position = global_position
		
	if has_hit:
		particles.emitting = true
		await get_tree().create_timer(particles.lifetime).timeout
	queue_free()
