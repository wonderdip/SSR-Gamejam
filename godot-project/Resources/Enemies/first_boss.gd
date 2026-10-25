extends Enemy
class_name Boss

@export var fist_cooldown_min: float = 2.0
@export var fist_cooldown_max: float = 4.5

@export var minion_cooldown_min: float = 2.0
@export var minion_cooldown_max: float = 4.5

@export var punch_cooldown_min: float = 2.0
@export var punch_cooldown_max: float = 4.5

@export var minions: Array[PackedScene]

@onready var fist_drop_player: AnimationPlayer = $FistDropPlayer
@onready var side_punch_player: AnimationPlayer = $SidePunchPlayer

@onready var fist_attack: Node2D = $FistAttack
@onready var drop_area: Sprite2D = $DropArea
@onready var minion_drop: Node2D = $MinionDrop
@onready var enemy_pos: Marker2D = $MinionDrop/EnemyPos
@onready var big_pinch: Sprite2D = $MinionDrop/BigPinch
@onready var punch_attack: Node2D = $PunchAttack
@onready var punch_area: Sprite2D = $PunchArea

var fist_timer: Timer
var fist_hit := false
var about_to_drop := false

var punch_timer: Timer
var punch_hit := false
var about_to_punch := false

var minion_timer: Timer
var minion_hit := false

func _ready() -> void:
	super()
	# Base _ready() awaits animation_finished (there's no "spawn" anim, and "idle"
	# loops, so it never fires) which leaves movement_locked = true forever.
	movement_locked = false
	
	match LevelManager.floor_num:
		1: enemy_name = "Priest OT I"
		2: enemy_name = "Priest OT II"
		3: enemy_name = "Priest OT III"
		4: enemy_name = "Priest OT IV"
		
	# Detach the fist from the boss's transform so it stays where we drop it.
	fist_attack.top_level = true
	fist_attack.visible = false
	minion_drop.top_level = true
	minion_drop.visible = false
	drop_area.visible = false
	punch_attack.visible = false
	punch_attack.top_level = true
	punch_area.visible = false
	fist_drop_player.animation_finished.connect(_on_fist_anim_finished)
	side_punch_player.animation_finished.connect(_on_punch_anim_finished)
	
	# Timer is a child, so it dies with the boss (no dangling await after queue_free)
	fist_timer = Timer.new()
	fist_timer.one_shot = true
	add_child(fist_timer)
	fist_timer.timeout.connect(_start_fist_drop)
	_schedule_next_fist()

	punch_timer = Timer.new()
	punch_timer.one_shot = true
	add_child(punch_timer)
	punch_timer.timeout.connect(_start_punch)
	_schedule_next_punch()
	
	minion_timer = Timer.new()
	minion_timer.one_shot = true
	add_child(minion_timer)
	minion_timer.timeout.connect(_start_minion_drop)
	_schedule_next_minion()

func _schedule_next_punch():
	punch_timer.start(randf_range(punch_cooldown_min, punch_cooldown_max))
	about_to_punch = false
	
func _schedule_next_fist() -> void:
	fist_timer.start(randf_range(fist_cooldown_min, fist_cooldown_max))
	about_to_drop = false
	
func _process(_delta: float) -> void:
	if fist_timer.time_left <= 1.1:
		drop_area.global_position = player_ref.center()
		if not about_to_drop:
			about_to_drop = true
			fist_drop_player.play("drop_telegraph")
			drop_area.visible = true
	
	
	if punch_timer.time_left <= 1.1:
		punch_area.global_position.x = LevelManager.player_room.get_room_center().x
		punch_area.global_position.y = player_ref.center().y
		if not about_to_punch:
			about_to_punch = true
			side_punch_player.play("punch_telegraph")
			punch_area.visible = true
		
	return
	
func _start_punch():
	if exploding or not is_instance_valid(player_ref):
		return
	punch_hit = false
	punch_attack.global_position = player_ref.center()
	punch_attack.visible = true
	side_punch_player.play("punch")

func _start_fist_drop() -> void:
	if exploding or not is_instance_valid(player_ref):
		return
	fist_hit = false
	fist_attack.global_position = player_ref.center()
	fist_attack.visible = true
	fist_drop_player.play("fist_drop")

func _schedule_next_minion():
	minion_timer.start(randf_range(minion_cooldown_min, minion_cooldown_max))

func _start_minion_drop() -> void:
	var room: Room = LevelManager.player_room
	if exploding or minions.is_empty() or room == null:
		_schedule_next_minion()
		return
	
	minion_drop.modulate.a = 1
	var enemy_instance: Enemy = minions.pick_random().instantiate() as Enemy
	room.add_child(enemy_instance)  # add_child first, then set global_position
	enemy_instance.movement_locked = true
	
	minion_drop.global_position = room.get_room_center()
	var start := minion_drop.global_position
	var center := room.get_room_center()
	var target := center + Vector2(randi_range(-128, 128), randi_range(-128, 128))
	
	big_pinch.frame = 0
	minion_drop.scale.x = -1.0 if start.x > center.x else 1.0  # flip before reading EnemyPos
	enemy_instance.global_position = enemy_pos.global_position
	minion_drop.show()
	
	var t := create_tween()
	t.tween_method(_carry_minion.bind(enemy_instance), start, target, 1.5)
	t.finished.connect(_release_minion.bind(enemy_instance))
	
	_schedule_next_minion()  # cooldown counts from the start of the drop

func _carry_minion(pos: Vector2, enemy: Enemy) -> void:
	minion_drop.global_position = pos
	if is_instance_valid(enemy):
		enemy.global_position = enemy_pos.global_position

func _release_minion(enemy: Enemy) -> void:
	big_pinch.frame = 1

	var t := create_tween()
	t.tween_property(minion_drop, "modulate:a", 0, 0.5).set_delay(0.5)

	if not is_instance_valid(enemy):
		return
	# don't cut the enemy's own spawn animation short
	if enemy.animation_player.current_animation == "spawn":
		await enemy.animation_player.animation_finished
	if is_instance_valid(enemy):
		enemy.movement_locked = false
	
func fist_landed():
	ScreenSfx.cam_shake(15, 5, 0.5)
	AudioManager.play_sfx("impact")
	AudioManager.play_sfx("crash")
	
func _on_fist_anim_finished(anim_name: StringName) -> void:
	if anim_name == &"fist_drop":
		fist_attack.visible = false
		_schedule_next_fist()
		return

func _on_punch_anim_finished(anim_name: StringName):
	if anim_name == &"punch":
		punch_attack.visible = false
		_schedule_next_punch()
		return

func _on_area_2d_body_entered(body: Node2D) -> void:
	if fist_hit or body != player_ref:
		return
	fist_hit = true
	if player_ref.has_method("take_damage"):
		player_ref.take_damage(damage, fist_attack.global_position, knockback)

func play_telegraph():
	AudioManager.play_sfx("dialog", -12)

func _on_punch_area_body_entered(body: Node2D) -> void:
	if punch_hit or body != player_ref:
		return
	punch_hit = true
	if player_ref.has_method("take_damage"):
		var punch_dir := Vector2.LEFT  # the way the punch travels
		var source := player_ref.center() - punch_dir * 100.0
		player_ref.take_damage(damage, source, 400)
