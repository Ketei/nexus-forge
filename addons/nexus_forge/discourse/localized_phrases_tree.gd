extends Tree


signal phrase_deleted(word: String)
signal phrase_changed

enum ButtonID {
	DELETE,
	NEW_ARGUMENT}

enum ArgumentType{
	VARIABLE_GET,
	FUNCTION_CALL,
	#ARGUMENT_PASS
	}

const DEFAULT_KEY: String = "(default)"
var base_language: String = ""
var current_language: String = ""
var current_region: String = "base"

var localization: Dictionary = {
	#"_key": {
		#"node": "",
		#"localization": {
			#"en": {
				#"base": {
					#"text": "Hello {-player}",
					#"arguments": {"default": "", "custom": {"player": {"wulfre": "bear"}}}
				#},
				#"US": {
					#"text": "Alo {-sister}",
					#"arguments": {"default": "", "custom": {"sister": {"astolfo": "brother"}}}
				#}
			#}
		#}
		#}
}
#var map: Dictionary = {
	#"_key": {"node": "", "args": {"_player": {"_ass(metadata)": "node"}}}
#}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_item().collapsed = true
	button_clicked.connect(_on_word_button_clicked)
	item_edited.connect(_on_item_edited)


func _on_word_button_clicked(item: TreeItem, _column: int, id: int, _mouse_button_index: int) -> void:
	if id == ButtonID.DELETE:
		var is_word: bool = item.get_parent() == get_root()
		if is_word:
			#map.erase(item.get_text(0))
			phrase_deleted.emit(item.get_text(0))
		#else: # It's an argument
			#var key: String = item.get_parent().get_parent().get_text(0)
			#map[key]["args"].erase(item.get_text(0))
		item.free()
	elif id == ButtonID.NEW_ARGUMENT:
		var new_window: ConfirmationDialog = preload("res://addons/nexus_forge/dialogs/lineedit_confirmation_dialog.gd").new()
		new_window.line_placeholder_text = "New Argument"
		new_window.title = "Create Argument..."
		new_window.ok_button_text = "Create"
		new_window.use_blacklist = true
		new_window.allow_empty = false
		new_window.strip_edges = true
		new_window.error_line_empty_msg = "Argument can't be empty"
		new_window.error_line_blacklist_word_msg = "Argument already in use"
		
		for existing_arg in item.get_children():
			new_window.text_blacklist.append(
					existing_arg.get_text(0))
		
		add_child(new_window)
		new_window.show()
		new_window.grab_text_focus()
		
		var result: Array = await new_window.dialog_finished
		if result[0]:
			#var key: String = item.get_parent().get_text(0)
			var new_argument: TreeItem = item.create_child()
			new_argument.set_text(0, result[1])
			#map[key]["args"][result[1]] = ""
			new_argument.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
			new_argument.set_editable(1, true)
			new_argument.add_button(1, get_theme_icon("Remove", "EditorIcons"), ButtonID.DELETE, false, "Delete argument")
			
		new_window.queue_free()


