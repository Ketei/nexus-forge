@tool
@icon("res://addons/nexus_forge/icons/hexagon.svg")
class_name TraitCatalog
extends Resource


const DEFAULT_DATA: Dictionary[String, Variant] = {}

@export_storage var _traits: Dictionary[StringName, Dictionary] = {
	&"a_trait": {
		"name": "",
		"description": "",
		"data": {}
	}
}
var _custom_traits: Dictionary[StringName, Dictionary] = {}


#region Defined Traits

func set_trait_name(trait_id: StringName, new_name: String) -> void:
	if _traits.has(trait_id):
		_traits[trait_id]["name"] = new_name


func get_trait_name(trait_id: StringName) -> String:
	if _traits.has(trait_id):
		return _traits[trait_id]["name"]
	return ""


func set_trait_description(trait_id: StringName, description: String) -> void:
	if _traits.has(trait_id):
		_traits[trait_id]["description"] = description


func get_trait_description(trait_id: StringName) -> String:
	if _traits.has(trait_id):
		return _traits[trait_id]["description"]
	return ""


func set_trait_data(trait_id: StringName, data_key: String, data: Variant) -> void:
	if not _traits.has(trait_id):
		return
	
	if data == null:
		if  _traits[trait_id]["data"].has(data_key):
			_traits[trait_id]["data"].erase(data_key)
	else:
		_traits[trait_id]["data"][data_key] = data


func clear_trait_data(trait_id: StringName) -> void:
	if _traits.has(trait_id):
		_traits[trait_id]["data"].clear()


func trait_data_keys(trait_id: StringName) -> Array[String]:
	var all_keys: Array[String] = []
	if _traits.has(trait_id):
		all_keys.assign(_traits[trait_id]["data"].keys())
	return all_keys

#endregion


func create_custom(trait_id: StringName) -> void:
	if _custom_traits.has(trait_id):
		return
	
	var data: Dictionary[String, Variant] = {}
	data.assign(DEFAULT_DATA)
	
	_custom_traits[trait_id] = {
		"name": "",
		"description": "",
		"data": data}


func has_custom(trait_id: StringName) -> bool:
	return _custom_traits.has(trait_id)


func erase_custom(trait_id: StringName) -> void:
	if _custom_traits.erase(trait_id):
		pass


func custom_traits() -> Array[StringName]:
	var all_traits: Array[StringName] = []
	all_traits.assign(_custom_traits.keys())
	return all_traits



func set_custom_trait_name(trait_id: StringName, new_name: String) -> void:
	if _custom_traits.has(trait_id):
		_custom_traits[trait_id]["name"] = new_name


func get_custom_trait_name(trait_id: StringName) -> String:
	if _custom_traits.has(trait_id):
		return _custom_traits[trait_id]["name"]
	return ""


func set_custom_trait_description(trait_id: StringName, description: String) -> void:
	if _custom_traits.has(trait_id):
		_custom_traits[trait_id]["description"] = description


func get_custom_trait_description(trait_id: StringName) -> String:
	if _custom_traits.has(trait_id):
		return _custom_traits[trait_id]["description"]
	return ""


func set_custom_trait_data(trait_id: StringName, data_key: String, data: Variant) -> void:
	if not _custom_traits.has(trait_id):
		return
	
	if data == null:
		if  _custom_traits[trait_id]["data"].has(data_key):
			_custom_traits[trait_id]["data"].erase(data_key)
	else:
		_custom_traits[trait_id]["data"][data_key] = data


func clear_custom_trait_data(trait_id: StringName) -> void:
	if _custom_traits.has(trait_id):
		_custom_traits[trait_id]["data"].clear()


func custom_trait_data_keys(trait_id: StringName) -> Array[String]:
	var all_keys: Array[String] = []
	if _custom_traits.has(trait_id):
		all_keys.assign(_custom_traits[trait_id]["data"].keys())
	return all_keys
