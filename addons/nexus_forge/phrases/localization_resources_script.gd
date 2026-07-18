@tool
extends PanelContainer

signal code_editor_variables_requested(path: String)

const BRACKET_HANDLER = preload("res://addons/nexus_forge/discourse/textedit_bracket_handler.gd")
const MAX_LINES: int = 3
const EXTRA_Y_PADDING: int = 8

var selected_key_index: int = -1
var selected_format: String = ""

var map: PhraseMap = null:
	set(m):
		map = m
		new_text_button.disabled = m == null
		language_opt_btn.disabled = m == null
		region_opt_btn.disabled = m == null

var save_required: bool = false
var text_editor: Window = null
var standard_regex: RegEx = null

@onready var search_file_ln_edt: LineEdit = $MainContainer/FilesContainer/SearchContainer/SearchFileLnEdt
@onready var file_menu_button: MenuButton = $MainContainer/FilesContainer/SearchContainer/FileMenuButton
@onready var files_tree: Tree = $MainContainer/FilesContainer/FilesTree
@onready var language_opt_btn: OptionButton = $MainContainer/FilesContainer/LanguageContainer/LangContainer/LanguageOptBtn
@onready var region_opt_btn: OptionButton = $MainContainer/FilesContainer/LanguageContainer/RegionContainer/RegionOptBtn
@onready var search_text_ln_edt: LineEdit = $MainContainer/DataHSplit/TextContainer/HBoxContainer/SearchTextLnEdt
@onready var new_text_button: Button = $MainContainer/DataHSplit/TextContainer/HBoxContainer/NewTextButton
#@onready var key_split_container: HSplitContainer = $MainContainer/DataHSplit/TextContainer/KeyScroll/KeySplitContainer
#@onready var key_container: VBoxContainer = $MainContainer/DataHSplit/TextContainer/KeyScroll/KeySplitContainer/KeyContainer
#@onready var text_container: VBoxContainer = $MainContainer/DataHSplit/TextContainer/KeyScroll/KeySplitContainer/TextContainer
@onready var search_case_ln_edt: LineEdit = $MainContainer/DataHSplit/CaseContainer/HeaderContainer/SearchCaseLnEdt
@onready var argument_opt_btn: OptionButton = $MainContainer/DataHSplit/CaseContainer/HeaderContainer/ArgumentOptBtn
@onready var new_case_btn: Button = $MainContainer/DataHSplit/CaseContainer/HeaderContainer/NewCaseBtn
#@onready var case_header_split: HSplitContainer = $MainContainer/DataHSplit/CaseContainer/CaseHeaderSplit
#@onready var cases_split: HSplitContainer = $MainContainer/DataHSplit/CaseContainer/KeyScroll/CasesSplit
#@onready var case_node_container: VBoxContainer = $MainContainer/DataHSplit/CaseContainer/KeyScroll/CasesSplit/CaseContainer/CaseNodeContainer
@onready var default_case_text: TextEdit = $MainContainer/DataHSplit/CaseContainer/CasesContainer/KeyScroll/CasesContainer/DefaultCaseContainer/DefaultCaseText
@onready var expand_default_btn: Button = $MainContainer/DataHSplit/CaseContainer/CasesContainer/KeyScroll/CasesContainer/DefaultCaseContainer/ExpandDefaultBtn
#@onready var result_node_container: VBoxContainer = $MainContainer/DataHSplit/CaseContainer/KeyScroll/CasesSplit/ResultContainer/ResultNodeContainer


