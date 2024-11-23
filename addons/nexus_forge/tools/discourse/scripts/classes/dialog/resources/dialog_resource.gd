class_name DialogData
extends Resource
## A resource that holds a conversation.
##
## This resource holds a full conversation, including events, signals, options,
## method calls, variables, etc. that can happen during it.


enum DialogType{
	DIALOG, # Dialog
	OPTIONS, # Reply Selector
	REPLY, # Reply
	CONDITION, # Conditional Split
	COMPARATION, # Comparation
	ELEMENT, # Variable
	RANDOM, # Random
	ID, # Go to ID
	CALL, # Call
	CHARACTER, # Character
	VARIABLES, # Variables
	VALUE, # Val selector
	SIGNAL, # Signal
	END,
	START,
	COMMENT,
}

enum NextType {
	ID, # Options now is also ID'd
	RANDOM,
	CONDITION,
	END,
}

enum ElementType {
	BOOL,
	INT,
	FLOAT,
	STRING,
	VAR,
}


## The initial conversation key contained in [member conversation].
@export var dialog_entry: Dictionary = {}
@export var _entry_offset: Vector2

# callable code is:
# var obj = get_tree().root.get_node_or_null(res["call"]["node"])
# if obj == null: return (do nothing)
# if obj.has_method(res["call"]["callable"]): Callable(obj, res["call"]["callable"]).callv(res["call"]["args"])
## A dictionary containing keys that identify sections of a conversation.[br]
## It is recommended to get the conversation via [method get_dialog_map] than
## using this variable directly.
@export var conversation: Dictionary = {}
## Nodes that don't connect to anything and/or are just for informative purposes.
@export var orphans: Array = []


## Returns an array with all the character IDs that participate in this
## conversation.
func get_conversation_characters() -> Array[StringName]:
	var characters: Array[StringName] = []
	for conv in conversation:
		if conversation[conv]["type"] != DialogType.DIALOG:
			continue
		characters.append(conversation[conv]["character"]["id"])
	return characters


func travel_tree(structure: Dictionary) -> String:
	match structure["type"]:
		NextType.ID:
			return structure["data"]["next"]
		NextType.RANDOM:
			if structure["data"]["use_weights"]:
				var random_pool := Random.create_random_weighted_pool()
				
				for exit in structure["data"]["options"]:
					random_pool.add_weighted(exit["next"], exit["weight"])
				
				var result: Dictionary = random_pool.get_rand_weighted()
				
				if result["type"] == NextType.ID:
					return result["data"]["next"]
				else:
					return travel_tree(result)
			else:
				var result: Dictionary = structure["data"]["options"].pick_random()
				
				if result["next"]["type"] == NextType.ID:
					return result["next"]["data"]["next"]
				else:
					return travel_tree(result["next"])
		NextType.CONDITION:
			var success: bool = false
			var element_a: Variant = structure["data"]["comparation"]["var_a"]["value"]["value"]
			var element_b: Variant = structure["data"]["comparation"]["var_a"]["value"]["value"]
			match structure["data"]["comparation"]["operator"]:
				OP_EQUAL:
					success = element_a == element_b
				OP_NOT_EQUAL:
					success = element_a != element_b
				OP_GREATER:
					success = element_a > element_b
				OP_GREATER_EQUAL:
					success = element_a >= element_b
				OP_LESS:
					success = element_a < element_b
				OP_LESS_EQUAL:
					success = element_a <= element_b
			var next_key: String = "true" if success else "false"
			var next_target: Dictionary = structure["data"][next_key]
			
			if next_target["type"] == NextType.ID:
				return next_target["data"]["next"]
			else:
				return travel_tree(next_target)
		_:
			return ""


## Returns the next dialog ID starting [param from_id]. If an empty string is
## passed it'll give the starting dialog.[br]
## If the dialog has options, passing the idx of the option is required, 
## else 0 will be assumed. If the return is an empty string it indicates 
## the end of the dialog.
func get_next_id(from_id: String = "", option_idx: int = 0) -> String:
	if not conversation.has(from_id) and not from_id.is_empty():
		printerr("[DISCOURSE] Given dialog id {0} is not found in conversation map.".format([from_id]))
		return ""
	
	var target_dict: Dictionary = dialog_entry if from_id.is_empty() else conversation[from_id]
	
	if target_dict["type"] == DialogType.OPTIONS:
		return travel_tree(target_dict["targets"][option_idx])
	else:
		return travel_tree(target_dict)


