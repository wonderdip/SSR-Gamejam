extends StaticBody2D

@export var interaction_area: Area2D
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
		var gun: GunInstance = GunInstance.new()
		gun.gun_data = ItemManager.get_random_gun()
		player.add_child(gun)
		
		opened = true
