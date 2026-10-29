extends Area2D

@export var damage: float = 50
@export var knockback: float = 200

func _ready() -> void:
	ScreenSfx.cam_shake(15, 5, 0.5)

func _on_body_entered(body: Node2D) -> void:
	
	if body is Enemy:
		body.take_damage(
			damage, Vector2.UP, knockback)
