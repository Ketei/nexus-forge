extends RefCounted

var _paths: Dictionary[String, String] = {
	"NFCharacterSheet": "",
	"NFStatBlock": "",
	"NFSkillSet": "",
	"NFTraitBlock": "",
	"NFQuest": "",
	"NFQuestStage": "",
	"NFQuestObjective": "",
	"NFItemSheet": ""}


func _init() -> void:
	for cl_item in ProjectSettings.get_global_class_list():
		if _paths.has(cl_item["class"]):
			_paths[cl_item["class"]] = cl_item["path"]


func get_class_script_path(cl_name: String) -> String:
	if not _paths.has(cl_name):
		return ""
	
	if not FileAccess.file_exists(_paths[cl_name]):
		for cl_item in ProjectSettings.get_global_class_list():
			if cl_item["class"] == cl_name:
				_paths[cl_name] = cl_item["path"]
				break
		if not FileAccess.file_exists(_paths[cl_name]):
			return ""
	
	return _paths[cl_name]
