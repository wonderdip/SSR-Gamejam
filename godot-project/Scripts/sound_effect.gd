extends Resource
class_name SoundEffect

@export var tag: String = ""
@export var audio_streams: Array[AudioStream] = []

var _last_index: int = -1

func get_stream() -> AudioStream:
	var n := audio_streams.size()
	if n == 0:
		return null
	if n == 1:
		return audio_streams[0]

	# Pick from the other n-1 options so we never repeat the last one
	var i := randi() % (n - 1)
	if _last_index >= 0 and i >= _last_index:
		i += 1
	_last_index = i
	return audio_streams[i]
