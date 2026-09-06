extends Node

signal scene_changed(new_scene: Node)
signal exiting_level(dir: TRIGGERDIRECTION, ascending: bool, forced_room: PackedScene)
signal gameloop_started

enum TRIGGERDIRECTION { LEFT, RIGHT, UP, DOWN }
enum RoomType { NORMAL, CHEST, ITEM, BOSS }

@export_category("Fade")
@export var fade_duration: float = 0.4
@export var fade_color: Color = Color.BLACK

@export_category("Player")
@export var player_scene: PackedScene

@export_category("Room Info")
@export var floor_num: int = 0
@export var floor_ascension_scene: PackedScene
@export var normal_rooms: Array[PackedScene] = []
@export var chest_rooms: Array[PackedScene] = []
@export var item_rooms: Array[PackedScene] = []
@export var boss_rooms: Array[PackedScene] = []

var current_scene: Node = null
var player: Player = null

var _container: Node = null
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _entry_direction: TRIGGERDIRECTION = TRIGGERDIRECTION.DOWN

func _ready() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = fade_color
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.modulate.a = 0.0
	_fade_layer.add_child(_fade_rect)

	exiting_level.connect(_on_exiting_level)

	if player_scene != null:
		player = player_scene.instantiate()
		player.name = "Player"

func register_container(container: Node) -> void:
	_container = container
	if _container.get_child_count() > 0:
		current_scene = _container.get_child(0)
		_place_player_in_current_scene()

func _on_exiting_level(dir: TRIGGERDIRECTION, ascending: bool, forced_room: PackedScene) -> void:
	# Room-selection strategy lives here — swap _pick_room_type() out for
	# whatever progression rule you want (guaranteed boss every N rooms,
	# weighted chest/item odds, etc). Defaults to always-normal for now.
	if ascending:
		floor_num += 1
		await _transition_to(floor_ascension_scene)
		return

	if forced_room != null:
		_entry_direction = _opposite_direction(dir)
		await _transition_to(forced_room)
		return

	var room_type: RoomType = _pick_room_type()
	var pool: Array[PackedScene] = _pool_for(room_type)

	if pool.is_empty():
		push_error("SceneManager: no rooms registered for room type %s" % RoomType.keys()[room_type])
		return

	var next_room: PackedScene = pool[randi() % pool.size()]
	_entry_direction = _opposite_direction(dir)
	await _transition_to(next_room)

func _pick_room_type() -> RoomType:
	return RoomType.NORMAL

func _pool_for(room_type: RoomType) -> Array[PackedScene]:
	match room_type:
		RoomType.CHEST:
			return chest_rooms
		RoomType.ITEM:
			return item_rooms
		RoomType.BOSS:
			return boss_rooms
		_:
			return normal_rooms

func _opposite_direction(dir: TRIGGERDIRECTION) -> TRIGGERDIRECTION:
	match dir:
		TRIGGERDIRECTION.LEFT:
			return TRIGGERDIRECTION.RIGHT
		TRIGGERDIRECTION.RIGHT:
			return TRIGGERDIRECTION.LEFT
		TRIGGERDIRECTION.UP:
			return TRIGGERDIRECTION.DOWN
		_:
			return TRIGGERDIRECTION.UP

func goto_scene(path: String) -> void:
	var packed_scene: PackedScene = load(path)
	if packed_scene == null:
		push_error("SceneManager: failed to load scene at path: %s" % path)
		return
	await _transition_to(packed_scene)

func goto_packed_scene(packed_scene: PackedScene) -> void:
	await _transition_to(packed_scene)

func _transition_to(packed_scene: PackedScene) -> void:
	await fade_out()
	call_deferred("_deferred_swap_scene", packed_scene)

func _deferred_swap_scene(packed_scene: PackedScene) -> void:
	if _container == null:
		push_error("SceneManager: no container registered — call register_container() first")
		return

	if player != null and player.get_parent() != null:
		player.get_parent().remove_child(player)

	if current_scene != null:
		current_scene.free()

	current_scene = packed_scene.instantiate()
	_container.add_child(current_scene)
	_place_player_in_current_scene()

	scene_changed.emit(current_scene)
	await fade_in()

func _place_player_in_current_scene() -> void:
	if player == null or current_scene == null:
		return
	
	if player.get_parent() != current_scene:
		if player.get_parent() != null:
			player.get_parent().remove_child(player)
		current_scene.add_child(player)

	if current_scene is Room:
		var room: Room = current_scene as Room
		var index: int = 0 if room.starting_room else _entry_direction
		player.global_position = room.spawn_positions[index]
		player.show()
		player._entering_level()
	else:
		player.hide()
	

func fade_out() -> void:
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween: Tween = create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, fade_duration)
	await tween.finished

func fade_in() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 0.0, fade_duration)
	await tween.finished
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
