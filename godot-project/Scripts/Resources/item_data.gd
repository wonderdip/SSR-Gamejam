extends Resource
class_name ItemData

@export var item_name: String = ""
@export var texture: Texture2D
@export_multiline() var description: String = ""
@export var item_type: ItemEnums.ITEM_TYPE
@export var rarity : ItemEnums.RARITIES
@export var unlocked: bool
