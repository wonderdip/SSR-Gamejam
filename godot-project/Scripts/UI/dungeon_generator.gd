extends Node
class_name DungeonGenerator

@export_category("Grid")
@export var grid_cols: int = 10
@export var grid_rows: int = 11
@export var start_index: int = 45

@export_category("Expansion Margins")
@export var left_margin_col: int = 1 ## must have x > this to expand leftward
@export var right_margin_col: int = 9 ## must have x < this to expand rightward
@export var top_margin_index: int = 20 ## must have i > this to expand upward
@export var bottom_margin_index: int = 70 ## must have i < this to expand downward

@export_category("Room Count")
@export var min_rooms: int = 7
@export var max_rooms: int = 15

@export_category("Special Room Counts")
@export var min_boss_rooms: int = 1
@export var max_boss_rooms: int = 1
@export var min_reward_rooms: int = 1
@export var max_reward_rooms: int = 1
@export var min_coin_rooms: int = 1
@export var max_coin_rooms: int = 1
@export var min_secret_rooms: int = 1
@export var max_secret_rooms: int = 1

@export_category("Branching")
@export_range(0.0, 1.0) var branch_chance: float = 0.5
@export var max_neighbours_to_visit: int = 1 ## room is skipped if it already has more neighbours than this

@export_category("Secret Room")
@export var secret_room_max_attempts: int = 900
@export var secret_room_min_x: int = 1
@export var secret_room_max_x: int = 9
@export var secret_room_min_y: int = 2
@export var secret_room_max_y: int = 9
@export var secret_room_min_isolation: int = 3 ## required neighbour count to qualify as secret room

@export_category("Generation Timing")
@export var step_interval: float = 0.0 ## 0 = generate instantly, >0 = animate one room per interval
@export var max_generation_attempts: int = 500 ## safety cap on retries if a layout can't fit all special rooms

signal generation_started()
signal room_added(index: int, room_type: String)
signal generation_complete(floorplan: Array[int], boss_rooms: Array[int], reward_rooms: Array[int], coin_rooms: Array[int], secret_rooms: Array[int])
signal generation_failed()

var floorplan: Array[int] = []
var cell_queue: Array[int] = []
var end_rooms: Array[int] = []
var floorplan_count: int = 0
var placed_special: bool = false
var _attempt_count: int = 0

var _timer: Timer

func _ready() -> void:
	if step_interval > 0.0:
		_timer = Timer.new()
		_timer.wait_time = step_interval
		_timer.timeout.connect(_on_timer_timeout)
		add_child(_timer)

func generate() -> void:
	_attempt_count = 0
	_begin_attempt()

	if step_interval > 0.0:
		_timer.start()
	else:
		_run_to_completion()

func _begin_attempt() -> void:
	_attempt_count += 1
	_reset()
	generation_started.emit()
	_visit(start_index)

func _reset() -> void:
	placed_special = false
	floorplan_count = 0
	floorplan.clear()
	for i in range(grid_cols * grid_rows):
		floorplan.append(0)
	cell_queue.clear()
	end_rooms.clear()

func _run_to_completion() -> void:
	while true:
		while cell_queue.size() > 0:
			_process_queue_step()

		if _place_special_rooms():
			placed_special = true
			return

		if _attempt_count >= max_generation_attempts:
			generation_failed.emit()
			return

		_begin_attempt()

func _on_timer_timeout() -> void:
	if cell_queue.size() > 0:
		_process_queue_step()
		return

	if placed_special:
		return

	if _place_special_rooms():
		placed_special = true
		_timer.stop()
		return

	if _attempt_count >= max_generation_attempts:
		_timer.stop()
		generation_failed.emit()
		return

	_begin_attempt()

func _process_queue_step() -> void:
	var i: int = cell_queue.pop_front()
	var x: int = i % grid_cols
	var created := false
	if x > left_margin_col:
		created = _visit(i - 1) or created
	if x < right_margin_col:
		created = _visit(i + 1) or created
	if i > top_margin_index:
		created = _visit(i - grid_cols) or created
	if i < bottom_margin_index:
		created = _visit(i + grid_cols) or created
	if not created:
		end_rooms.append(i)

func _place_special_rooms() -> bool:
	if floorplan_count < min_rooms:
		return false

	var boss_rooms := _pop_random_end_rooms(_random_count(min_boss_rooms, max_boss_rooms))
	var reward_rooms := _pop_random_end_rooms(_random_count(min_reward_rooms, max_reward_rooms))
	var coin_rooms := _pop_random_end_rooms(_random_count(min_coin_rooms, max_coin_rooms))
	var secret_rooms := _pick_secret_rooms(_random_count(min_secret_rooms, max_secret_rooms), boss_rooms)

	if boss_rooms.size() < min_boss_rooms or reward_rooms.size() < min_reward_rooms \
			or coin_rooms.size() < min_coin_rooms or secret_rooms.size() < min_secret_rooms:
		return false

	for i in boss_rooms:
		room_added.emit(i, "boss")
	for i in reward_rooms:
		room_added.emit(i, "reward")
	for i in coin_rooms:
		room_added.emit(i, "coin")
	for i in secret_rooms:
		room_added.emit(i, "secret")

	generation_complete.emit(floorplan, boss_rooms, reward_rooms, coin_rooms, secret_rooms)
	return true

func _random_count(min_count: int, max_count: int) -> int:
	return randi_range(mini(min_count, max_count), maxi(min_count, max_count))

func _pop_random_end_room() -> int:
	if end_rooms.is_empty():
		return -1
	var index := randi() % end_rooms.size()
	var i: int = end_rooms[index]
	end_rooms.remove_at(index)
	return i

func _pop_random_end_rooms(count: int) -> Array[int]:
	var result: Array[int] = []
	for _n in range(count):
		var picked := _pop_random_end_room()
		if picked == -1:
			break
		result.append(picked)
	return result

func _pick_secret_room(avoid_adjacent_to: Array[int]) -> int:
	for _attempt in range(secret_room_max_attempts):
		var x := randi_range(secret_room_min_x, secret_room_max_x)
		var y := randi_range(secret_room_min_y, secret_room_max_y)
		var i := y * grid_cols + x

		if floorplan[i] == 1:
			continue

		var touches_avoided := false
		for avoided in avoid_adjacent_to:
			if avoided == i - 1 or avoided == i + 1 \
					or avoided == i + grid_cols or avoided == i - grid_cols:
				touches_avoided = true
				break
		if touches_avoided:
			continue

		if _neighbour_count(i) >= secret_room_min_isolation:
			return i

	return -1

func _pick_secret_rooms(count: int, avoid_adjacent_to: Array[int]) -> Array[int]:
	var result: Array[int] = []
	for _n in range(count):
		var picked := _pick_secret_room(avoid_adjacent_to)
		if picked == -1:
			break
		floorplan[picked] = 1
		result.append(picked)
	return result

func _neighbour_count(i: int) -> int:
	return floorplan[i - grid_cols] + floorplan[i - 1] + floorplan[i + 1] + floorplan[i + grid_cols]

func _visit(i: int) -> bool:
	if floorplan[i] == 1:
		return false

	if _neighbour_count(i) > max_neighbours_to_visit:
		return false

	if floorplan_count >= max_rooms:
		return false

	if randf() < branch_chance and i != start_index:
		return false

	cell_queue.append(i)
	floorplan[i] = 1
	floorplan_count += 1

	room_added.emit(i, "cell")
	return true
