class_name NFCallablesRes
extends RefCounted


var callables: Dictionary = {
	"direct": {
		"set_name": {
			"name": "Set Actor Name",
			"callable": NexusForge.Variables.set_variable,
			"args": [
				{"name": "Actor", "type": TYPE_STRING},
				{"name": "Name", "type": TYPE_STRING}]}},
	"return": {
		"is_alive": {
			"name": "Character Alive",
			"callable": NexusForge.Variables.get_variable,
			"args": [
				{"name": "Actor ID", "type": TYPE_STRING}]}}}


func add_callable(id: String, name: String, callable: Callable, is_return: bool, args: Array[Dictionary]) -> void:
	var key: String = "return" if is_return else "direct"
	callables[key][id] = {
		"name": name,
		"callable": callable,
		"args": args}


func get_callable_count(type_return: bool = false) -> int:
	if type_return:
		return callables["return"].size()
	return callables["direct"].size()


func get_callable_ids(type_return: bool = false) -> Array:
	if type_return:
		return callables["return"].keys()
	return callables["direct"].keys()


func get_callable_name(id: String, type_return: bool) -> String:
	if type_return:
		return callables["return"][id]["name"]
	return callables["direct"][id]["name"]


func get_callable_args(id: String, type_return: bool) -> Array[Dictionary]:
	var return_array: Array[Dictionary] = []
	if type_return:
		return_array.assign(callables["return"][id]["args"])
	else:
		return_array.assign(callables["direct"][id]["args"])
	return return_array