func ready_plugin() -> void:
	text_editor = load("res://addons/nexus_forge/discourse/discourse_text_editor.tscn").instantiate()
	add_child(text_editor)
	text_editor.signal_variables = true
	text_editor.text_code_edit.syntax_highlighter
	text_editor.variable_called.connect(_on_editor_variable_called)
	text_editor.ready_plugin()
	
	var highlighter: NFEditorDialogSyntaxHighlighter = text_editor.text_code_edit.syntax_highlighter
	
	highlighter.set_use_token("&", false)
	highlighter.set_use_token("?", false)
	highlighter.match_unused_under_any = true
	
	standard_regex = RegEx.new()
	standard_regex.compile("\\{(\\![a-zA-Z\\_][a-zA-Z0-9\\_]+|(?!\\!)[^\\}]+)\\}")
	
	files_tree.ready_plugin()
	language_opt_btn.get_popup().min_size = Vector2i.ZERO
	region_opt_btn.get_popup().min_size = Vector2i.ZERO
	
	language_opt_btn.get_popup().max_size = Vector2i(280, 260)
	region_opt_btn.get_popup().max_size = Vector2i(280, 260)
	
	var locale: PackedStringArray = OS.get_locale().split("_")
	locale.resize(2)
	
	file_menu_button.icon = get_theme_icon("GuiTabMenuHl", "EditorIcons")
	
	expand_default_btn.icon = get_theme_icon("DistractionFree", "EditorIcons")
	expand_default_btn.pressed.connect(_on_open_focus_editor_pressed.bind(default_case_text, false))
	
	var def_highlighter: NFEditorDialogSyntaxHighlighter = NFEditorDialogSyntaxHighlighter.new()
	def_highlighter.set_use_token("&", false)
	def_highlighter.set_use_token("?", false)
	def_highlighter.match_unused_under_any = true
	default_case_text.set_script(BRACKET_HANDLER)
	default_case_text.syntax_highlighter = def_highlighter
	default_case_text.enter_shifts_focus = true
	
	_update_choice_textbox_size(default_case_text)
	
	for lang_code in TranslationServer.get_all_languages():
		language_opt_btn.add_item(TranslationServer.get_language_name(lang_code))
		language_opt_btn.set_item_metadata(-1, lang_code)
	
	select_language(locale[0])
	
	region_opt_btn.add_item("- N/A -")
	region_opt_btn.set_item_metadata(0, "")
	
	for country_code in TranslationServer.get_all_countries():
		region_opt_btn.add_item(TranslationServer.get_country_name(country_code))
		region_opt_btn.set_item_metadata(-1, country_code)
	
	region_opt_btn.select(0)
	
	new_text_button.pressed.connect(_on_new_key_field_button_pressed)
	new_case_btn.pressed.connect(_on_new_case_button_pressed)
	argument_opt_btn.item_selected.connect(_on_format_item_selected)
	
	files_tree.map_resource_selected.connect(_on_map_resource_selected)
	
	file_menu_button.get_popup().id_pressed.connect(_on_menu_id_pressed)
	files_tree.map_close_pressed.connect(_on_map_close_pressed)
	
	language_opt_btn.item_selected.connect(_on_file_edited)
	region_opt_btn.item_selected.connect(_on_file_edited)
	
	default_case_text.resized.connect(_update_choice_textbox_size.bind(default_case_text))
	default_case_text.text_changed.connect(_on_text_field_changed.bind(default_case_text))
	
	search_text_ln_edt.text_changed.connect(_on_key_search_text_changed)
	search_case_ln_edt.text_changed.connect(_on_case_search_text_changed)


func _on_case_line_text_changed(_text: String = "") -> void:
	validate_cases_entries()
	_on_file_edited()


func validate_cases_entries() -> void:
	var all_ids: Dictionary[String, Array] = {}
	var default_case: HBoxContainer = %CasesContainer.get_child(0)
	
	for node:HBoxContainer in %CasesContainer.get_children():
		if node == default_case or node.is_queued_for_deletion():
			continue
		
		var item: LineEdit = node.get_child(1)
		var key: String = item.text.strip_edges()
		
		if key.is_empty():
			continue
		
		if not all_ids.has(key):
			all_ids[key] = []
		all_ids[key].append(item)
	
	for item_key:String in all_ids.keys():
		if 1 < all_ids[item_key].size():
			for item:LineEdit in all_ids[item_key]:
				item.add_theme_color_override(&"font_color", Color(1.0, 0.29, 0.325))
		else:
			for item:LineEdit in all_ids[item_key]:
				if item.has_theme_color(&"font_color"):
					item.remove_theme_color_override(&"font_color")


func _on_key_line_text_changed(_text: String = "") -> void:
	validate_phrase_keys()
	_on_file_edited()


func validate_phrase_keys() -> void:
	var all_ids: Dictionary[String, Array] = {}
	
	for node in %EntriesContainer.get_children():
		if node.is_queued_for_deletion():
			continue
		
		var line: LineEdit = node.get_child(1)
		var key: String = line.text.strip_edges()
		
		if key.is_empty():
			continue
		
		if all_ids.has(key) == false:
			all_ids[key] = []
		all_ids[key].append(line)
	
	for item_key:String in all_ids.keys():
		if 1 < all_ids[item_key].size():
			for item:LineEdit in all_ids[item_key]:
				item.add_theme_color_override(&"font_color", Color(1.0, 0.29, 0.325))
		else:
			for item:LineEdit in all_ids[item_key]:
				if item.has_theme_color(&"font_color"):
					item.remove_theme_color_override(&"font_color")
	


#func _on_text_line_text_submitted(_text: String, edit_btn: Button) -> void:
	#edit_btn.grab_focus()


func _on_erase_case_button_pressed(item: HBoxContainer) -> void:
	erase_case(item.get_index() - 1)
	validate_cases_entries()


func _on_erase_key_button_pressed(key_node: HBoxContainer) -> void:
	if selected_key_index == key_node.get_index():
		selected_key_index = -1
		selected_format = ""
		clear_cases()
		default_case_text.clear()
		default_case_text.editable = false
		_update_choice_textbox_size(default_case_text)
		argument_opt_btn.clear()
		argument_opt_btn.disabled = true
		new_case_btn.disabled = true
	
	map.erase_entry(key_node.get_meta(&"phrase_key"))
	
	erase_key(key_node.get_index())
	
	validate_phrase_keys()


