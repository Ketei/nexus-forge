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

# Order of events -> 
# Set characer & portrait -> set dialog & time -> set options -> set variables
# call methods -> signal start -> display text -> |if options exist| display options
# select option -> set options variables -> send option signal -> call option methods
# hide options -> || if unpaused, move to next.


### Returns the internal conversation dictionary with each dialogue key having
### the complete structure required for a conversation with the conversation
### data of each dialogue included.[br]
### It'll also build the dialog map if it hand't been before.
### Check [method get_dialog_structure] for the conversation structure and
### [method get_option_structure] for the reply option structure.[br]
### DON'T change the dictionary from the resource.
#func get_dialog_map() -> Dictionary:
	#if _full_conv.is_empty():
		#_build_full_conv()
	#return _full_conv
#
#
### Will build the conversation map if empty, if it isn't empty it'll do nothing.
### It is reccomended to call this during a loading screen to prevent any lag
### spike the building might cause.
#func build_dialog_map() -> void:
	#if _full_conv.is_empty():
		#_build_full_conv()
#
#
### Fully rebuilds the interanl conversation map if you changed it.
#func rebuild_dialog_map() -> void:
	#_build_full_conv()
#
#
## Returns an array with all the character IDs that participate in this
## conversation.
func get_conversation_characters() -> Array[StringName]:
	var characters: Array[StringName] = []
	for conv in conversation:
		if conversation[conv]["type"] != DialogType.DIALOG:
			continue
		characters.append(conversation[conv]["character"]["id"])
	return characters


### Gets a dictionary with keys [code]id[/code], [code]idle[/code] and [br]
### [code]talking[/code].
#func get_character(conversation_id: String) -> Dictionary:
	#return _full_conv[conversation_id]["character"]
#
#
### Gets the character id of [param conversation_id].
#func get_character_id(conversation_id: String) -> String:
	#return _full_conv[conversation_id]["character"]["id"]
#
#
### Gets the character mood of [param conversation_id].
#func get_character_portrait_idle(conversation_id: String) -> Dictionary:
	#return _full_conv[conversation_id]["character"]["idle"]
#
#
### Gets the character mood of [param conversation_id].
#func get_character_portrait_talking(conversation_id: String) -> Dictionary:
	#return _full_conv[conversation_id]["character"]["talking"]
#
#
### Gets a dictionary with keys [code]text[/code] and [code]seconds_per_letter[/code].
#func get_dialog(conversation_id: String) -> Dictionary:
	#return _full_conv[conversation_id]["dialog"]
#
#
### Returns the dialogue text from [param conversation_id].
#func get_dialog_text(conversation_id: String) -> String:
	#return _full_conv[conversation_id]["dialog"]["text"]
#
#
### Gets a dictionary with keys [code]options[/code] and [code]cancel[/code].
#func get_dialog_replies(conversation_id: String) -> Dictionary:
	#return _full_conv[conversation_id]["replies"]
#
#
### Returns true if the [param conversation_id] has replies. If not it means only text
### needs to be displayed.
#func has_replies(conversation_id: String) -> bool:
	#return not _full_conv[conversation_id]["replies"]["options"].is_empty()
#
#
### Returns the string to emit on the signal
#func get_signal_arg(conversation_id: String) -> String:
	#return _full_conv[conversation_id]["signal"]
#
#
### Gets the next direct dialog id to go to. It'll only return the direct next
### dialog id. It won't take options into consideration.
#func get_next_dialog(conversation_id: String) -> String:
	#return _full_conv[conversation_id]["next"]
#
#
### Gets a dictionary with keys as variable name and values as the values to set.
#func get_variables(conversation_id: String) -> Dictionary:
	#return _full_conv[conversation_id]["set_variable"]
#
#
### Returns true if the conversation has the required method call fields.
#func has_method_call(conversation_id: String) -> bool:
	#return not (_full_conv[conversation_id]["call"]["node"].is_empty() or _full_conv[conversation_id]["call"]["method"].is_empty())
#
#
### Gets a dictionary with keys [code]node[/code], [code]method[/code] 
### and [code]args[/code].
#func get_method_call(conversation_id: String) -> Dictionary:
	#return _full_conv[conversation_id]["call"]
#
#
### Returns true if the conversation should be paused on this dialog.
#func pause_after_display(conversation_id: String) -> bool:
	#return _full_conv[conversation_id]["pause"]
#
#
### Gets a dictionary with keys [code]text[/code], [code]next[/code],
### [code]signal[/code], [code]set_variable[/code] and [code]call[/code].
#func get_option_data(conversation_id: String, option_idx: int) -> Dictionary:
	#return _full_conv[conversation_id]["replies"]["options"][option_idx]
#
#
### Returns true if the conversation option has the required method call fields.
#func has_option_method_call(conversation_id: String, option_idx: int) -> bool:
	#return not (_full_conv[conversation_id]["replies"]["options"][option_idx]["call"]["node"].is_empty() or _full_conv[conversation_id]["replies"]["options"][option_idx]["call"]["method"].is_empty())
