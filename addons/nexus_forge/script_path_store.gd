@tool
extends RefCounted


signal classes_updated(updated: Array[String])


var _timestamps: Dictionary[String, int] = {
	"NFCharacterSheet": 0,
	"NFStatBlock": 0,
	"NFSkillSet": 0,
	"NFTraitBlock": 0,
	"NFQuest": 0,
	"NFQuestStage": 0,
	"NFQuestObjective": 0,
	"NFItemSheet": 0,
	"DiscourseAPI": 0}


func _init() -> void:
	for cl_item in ProjectSettings.get_global_class_list():
		if _timestamps.has(cl_item["class"]):
			_timestamps[cl_item["class"]] = FileAccess.get_modified_time(cl_item["path"])


# If using an external editor, we can't be "specific" or rely on location
# much. So we have to iterate through the global class list instead to perform
# precise updates.
func check_for_updates() -> void:
	var updated_classes: Array[String] = []
	var new_timestamps: Dictionary[String, int] = {}
	var all_keys: Array = _timestamps.keys()
	
	for item in ProjectSettings.get_global_class_list():
		if _timestamps.has(item["class"]):
			new_timestamps[item["class"]] = FileAccess.get_modified_time(item["path"])
			if new_timestamps.has_all(all_keys):
				break
	
	for cl_nm in _timestamps:
		if new_timestamps.has(cl_nm):
			if new_timestamps[cl_nm] != _timestamps[cl_nm]:
				_timestamps[cl_nm] = new_timestamps[cl_nm]
				if new_timestamps[cl_nm] != 0:
					updated_classes.append(cl_nm)
	
	if not updated_classes.is_empty():
		classes_updated.emit(updated_classes)


# When Godot internally trigers resource_saved, we have direct access to the
# resource, using this method when that happens we skip having to iterate
# through ProjectSettings to get all classes, and we can trigger specific
# updates
func validate_update(cl_name: String, path: String) -> void:
	if not _timestamps.has(cl_name):
		return
	
	var original_timestamp: int = _timestamps[cl_name]
	var new_timestamp: int = FileAccess.get_modified_time(path)
	_timestamps[cl_name] = new_timestamp
	if new_timestamp != 0:
		classes_updated.emit(NFArrayUtils.create_typed(TYPE_STRING, [cl_name]))
