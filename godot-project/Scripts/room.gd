extends Node2D
class_name Room

@export var enemy_list: Array[PackedScene] = []
@export var room_size: Vector2 = Vector2(256, 144)

## Manually placed room vars
@export var starting_room: bool = false
@export var spawn_positions: Array[Vector2] = [
	Vector2(8, 72),
	Vector2(232, 72),
	Vector2(120, 10),
	Vector2(120, 120)
]

var dungeon_index: int = -1
var tilemaps: Array[TileMapLayer]
var discovered: bool = false

# Room.gd
var cleared: bool = false
var enemies_alive: int = 0

func spawn_enemies() -> void:
	if cleared or enemy_list.is_empty():
		return
	for enemy in enemy_list:
		var enemy_instance = enemy.instantiate() as Enemy
		add_child(enemy_instance)
		enemy_instance.global_position = (
			get_room_center() + 
			Vector2(
				randi_range(-(room_size.x / 4), (room_size.x / 4)),
				randi_range(-(room_size.y / 4), (room_size.y / 4))
				)
			)
		enemy_instance.died.connect(_on_enemy_died)
		enemies_alive += 1

func _on_enemy_died(_enemy: Enemy) -> void:
	enemies_alive -= 1
	if enemies_alive <= 0:
		cleared = true
			
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

		erase_wall_for_door(direction)

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

func erase_wall_for_door(direction: LevelManager.TRIGGERDIRECTION) -> void:
	for child in get_children():
		if child is TileMapLayer:
			var tilemap := child as TileMapLayer
			
			match direction:
				LevelManager.TRIGGERDIRECTION.LEFT:
					_erase_left_doorway(tilemap)
				LevelManager.TRIGGERDIRECTION.RIGHT:
					_erase_right_doorway(tilemap)
				LevelManager.TRIGGERDIRECTION.UP:
					_erase_up_doorway(tilemap)
				LevelManager.TRIGGERDIRECTION.DOWN:
					_erase_down_doorway(tilemap)
	
func _erase_left_doorway(tilemap: TileMapLayer) -> void:
	for y in range(4, 6):
		tilemap.erase_cell(Vector2i(0, y))
	
func _erase_right_doorway(tilemap: TileMapLayer) -> void:
	for y in range(4, 6):
		tilemap.erase_cell(Vector2i(15, y))
		
func _erase_up_doorway(tilemap: TileMapLayer) -> void:
	for x in range(7, 9):
		tilemap.erase_cell(Vector2i(x, 0))
	for x in range(7, 9):
		tilemap.erase_cell(Vector2i(x, 1))

func _erase_down_doorway(tilemap: TileMapLayer) -> void:
	for x in range(7, 9):
		tilemap.erase_cell(Vector2i(x, 8))
		
		
