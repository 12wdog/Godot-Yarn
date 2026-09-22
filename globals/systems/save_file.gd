class_name SaveFile 
extends Resource

@export var save_data : Dictionary[StringName, SaveData] = {
	SaveLoadHandler.SAVE_SYS: SaveData.new(null, SaveLoadHandler.SAVE_SYS_VERSION)
}

func push(data : Resource, version : int, tag : StringName) -> void:
	save_data[tag] = SaveData.new(data, version)

func pull(tag : StringName) -> SaveData:
	if save_data.has(tag):
		return save_data[tag]
	return null
