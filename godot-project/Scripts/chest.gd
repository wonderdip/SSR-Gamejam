extends StaticBody2D

@export var interaction_area: Area2D
@export var animation_player: AnimationPlayer
@export var specific_reward: ItemData
@export var particles: GPUParticles2D

var can_open: bool = false
var opened: bool = false
var player: Player = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interaction_area.body_entered.connect(_on_played_entered_interaction_area)

func _on_played_entered_interaction_area(body: Node):
	if body is Player:
		player = body
		can_open = true
	
func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("interact")
	and not event.is_echo()
	and not opened
	and can_open):
		animation_player.play("open_chest")
		await animation_player.animation_finished
		particles.restart()
		
		var weapon : ItemData
		
		if specific_reward: weapon = specific_reward
		else: weapon = ItemManager.get_random_weapon()
		
		_spawn_pickup(weapon)
		opened = true
		$Sprite2D.modulate = Color.DIM_GRAY
		

func _spawn_pickup(data: ItemData) -> void:
	var pickup := WeaponPickup.new()
	pickup.item_data = data
	get_parent().add_child(pickup)
	pickup.global_position =\
	global_position + Vector2(randi_range(-10, 10), randi_range(-10, 10))
	
	pickup.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(pickup, "scale", Vector2(1, 1), 0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	
	