func _on_format_item_selected(idx: int) -> void:
	if selected_format != "":
		save_current_phrase_key()
	
	if selected_key_index < 0:
		return
	
	search_case_ln_edt.text = ""
	search_case_ln_edt.set_meta(&"current_search", "")
	clear_cases()
	
	var phrase_key: StringName = %EntriesContainer.get_child(selected_key_index).get_meta(&"phrase_key")
	var format_argument: String = argument_opt_btn.get_item_text(idx)
	
	default_case_text.text = map.get_case_default(phrase_key, format_argument)
	_update_choice_textbox_size(default_case_text)
	
	for case in map._phrases[phrase_key]["formats"][format_argument]["cases"].keys():
		create_case_entry(
				case,
				map.get_case(phrase_key, format_argument, case))
	
	selected_format = format_argument


func _on_map_resource_selected(new_map: PhraseMap) -> void:
	if map != null:
		save_current_resource()
	load_map(new_map)
	map = new_map
	save_required = false


func _on_map_close_pressed(closing_map: PhraseMap, requires_save: bool) -> void:
	if requires_save:
		var unsaved_dialog: AcceptDialog = load("res://addons/nexus_forge/dialogs/unsaved_dialog_script.gd").new()
		unsaved_dialog.dialog_text = "File has unsaved changes\nDo you want to save before closing?"
		unsaved_dialog.title = "Save changes..."
		add_child(unsaved_dialog)
		unsaved_dialog.show()
		
		var result: int = await unsaved_dialog.dialog_finished
		# 0 = save, 1 = don't save, 2 = cancel
		if result == 0: # Save
			save_current_resource()
			ResourceSaver.save(map)
		elif result == 2: # Cancel
			unsaved_dialog.queue_free()
			return
		
		unsaved_dialog.queue_free()
	
	if map == closing_map:
		clear_cases()
		default_case_text.clear()
		default_case_text.editable = false
		_update_choice_textbox_size(default_case_text)
		argument_opt_btn.clear()
		argument_opt_btn.disabled = true
		
		clear_keys()
		
		map = null
	
	files_tree.remove_map(closing_map)


func _on_edit_cases_pressed(container: HBoxContainer) -> void:
	var erase_btn: Button = container.get_child(0)
	var text_key: LineEdit = container.get_child(1)
	var text_line: TextEdit = container.get_child(2)
	var expand_button: Button = container.get_child(3)
	var edit_button: Button = container.get_child(4)
	
	if 0 <= selected_key_index:
		var prev_selected: HBoxContainer = %EntriesContainer.get_child(selected_key_index)
		if not selected_format.is_empty():
			save_current_phrase_key()
		
		prev_selected.get_child(0).disabled = false
		prev_selected.get_child(1).editable = true
		prev_selected.get_child(2).editable = true
		prev_selected.get_child(3).disabled = false
		var prev_edt_btn: Button = prev_selected.get_child(4)
		prev_edt_btn.icon = get_theme_icon("Edit", "EditorIcons")
		prev_edt_btn.tooltip_text = "Edit Cases"
		
		clear_cases()
		selected_format = ""
		
		if container.get_index() == selected_key_index:
			selected_key_index = -1
			default_case_text.clear()
			default_case_text.editable = false
			_update_choice_textbox_size(default_case_text)
			argument_opt_btn.clear()
			argument_opt_btn.disabled = true
			new_case_btn.disabled = true
			return
	
	selected_format = ""
	clear_cases()
	erase_btn.disabled = true
	text_key.editable = false
	text_line.editable = false
	expand_button.disabled = true
	edit_button.icon = get_theme_icon("Unlock", "EditorIcons")
	edit_button.tooltip_text = "Unlock"
	selected_key_index = container.get_index()
	
	var phrase_key: StringName = container.get_meta(&"phrase_key")
	
	if not map.has_entry(phrase_key) or map.get_entry(phrase_key) != text_line.text.strip_edges():
		map.set_entry(phrase_key, text_line.text.strip_edges())
	
	argument_opt_btn.clear()
	
	for existing_key in map.get_formats(phrase_key):
		argument_opt_btn.add_item(existing_key)
	
	default_case_text.editable = 0 < argument_opt_btn.item_count
	argument_opt_btn.disabled = not default_case_text.editable
	new_case_btn.disabled = argument_opt_btn.disabled
	
	if 0 < argument_opt_btn.item_count:
		var argument_format: String = argument_opt_btn.get_item_text(0)
		argument_opt_btn.select(0)
		default_case_text.text = map.get_case_default(phrase_key, argument_format)
		_update_choice_textbox_size(default_case_text)
		for custom_case in map._phrases[phrase_key]["formats"][argument_format]["cases"].keys():
			create_case_entry(
					custom_case,
					map.get_case(phrase_key, argument_format, custom_case))
		selected_format = argument_format


func _on_new_key_field_button_pressed() -> void:
	create_key_text_entry(&"", "")
	_on_file_edited()


func _on_file_edited(_arg = null) -> void:
	if save_required:
		return
	save_required = true
	files_tree.set_save_required(map, true)