func _on_item_edited() -> void:
	var edited: TreeItem = get_edited()
	
	if edited.get_parent() != get_root() or get_edited_column() != 1:
		return
	
	var phrase: Dictionary[String, Array] = get_phrase_arguments(edited.get_text(1))
	var reused_functions: Dictionary[String, TreeItem] = {}
	var reused_variables: Dictionary[String, TreeItem] = {}
	#var reused_arguments: Dictionary[String, TreeItem] = {}
	
	localization[edited.get_text(0)]["localization"][current_language][current_region]["text"] = edited.get_text(1)
	localization[edited.get_text(0)]["localization"][current_language][current_region]["arguments"].clear()
	
	for child in edited.get_children():
		match child.get_metadata(1):
			ArgumentType.VARIABLE_GET:
				if child.get_text(0) not in phrase["variables"]:
					child.free()
				else:
					reused_variables[child.get_text(0)] = child
					edited.remove_child(child)
			ArgumentType.FUNCTION_CALL:
				if child.get_text(0) not in phrase["functions"]:
					child.free()
				else:
					reused_functions[child.get_text(0)] = child
					edited.remove_child(child)
			#ArgumentType.ARGUMENT_PASS:
				#if child.get_text(0) not in phrase["arguments"]:
					#child.free()
				#else:
					#reused_arguments[child.get_text(0)] = child
					#edited.remove_child(child)
	
	for function in phrase["functions"]:
		if reused_functions.has(function):
			edited.add_child(reused_functions[function])
		else:
			var new_function: TreeItem = edited.create_child()
			new_function.set_text(0, function)
			new_function.set_text(1, "Function Call")
			new_function.set_metadata(1, ArgumentType.FUNCTION_CALL)
			new_function.add_button(
					1,
					get_theme_icon("Add", "EditorIcons"),
					ButtonID.NEW_ARGUMENT,
					false,
					"Create Case")
			
			var default_arg: TreeItem = new_function.create_child()
			default_arg.set_text(0, DEFAULT_KEY)
			default_arg.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
			default_arg.set_editable(1, true)
			
	
	for variable in phrase["variables"]:
		if reused_variables.has(variable):
			edited.add_child(reused_variables[variable])
		else:
			var new_var_entry: TreeItem = edited.create_child()
			new_var_entry.set_text(0, variable)
			new_var_entry.set_text(1, "Variable Get")
			new_var_entry.set_metadata(1, ArgumentType.VARIABLE_GET)
			new_var_entry.add_button(
					1,
					get_theme_icon("Add", "EditorIcons"),
					ButtonID.NEW_ARGUMENT,
					false,
					"Create Case")
			
			var default_arg: TreeItem = new_var_entry.create_child()
			default_arg.set_text(0, DEFAULT_KEY)
			default_arg.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
			default_arg.set_editable(1, true)
			
			
	
	#for argument in phrase["arguments"]:
		#if reused_arguments.has(argument):
			#edited.add_child(reused_arguments[argument])
		#else:
			#var new_arg: TreeItem = edited.create_child()
			#new_arg.set_text(0, argument)
			#new_arg.add_button(
				#1,
				#preload("res://addons/nexus_forge/common_icons/plus_icon.svg"),
				#ButtonID.NEW_ARGUMENT,
				#false,
				#"Create argument")
			#new_arg.set_metadata(1, ArgumentType.ARGUMENT_PASS)
		#
	
	# Making sure all items are in scene to prevent memory leaks
	
	for item_key in reused_functions.keys():
		if reused_functions[item_key].get_parent() == null:
			reused_functions[item_key].free()
	
	for item_key in reused_variables.keys():
		if reused_variables[item_key].get_parent() == null:
			reused_variables[item_key].free()
	
	#for item_key in reused_arguments.keys():
		#if reused_arguments[item_key].get_parent() == null:
			#reused_arguments[item_key].free()
	
	phrase_changed.emit()


func create_key(phrase_key: String) -> void:
	#var phrase: Dictionary[String, Array] = get_phrase_arguments(phrase_text)
	
	var new_entry: TreeItem = get_root().create_child()
	
	new_entry.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
	new_entry.set_edit_multiline(1, true)
	
	new_entry.set_text(0, phrase_key)
	new_entry.set_editable(1, true)
	new_entry.add_button(
			1,
			get_theme_icon("Remove", "EditorIcons"),
			ButtonID.DELETE,
			false,
			"Delete")
	#map[phrase_key] = {"node": new_entry, "args": {}}
	var localization_data: Dictionary = {}
	
	if is_locale_valid():
		localization_data[current_language] = {current_region: {"text": "", "arguments": {}}} 
	
	localization[phrase_key] = {
		"node": new_entry,
		"localization": localization_data}
	
	phrase_changed.emit()


