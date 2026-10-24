extends Node2D
class_name Room

@export var enemy_list: Array[PackedScene] = []
@export var room_size: Vector2 = Vector2(256, 144)
@export var is_boss_room: bool = false
var boss: Enemy

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
var spawned: bool = false
var exit_doors: Array[Door] = []

func spawn_enemies() -> void:
	if spawned or cleared or enemy_list.is_empty():
		return
	spawned = true
	for enemy in enemy_list:
		var enemy_instance = enemy.instantiate() as Enemy
		add_child(enemy_instance)
		var spawn_marker := get_node_or_null("BossSpawn") as Marker2D
		if is_boss_room and spawn_marker:
			enemy_instance.global_position = spawn_marker.global_position
			boss = enemy_instance
			boss.process_mode = Node.PROCESS_MODE_DISABLED  # frozen until the intro ends
		else:
			enemy_instance.global_position = (
				get_room_center() +
				Vector2(
					randi_range(-(room_size.x / 4), (room_size.x / 4)),
					randi_range(-(room_size.y / 4), (room_size.y / 4))
				)
			)
		enemy_instance.died.connect(_on_enemy_died)
		enemies_alive += 1

func play_boss_intro() -> void:
	var player: Player = SceneManager.player
	var cam := get_tree().get_first_node_in_group(&"room_camera") as RoomCamera
	player.movement_locked = true
	cam.follow_target = boss                # camera glides to the boss
	await get_tree().create_timer(1.2).timeout
	cam.follow_target = player              # and back to the player
	await get_tree().create_timer(0.6).timeout
	boss.process_mode = Node.PROCESS_MODE_INHERIT
	player.movement_locked = false
	LevelManager.main_cam.follow(player, get_room_rect())
	
func _on_enemy_died(_enemy: Enemy) -> void:
	enemies_alive -= 1
	if enemies_alive <= 0:
		cleared = true
		unlock_doors()
		if is_boss_room:
			spawn_portal()

func spawn_portal():
	pass

func lock_doors() -> void:
	for door in exit_doors:
		door.set_locked(true)

func unlock_doors() -> void:
	for door in exit_doors:
		door.set_locked(false)
			
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
		exit_doors.append(door)
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
	
func _tiles() -> Vector2i:
	return Vector2i(room_size / 16.0)

func _erase_left_doorway(tm: TileMapLayer) -> void:
	for y in range(_tiles().y / 2, _tiles().y / 2 + 2):
		tm.erase_cell(Vector2i(0, y))

func _erase_right_doorway(tm: TileMapLayer) -> void:
	for y in range(_tiles().y / 2, _tiles().y / 2 + 2):
		tm.erase_cell(Vector2i(_tiles().x - 1, y))

func _erase_up_doorway(tm: TileMapLayer) -> void:
	for x in range(_tiles().x / 2 - 1, _tiles().x / 2 + 1):
		tm.erase_cell(Vector2i(x, 0))
		tm.erase_cell(Vector2i(x, 1))

func _erase_down_doorway(tm: TileMapLayer) -> void:
	for x in range(_tiles().x / 2 - 1, _tiles().x / 2 + 1):
		tm.erase_cell(Vector2i(x, _tiles().y - 1))
		
		
