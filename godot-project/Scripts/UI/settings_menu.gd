extends CanvasLayer

const RESOLUTIONS := [
	Vector2i(256, 144),
	Vector2i(256*2, 144*2),
	Vector2i(256*3, 144*3),
	Vector2i(256*4, 144*4),
	Vector2i(256*5, 144*5),
]

enum ScreenMode {
	WINDOWED,
	BORDERLESS,
	FULLSCREEN
}

@export var default_res: int = 3
@onready var master_slider: HSlider = %MasterVolSlider
@onready var music_slider: HSlider = %MusicVolSlider
@onready var sfx_slider: HSlider = %SFXVolSlider
@onready var pause_menu: CanvasLayer = $"../PauseMenu"

var from_pause_menu : bool = false
var current_res : Vector2i = RESOLUTIONS[0]

func _ready() -> void:
	hide()
	master_slider.value = get_bus_volume("Master")
	music_slider.value = get_bus_volume("Music")
	sfx_slider.value = get_bus_volume("SFX")
	_on_resolution_dropdown_item_selected(default_res)
	SceneManager.scene_changed.connect(_scene_changed)

func _scene_changed(scene: Node):
	if scene.name == "TitleScreen": scene.open_settings.connect(open_from_title)

func open_from_title():
	show()

func set_bus_volume(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)

	if bus_index == -1:
		return

	value = max(value, 0.0001)
	AudioServer.set_bus_mute(bus_index, false)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

func get_bus_volume(bus_name: String) -> float:
	var bus_index := AudioServer.get_bus_index(bus_name)

	if bus_index == -1:
		return 1.0

	return clamp(db_to_linear(AudioServer.get_bus_volume_db(bus_index)), 0.0, 1.0)

func _on_back_button_pressed() -> void:
	hide()
	if from_pause_menu == true:
		pause_menu.show()

func _on_visibility_changed() -> void:
	
	if visible and get_tree().paused:
		get_tree().paused = true
		from_pause_menu = true
		
	if visible and not get_tree().paused:
		get_tree().paused = true
		from_pause_menu = false

	if not visible:
		get_tree().paused = false

func _on_resolution_dropdown_item_selected(index: int) -> void:
	current_res = RESOLUTIONS[index]
	DisplayServer.window_set_size(current_res)
	
	var screen : int = DisplayServer.window_get_current_screen()
	var screen_pos : Vector2i = DisplayServer.screen_get_position(screen)
	var screen_size : Vector2i = DisplayServer.screen_get_size(screen)
	var window_offset: Vector2i = (screen_size - current_res)
	@warning_ignore("integer_division")
	var window_position : Vector2i = screen_pos + (window_offset / 2)
	
	DisplayServer.window_set_position(window_position)
	
func _on_screen_mode_dropdown_item_selected(index: int) -> void:
	match index:
		ScreenMode.WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_size(current_res)

		ScreenMode.BORDERLESS:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_size(current_res)

		ScreenMode.FULLSCREEN:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_vsync_toggle_toggled(toggled_on: bool) -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if toggled_on else DisplayServer.VSYNC_DISABLED
	)

func _on_master_vol_slider_value_changed(value: float) -> void:
	set_bus_volume("Master", value)

func _on_music_vol_slider_value_changed(value: float) -> void:
	set_bus_volume("Music", value)

func _on_sfx_vol_slider_value_changed(value: float) -> void:
	set_bus_volume("SFX", value)
