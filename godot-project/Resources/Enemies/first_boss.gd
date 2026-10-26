extends Enemy
class_name Boss

const ABILITIES: Array[StringName] = [&"fist", &"punch", &"down_punch", &"minion"]
const TELEGRAPH_TIME := 1.1  # how long before an attack its telegraph starts (at speed 1.0)
const MINION_MIN_GAP := 2.5  # the minion hand is reused, so drops can't overlap

# Shuffled on floor 1 of each run, so every later floor adds to the same set.
static var _ability_order: Array[StringName] = []

@export_category("Damages")
@export var drop_dmg: float = 50
@export var side_punch_dmg: float = 50
@export var down_punch_dmg: float = 50

@export_category("CDs")
@export var fist_cooldown_min: float = 2.0
@export var fist_cooldown_max: float = 4.5

@export var minion_cooldown_min: float = 2.0
@export var minion_cooldown_max: float = 4.5

@export var punch_cooldown_min: float = 2.0
@export var punch_cooldown_max: float = 4.5

@export var down_punch_cooldown_min: float = 2.0
@export var down_punch_cooldown_max: float = 4.5

@export_category("Floor Scaling")
## Applied once per floor after every ability is unlocked.
@export var cooldown_mult_per_floor: float = 0.9
@export var min_cooldown_mult: float = 0.4
## Added to every AnimationPlayer's speed_scale once per floor after everything is unlocked.
@export var speed_gain_per_floor: float = 0.05

@export var minions: Array[PackedScene]

@onready var fist_drop_player: AnimationPlayer = $FistDropPlayer
@onready var side_punch_player: AnimationPlayer = $SidePunchPlayer
@onready var down_punch_player: AnimationPlayer = $DownPunchPlayer

@onready var fist_attack: Node2D = $FistAttack
@onready var drop_area: Sprite2D = $DropArea
@onready var minion_drop: Node2D = $MinionDrop
@onready var enemy_pos: Marker2D = $MinionDrop/EnemyPos
@onready var big_pinch: Sprite2D = $MinionDrop/BigPinch
@onready var punch_attack: Node2D = $PunchAttack
@onready var punch_area: Sprite2D = $PunchArea

@onready var down_punch_area: Sprite2D = $DownPunchArea
@onready var down_punch_attack: Node2D = $DownPunchAttack

var enabled: Array[StringName] = []
var cooldown_mult := 1.0
var anim_speed := 1.0

var fist_timer: Timer
var fist_hit := false
var about_to_drop := false

var punch_timer: Timer
var punch_hit := false
var about_to_punch := false

var down_punch_timer: Timer
var down_punch_hit := false
var about_to_down_punch := false

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
		_: enemy_name = "Priest OT " + str(LevelManager.floor_num)
	
	_setup_progression()
		
	# Detach the fist from the boss's transform so it stays where we drop it.
	fist_attack.top_level = true
	fist_attack.visible = false
	drop_area.visible = false
	
	minion_drop.top_level = true
	minion_drop.visible = false
	
	punch_attack.visible = false
	punch_attack.top_level = true
	punch_area.visible = false
	
	down_punch_attack.visible = false
	down_punch_attack.top_level = true
	down_punch_area.visible = false
	
	fist_drop_player.animation_finished.connect(_on_fist_anim_finished)
	side_punch_player.animation_finished.connect(_on_punch_anim_finished)
	down_punch_player.animation_finished.connect(_on_down_punch_anim_finished)
	
	# Timers are children, so they die with the boss (no dangling await after queue_free).
	# Only unlocked abilities get a timer, so the others never trigger.
	if _is_on(&"fist"):
		fist_timer = _make_timer(_start_fist_drop)
		_schedule_next_fist()
	if _is_on(&"punch"):
		punch_timer = _make_timer(_start_punch)
		_schedule_next_punch()
	if _is_on(&"down_punch"):
		down_punch_timer = _make_timer(_start_down_punch)
		_schedule_next_down_punch()
	if _is_on(&"minion"):
		minion_timer = _make_timer(_start_minion_drop)
		_schedule_next_minion()

func _setup_progression() -> void:
	var floor_n := maxi(LevelManager.floor_num, 1)
	
	# New run (floor 1): pick a fresh random order. Later floors reuse it.
	if floor_n == 1 or _ability_order.is_empty():
		_ability_order = ABILITIES.duplicate()
		_ability_order.shuffle()
	
	# Floor N unlocks N abilities, up to all of them.
	enabled = _ability_order.slice(0, mini(floor_n, ABILITIES.size()))
	
	# Every floor after everything is unlocked: shorter cooldowns, faster animations.
	var extra := maxi(floor_n - ABILITIES.size(), 0)
	cooldown_mult = maxf(pow(cooldown_mult_per_floor, extra), min_cooldown_mult)
	anim_speed = 1.0 + speed_gain_per_floor * extra
	for p: AnimationPlayer in [animation_player, fist_drop_player, side_punch_player, down_punch_player]:
		p.speed_scale = anim_speed

