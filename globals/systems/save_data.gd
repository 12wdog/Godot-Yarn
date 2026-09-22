class_name SaveData
extends Resource

var data : Resource
var version : int

func _init(data : Resource, version : int) -> void:
	self.data = data
	self.version = version
