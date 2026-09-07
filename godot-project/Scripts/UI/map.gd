extends Node2D
class_name Map

@export_category("Icons")
@export var normal_room_icon: Texture2D
@export var boss_room_icon: Texture2D
@export var reward_room_icon: Texture2D
@export var coin_room_icon: Texture2D
@export var secret_room_icon: Texture2D
@export var player_icon: Texture2D

@export_category("Layout")
@export var cell_size: Vector2 = Vector2(8, 8)

var dungeon_generator: DungeonGenerator

var _room_icons: Array[Sprite2D] = []
var _player_icon: Sprite2D

func _ready() -> void:
	dungeon_generator = LevelManager.dungeon_generator
	dungeon_generator.generation_started.connect(_clear_room_icons)
	dungeon_generator.room_added.connect(_draw_room_icon)
	dungeon_generator.generation_complete.connect(_draw_player_icon)
	LevelManager.player_icon_update.connect(_update_player_icon)
	
func _clear_room_icons() -> void:
	for icon in _room_icons:
		icon.queue_free()
	_room_icons.clear()

func _draw_room_icon(index: int, room_type: String) -> void:
	var texture: Texture2D = _icon_for_type(room_type)
	if texture == null:
		return

	var x: int = index % dungeon_generator.grid_cols
	var y: int = index / dungeon_generator.grid_cols

	var icon := Sprite2D.new()
	icon.texture = texture
	icon.position = Vector2(x, y) * cell_size
	add_child(icon)
	_room_icons.append(icon)

func _icon_for_type(room_type: String) -> Texture2D:
	match room_type:
		"cell":
			return normal_room_icon
		"boss":
			return boss_room_icon
		"reward":
			return reward_room_icon
		"coin":
			return coin_room_icon
		"secret":
			return secret_room_icon
		_:
			return null
	
func _draw_player_icon(
	_floorplan: Array[int], 
	_boss_rooms: Array[int], 
	_reward_rooms: Array[int], 
	_coin_rooms: Array[int], 
	_secret_rooms: Array[int]
) -> void:

	if _player_icon != null:
		_player_icon.queue_free()

	_player_icon = Sprite2D.new()
	_player_icon.texture = player_icon
	add_child(_player_icon)

	_update_player_icon()
	
func _update_player_icon() -> void:
	var index: int = LevelManager.player_room_index
	
	if index < 0:
		return
	
	var x: int = index % dungeon_generator.grid_cols
	var y: int = index / dungeon_generator.grid_cols
	
	var target_position: Vector2 = Vector2(x, y) * cell_size
	var pos_tween = create_tween()
	pos_tween.tween_property(_player_icon, "position", target_position, 0.25
	).set_trans(Tween.TRANS_BACK
	).set_ease(Tween.EASE_IN_OUT)
	
	
