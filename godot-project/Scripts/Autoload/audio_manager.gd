extends Node

@export var sfx_pool: Array[SoundEffect]
@export var music_pool: Array[SoundEffect]

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var last_played: Dictionary = {}


var _lookup: Dictionary = {}  # String -> SoundEffect

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

	for i in sfx_pool.size():
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)
	
	set_music_volume(0.5)
	set_sfx_volume(0.5)
	
	for effect in sfx_pool:
		_register(effect)
	for song in music_pool:
		_register(song)

func _register(effect: SoundEffect) -> void:
	if effect.tag in _lookup:
		push_warning("Duplicate audio tag: %s" % effect.tag)
		return
	_lookup[effect.tag] = effect

func get_audio_stream(tag: String) -> AudioStream:
	var effect: SoundEffect = _lookup.get(tag)
	if effect == null:
		push_warning("No audio found for tag: %s" % tag)
		return null
	return effect.get_stream()

func play_sfx(tag: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var stream := get_audio_stream(tag)
	if stream == null:
		return

	var player := _get_free_sfx_player()
	if player == null:
		return

	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()

func play_music(tag: String, volume_db: float = 0.0) -> void:
	var stream: AudioStream = get_audio_stream(tag)
	if stream == null:
		return
	
	if music_player.stream == stream and music_player.playing:
		return
	
	music_player.stop()
	music_player.stream = stream
	music_player.volume_db = volume_db
	music_player.play()
	
func stop_music() -> void:
	music_player.stop()

func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	
	return sfx_players[0]
	
func set_music_volume(value: float) -> void:
	_set_bus_volume("Music", value)

func set_sfx_volume(value: float) -> void:
	_set_bus_volume("SFX", value)

func _set_bus_volume(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return

	value = clamp(value, 0.0, 1.0)

	if value == 0.0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
