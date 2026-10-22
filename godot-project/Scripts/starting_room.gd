extends Room
class_name StartingRoom

@onready var first_weapon: WeaponPickup = %FirstWeapon
@onready var book: WeaponPickup = %Book
@onready var interaction_trigger: Area2D = $InteractionTrigger

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var inv = SceneManager.player.inventory
	if LevelManager.main_cam:
		LevelManager.main_cam.set_enabled(true)
		
	if not inv.unique_items.is_empty():
		book.queue_free()
			