#
#


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


## Returns a complete dialog structure with default values. Used for the
## creation of a complete conversation map.[br]
## [codeblock lang=gdscript]
## {
##	"type": DialogType.DIALOG
##	"character": {
##		"id": "",
##		"idle": {"animation": "", "play": false},
##		"talking": {"animation": "", "play": false}},
##	"dialog": {"text": "", "seconds_per_letter": -1.0},
##	"next": {},
##	"signal": {},
##	"set_variable": {},
##	"call": {},
##	"pause": false
## }
## [/codeblock]
static func get_dialog_structure() -> Dictionary:
	return {
		"type": DialogType.DIALOG,
		"character": {},
		"dialog": {"text": "", "seconds_per_letter": -1.0}, # <0 means nothing will change.
		# get_next_structure
		"next": {},
		"signal": {},
		"set_variable": {},
		"call": {},
		"pause": false,
		"offset": Vector2(), # Editor only
		"expand": true # Editor only
	}


static func get_character_structure() -> Dictionary:
	return {
		"id": "",
		"idle": {"animation": "", "play": false},
		"talking": {"animation": "", "play": false},
		"offset": Vector2(),
		"expand": true # Editor only
	}


static func get_call_structure() -> Dictionary:
	return {
		"type": DialogType.CALL,
		"object": "",
		"method": "",
		"args": [],
		"call_at_start": true,
		"is_return": false,
		"offset": Vector2(),
		"expand": true # Editor only
	}


# Used for signal emmision.
static func get_signal_structure() -> Dictionary:
	return {"signal": "", "call_at_start": true,"offset": Vector2()}


# To be used on the "next" of dialogs replies.
static func get_next_structure() -> Dictionary:
	return {
		"type": NextType.END,
		# get_next_by_id, get_replies_structure, 
		# get_condition_structure, get_random_select_structure
		"data": {}
	}


static func get_next_by_id() -> Dictionary:
	return {"next": "", "use_shortcut": false, "offset": Vector2()}


static func get_replies_structure() -> Dictionary:
	return {
		"type": DialogType.OPTIONS,
		"options": [], # Has get_option_structure
		"targets": [], # get_next.., get_condition, get_random_select
		"cancel": -1,
		"keep_dialog": true,
		"offset": Vector2() # Offsest of the reply selector
	}


## Returns a complete dialog option structure with default values. Used for the
## creation of a complete conversation map.[br]
## [codeblock lang=gdscript]
##{
##	"text": "",
##	"next": "",
##	"signal": "",
##	"conditions": {},
##	"set_variable": {},
##	"call": {"node": "", "method": &"", "args": []}
##}
## [/codeblock]
static func get_option_structure() -> Dictionary:
	return {
		"text": "",
		"signal": {},
		"conditions": {}, # uses get_comparation_structure.
		"set_variable": {},
		"call": {},
		"offset": Vector2()
	}


static func get_condition_structure() -> Dictionary:
	return {
		"type": DialogType.CONDITION,
		"comparation": {}, # uses get_comparation_structure
		"true": {}, # next_structure
		"false": {},
		"offset": Vector2()
	}


# Used in condition structure and replies
static func get_comparation_structure() -> Dictionary:
	return {
		"type": DialogType.COMPARATION,
		"var_a": {}, # Can use get_comparation_structure and get_element_structure
		"var_b": {},
		"operator": OP_EQUAL,
		"offset": Vector2()
	}


# Used for comparation
static func get_element_structure() -> Dictionary:
	return {
		"type": DialogType.ELEMENT,
		"value": {}, # uses _get_val_structure
		"offset": Vector2()
	}


# Used only on get_element_structure
static func _get_val_structure(element_type := ElementType.STRING) -> Dictionary:
	return {
		"element_type": element_type,
		"value": ""
	}


static func get_set_var_structure() -> Dictionary:
	return {
		"variables": {},
		"offset": Vector2(), # Editor only
		"expand": true # Editor only
	}


static func get_random_select_structure() -> Dictionary:
	return {
		"type": DialogType.RANDOM,
		"use_weights": false,
		"options": [], # full of get_random_select_opt_structure
		"offset": Vector2()
	}


static func get_random_select_opt_structure() -> Dictionary:
	return {
		"next": {},
		"weight": 0.0
	}


static func get_comment_structure() -> Dictionary:
	return {
		"text": "",
		"size": Vector2(175, 100),
		"offset": Vector2()
	}


static func get_end_structure() -> Dictionary:
	return {
		"type": DialogType.END,
		"offset": Vector2()}


# var_a: "variant" = Will "variant"(string)
# var_a: "{variant}" = will access the variable "variant" and compare it.
# var_a: "[Globals/variant,{arg_a,arg_b}]" = Will do Globals.variant.callv()
#	with everything in {} as a list as argument

# comparators "==" "!=" "<" ">" "<=" ">="