func _on_new_case_button_pressed() -> void:
	create_case_entry("", "")
	_on_file_edited()


func _on_menu_id_pressed(id: int) -> void:
	var map_dialog: FileDialog = load("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	
	if id == 0: # New Map
		map_dialog.file_mode = map_dialog.FILE_MODE_SAVE_FILE
		map_dialog.title = "New map"
		
	elif id == 1: # Open Map
		map_dialog.file_mode = map_dialog.FILE_MODE_OPEN_FILE
		map_dialog.title = "Open map"
	
	add_child(map_dialog)
	map_dialog.show()
	
	var result: Array = await map_dialog.dialog_finished # (success: bool, resource_path: String)
	
	if result[0]:
		if id == 0: # New file
			var lang: String = language_opt_btn.get_selected_metadata().to_lower()
			var reg: String = region_opt_btn.get_selected_metadata().to_upper()
			var locale_code: String = lang if reg.is_empty() else lang + "_" + reg
			
			if 0 <= selected_key_index:
				save_current_resource()
			var new_map: PhraseMap = PhraseMap.new()
			new_map.locale = locale_code
			
			if ResourceLoader.has_cached(result[1]):
				new_map.take_over_path(result[1])
			new_map.resource_path = result[1]
			ResourceSaver.save(new_map, result[1])
			files_tree.add_map(new_map, true, false)
			load_map(new_map)
			map = new_map
			save_required = false
		elif id == 1:
			var res_pre: Resource = load(result[1])
			if res_pre is PhraseMap:
				if 0 <= selected_key_index:
					save_current_resource()
				
				if files_tree.has_map(res_pre):
					files_tree.select_map(res_pre, false)
				else:
					files_tree.add_map(res_pre, true, false)
				load_map(res_pre)
				map = res_pre
				save_required = false
	map_dialog.queue_free()


func _on_key_search_text_changed(text: String) -> void:
	var clean_text: String = text.strip_edges()
	
	if clean_text == search_text_ln_edt.get_meta(&"current_search", ""):
		return
	
	var mode: int = 1 if clean_text.begins_with("key:") else 2 if clean_text.begins_with("text:") else 0
	
	if mode != 0:
		clean_text = clean_text.trim_prefix("key:" if mode == 1 else "text:")
	
	#var idx: int = -1
	
	if clean_text.is_empty():
		for node in %EntriesContainer.get_children():
			node.visible = true
	else:
		for node in %EntriesContainer.get_children():
			if mode == 0: # Both
				node.visible = node.get_child(1).text.containsn(clean_text) or node.get_child(2).text.containsn(clean_text)
			elif mode == 1: # Key Only
				node.visible = node.get_child(1).text.containsn(clean_text)
			elif mode == 2: # Text only
				node.visible = node.get_child(2).text.containsn(clean_text)
			
	
	search_text_ln_edt.set_meta(&"current_search", clean_text)


func _on_case_search_text_changed(text: String) -> void:
	var clean_text: String = text.strip_edges()
	
	if clean_text == search_case_ln_edt.get_meta(&"current_search", ""):
		return
	
	var mode: int = 1 if clean_text.begins_with("case:") else 2 if clean_text.begins_with("result:") else 0
	
	if mode != 0:
		clean_text = clean_text.trim_prefix("case:" if mode == 1 else "result:")
	
	
	if clean_text.is_empty():
		for case_index in range(1, %CasesContainer.get_child_count()):
			%CasesContainer.get_child(case_index).visible = true
	else:
		for case_index in range(1, %CasesContainer.get_child_count()):
			var case_node: HBoxContainer = %CasesContainer.get_child(case_index)
			if mode == 0: # Both
				case_node.visible = case_node.get_child(0).text.containsn(clean_text) or case_node.get_child(1).text.containsn(clean_text)
			elif mode == 1: # Case
				case_node.visible = case_node.get_child(0).text.containsn(clean_text)
			elif mode == 2: # Format
				case_node.visible = case_node.get_child(1).text.containsn(clean_text)
	
	search_case_ln_edt.set_meta(&"current_search", clean_text)


func plugin_open_resource(resource: PhraseMap) -> void:
	if resource == map:
		return
	elif map != null:
		save_current_resource()
	
	if files_tree.has_map(resource):
		files_tree.select_map(resource, false)
	else:
		files_tree.add_map(resource, true, false)
	
	load_map(resource)
	map = resource
	save_required = false


func get_open_maps() -> Array[String]:
	return files_tree.get_open_files()


func open_map_files(files: Array[String]) -> void:
	for file in files:
		if not FileAccess.file_exists(file):
			continue
		var res_load: Resource = load(file)
		if res_load != null and res_load is PhraseMap:
			if files_tree.has_map(res_load):
				continue
			files_tree.add_map(res_load, false)


func select_language(language_code: String) -> void:
	if language_code.is_empty():
		return
	
	for idx in range(language_opt_btn.item_count):
		if language_opt_btn.get_item_metadata(idx) == language_code:
			language_opt_btn.select(idx)
			return


func select_region(country_code: String) -> void:
	if country_code.is_empty():
		region_opt_btn.select(0)
		return
	
	for idx in range(region_opt_btn.item_count):
		if region_opt_btn.get_item_metadata(idx) == country_code:
			region_opt_btn.select(idx)
			return


func load_map(new_map: PhraseMap) -> void:
	var locale_parts: PackedStringArray = new_map.locale.split("_", false, 1)
	var parts_size: int = locale_parts.size()
	var lang: String = locale_parts[0] if 0 < parts_size else language_opt_btn.get_selected_metadata()
	var reg: String = locale_parts[1] if parts_size == 2 else ""
	clear_keys()
	search_text_ln_edt.text = ""
	search_text_ln_edt.set_meta(&"current_search", "")
	select_language(lang)
	select_region(reg)
	clear_cases()
	search_case_ln_edt.text = ""
	search_case_ln_edt.set_meta(&"current_search", "")
	argument_opt_btn.clear()
	argument_opt_btn.disabled = true
	new_case_btn.disabled = true
	default_case_text.clear()
	default_case_text.editable = false
	_update_choice_textbox_size(default_case_text)
	
	selected_key_index = -1
	selected_format = ""
	
	for key:StringName in new_map.entries():
		create_key_text_entry(key, new_map.get_entry(key))


func save_current_phrase_key(fix_cases: bool = false) -> void:
	if selected_key_index < 0:
		return
	
	var phrase_key: StringName = %EntriesContainer.get_child(selected_key_index).get_meta(&"phrase_key")
	
	var cases: Dictionary[String, String] = {}
	var node_map: Dictionary[String, LineEdit] = {}
	
	var desired: String = ""
	var modified: String = ""
	var iteration: int = 0
	
	for case_index in range(1, %CasesContainer.get_child_count()):
		var case_entry: HBoxContainer = %CasesContainer.get_child(case_index)
		desired = case_entry.get_child(1).text.strip_edges()
		modified = desired
		iteration = 0
		while cases.has(modified):
			iteration += 1
			modified = desired + str(iteration)
		cases[modified] = case_entry.get_child(2).text
		node_map[modified] = case_entry.get_child(1)
	
	map.clear_cases(phrase_key, selected_format)
	
	for case in cases.keys():
		map.set_case(
				phrase_key,
				selected_format,
				case,
				cases[case])
		
		if fix_cases and case != node_map[case].text.strip_edges():
			node_map[case].text = case
	
	map.set_case_default(phrase_key, selected_format, default_case_text.text.strip_edges())
	
	if fix_cases:
		validate_cases_entries()


func clear_keys() -> void:
	for entry in %EntriesContainer.get_children():
		entry.queue_free()


func clear_cases() -> void:
	var default: HBoxContainer = %CasesContainer.get_child(0)
	
	for node in %CasesContainer.get_children():
		if node == default:
			continue
		%CasesContainer.remove_child(node)
		node.queue_free()


func erase_case(case_index: int) -> void:
	var case_count: int = %CasesContainer.get_child_count() - 1
	if case_count <= case_index or case_count <= 0:
		return
	
	var node: HBoxContainer = %CasesContainer.get_child(case_index + 1)
	var default_case: HBoxContainer = %CasesContainer.get_child(0)
	
	if case_count == 1:
		new_case_btn.focus_next = ^""
		node.queue_free()
		return
	
	if case_index == 0: # Removing the first item.
		var second: HBoxContainer = %CasesContainer.get_child(2)
		var def_expand_btn: Button = default_case.get_child(2)
		var second_case_ln: LineEdit = second.get_child(1)
		
		second_case_ln.focus_previous = def_expand_btn.get_path()
		def_expand_btn.focus_next = second_case_ln.get_path()
	elif case_count == case_index + 1: # It's the last item
		var case_text: LineEdit = %CasesContainer.get_child(-2).get_child(1)
		case_text.focus_next = ^""
	else: # It's between 2 items
		var expand_up: Button = %CasesContainer.get_child(case_index).get_child(-1)
		var line_down: LineEdit = %CasesContainer.get_child(case_index + 2).get_child(1)
		
		expand_up.focus_next = line_down.get_path()
		line_down.focus_previous = expand_up.get_path()
	
	%CasesContainer.remove_child(node)
	node.queue_free()


func erase_key(index: int) -> void:
	var item: HBoxContainer = %EntriesContainer.get_child(index)
	var new_child_count: int = %EntriesContainer.get_child_count() - 1
	
	if new_child_count <= 0:
		new_text_button.focus_next = ^""
		item.queue_free()
		return
	
	if index == 0: # It's the first item
		var target_ln: LineEdit = %EntriesContainer.get_child(1).get_child(1)
		new_text_button.focus_next = target_ln.get_path()
		target_ln.focus_previous = new_text_button.get_path()
	elif new_child_count == index: # It's the last item
		var target_btn: Button = %EntriesContainer.get_child(-2).get_child(-1)
		target_btn.focus_next = ^""
	else: # It's between 2 items
		var edit_btn_up: Button = %EntriesContainer.get_child(index - 1).get_child(-1)
		var line_down: LineEdit = %EntriesContainer.get_child(index + 1).get_child(1)
		edit_btn_up.focus_next = line_down.get_path()
		line_down.focus_previous = edit_btn_up.get_path()
	
	item.queue_free()


func save_current_resource(fix_keys: bool = false) -> void:
	if selected_format != "":
		save_current_phrase_key(fix_keys)
	
	var lang: String = language_opt_btn.get_selected_metadata().to_lower()
	var reg: String = region_opt_btn.get_selected_metadata().to_upper()
	var locale_code: String = lang if reg.is_empty() else lang + "_" + reg
	
	map.locale = locale_code
	
	# Correct key: Current text
	var keys: Dictionary[String, String] = {}
	
	# Correct key: Line field
	#var node_map: Dictionary[String, LineEdit] = {}
	
	var new_phrases: Dictionary[StringName, Dictionary]
	
	for key_node in %EntriesContainer.get_children():
		if key_node.is_queued_for_deletion():
			continue
		var entry_key: StringName = key_node.get_meta(&"phrase_key")
		var desired_id: String = key_node.get_child(1).text.strip_edges()
		var trailing_int: Dictionary = StringUtils.get_trailing_integer(desired_id)
		var iteration: int = trailing_int["integer"]
		var modified: String = desired_id
		
		if trailing_int["has_integer"]:
			desired_id = desired_id.trim_suffix(str(iteration))
		
		while keys.has(modified):
			iteration += 1
			modified = desired_id + str(iteration)
		
		# Update the entry first.
		map.set_entry(
				entry_key,
				key_node.get_child(2).text)
		
		# Store the entry with the correct key.
		new_phrases[modified] = map._phrases[entry_key]
		
		key_node.set_meta(&"phrase_key", modified) # Update the key on the node
		
		if fix_keys:
			key_node.get_child(1).text = modified
	
	# Assign the correct map to the dictionary.
	map._phrases.assign(new_phrases)
	
	if fix_keys:
		validate_phrase_keys()


func has_unsaved_files() -> bool:
	return files_tree.has_unsaved()


func save_all() -> void:
	for resource:PhraseMap in files_tree.get_unsaved_resources():
		if resource == map:
			save_current_resource(true)
		ResourceSaver.save(resource)
	files_tree.set_save_required_all(false)
	save_required = false


func filesystem_resource_removed(resource: Resource) -> void:
	if resource == null:
		return
	files_tree.remove_map(resource)
	if map == resource:
		clear_cases()
		default_case_text.clear()
		default_case_text.editable = false
		_update_choice_textbox_size(default_case_text)
		argument_opt_btn.clear()
		argument_opt_btn.disabled = true
		clear_keys()
		map = null


func close_active_map() -> void:
	if map == null:
		return
	
	if files_tree.requires_save(map):
		var unsaved_dialog: AcceptDialog = load("res://addons/nexus_forge/dialogs/unsaved_dialog_script.gd").new()
		unsaved_dialog.dialog_text = "File has unsaved changes\nDo you want to save before closing?"
		unsaved_dialog.title = "Save changes..."
		add_child(unsaved_dialog)
		unsaved_dialog.show()
		
		var result: int = await unsaved_dialog.dialog_finished
		# 0 = save, 1 = don't save, 2 = cancel
		if result == 0: # Save
			save_current_resource()
			ResourceSaver.save(map)
		elif result == 2: # Cancel
			unsaved_dialog.queue_free()
			return
		
		unsaved_dialog.queue_free()
	
	clear_cases()
	default_case_text.clear()
	default_case_text.editable = false
	_update_choice_textbox_size(default_case_text)
	argument_opt_btn.clear()
	argument_opt_btn.disabled = true
	
	clear_keys()
	
	files_tree.remove_map(map)
	
	map = null


func create_case_entry(case: String, format: String) -> void:
	var container: HBoxContainer = HBoxContainer.new()
	var case_line: LineEdit = LineEdit.new()
	var case_text: TextEdit = BRACKET_HANDLER.new()
	var erase_btn: Button = Button.new()
	var highlighter: NFEditorDialogSyntaxHighlighter = NFEditorDialogSyntaxHighlighter.new()
	var expand_text: Button = Button.new()
	
	highlighter.set_use_token("&", false)
	highlighter.set_use_token("?", false)
	highlighter.match_unused_under_any = true
	
	case_line.text = case
	case_line.text_changed.connect(_on_case_line_text_changed)
	case_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	case_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	case_line.size_flags_stretch_ratio = 1.0
	case_line.custom_minimum_size = Vector2(115.0, 33.0)
	
	case_text.syntax_highlighter = highlighter
	case_text.caret_blink = true
	case_text.placeholder_text = "Case format"
	case_text.custom_minimum_size.y = 33.0
	case_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	case_text.size_flags_stretch_ratio = 2.0
	case_text.text = format
	case_text.enter_shifts_focus = true
	
	erase_btn.tooltip_text = "Erase case"
	erase_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	erase_btn.flat = true
	erase_btn.icon = get_theme_icon("Remove", "EditorIcons")
	erase_btn.custom_minimum_size = Vector2(33.0, 33.0)
	erase_btn.pressed.connect(_on_erase_case_button_pressed.bind(container))
	
	expand_text.tooltip_text = "Open Editor"
	expand_text.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	expand_text.flat = true
	expand_text.custom_minimum_size = Vector2(33.0, 33.0)
	expand_text.icon = get_theme_icon("DistractionFree", "EditorIcons")
	expand_text.pressed.connect(_on_open_focus_editor_pressed.bind(case_text, false))
	
	container.add_child(erase_btn)
	container.add_child(case_line)
	container.add_child(case_text)
	container.add_child(expand_text)
	
	%CasesContainer.add_child(container)
	
	if %CasesContainer.get_child_count() <= 2: # It's the first item added
		expand_default_btn.focus_next = case_line.get_path()
		case_line.focus_previous = expand_default_btn.get_path()
	else: # We've added more before
		var prev_case: HBoxContainer = %CasesContainer.get_child(-2)
		case_line.focus_previous = prev_case.get_child(3).get_path()
		prev_case.get_child(3).focus_next = case_line.get_path()
	
	case_line.focus_next = case_text.get_path()
	case_text.focus_previous = case_line.get_path()
	case_text.focus_next = expand_text.get_path()
	expand_text.focus_previous = case_text.get_path()
	
	case_line.text_submitted.connect(_on_case_key_text_submitted.bind(case_line))
	
	case_text.resized.connect(_update_choice_textbox_size.bind(case_text))
	case_text.text_changed.connect(_on_text_field_changed.bind(case_text))


func create_key_text_entry(key: StringName, text_entry: String) -> void:
	print("Creating %s for %s" % [key, text_entry])
	var container: HBoxContainer = HBoxContainer.new()
	var erase_button: Button = Button.new()
	var key_line: LineEdit = LineEdit.new()
	var expand_button: Button = Button.new()
	var edit_button: Button = Button.new()
	var text_editor: TextEdit = BRACKET_HANDLER.new()
	var highligher: NFEditorDialogSyntaxHighlighter = NFEditorDialogSyntaxHighlighter.new()
	var entries: VBoxContainer = %EntriesContainer
	
	highligher.set_use_token("&", false)
	highligher.set_use_token("?", false)
	highligher.match_unused_under_any = true
	
	text_editor.syntax_highlighter = highligher
	text_editor.enter_shifts_focus = true
	
	if key.is_empty():
		container.set_meta(&"phrase_key", StringName(UUID.generate_new()))
	else:
		container.set_meta(&"phrase_key", key)
	
	key_line.caret_blink = true
	key_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	key_line.custom_minimum_size = Vector2(115.0, 33.0)
	key_line.placeholder_text = "Key"
	key_line.text = String(key)
	key_line.size_flags_stretch_ratio = 1.0
	
	erase_button.icon = get_theme_icon("Remove", "EditorIcons")
	erase_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	erase_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	erase_button.tooltip_text = "Erase key"
	erase_button.flat = true
	erase_button.custom_minimum_size = Vector2(33.0, 33.0)
	
	text_editor.text = text_entry
	text_editor.caret_blink = true
	text_editor.custom_minimum_size.y = 33.0
	text_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_editor.placeholder_text = "Phrase Text"
	text_editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	text_editor.size_flags_stretch_ratio = 2.0
	
	edit_button.custom_minimum_size = Vector2(33.0, 33.0)
	edit_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit_button.flat = true
	edit_button.icon = get_theme_icon("Edit", "EditorIcons")
	edit_button.tooltip_text = "Edit Cases"
	
	expand_button.custom_minimum_size = Vector2(33.0, 33.0)
	expand_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	expand_button.flat = true
	expand_button.icon = get_theme_icon("DistractionFree", "EditorIcons")
	expand_button.tooltip_text = "Open Editor"
	
	container.add_child(erase_button)
	container.add_child(key_line)
	container.add_child(text_editor)
	container.add_child(expand_button)
	container.add_child(edit_button)
	
	entries.add_child(container)
	
	if 0 < entries.get_child_count() - 1:
		var edit_btn: Button = entries.get_child(-2).get_child(-1)
		edit_btn.focus_next = key_line.get_path()
		key_line.focus_previous = edit_btn.get_path()
	else:
		new_text_button.focus_next = key_line.get_path()
		key_line.focus_previous = new_text_button.get_path()
	
	key_line.focus_next = text_editor.get_path()
	key_line.focus_neighbor_right = text_editor.get_path()
	
	text_editor.focus_previous = key_line.get_path()
	text_editor.focus_neighbor_left = key_line.get_path()
	text_editor.focus_next = expand_button.get_path()
	
	expand_button.focus_next = edit_button.get_path()
	expand_button.focus_previous = text_editor.get_path()
	
	edit_button.focus_previous = expand_button.get_path()
	
	key_line.text_changed.connect(_on_key_line_text_changed)
	key_line.text_submitted.connect(_on_case_key_text_submitted.bind(key_line))
	erase_button.pressed.connect(_on_erase_key_button_pressed.bind(container))
	text_editor.text_changed.connect(_on_text_field_changed.bind(text_editor))
	text_editor.resized.connect(_update_choice_textbox_size.bind(text_editor))
	expand_button.pressed.connect(_on_open_focus_editor_pressed.bind(text_editor, true))
	edit_button.pressed.connect(_on_edit_cases_pressed.bind(container))


func set_text_code_editor_variable_paths(paths: Array[Dictionary]) -> void:
	if not text_editor.visible:
		return
	
	text_editor.display_completion_options_variables(paths)


func _on_case_key_text_submitted(_text: String, field: LineEdit) -> void:
	var next_node: Control = field.find_next_valid_focus()
	if next_node != null:
		next_node.grab_focus()


func _update_choice_textbox_size(box: TextEdit) -> void:
	if box.size.x <= 0 or not box.is_visible_in_tree():
		return
	
	box.scroll_fit_content_height = true
	var total_visual_lines: int = 0
	for i in range(box.get_line_count()):
		total_visual_lines += 1 + box.get_line_wrap_count(i)
	if total_visual_lines <= MAX_LINES:
		box.custom_minimum_size.y = 0
		box.queue_redraw.call_deferred()
		return
	box.scroll_fit_content_height = false
	
	var new_height: float = MAX_LINES * box.get_line_height() + EXTRA_Y_PADDING
	if new_height != box.custom_minimum_size.y:
		box.custom_minimum_size.y = new_height
		box.queue_redraw.call_deferred()


func _on_text_field_changed(field: TextEdit) -> void:
	_update_choice_textbox_size(field)
	_on_file_edited()


func _on_open_focus_editor_pressed(target: TextEdit, is_key: bool) -> void:
	if text_editor.visible:
		return
	
	if is_key:
		var methods: Dictionary[String, Variant] = {}
		var standard_formats: Dictionary[String, Variant] = {}
		
		for method in get_api_user_methods():
			methods[method] = null
		
		for rgx_match in standard_regex.search_all(target.text):
			var text: String = rgx_match.get_string(1)
			var token: String = text[0]
			
			if token == "!" or token == "$":
				continue
			else:
				standard_formats[text] = null
		
		text_editor.variables.clear()
		text_editor.methods.assign(methods.keys())
		text_editor.plain_formats.assign(standard_formats.keys())
		text_editor.signal_variables = true
	else:
		var methods: Dictionary[String, Variant] = {}
		var variables: Dictionary[String, Variant] = {}
		var standard_formats: Dictionary[String, Variant] = {}
		
		for rgx_match in standard_regex.search_all(%EntriesContainer.get_child(selected_key_index).get_child(2).text):
			var text: String = rgx_match.get_string(1)
			var token: String = text[0]
			
			if token == "!":
				methods[text.substr(1)] = null
			elif token == "$":
				variables[text.substr(1)] = null
			else:
				standard_formats[text] = null
		
		text_editor.methods.assign(methods.keys())
		text_editor.plain_formats.assign(standard_formats.keys())
		text_editor.variables.assign(variables.keys())
		
		text_editor.signal_variables = false
	
	text_editor.set_code_text(target.text)
	text_editor.popup_centered()
	text_editor.grab_code_focus()
	
	var result: Array = await text_editor.action_finished
	
	if result[0]:
		if target.text != result[1]:
			target.text = result[1]
			_update_choice_textbox_size(target)


func _on_editor_variable_called(path: String) -> void:
	code_editor_variables_requested.emit(path.strip_edges().simplify_path())


func get_api_user_methods() -> Array[String]:
	var methods: Array[String] = []
	
	var method_blacklsit: Array[String] = []
	var singleton: PhraseAPI = PhraseAPI.new()
	var base_methods: Array = ClassDB.class_get_method_list(&"RefCounted")
	
	for method in base_methods:
		method_blacklsit.append(method["name"])
		
	for method:Dictionary in singleton.get_method_list():
		if method["name"] in method_blacklsit or method["return"]["type"] == TYPE_NIL:
			continue
		
		#var default_count: int = method["default_args"].size()
		#var default_index: int = method["args"].size() - default_count
		#var args: Array[Dictionary] = []
		#var arg_idx: int = -1
		#for arg: Dictionary in method["args"]:
			#arg_idx += 1
			#args.append({
				#"name": arg["name"],
				#"type": arg["type"],
				#"has_default": default_index <= arg_idx})
		#methods[method["name"]] = {"return_type": method["return"]["type"], "arguments": args}
		methods.append(method["name"])
	
	return methods
