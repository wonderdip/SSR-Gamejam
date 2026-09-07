extends Node2D
class_name Door

## Reusable exit piece. Room.configure_exits() instantiates one of these per
## needed direction and positions it at that side's socket — this is what
## replaces hand-placing a LevelTrigger (and repainting walls) per template.
##
## Assumes the door art is drawn facing UP and can be rotated in 90-degree
## steps to face the other three directions without looking wrong. If your
## door art isn't symmetric enough for that, swap _rotation_for()'s rotation
## with switching between four child visual variants instead.

@onready var trigger: RoomTransitionTrigger = %Trigger
@onready var left_door: Node2D = %LeftDoor
@onready var right_door: Node2D = %RightDoor
@onready var top_door: Node2D = %TopDoor
@onready var bottom_door: Node2D = %BottomDoor

func set_direction(direction: LevelManager.TRIGGERDIRECTION) -> void:
	trigger.direction = direction
	trigger.rotation = _rotation_for(direction)
	
	match direction:
		LevelManager.TRIGGERDIRECTION.LEFT:
			left_door.show()
		LevelManager.TRIGGERDIRECTION.RIGHT:
			right_door.show()
		LevelManager.TRIGGERDIRECTION.UP:
			top_door.show()
		LevelManager.TRIGGERDIRECTION.DOWN:
			bottom_door.show()
			
func _rotation_for(direction: LevelManager.TRIGGERDIRECTION) -> float:
	match direction:
		LevelManager.TRIGGERDIRECTION.UP:
			return 0.0
		LevelManager.TRIGGERDIRECTION.RIGHT:
			return PI / 2.0
		LevelManager.TRIGGERDIRECTION.DOWN:
			return PI
		_:
			return -PI / 2.0