func get_phrase_arguments(phrase_text: String) -> Dictionary[String, Array]:
	var function_calls: Array[String] = []
	var variable_calls: Array[String] = []
	#var arguments_vals: Array[String] = []
	
	var arguments: Dictionary[String, Array] = {
		"functions": function_calls,
		"variables": variable_calls,
		#"arguments": arguments_vals
		}
	
	var regex_search: RegEx = RegEx.new()
	#regex_search.compile("\\{\\-([^\\s\\}]+)\\}")
	#
	#for regex_match in regex_search.search_all(phrase_text): # -Argument
		#arguments_vals.append(regex_match.get_string(1))
	
	regex_search.compile("\\{\\$([^\\s\\}]+)\\}")
	
	for regex_match in regex_search.search_all(phrase_text): # $variable
		variable_calls.append(regex_match.get_string(1))
	
	regex_search.compile("\\{\\!([^\\s\\}]+)\\}")
	
	for regex_match in regex_search.search_all(phrase_text): # !function
		function_calls.append(regex_match.get_string(1))
	
	return arguments


func create_contextn(on_word: String, context_array: Array[String]) -> void:
	for item in get_root().get_children():
		if item.get_text(0) != on_word:
			continue
		var existing_contexts: Array[String] = []
		
		for context_item in item.get_children():
			existing_contexts.append(context_item.get_text(0))
		
		for new_context in context_array:
			var idx: int = existing_contexts.bsearch(new_context)
			
			if existing_contexts[idx] == new_context:
				if idx == 0:
					item.move_before(get_root().get_first_child())
				else:
					item.move_after(get_root().get_child(idx - 1))
			else:
				existing_contexts.insert(idx, new_context)
				var new_context_item: TreeItem = item.create_child(idx)
				new_context_item.set_text(
						0,
						"(default)" if new_context.is_empty() else new_context)
				new_context_item.add_button(
						0,
						get_theme_icon("Remove", "EditorIcons"),
						ButtonID.DELETE,
						false,
						"Delete Context")
				new_context_item.set_metadata(
						0,
						{
							"singular": "",
							"plural": "",
							"context": new_context})
		break


func get_used_keys() -> Array[String]:
	var words: Array[String] = []
	for item in get_root().get_children():
		words.append(item.get_text(0))
	return words


func search_word(word: String) -> void:
	if word.strip_edges().is_empty():
		for word_item in get_root().get_children():
			set_all_items_visibility(word_item, true)
	else:
		for word_item in get_root().get_children():
			var word_visible: bool = false
			for context_item in word_item.get_children():
				if context_item.get_text(0).containsn(word):
					if word_visible == false:
						word_visible = true
					context_item.visible = true
				else:
					context_item.visible = false
			
			word_item.visible = word_visible or word_item.get_text(0).containsn(word)


func set_all_items_visibility(on: TreeItem, item_visible: bool) -> void:
	on.visible = item_visible
	for item in on.get_children():
		set_all_items_visibility(item, item_visible)


func get_phrases() -> Dictionary[String, Dictionary]:
	var data: Dictionary[String, Dictionary] = {}
	
	for key_item in get_root().get_children():
		var args: Dictionary[String, Dictionary] = {}
		for arg_item in key_item.get_children():
			var arg_prefix: String = "$" if arg_item.get_metadata(1) == ArgumentType.VARIABLE_GET else "!"
			var arg_key: String = arg_prefix + arg_item.get_text(0)
			var custom_args: Dictionary[String, String] = {}
			args[arg_key] = {}
			for case in arg_item.get_children():
				var case_text: String = case.get_text(1)
				if case.get_text(0) == DEFAULT_KEY:
					args[arg_key]["default"] = case_text
				else:
					custom_args[case.get_text(0)] = case.get_text(1)
			args[arg_key]["custom"] = custom_args
		
		data[key_item.get_text(0)] = {
			"text": key_item.get_text(1),
			"arguments": args}
	return data


func clear_phrases() -> void:
	for item in get_root().get_children():
		item.free()


