extends Area2D
class_name WeaponPickup

var instance: Node
@export var item_data: ItemData
@export var texture_scale: Vector2
var player: Player = null
var prompt: Label
var shader_material: ShaderMaterial

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(2, true)   # Items
	set_collision_mask_value(1, true)    # Player

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	shape.shape = circle
	add_child(shape)

	var sprite := Sprite2D.new()
	sprite.scale = texture_scale if texture_scale else Vector2(0.7, 0.7)
	if rotation_degrees != 0:
		sprite.rotate(rotation)
		rotation_degrees = 0
	sprite.texture = item_data.texture
	
	shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://Shader/Shine.gdshader")
	shader_material.set_shader_parameter("shine_size", 0.06)
	sprite.material = shader_material
	
	add_child(sprite)
	
	prompt = Label.new()
	prompt.text = "E"
	prompt.add_theme_font_size_override("font_size", 8)
	prompt.custom_minimum_size.x = 16
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.position = Vector2(-8, -16)   # -8 = half of the 16px width
	prompt.z_index = 10
	prompt.hide()
	add_child(prompt)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	shine()
	
func shine():
	while true:
		var shine_tween := create_tween()
		
		shader_material.set_shader_parameter("shine_progress", 1.0)
		
		shine_tween.tween_method(
			func(value): shader_material.set_shader_parameter("shine_progress", value),
			1.0,
			0.0,
			2.5
		)
		
		await shine_tween.finished
		
		# Optional delay between shines
		await get_tree().create_timer(1).timeout

func _on_body_entered(body: Node) -> void:
	if body is Player:
		player = body
		prompt.show()

func _on_body_exited(body: Node) -> void:
	if body == player:
		player = null
		prompt.hide()

func _input(event: InputEvent) -> void:
	if player and event.is_action_pressed("interact") and not event.is_echo():
		get_viewport().set_input_as_handled()
		var inv := player.inventory
		inv.add_item(item_data, instance)
		queue_free()

func _exit_tree() -> void:
	if instance and is_instance_valid(instance) and instance.get_parent() == null:
		instance.free()
