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

func get_random_weapon():
	var rng: int = randi_range(1, 2)
	if rng == 1:
		return get_random_gun()
	else:
		return get_random_melee()
		
func get_random_gun() -> GunData:
	var rarity: ItemEnums.RARITIES = _roll_rarity()
	var pool: Array[GunData] = get_guns_by_rarity(rarity)

	while pool.is_empty() and rarity > ItemEnums.RARITIES.Common:
		rarity -= 1
		pool = get_guns_by_rarity(rarity)

	if pool.is_empty():
		push_warning("No guns available in any rarity pool")
		return null

	return pool[randi() % pool.size()]

func get_guns_by_rarity(rarity: ItemEnums.RARITIES) -> Array[GunData]:
	return guns.filter(func(g): return g != null and g.rarity == rarity)

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

func get_random_melee() -> MeleeData:
	var rarity: ItemEnums.RARITIES = _roll_rarity()
	var pool: Array[MeleeData] = get_melees_by_rarity(rarity)

	while pool.is_empty() and rarity > ItemEnums.RARITIES.Common:
		rarity -= 1
		pool = get_melees_by_rarity(rarity)

	if pool.is_empty():
		push_warning("No melees available in any rarity pool")
		return null

	return pool[randi() % pool.size()]

func get_melees_by_rarity(rarity: ItemEnums.RARITIES) -> Array[MeleeData]:
	return melees.filter(func(g): return g != null and g.rarity == rarity)
