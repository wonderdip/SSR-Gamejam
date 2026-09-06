@tool
class_name GlitchShuffleEffect
extends RichTextEffect

# Usage in BBCode (on a RichTextLabel with bbcode_enabled = true):
# [shuffle chance=0.35 speed=6.0 settle=1.5 chars=abcdefghijklmnopqrstuvwxyz]forgetting[/shuffle]
#
# chance  - probability (0-1) a given character is swapped on any given cycle
# speed   - cycles per second (higher = more frantic flicker)
# settle  - seconds until the effect stops and the true text is shown (0 = never settles)
# chars   - pool of characters to substitute in

var bbcode: String = "shuffle"

# Cache the default character pool to avoid string concatenation every call
var _default_pool: String = ""

func _init() -> void:
	_default_pool = "abcdefghijklmnopqrstuvwxyz123456789#$%&'()*+,\
	-./:;<=>?[]_`|~@∎ÄÁÀÂÅÃäáàâåãÏÍÌÎïíìîÜÚÙÛüúùûÖÓ\
	ÒÔÕöóòôõËÉÈÊëéèêŸÝỲÿýỳÇçÑñÆæŒœßðÐþÞ¿¡"

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var chance: float = char_fx.env.get("chance", 0.35)
	var speed: float = char_fx.env.get("speed", 6.0)
	var settle: float = char_fx.env.get("settle", 0.0)
	var pool: String = char_fx.env.get("chars", _default_pool)

	if settle > 0.0 and char_fx.elapsed_time >= settle:
		return true

	# stagger each character's cycle so they don't all flicker in lockstep
	var cycle: int = int((char_fx.elapsed_time * speed) + char_fx.relative_index * 1.7)

	# Use built-in randf() with seeded hash instead of creating RandomNumberGenerator
	# This is significantly faster and achieves the same deterministic behavior
	random_seed(hash(cycle) ^ (char_fx.relative_index * 92821))
	
	if randf() < chance:
		var random_char: String = pool[randi() % pool.length()]
		var font_rid: RID = char_fx.font
		var ts: TextServer = TextServerManager.get_primary_interface()
		var glyph_index: int = ts.font_get_glyph_index(font_rid, 8, random_char.unicode_at(0), 0)
		char_fx.glyph_index = glyph_index

	return true
