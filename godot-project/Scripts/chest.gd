extends StaticBody2D

@export var interaction_area: Area2D
@export var animation_player: AnimationPlayer
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
		var weapon : ItemData = ItemManager.get_random_weapon()
		player.inventory.add_item(weapon)
		opened = true
