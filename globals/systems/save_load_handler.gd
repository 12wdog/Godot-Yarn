extends Node

const SAVE_SYS := &"SAVE_SYS"
const SAVE_SYS_VERSION := 1
const DIR_PATH := "user://saves"

var is_loaded := false
var save_data := SaveFile.new()

func push(data : Resource, version : int, tag : StringName) -> void:
	if tag == SAVE_SYS:
		Log.error("Attempted to save data using registered keyword. Data WAS NOT saved.")
		return
	save_data.push(data, version, tag)

func pull(tag : StringName) -> SaveData:
	return save_data.pull(tag)
	
func save_to_file(file_name : String) -> void:
	if not DirAccess.dir_exists_absolute(DIR_PATH):
		DirAccess.make_dir_recursive_absolute(DIR_PATH)
	
	var file_path := "%s/%s" % [DIR_PATH, file_name]
	var result = ResourceSaver.save(save_data, file_path, ResourceSaver.FLAG_BUNDLE_RESOURCES)
	if result != OK:
		Log.error("Failed to save file. Err type: %s" % error_string(result))


func load_from_file(file_name : String) -> void:
	if not DirAccess.dir_exists_absolute(DIR_PATH):
		Log.error("Save path and file do not exist. No save data loaded.")
		save_data = SaveFile.new()
		return
	
	var file_path := "%s/%s" % [DIR_PATH, file_name]
	
	if not FileAccess.file_exists(file_path):
		Log.error("Save file does not exist. No save data loaded.")
		save_data = SaveFile.new()
		return
	
	save_data = (load(file_path) as SaveFile)

class SaveFile extends Resource:
	var save_data : Dictionary[StringName, SaveData] = {
		SAVE_SYS: SaveData.new(null, SAVE_SYS_VERSION)
	}
	
	func push(data : Resource, version : int, tag : StringName) -> void:
		save_data[tag] = SaveData.new(data, version)
	
	func pull(tag : StringName) -> SaveData:
		if save_data.has(tag):
			return save_data[tag]
		return null
