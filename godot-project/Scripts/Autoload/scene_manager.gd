extends Node

signal scene_changed(new_scene: Node)
signal scene_removed

@export_category("Fade")
@export var fade_duration: float = 0.4
@export var fade_color: Color = Color.BLACK

@export_category("Player")
@export var player_scene: PackedScene

var current_scene: Node = null
var player: Player = null

var _container: Node = null
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect

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

	if player_scene != null:
		player = player_scene.instantiate()
		player.name = "Player"

func register_container(container: Node) -> void:
	_container = container
	if _container.get_child_count() > 0:
		current_scene = _container.get_child(0)

func goto_scene(path: String) -> void:
	var packed_scene: PackedScene = load(path)
	if packed_scene == null:
		push_error("SceneManager: failed to load scene at path: %s" % path)
		return
	await _transition_to(packed_scene)

func remove_scene():
	current_scene.queue_free()
	scene_removed.emit()
	
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

	scene_changed.emit(current_scene)
	await fade_in()

func fade_out() -> void:
	print("made tween")
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween: Tween = create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, fade_duration)
	await tween.finished

func fade_in() -> void:
	print("made tween")
	var tween: Tween = create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 0.0, fade_duration)
	await tween.finished
	print("past tween")
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