func set_phrase_data(phrase_data: Dictionary[String, Dictionary]) -> void:
	clear_phrases()
	localization.clear()
	for key in phrase_data.keys():
		create_key(key)
		for language in phrase_data[key].keys():
			var language_dict: Dictionary = {}
			localization[key]["localization"][language] = language_dict
			for region in phrase_data[key][language].keys():
				var region_dict: Dictionary = {}
				language_dict[region] = region_dict
				region_dict["text"] = phrase_data[key][language][region]["text"]
				region_dict["arguments"] = phrase_data[key][language][region]["arguments"].duplicate(true)


func set_phrases(phrases: Dictionary[String, Dictionary]) -> void:
	for child in get_root().get_children():
		child.free()
	 #phrases = {
		#KEY: {
			#"text": "",
			#"arguments": {
				#"default": "",
				#"custom": {
					#arg_key: {case_text: case} }}}}
	for phrase_key in phrases.keys():
		var new_phrase: TreeItem = get_root().create_child()
		new_phrase.set_text(0, phrase_key)
		new_phrase.set_text(1, phrases[phrase_key]["text"])
		for arg_key in phrases[phrase_key]["arguments"].keys():
			var new_arg: TreeItem = new_phrase.create_child()
			new_arg.set_text(0, arg_key)
			var default_case: TreeItem = new_arg.create_child()
			default_case.set_text(0, DEFAULT_KEY)
			default_case.set_text(1, phrases[phrase_key]["arguments"][arg_key]["default"])
			for case in phrases[phrase_key]["arguments"][arg_key]["custom"].keys():
				var case_item: TreeItem = new_arg.create_child()
				case_item.set_text(0, case)
				case_item.set_text(1, phrases[phrase_key]["arguments"][arg_key]["custom"][case])


func is_locale_valid() -> bool:
	return current_language != ""


func on_main_language() -> bool:
	return current_language == base_language


func set_locale(language: String, region: String = "base") -> void:
	get_root().visible = language != ""
	current_language = language
	current_region = region
	if language == "":
		return
	
	for node_key in localization.keys():
		var arguments: Dictionary = {}
		if localization[node_key]["localization"].has(language) and localization[node_key]["localization"][language].has(region):
			arguments.assign(localization[node_key]["localization"][language][region]["arguments"])
		localization[node_key]["node"].set_text(1, localization[node_key]["localization"][language][region]["text"])
		set_arguments_on_tree(
				localization[node_key]["node"],
				arguments)


func save_locale() -> void:
	if not is_locale_valid():
		return
	
	var current_data: Dictionary[String, Dictionary] = get_phrases()
	for phrase_key in current_data.keys():
	#for item in get_root().get_children(): # KEY_0
		#if not localization.has(item.get_text(0)):
			#localization[item.get_text(0)] = {"node": item, "localization": {}}
		#if not localization[item.get_text(0)]["localization"].has(current_language):
			#localization[item.get_text(0)]["localization"][current_language] = {}
		#if not localization[item.get_text(0)]["localization"][current_language].has(current_region):
			#localization[item.get_text(0)]["localization"][current_language][current_region] = {}
		#
		#var arguments: Dictionary = {}
		#var custom_cases: Dictionary[String, Dictionary] = {}
		#arguments["custom"] = custom_cases
		#arguments[DEFAULT_KEY] = ""
		#
		#for argument in item.get_children(): # thing
			#var cases: Dictionary[String, String] = {}
			#for case in argument.get_children(): # (default)
				#var case_key: String = case.get_text(0)
				#if case_key == DEFAULT_KEY:
					#arguments[case_key] = case.get_text(1)
				#else:
					#cases[case.get_text(0)] = case.get_text(1)
			##arguments["custom"][argument.get_text(0)] = cases
			#custom_cases[argument.get_text(0)] = cases
		
		#localization[item.get_text(0)]["localization"][current_language][current_region] = {
			#"text": item.get_text(1),
			#"arguments": arguments}
		localization[phrase_key]["localization"][current_language][current_region] = current_data[phrase_key]


