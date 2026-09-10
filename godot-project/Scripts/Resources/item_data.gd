extends Resource
class_name ItemData

@export var item_name: String = ""
@export var texture: Texture2D
@export_multiline() var description: String = ""

@export var unlocked: bool
@export var rarity : ItemEnums.RARITIES
