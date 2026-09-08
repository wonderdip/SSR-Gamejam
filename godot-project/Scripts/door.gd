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
@onready var collision_shape_2d: CollisionShape2D = $Trigger/CollisionShape2D
@onready var left_door: Node2D = %LeftDoor
@onready var right_door: Node2D = %RightDoor
@onready var top_door: Node2D = %TopDoor
@onready var bottom_door: Node2D = %BottomDoor
@export var trigger_y_offset: int = 8
@export var trigger_x_offset: int = 8

func set_direction(direction: LevelManager.TRIGGERDIRECTION) -> void:
	trigger.direction = direction
	trigger.rotation = _rotation_for(direction)
	
	match direction:
		LevelManager.TRIGGERDIRECTION.LEFT:
			left_door.show()
			trigger.global_position.y += trigger_y_offset
			trigger.global_position.x += trigger_x_offset
			collision_shape_2d.debug_color = Color.RED
			
		LevelManager.TRIGGERDIRECTION.RIGHT:
			right_door.show()
			trigger.global_position.y += trigger_y_offset
			trigger.global_position.x -= trigger_x_offset
			collision_shape_2d.debug_color = Color.BLUE
			
		LevelManager.TRIGGERDIRECTION.UP:
			top_door.show()
			trigger.global_position.y += trigger_y_offset
			collision_shape_2d.debug_color = Color.GREEN
			
		LevelManager.TRIGGERDIRECTION.DOWN:
			bottom_door.show()
			trigger.global_position.y -= trigger_y_offset
			collision_shape_2d.debug_color = Color.YELLOW
	
	collision_shape_2d.debug_color.a = 0.5
	
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
