class_name NFCallablesRes
extends RefCounted


var callables: Dictionary = {
	"direct": {
		"set_name": {
			"name": "Set Actor Name",
			"callable": NexusForge.Variables.set_variable,
			"args": [TYPE_STRING, TYPE_STRING]
		},
		"cutscene_a": {"name": "Trigger cutscene A", "callable": print, "args": []},
		"cutscene_b": {"name": "Trigger cutscene B", "callable": print, "args": []},
		"cutscene_c": {"name": "Trigger cutscene C", "callable": print, "args": []}
		},
	"return": {
		"is_alive": {
			"name": "Character Alive",
			"callable": NexusForge.Variables.get_variable,
			"args": [TYPE_STRING],
			"returns": TYPE_BOOL
		}
	}}


func add_callable(id: String, name: String, callable: Callable, is_return: bool, args: Array[Dictionary]) -> void:
	var key: String = "return" if is_return else "direct"
	callables[key][id] = {
		"name": name,
		"callable": callable,
		"args": args}


func get_callable(id: String) -> Callable:
	return callables["direct"][id]["callable"]


func get_callable_return(id: String) -> Callable:
	return callables["return"][id]["callable"]


func get_callable_return_count() -> int:
	return callables["return"].size()


func get_callable_count() -> int:
	return callables["direct"].size()


func get_callable_ids() -> Array[String]:
	return Array(callables["direct"].keys(), TYPE_STRING, &"", null)


func get_callable_return_ids() -> Array[String]:
	return Array(callables["return"].keys(), TYPE_STRING, &"", null)


func get_callable_name(id: String) -> String:
	return callables["direct"][id]["name"]


func get_callable_return_name(id: String) -> String:
	return callables["return"][id]["name"]


func get_callable_args(id: String) -> Array[int]:
	return Array(
		callables["direct"][id]["args"].duplicate(),
		TYPE_INT,
		&"",
		null)


func get_callable_return_args(id: String) -> Array[int]:
	return Array(
		callables["return"][id]["args"].duplicate(),
		TYPE_INT,
		&"",
		null)


func get_callable_return_type(id: String) -> int:
	return callables["return"][id]["returns"]
