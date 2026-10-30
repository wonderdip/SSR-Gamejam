extends Control
class_name StatHUD

@export var COUNTER_LIT : Color = Color(1, 1, 1, 1)
@export var COUNTER_SPENT : Color = Color(0.15, 0.15, 0.15, 1)

@onready var weapon_icon: TextureRect = $Icon
@onready var panel: NinePatchRect = $Panel
@onready var container: HBoxContainer = $Container
@onready var health_bar: TextureProgressBar = $HealthBar

@export var melee_counter_texture: Texture2D
@export var bullet_counter_texture: Texture2D

var player: Player
var _tween: Tween

func _ready() -> void:
	player = SceneManager.player
	player.inventory.active_weapon_changed.connect(_on_active_weapon_changed)
	player.damaged.connect(_on_player_damaged)
	player.player_died.connect(_reset)
	health_bar.max_value = player.max_health
	health_bar.value = player.max_health
	_on_active_weapon_changed(player.inventory.current_weapon)

func _reset():
	clear_counters()
	health_bar.value = player.max_health

func _on_player_damaged():
	print("player damaged")
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(health_bar, "value", maxf(player.current_health, 0.0), 0.25)

func _on_active_weapon_changed(weapon: Node) -> void:
	clear_counters()
	weapon_icon.visible = weapon != null
	if weapon is GunInstance:
		weapon_icon.texture = weapon.gun_data.mini_texture
		_build_counters(container, weapon.gun_data.magazine_size, bullet_counter_texture)
	elif weapon is MeleeInstance:
		weapon_icon.texture = weapon.melee_data.mini_texture
		_build_counters(container, weapon.melee_data.swings_before_cd, melee_counter_texture)

func _build_counters(container: Control, count: int, texture: Texture2D) -> void:
	clear_counters()
	
	var separation := container.get_theme_constant("separation")
	var available_width := container.size.x - separation * (count - 1)
	var base_width := floori(available_width / count)
	var remainder := int(available_width) - base_width * count

	for i in count:
		var counter := NinePatchRect.new()
		counter.texture = texture
		counter.custom_minimum_size.x = base_width + (1 if i < remainder else 0)
		counter.patch_margin_bottom = 2
		counter.patch_margin_top = 2
		counter.patch_margin_left = 1
		counter.patch_margin_right = 1
		container.add_child(counter)
	
func _process(_delta: float) -> void:
	if player.inventory.current_weapon:
		_update_counters(container, player.inventory.current_weapon)
		
	else:
		clear_counters()

func clear_counters():
	if container.get_child_count() > 0:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()
			
func _update_counters(container: Control, instance: Node) -> void:
	if not instance:
		return
	
	var total: int
	var lit_count: int
	
	if instance is MeleeInstance:
		total = instance.melee_data.swings_before_cd
		if instance.recharging:
			var progress : float = 1.0 - (instance.cooldown_time_left / instance.melee_data.cooldown)
			lit_count = floor(progress * total)
			
		else:
			lit_count = instance.swings
			
	elif instance is GunInstance:
		total = instance.gun_data.magazine_size
		if instance.reloading:
			var progress : float = 1.0 - (instance.reload_time_left / instance.gun_data.reload_time)
			lit_count = floor(progress * total)
			
		else:
			lit_count = instance.current_ammo
			
	var counters := container.get_children()
	for i in counters.size():
		counters[i].modulate = COUNTER_LIT if i < lit_count else COUNTER_SPENT
