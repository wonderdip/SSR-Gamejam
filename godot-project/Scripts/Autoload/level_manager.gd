extends Node

signal ascend_requested()
signal player_icon_update()

enum TRIGGERDIRECTION { LEFT, RIGHT, UP, DOWN }
enum RoomType { NORMAL, CHEST, ITEM, BOSS, SECRET }

@export var ascent_scene: PackedScene

@export_category("Dungeon Generation")
@export var dungeon_generator: DungeonGenerator
@export var door_scene: PackedScene ## the reusable Door piece — see door.gd

@export_category("Room Pools")
@export var normal_rooms: Array[PackedScene] = []
@export var chest_rooms: Array[PackedScene] = []
@export var item_rooms: Array[PackedScene] = []
@export var boss_rooms: Array[PackedScene] = []
@export var secret_rooms: Array[PackedScene] = []

var floor_num: int = 0
var player_room: Room
var player_room_index: int = -1
var in_dungeon: bool = false ## true while the dungeon (not the hub/other scenes) is the active view
var game_started: bool = false ## true once the player has reached the hub at least once this session

var _room_container: Node = null
var _room_type_by_index: Dictionary = {} ## int -> String, filled while generating
var _room_instances: Dictionary = {} ## int -> Room, this floor's rooms
var main_cam: Camera2D

func _ready() -> void:
	ascend_requested.connect(_on_ascend_requested)
	
	if dungeon_generator == null:
		dungeon_generator = DungeonGenerator.new()
		add_child(dungeon_generator)
	
	dungeon_generator.room_added.connect(_on_generator_room_added)
	dungeon_generator.generation_complete.connect(_on_generator_complete)
	dungeon_generator.generation_failed.connect(_on_generator_failed)

## Call once, after the dungeon root scene (containing the room container and
## RoomCamera) has been swapped in via SceneManager.
func register_container(room_container: Node) -> void:
	_room_container = room_container
	
func _on_ascend_requested() -> void:
	floor_num += 1
	SceneManager.goto_packed_scene(ascent_scene)

func _build_floor(with_fade_out: bool) -> void:
	if with_fade_out:
		await SceneManager.fade_out()

	_teardown_current_floor()
	_room_type_by_index.clear()
	dungeon_generator.generate()

func _teardown_current_floor() -> void:
	if SceneManager.player != null and SceneManager.player.get_parent() != null:
		SceneManager.player.get_parent().remove_child(SceneManager.player)

	for room in _room_instances.values():
		(room as Room).queue_free()
	_room_instances.clear()

func _on_generator_room_added(index: int, room_type: String) -> void:
	_room_type_by_index[index] = room_type

func _on_generator_complete(floorplan: Array[int], _boss: Array[int], _reward: Array[int], _coin: Array[int], _secret: Array[int]) -> void:
	_instantiate_floor(floorplan)
	_wire_room_doors(floorplan)
	_place_player_on_floor()
	await SceneManager.fade_in()

func _on_generator_failed() -> void:
	push_error("LevelManager: dungeon generation failed to produce a valid floor — retry or loosen its room-count settings")
	await SceneManager.fade_in()

func _instantiate_floor(floorplan: Array[int]) -> void:
	if _room_container == null:
		push_error("LevelManager: no room container registered — call register_container() first")
		return

	for index in range(floorplan.size()):
		if floorplan[index] != 1:
			continue

		var room_type: String = _room_type_by_index.get(index, "cell")
		var pool: Array[PackedScene] = _pool_for_generator_type(room_type)
		if pool.is_empty():
			push_warning("LevelManager: no scenes registered for room type '%s' — skipping index %d" % [room_type, index])
			continue
		
		var room: Room = pool[randi() % pool.size()].instantiate()
		
		var grid_x: int = index % dungeon_generator.grid_cols
		var grid_y: int = index / dungeon_generator.grid_cols
		
		room.dungeon_index = index
		room.position = Vector2(grid_x, grid_y) * room.room_size
		
		_room_container.add_child(room)
		_room_instances[index] = room

