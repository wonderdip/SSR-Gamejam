extends Node2D
class_name Door

@onready var trigger: RoomTransitionTrigger = %Trigger
@onready var collision_shape_2d: CollisionShape2D = $Trigger/CollisionShape2D
@onready var left_door: Node2D = %LeftDoor
@onready var right_door: Node2D = %RightDoor
@onready var top_door: Node2D = %TopDoor
@onready var bottom_door: Node2D = %BottomDoor
@export var trigger_y_offset: int = 8
@export var trigger_x_offset: int = 8

@export var locked_color: Color = Color(0.675, 0.0, 0.102, 1.0)  # same red as the scene
@export var unlocked_color: Color = Color(0.1, 0.8, 0.25)
@export var blocker_offset: float = 8.0  # trigger is 8px inside the room; this puts the blocker on the room edge

var locked: bool = false
var _lights: Array[PointLight2D] = []
var _blocker_shape: CollisionShape2D

func _ready() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 16
	body.collision_mask = 0
	body.position = Vector2(0, -blocker_offset)

	var rect := RectangleShape2D.new()
	rect.size = Vector2((collision_shape_2d.shape as RectangleShape2D).size.x, 8)
	_blocker_shape = CollisionShape2D.new()
	_blocker_shape.shape = rect
	_blocker_shape.disabled = true

	body.add_child(_blocker_shape)
	trigger.add_child(body)

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
	
	for visual in [left_door, right_door, top_door, bottom_door]:
		if visual.visible:
			for child in visual.get_children():
				if child is PointLight2D:
					_lights.append(child)
	set_locked(false)

func set_locked(value: bool) -> void:
	locked = value
	var color := locked_color if locked else unlocked_color
	for light in _lights:
		light.color = color
	_blocker_shape.set_deferred("disabled", not locked)
	collision_shape_2d.set_deferred("disabled", locked)
	
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
