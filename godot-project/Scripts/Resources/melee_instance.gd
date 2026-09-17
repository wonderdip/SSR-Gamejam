extends Area2D
class_name MeleeInstance

var melee_data: MeleeData
var damage: float
var swings: int

@export var trail_particles: GPUParticles2D
@export var melee_sprite: Sprite2D
@export var collision_shape: CollisionShape2D
@export var hit_particle: GPUParticles2D
@export var animation_player: AnimationPlayer
@export var vfx: Node2D

var pivot: Marker2D
var dead_zone: float = 5.0
var player: Player
var is_swinging: bool = false
var swing_tween: Tween
var recharging: bool = false
var cooldown_time_left: float = 0.0

func _ready() -> void:
	pivot = player.melee_pos
	rotation = deg_to_rad(90)
	set_physics_layers()
	collision_shape.disabled = true
	body_entered.connect(_on_area_2d_body_entered)
	swings = melee_data.swings_before_cd
	
	if melee_data.equip_sound:
		AudioManager.play_sfx(melee_data.equip_sound,0 ,randf_range(0.95, 1.05))
	
func set_physics_layers():
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	set_collision_layer_value(4, true)
	
	set_collision_mask_value(3, true)
	set_collision_mask_value(5, true)
	
func _process(delta: float) -> void:
	if recharging:
		cooldown_time_left = max(cooldown_time_left - delta, 0.0)
	if not is_swinging:
		update_art()

	if Input.is_action_just_pressed("shoot") and swings > 0 and not recharging:
		if not is_swinging:
			swing()



func update_art():
	if is_swinging:
		return
	var mouse_pos = get_global_mouse_position()
	var pivot_pos = pivot.global_position
	pivot.global_rotation = (mouse_pos - pivot_pos).angle()

	melee_sprite.flip_h = mouse_pos.x < pivot_pos.x - dead_zone
	
	if vfx:
		if melee_sprite.flip_h:
			vfx.scale.x = -1
		else:
			vfx.scale.x = 1
		
func swing():
	is_swinging = true
	collision_shape.disabled = false
	swings -= 1

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
		func(angle: float): pivot.global_rotation = angle,
		base_angle, start_angle, windup_time
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	AudioManager.play_sfx(melee_data.swing_sound, 0.0, randf_range(0.95, 1.05))

	if trail_particles:
		trail_particles.emitting = true
		trail_particles.show()
	
	if animation_player:
		swing_tween.tween_callback(func():
			if animation_player.has_animation("slash"):
				var anim_len := animation_player.get_animation("slash").length
				animation_player.speed_scale = anim_len / strike_time
				animation_player.play("slash")
		)

	swing_tween.tween_method(
		func(angle: float): pivot.global_rotation = angle,
		start_angle, end_angle, strike_time
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)

	swing_tween.tween_callback(_end_swing)
	
func _end_swing():
	is_swinging = false
	collision_shape.disabled = true
	if trail_particles:
		trail_particles.hide()
		trail_particles.emitting = false

	if swings <= 0 and not recharging:
		_start_cooldown()

func _start_cooldown() -> void:
	recharging = true
	cooldown_time_left = melee_data.cooldown
	
	var timer := get_tree().create_timer(melee_data.cooldown)
	melee_sprite.modulate = Color.BLACK
	
	var tween = create_tween()
	tween.tween_property(melee_sprite, "modulate", Color.WHITE, melee_data.cooldown)
	
	await timer.timeout
	tween.kill()
	
	if not is_instance_valid(self):
		return
		
	swings = melee_data.swings_before_cd
	recharging = false
	cooldown_time_left = 0.0
	
func _on_area_2d_body_entered(body: Node):
	#particles.emitting = true
	if body.has_method("take_damage"):
		body.take_damage(melee_data.damage)
