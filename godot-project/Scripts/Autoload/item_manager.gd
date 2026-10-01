extends Node

@export var melees: Array[MeleeData]
@export var guns: Array[GunData]

@export var rarity_weights: Dictionary = {
	ItemEnums.RARITIES.Common: 60.0,
	ItemEnums.RARITIES.Uncommon: 25.0,
	ItemEnums.RARITIES.Rare: 10.0,
	ItemEnums.RARITIES.Epic: 4.0,
	ItemEnums.RARITIES.Legendary: 1.0,
}

var _all_weapons: Array = []

func _ready() -> void:
	for g in guns:
		if g != null:
			_all_weapons.append(g)
	for m in melees:
		if m != null:
			_all_weapons.append(m)

# exclude: weapons you don't want returned (e.g. ones the player already owns)
func get_random_weapon(exclude: Array = []) -> Resource:
	var start: ItemEnums.RARITIES = _roll_rarity()

	for rarity in _rarities_by_distance(start):
		var pool: Array = _all_weapons.filter(
			func(w): return w.rarity == rarity and not exclude.has(w)
		)
		if not pool.is_empty():
			return pool.pick_random()

	push_warning("No weapons available")
	return null

# Rolled rarity first, then fall back to the closest rarities (lower before higher)
func _rarities_by_distance(start: int) -> Array:
	var all: Array = rarity_weights.keys()
	all.sort_custom(func(a, b):
		var da: int = abs(a - start)
		var db: int = abs(b - start)
		if da == db:
			return a < b
		return da < db
	)
	return all

func _roll_rarity() -> ItemEnums.RARITIES:
	var total_weight: float = 0.0
	for w in rarity_weights.values():
		total_weight += w

	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	for rarity in rarity_weights.keys():
		cumulative += rarity_weights[rarity]
		if roll < cumulative:
			return rarity

	return ItemEnums.RARITIES.Common