func _pool_for_generator_type(room_type: String) -> Array[PackedScene]:
	match room_type:
		"boss":
			return boss_rooms
		"reward":
			return item_rooms
		"coin":
			return chest_rooms
		"secret":
			return secret_rooms
		_:
			return normal_rooms

func _wire_room_doors(floorplan: Array[int]) -> void:
	var cols: int = dungeon_generator.grid_cols
	for index in _room_instances.keys():
		var room: Room = _room_instances[index]
		var active_directions: Array[TRIGGERDIRECTION] = []

		_collect_direction(index - 1, TRIGGERDIRECTION.LEFT, floorplan, active_directions)
		_collect_direction(index + 1, TRIGGERDIRECTION.RIGHT, floorplan, active_directions)
		_collect_direction(index - cols, TRIGGERDIRECTION.UP, floorplan, active_directions)
		_collect_direction(index + cols, TRIGGERDIRECTION.DOWN, floorplan, active_directions)

		var doors: Dictionary = room.configure_exits(active_directions, door_scene)
		for direction in doors.keys():
			var neighbour_index: int = _neighbour_index(index, direction, cols)
			var neighbour: Room = _room_instances.get(neighbour_index)
			if neighbour != null:
				(doors[direction] as RoomTransitionTrigger).target_room = room

func _collect_direction(neighbour_index: int, direction: TRIGGERDIRECTION, floorplan: Array[int], out: Array[TRIGGERDIRECTION]) -> void:
	if neighbour_index < 0 or neighbour_index >= floorplan.size():
		return
	if floorplan[neighbour_index] == 1:
		out.append(direction)

func _neighbour_index(index: int, direction: TRIGGERDIRECTION, cols: int) -> int:
	match direction:
		TRIGGERDIRECTION.LEFT:
			return index - 1
		TRIGGERDIRECTION.RIGHT:
			return index + 1
		TRIGGERDIRECTION.UP:
			return index - cols
		_:
			return index + cols

func initial_player_spawn():
	var player: Player = SceneManager.player
	if player == null:
		return
	
	var start_room: Room = SceneManager.current_scene as Room
	if start_room == null:
		push_error("LevelManager: no room was instantiated at the dungeon's start index")
		return

	if player.get_parent() != null:
		player.get_parent().remove_child(player)
	_room_container.add_child(player)
	
	player.global_position = start_room.spawn_positions[0]
	player.show()
	player._entering_level(true)
	_room_container.get_parent()._on_main_scene_changed(start_room)
	
	main_cam = get_tree().get_first_node_in_group(&"room_camera") as RoomCamera
	if main_cam != null:
		main_cam.snap_to_room(start_room.get_room_center(), start_room.get_room_rect())

	game_started = true

func _place_player_on_floor() -> void:
	var player: Player = SceneManager.player
	if player == null:
		return
	
	var start_index: int
	if player_room != null:
		start_index = player_room_index
	else:
		start_index = dungeon_generator.start_index
		
	var start_room: Room = _room_instances.get(start_index)
	
	if start_room == null:
		push_error("LevelManager: no room was instantiated at the dungeon's start index")
		return
	
	player_room_index = start_index
	player_room = start_room
	
	if player.get_parent() != null:
		player.get_parent().remove_child(player)
	_room_container.add_child(player)
	
	player.global_position = start_room.get_room_center()
	player.show()
	player._entering_level(true)
	
	main_cam = get_tree().get_first_node_in_group(&"room_camera") as RoomCamera
	if main_cam != null:
		main_cam.snap_to_room(start_room.get_room_center(), start_room.get_room_rect())

	in_dungeon = true

func set_player_room(room: Room) -> void:
	player_room = room
	player_room_index = room.dungeon_index
	player_icon_update.emit()
