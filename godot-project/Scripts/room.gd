extends Node2D
class_name Room

## room_size must match every template (256x144 here, matching the game's
## viewport) since LevelManager positions rooms on a uniform grid.
@export var room_size: Vector2 = Vector2(256, 144)

## Legacy fields, still usable for hand-placed rooms (e.g. a tutorial room
## that isn't part of a generated floor). Procedurally generated floors place
## the player via get_room_center() instead and don't need these.
@export var starting_room: bool = false
@export var spawn_positions: Array[Vector2] = [
	Vector2(8, 72),
	Vector2(232, 72),
	Vector2(120, 10),
	Vector2(120, 120)
]

var dungeon_index: int = -1

func get_room_rect() -> Rect2:
	return Rect2(global_position, room_size)

func get_room_center() -> Vector2:
	return global_position + room_size / 2.0

## Spawns a Door at each active direction's standard socket position and
## returns {direction: RoomTransitionTrigger} so the caller (LevelManager)
## can wire target_room once it knows the neighbouring rooms. Directions not
## included are left as whatever the template's base art shows — author
## every template fully closed, since doors are additive.
func configure_exits(active_directions: Array[LevelManager.TRIGGERDIRECTION], door_scene: PackedScene) -> Dictionary:
	var doors: Dictionary = {}
	for direction in active_directions:
		var door: Door = door_scene.instantiate()
		add_child(door)
		door.position = _socket_position(direction)
		door.set_direction(direction)
		doors[direction] = door.trigger
	return doors

func _socket_position(direction: LevelManager.TRIGGERDIRECTION) -> Vector2:
	match direction:
		LevelManager.TRIGGERDIRECTION.LEFT:
			return Vector2(0.0, room_size.y / 2.0)
		LevelManager.TRIGGERDIRECTION.RIGHT:
			return Vector2(room_size.x, room_size.y / 2.0)
		LevelManager.TRIGGERDIRECTION.UP:
			return Vector2(room_size.x / 2.0, 0.0)
		_:
			return Vector2(room_size.x / 2.0, room_size.y)