func _is_on(ability: StringName) -> bool:
	return enabled.has(ability)

func _make_timer(callback: Callable) -> Timer:
	var t := Timer.new()
	t.one_shot = true
	add_child(t)
	t.timeout.connect(callback)
	return t

## min_gap is in "speed 1.0" seconds; it keeps the cooldown from being shorter than the
## telegraph (or the minion hand's trip) once the timers and animations have scaled.
func _cooldown(cd_min: float, cd_max: float, min_gap: float) -> float:
	return maxf(randf_range(cd_min, cd_max) * cooldown_mult, min_gap / anim_speed)

func _schedule_next_down_punch():
	down_punch_timer.start(_cooldown(down_punch_cooldown_min, down_punch_cooldown_max, TELEGRAPH_TIME + 0.2))
	about_to_down_punch = false
	
func _schedule_next_punch():
	punch_timer.start(_cooldown(punch_cooldown_min, punch_cooldown_max, TELEGRAPH_TIME + 0.2))
	about_to_punch = false
	
func _schedule_next_fist() -> void:
	fist_timer.start(_cooldown(fist_cooldown_min, fist_cooldown_max, TELEGRAPH_TIME + 0.2))
	about_to_drop = false
	
func _process(_delta: float) -> void:
	if exploding or not is_instance_valid(player_ref) or LevelManager.player_room == null:
		return
	
	# Telegraph animations are scaled too, so start them earlier/later to still end on the hit.
	var lead := TELEGRAPH_TIME / anim_speed
	
	if _is_on(&"fist") and not fist_timer.is_stopped() and fist_timer.time_left <= lead:
		drop_area.global_position = player_ref.center()
		if not about_to_drop:
			about_to_drop = true
			fist_drop_player.play("drop_telegraph")
			drop_area.visible = true
	
	if _is_on(&"punch") and not punch_timer.is_stopped() and punch_timer.time_left <= lead:
		punch_area.global_position.x = LevelManager.player_room.get_room_center().x
		punch_area.global_position.y = player_ref.center().y  # was .x, which put the telegraph in the wrong place
		if not about_to_punch:
			about_to_punch = true
			side_punch_player.play("punch_telegraph")
			punch_area.visible = true

	if _is_on(&"down_punch") and not down_punch_timer.is_stopped() and down_punch_timer.time_left <= lead:
		down_punch_area.global_position.x = player_ref.center().x
		down_punch_area.global_position.y = LevelManager.player_room.get_room_center().y
		if not about_to_down_punch:
			about_to_down_punch = true
			down_punch_player.play("punch_telegraph")
			down_punch_area.visible = true

func _start_down_punch():
	if exploding or not is_instance_valid(player_ref):
		return
	down_punch_hit = false
	down_punch_attack.global_position = player_ref.center()
	down_punch_attack.visible = true
	down_punch_player.play("punch")

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
	minion_timer.start(_cooldown(minion_cooldown_min, minion_cooldown_max, MINION_MIN_GAP))

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
	t.set_speed_scale(anim_speed)
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

func _on_down_punch_anim_finished(anim_name: StringName):
	if anim_name == &"punch":
		down_punch_attack.visible = false
		_schedule_next_down_punch()
		return
		
func _on_area_2d_body_entered(body: Node2D) -> void:
	if fist_hit or body != player_ref:
		return
	fist_hit = true
	if player_ref.has_method("take_damage"):
		player_ref.take_damage(drop_dmg, fist_attack.global_position, knockback)

func play_telegraph():
	AudioManager.play_sfx("dialog", -12)

func _on_punch_area_body_entered(body: Node2D) -> void:
	if punch_hit or body != player_ref:
		return
	punch_hit = true
	if player_ref.has_method("take_damage"):
		var punch_dir := Vector2.LEFT  # the way the punch travels
		var source := player_ref.center() - punch_dir * 100.0
		player_ref.take_damage(side_punch_dmg, source, 400)

func _on_down_punch_area_body_entered(body: Node2D) -> void:
	if down_punch_hit or body != player_ref:
		return
	down_punch_hit = true
	if player_ref.has_method("take_damage"):
		var punch_dir := Vector2.DOWN  # the way the punch travels
		var source := player_ref.center() - punch_dir * 100.0
		player_ref.take_damage(down_punch_dmg, source, 400)