func set_arguments_on_tree(tree: TreeItem, argument: Dictionary) -> void:
	for arg in tree.get_children():
		arg.free()
	
	for case:String in argument.keys():
		var case_item: TreeItem = tree.create_child()
		case_item.set_text(0, case.right(-1))
		case_item.set_text(1, "Function Call" if case.begins_with("!") else "Variable Get")
		case_item.set_metadata(1, ArgumentType.FUNCTION_CALL if case.begins_with("!") else ArgumentType.VARIABLE_GET)
		case_item.add_button(
				1,
				get_theme_icon("Add", "EditorIcons"),
				ButtonID.NEW_ARGUMENT,
				false,
				"Create Case")
		
		
		var default_case: TreeItem = case_item.create_child()
		default_case.set_text(0, DEFAULT_KEY)
		default_case.set_text(1, argument[case]["default"])
		default_case.set_editable(1, true)
		
		for custom_case in argument[case]["custom"].keys():
			var new_case: TreeItem = case_item.create_child()
			new_case.set_text(0, custom_case)
			new_case.set_text(1, argument[case]["custom"][custom_case])
			new_case.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
			new_case.set_editable(1, true)
			new_case.add_button(1, get_theme_icon("Remove", "EditorIcons"), ButtonID.DELETE, false, "Delete argument")
		
		
		
		#for arg_key in argument[case]["custom"].keys():
			#var new_arg: TreeItem = case_item.create_child()
			#new_arg.set_text(0, arg_key)
			#new_arg.add_button(
				#1,
				#preload("res://addons/nexus_forge/common_icons/plus_icon.svg"),
				#ButtonID.NEW_ARGUMENT,
				#false,
				#"Create argument")
			#new_arg.set_metadata(1, ArgumentType.ARGUMENT_PASS)
			


#func set_arguments_on(key: String, argument: Dictionary) -> void:
	#for item in get_root().get_children():
		#if item.get_text(0) != key:
			#continue
		#for arg in item.get_children():
			#arg.free()
		#var default_arg: TreeItem = item.create_child()
		#default_arg.set_text(0, DEFAULT_KEY)
		#default_arg.set_text(1, argument["default"])
		#default_arg.set_editable(1, true)
		#
		#for arg_key in argument["custom"].keys():
			#var new_arg: TreeItem = item.create_child()
			#new_arg.set_text(0, arg_key)
			#for case in argument["custom"][arg_key].keys():
				#var new_case: TreeItem = new_arg.create_child()
				#new_case.set_text(0, case)
				#new_case.set_text(1, argument["custom"][arg_key][case])
		#break


func create_locale(language: String, region: String = "base") -> void:
	for key_phrase in localization.keys():
		if not localization[key_phrase]["localization"].has(language):
			localization[key_phrase]["localization"][language] = {}
		if not localization[key_phrase]["localization"][language].has(region):
			localization[key_phrase]["localization"][language][region] = {}
		
		localization[key_phrase]["localization"][language][region]["text"] = localization[key_phrase]["localization"][base_language]["base"]["text"]
		localization[key_phrase]["localization"][language][region]["arguments"] = localization[key_phrase]["localization"][base_language]["base"]["arguments"].duplicate(true)


func remove_locale(language: String, region: String = "base") -> void:
	if region == "base":
		for key_phrase in localization.keys():
			localization[key_phrase]["localization"].erase(language)
	else:
		for key_phrase in localization.keys():
			localization[key_phrase]["localization"][language].erase(region)


func get_localization_structure() -> Dictionary[String, Dictionary]:
	var data: Dictionary[String, Dictionary] = {}
	
	for key_word:String in localization.keys():
		data[key_word] = {}
		for language_key:String in localization[key_word]["localization"].keys():
			data[key_word][language_key] = {}
			for region_key:String in localization[key_word]["localization"][language_key].keys():
				data[key_word][language_key][region_key] = {
					"text": localization[key_word]["localization"][language_key][region_key]["text"],
					"arguments": localization[key_word]["localization"][language_key][region_key]["arguments"].duplicate(true)}
	
	return data
