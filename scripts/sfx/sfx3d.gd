class_name SFX3D
extends AudioStreamPlayer3D


func _init(
	audio_stream: AudioStream,
	volume: float = 1.0,
	pitch_scale: float = 1.0
) -> void:
	stream = audio_stream
	volume_db = linear_to_db(clampf(volume, 0.0001, 1.0))
	self.pitch_scale = pitch_scale
	bus = &"SFX"

	finished.connect(queue_free)


func _ready() -> void:
	play()