## Returns 0 if it's dialog, returns 1 if it's options.
func get_dialog_type(dialog_id: String) -> int:
	return conversation[dialog_id]["type"]


## Returns a dictionary with all the necesary info for the [param dialog_id].
## The key [code]type[/code] on the return dictionary determines the content of
## the dictionary. It can either be [constant DialogType.DIALOG] or
## [constant DialogType.OPTIONS].
func get_dialog_data(dialog_id: String) -> Dictionary:
	var data: Dictionary = {"type": conversation[dialog_id]["type"]}
	
	match data["type"]:
		DialogType.DIALOG:
			var dialog_data: Dictionary = {
				"character": {
					"id": conversation[dialog_id]["character"]["id"],
					"talking": conversation[dialog_id]["character"]["talking"],
					"idle": conversation[dialog_id]["character"]["idle"]},
				"dialog": {
					"text": conversation[dialog_id]["dialog"]["text"],
					"speed": conversation[dialog_id]["dialog"]["seconds_per_letter"]},
				"pause": conversation[dialog_id]["pause"],
				"variables": conversation[dialog_id]["set_variable"]["variables"].duplicate(),
				"call": {
					"object": conversation[dialog_id]["call"]["object"],
					"method": conversation[dialog_id]["call"]["method"],
					"args": conversation[dialog_id]["call"]["args"].duplicate(),
					"at_start": conversation[dialog_id]["call"]["call_at_start"]},
				"signal": {
					"argument": conversation[dialog_id]["signal"]["signal"],
					"at_start": conversation[dialog_id]["signal"]["call_at_start"]}}
			
			data.merge(dialog_data)
		
		DialogType.OPTIONS:
			var options: Array[Dictionary] = []
			for option_idx in range(conversation[dialog_id]["options"].size()):
				var option_dict: Dictionary = {
					"text": conversation[dialog_id]["options"][option_idx]["text"],
					"id": option_idx,
					"call": {
						"object": conversation[dialog_id]["options"][option_idx]["call"]["object"],
						"method": conversation[dialog_id]["options"][option_idx]["call"]["method"],
						"args": conversation[dialog_id]["options"][option_idx]["call"]["args"].duplicate(),
						"at_start": conversation[dialog_id]["options"][option_idx]["call"]["call_at_start"]},
					"conditions": {},
					"variables": conversation[dialog_id]["options"][option_idx]["set_variable"]["variables"].duplicate(),
					"signal": {
						"argument": conversation[dialog_id]["options"][option_idx]["signal"]["signal"],
						"at_start": conversation[dialog_id]["options"][option_idx]["signal"]["call_at_start"]}}
					
				if not conversation[dialog_id]["options"][option_idx]["conditions"].is_empty():
					option_dict["conditions"] = {
						"operator": conversation[dialog_id]["options"][option_idx]["conditions"]["operator"],
						"a": _simplify_condition_structure(conversation[dialog_id]["options"][option_idx]["conditions"]["var_a"]["value"]),
						"b": _simplify_condition_structure(conversation[dialog_id]["options"][option_idx]["conditions"]["var_a"]["value"])}
				
				options.append(option_dict)
			
			var option_data: Dictionary = {
				"cancel_id": conversation[dialog_id]["cancel"],
				"keep_dialog_on_screen": conversation[dialog_id]["keep_dialog"],
				"options": options}
	
	return data
	

static func _simplify_condition_structure(condition_dict: Dictionary) -> Dictionary:
	var return_dict: Dictionary = {}
	if condition_dict["type"] == DialogType.ELEMENT:
		return_dict["type"] = 0
		return_dict["value"] = condition_dict["value"]["value"]
	elif condition_dict["type"] == DialogType.COMPARATION:
		# Making sure we have things to compare.
		if not condition_dict["var_a"].is_empty() and not condition_dict["var_b"].is_empty():
			return_dict["type"] = 1
			return_dict["value"] = {
				"a": _simplify_condition_structure(condition_dict["var_a"]),
				"b": _simplify_condition_structure(condition_dict["var_b"])}
	elif condition_dict["type"] == DialogType.CALL:
		return_dict["type"] = 2
		return_dict["value"] = {
			"object": condition_dict["object"],
			"method": condition_dict["is_alive"],
			"args": condition_dict["args"].duplicate()}
	
	return return_dict
