class_name SaveData
extends Resource

@export var data : Resource
@export var version : int

func _init(data : Resource, version : int) -> void:
	self.data = data
	self.version = version
