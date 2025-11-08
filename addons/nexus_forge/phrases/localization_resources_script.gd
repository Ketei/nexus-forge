@tool
extends PanelContainer



# The idea is that all key LineEdit contain a meta called "phrase_key", this
# contains the ORIGINAL key that came from the file. And it'll be the key we will
# use to save/load things from the map in memory.
#
# When saving the file (or switching files), we will perform a check, and if the
# meta is different from the text, we will update the file's keys before saving.


var selected_key: LineEdit = null
var selected_format: String = ""

var map: PhraseMap = null:
	set(m):
		map = m
		new_text_button.disabled = m == null
		language_opt_btn.disabled = m == null
		region_opt_btn.disabled = m == null

var save_required: bool = false

@onready var search_file_ln_edt: LineEdit = $MainContainer/FilesContainer/SearchContainer/SearchFileLnEdt
@onready var file_menu_button: MenuButton = $MainContainer/FilesContainer/SearchContainer/FileMenuButton
@onready var files_tree: Tree = $MainContainer/FilesContainer/FilesTree
@onready var language_opt_btn: OptionButton = $MainContainer/FilesContainer/LanguageContainer/LangContainer/LanguageOptBtn
@onready var region_opt_btn: OptionButton = $MainContainer/FilesContainer/LanguageContainer/RegionContainer/RegionOptBtn
@onready var search_text_ln_edt: LineEdit = $MainContainer/DataHSplit/TextContainer/HBoxContainer/SearchTextLnEdt
@onready var new_text_button: Button = $MainContainer/DataHSplit/TextContainer/HBoxContainer/NewTextButton
@onready var key_header_split: HSplitContainer = $MainContainer/DataHSplit/TextContainer/KeyHeaderSplit
@onready var key_split_container: HSplitContainer = $MainContainer/DataHSplit/TextContainer/KeyScroll/KeySplitContainer
@onready var key_container: VBoxContainer = $MainContainer/DataHSplit/TextContainer/KeyScroll/KeySplitContainer/KeyContainer
@onready var text_container: VBoxContainer = $MainContainer/DataHSplit/TextContainer/KeyScroll/KeySplitContainer/TextContainer
@onready var search_case_ln_edt: LineEdit = $MainContainer/DataHSplit/CaseContainer/HeaderContainer/SearchCaseLnEdt
@onready var argument_opt_btn: OptionButton = $MainContainer/DataHSplit/CaseContainer/HeaderContainer/ArgumentOptBtn
@onready var new_case_btn: Button = $MainContainer/DataHSplit/CaseContainer/HeaderContainer/NewCaseBtn
@onready var case_header_split: HSplitContainer = $MainContainer/DataHSplit/CaseContainer/CaseHeaderSplit
@onready var cases_split: HSplitContainer = $MainContainer/DataHSplit/CaseContainer/KeyScroll/CasesSplit
@onready var case_node_container: VBoxContainer = $MainContainer/DataHSplit/CaseContainer/KeyScroll/CasesSplit/CaseContainer/CaseNodeContainer
@onready var default_case_ln_edt: LineEdit = $MainContainer/DataHSplit/CaseContainer/KeyScroll/CasesSplit/ResultContainer/DefaultCaseLnEdt
@onready var result_node_container: VBoxContainer = $MainContainer/DataHSplit/CaseContainer/KeyScroll/CasesSplit/ResultContainer/ResultNodeContainer


func _ready() -> void:
	if Engine.is_editor_hint() and get_tree().edited_scene_root == self:
		return
	
	language_opt_btn.get_popup().min_size = Vector2i.ZERO
	region_opt_btn.get_popup().min_size = Vector2i.ZERO
	
	language_opt_btn.get_popup().max_size = Vector2i(280, 260)
	region_opt_btn.get_popup().max_size = Vector2i(280, 260)
	
	var locale: PackedStringArray = OS.get_locale().split("_")
	locale.resize(2)
	
	file_menu_button.icon = get_theme_icon("GuiTabMenuHl", "EditorIcons")
	key_split_container.dragged.connect(_on_scroll_dragged.bind(key_header_split))
	cases_split.dragged.connect(_on_scroll_dragged.bind(case_header_split))
	
	for lang_code in TranslationServer.get_all_languages():
		language_opt_btn.add_item(TranslationServer.get_language_name(lang_code))
		language_opt_btn.set_item_metadata(-1, lang_code)
	
	select_language(locale[0])
	
	for country_code in TranslationServer.get_all_countries():
		region_opt_btn.add_item(TranslationServer.get_country_name(country_code))
		region_opt_btn.set_item_metadata(-1, country_code)
	
	select_region(locale[1])
	
	new_text_button.pressed.connect(_on_new_key_field_button_pressed)
	new_case_btn.pressed.connect(_on_new_case_button_pressed)
	argument_opt_btn.item_selected.connect(_on_format_item_selected)
	
	files_tree.map_resource_selected.connect(_on_map_resource_selected)
	
	file_menu_button.get_popup().id_pressed.connect(_on_menu_id_pressed)
	files_tree.map_close_pressed.connect(_on_map_close_pressed)
	
	language_opt_btn.item_selected.connect(_on_file_edited)
	region_opt_btn.item_selected.connect(_on_file_edited)
	
	default_case_ln_edt.text_changed.connect(_on_file_edited)
	
	search_text_ln_edt.text_changed.connect(_on_key_search_text_changed)
	search_case_ln_edt.text_changed.connect(_on_case_search_text_changed)


func _on_scroll_dragged(offset: int, container: HSplitContainer) -> void:
	container.split_offset = offset


func _on_key_text_submitted(_text: String, line: LineEdit) -> void:
	line.release_focus()


func _on_key_line_text_submitted(_text: String, text_line: LineEdit) -> void:
	text_line.grab_focus()


func _on_case_line_text_changed(_text: String = "") -> void:
	var all_ids: Dictionary[String, Array] = {}
	
	for item:LineEdit in case_node_container.get_children():
		#var line: LineEdit = item
		var key: String = item.text.strip_edges()
		
		if key.is_empty():
			continue
		
		if all_ids.has(key) == false:
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
	var all_ids: Dictionary[String, Array] = {}
	
	for item in key_container.get_children():
		var line: LineEdit = item.get_child(1)
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
	
	_on_file_edited()


func _on_text_line_text_submitted(_text: String, edit_btn: Button) -> void:
	edit_btn.grab_focus()


func _on_erase_case_button_pressed(case_line: LineEdit) -> void:
	erase_case(case_line.get_index())
	_on_case_line_text_changed()


func _on_erase_key_button_pressed(key: LineEdit) -> void:
	if selected_key == key:
		selected_key = null
		selected_format = ""
		clear_cases()
		default_case_ln_edt.text = ""
		default_case_ln_edt.editable = false
		argument_opt_btn.clear()
		argument_opt_btn.disabled = true
		new_case_btn.disabled = true
	
	map.erase_phrase(key.get_meta(&"phrase_key"))
	
	erase_key(
		key.get_parent().get_index())
	
	_on_key_line_text_changed()


func _on_format_item_selected(idx: int) -> void:
	if selected_format != "":
		save_current_phrase_key()
	
	search_case_ln_edt.text = ""
	search_case_ln_edt.set_meta(&"current_search", "")
	clear_cases()
	
	var phrase_key: StringName = selected_key.get_meta(&"phrase_key")
	var format_argument: String = argument_opt_btn.get_item_text(idx)
	
	default_case_ln_edt.text = map.get_phrase_argument_default(phrase_key, format_argument)
	
	for case in map._phrases[phrase_key]["arguments"][format_argument]["custom"].keys():
		add_new_case(
				case,
				map._phrases[phrase_key]["arguments"][format_argument]["custom"][case])
	
	selected_format = format_argument


func _on_map_resource_selected(new_map: PhraseMap) -> void:
	save_current_resource()
	load_map(new_map)
	map = new_map
	save_required = false


func _on_map_close_pressed(closing_map: PhraseMap, requires_save: bool) -> void:
	if requires_save:
		var unsaved_dialog := preload("res://addons/nexus_forge/dialogs/unsaved_dialog_script.gd").new()
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
		default_case_ln_edt.text = ""
		default_case_ln_edt.editable = false
		argument_opt_btn.clear()
		argument_opt_btn.disabled = true
		
		clear_keys()
		
		map = null
	
	files_tree.remove_map(closing_map)


func _on_edit_cases_pressed(text_line: LineEdit, key: LineEdit, button: Button) -> void:
	if key == selected_key:
		if selected_format != "":
			save_current_phrase_key()
		text_line.editable = true
		button.icon = get_theme_icon("Edit", "EditorIcons")
		button.tooltip_text = "Edit Cases"
		selected_key = null
		selected_format = ""
		clear_cases()
		default_case_ln_edt.text = ""
		default_case_ln_edt.editable = false
		argument_opt_btn.clear()
		argument_opt_btn.disabled = true
		new_case_btn.disabled = true
		return
	elif selected_key != null:
		if selected_format != "":
			save_current_phrase_key()
		var old_edit: Button = text_container.get_child(selected_key.get_parent().get_index()).get_child(1)
		old_edit.get_parent().get_child(0).editable = true
		old_edit.icon = get_theme_icon("Edit", "EditorIcons")
		old_edit.tooltip_text = "Edit Cases"
		search_case_ln_edt.text = ""
		search_case_ln_edt.set_meta(&"current_search", "")
		clear_cases()
	
	var phrase_key: StringName = key.get_meta(&"phrase_key")
	
	if not map.has_phrase(phrase_key):
		map.create_phrase(phrase_key, text_line.text.strip_edges())
	elif map.get_phrase_text(phrase_key) != text_line.text.strip_edges():
		map.set_phrase_text(phrase_key, text_line.text.strip_edges())
	
	argument_opt_btn.clear()
	
	for existing_key in map.get_phrase_format_fields(phrase_key):
		argument_opt_btn.add_item(existing_key)
	
	selected_key = key
	default_case_ln_edt.editable = 0 < argument_opt_btn.item_count
	argument_opt_btn.disabled = not default_case_ln_edt.editable
	new_case_btn.disabled = argument_opt_btn.disabled
	
	if 0 < argument_opt_btn.item_count:
		var argument_format: String = argument_opt_btn.get_item_text(0)
		argument_opt_btn.select(0)
		default_case_ln_edt.text = map.get_phrase_argument_default(phrase_key, argument_format)
		for custom_case in map._phrases[phrase_key]["arguments"][argument_format]["custom"].keys():
			add_new_case(
					custom_case,
					map._phrases[phrase_key]["arguments"][argument_format]["custom"][custom_case])
		selected_format = argument_format
	
	text_line.editable = false
	button.icon = get_theme_icon("Unlock", "EditorIcons")
	button.tooltip_text = "Unlock Text"


func _on_new_key_field_button_pressed() -> void:
	add_new_phrase()
	_on_file_edited()


func _on_file_edited(_arg = null) -> void:
	if save_required:
		return
	save_required = true
	files_tree.set_save_required(map, true)


func _on_new_case_button_pressed() -> void:
	add_new_case()
	_on_file_edited()


func _on_menu_id_pressed(id: int) -> void:
	var map_dialog := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	
	if id == 0: # New Map
		map_dialog.file_mode = map_dialog.FILE_MODE_SAVE_FILE
		map_dialog.title = "New map"
		
	elif id == 1: # Open Map
		map_dialog.file_mode = map_dialog.FILE_MODE_OPEN_FILE
		map_dialog.title = "Open map"
	
	map_dialog.file_selected.connect(_on_file_map_selected.bind(map_dialog))
	map_dialog.canceled.connect(_on_file_map_canceled.bind(map_dialog))
	add_child(map_dialog)
	map_dialog.show()


func _on_file_map_canceled(dialog: FileDialog) -> void:
	dialog.queue_free()


func _on_file_map_selected(path: String, dialog: ConfirmationDialog) -> void:
	if dialog.file_mode == dialog.FILE_MODE_SAVE_FILE:
		if selected_key != null:
			save_current_resource()
		var new_map: PhraseMap = PhraseMap.new()
		new_map.language = language_opt_btn.get_selected_metadata()
		new_map.region = region_opt_btn.get_selected_metadata()
		if ResourceLoader.has_cached(path):
			new_map.take_over_path(path)
		new_map.resource_path = path
		files_tree.add_map(new_map, true, false)
		load_map(new_map)
		map = new_map
		save_required = false
	else:
		var res_pre: Resource = load(path)
		if res_pre is PhraseMap:
			if selected_key != null:
				save_current_resource()
			
			if files_tree.has_map(res_pre):
				files_tree.select_map(res_pre, false)
			else:
				files_tree.add_map(res_pre, true, false)
			load_map(res_pre)
			map = res_pre
			save_required = false
	dialog.queue_free()


func _on_key_search_text_changed(text: String) -> void:
	var clean_text: String = text.strip_edges()
	
	if clean_text == search_text_ln_edt.get_meta(&"current_search", ""):
		return
	
	var mode: int = 1 if clean_text.begins_with("key:") else 2 if clean_text.begins_with("text:") else 0
	
	if mode != 0:
		clean_text = clean_text.trim_prefix("key:" if mode == 1 else "text:")
	
	var idx: int = -1
	
	for key_child in key_container.get_children():
		idx += 1
		if clean_text.is_empty():
			key_child.visible = true
		else:
			if mode == 0:
				key_child.visible = key_child.get_child(1).text.containsn(clean_text) or text_container.get_child(idx).get_child(0).text.containsn(clean_text)
			elif mode == 1:
				key_child.visible = key_child.get_child(1).text.containsn(clean_text)
			elif mode == 2:
				key_child.visible = text_container.get_child(idx).get_child(0).text.containsn(clean_text)
		
		text_container.get_child(idx).visible = key_child.visible
	
	search_text_ln_edt.set_meta(&"current_search", clean_text)


func _on_case_search_text_changed(text: String) -> void:
	var clean_text: String = text.strip_edges()
	
	if clean_text == search_case_ln_edt.get_meta(&"current_search", ""):
		return
	
	var mode: int = 1 if clean_text.begins_with("case:") else 2 if clean_text.begins_with("result:") else 0
	
	if mode != 0:
		clean_text = clean_text.trim_prefix("case:" if mode == 1 else "result:")
	
	
	var idx: int = -1
	for case:LineEdit in case_node_container.get_children():
		idx += 1
		
		if clean_text.is_empty():
			case.visible = true
		else:
			if mode == 0:
				case.visible = case.text.containsn(clean_text) or result_node_container.get_child(idx).get_child(0).text.containsn(clean_text)
			elif mode == 1:
				case.visible = case.text.containsn(clean_text)
			elif mode == 2:
				case.visible = result_node_container.get_child(idx).get_child(0).text.containsn(clean_text)
		
		result_node_container.get_child(idx).visible = case.visible
	
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


func select_language(language_code: String) -> void:
	if language_code.is_empty():
		return
	
	for idx in range(language_opt_btn.item_count):
		if language_opt_btn.get_item_metadata(idx) == language_code:
			language_opt_btn.select(idx)
			return


func select_region(country_code: String) -> void:
	if country_code.is_empty():
		return
	
	for idx in range(region_opt_btn.item_count):
		if region_opt_btn.get_item_metadata(idx) == country_code:
			region_opt_btn.select(idx)
			return


func load_map(new_map: PhraseMap) -> void:
	clear_keys()
	search_text_ln_edt.text = ""
	search_text_ln_edt.set_meta(&"current_search", "")
	select_language(new_map.language)
	select_region(new_map.region)
	clear_cases()
	search_case_ln_edt.text = ""
	search_case_ln_edt.set_meta(&"current_search", "")
	argument_opt_btn.clear()
	argument_opt_btn.disabled = true
	new_case_btn.disabled = true
	default_case_ln_edt.text = ""
	default_case_ln_edt.editable = false
	
	selected_key = null
	selected_format = ""
	
	for key:StringName in new_map.phrases():
		add_new_phrase(
				key,
				new_map.get_phrase_text(key))


func save_current_phrase_key(fix_cases: bool = false) -> void:
	var phrase_key: StringName = selected_key.get_meta(&"phrase_key")
	
	var cases: Dictionary[String, String] = {}
	var node_map: Dictionary[String, LineEdit] = {}
	
	map.set_phrase_argument_default(
			phrase_key,
			selected_format,
			default_case_ln_edt.text.strip_edges())
	
	var case_idx: int = -1
	var desired: String = ""
	var modified: String = ""
	var iteration: int = 0
	
	for case_key:LineEdit in case_node_container.get_children():
		case_idx += 1
		desired = case_key.text.strip_edges()
		modified = desired
		iteration = 0
		while cases.has(modified):
			iteration += 1
			modified = desired + str(iteration)
		cases[modified] = result_node_container.get_child(case_idx).get_child(0).text
		node_map[modified] = case_key
	
	map.clear_phrase_argument_cases(phrase_key, selected_format)
	
	for case in cases.keys():
		map.set_phrase_argument_case(
				phrase_key,
				selected_format,
				case,
				cases[case])
		
		if fix_cases and case != node_map[case].text.strip_edges():
			node_map[case] = case
	
	if fix_cases:
		_on_case_line_text_changed()


func clear_keys() -> void:
	for key_node in key_container.get_children():
		key_container.remove_child(key_node)
		key_node.queue_free()
	for text_node in text_container.get_children():
		text_container.remove_child(text_node)
		text_node.queue_free()


func clear_cases() -> void:
	for case_key in case_node_container.get_children():
		case_node_container.remove_child(case_key)
		case_key.queue_free()
	for case_result in result_node_container.get_children():
		result_node_container.remove_child(case_result)
		case_result.queue_free()


func add_new_phrase(key: StringName = &"", text: String = "") -> void:
	var new_key: = new_key_container(key)
	var new_text: = new_text_field(text)
	
	key_container.add_child(new_key)
	text_container.add_child(new_text)
	
	var text_edit: LineEdit = new_text.get_child(0)
	var key_edit: LineEdit = new_key.get_child(1)
	var text_edit_btn: Button = new_text.get_child(1)
	
	if 0 < key_container.get_child_count() - 1:
		var btn: Button = text_container.get_child(-2).get_child(1)
		btn.focus_next = key_edit.get_path()
		key_edit.focus_previous = btn.get_path()
	else:
		new_text_button.focus_next = key_edit.get_path()
		key_edit.focus_previous = new_text_button.get_path()
	
	key_edit.focus_next = text_edit.get_path()
	key_edit.focus_neighbor_right = text_edit.get_path()
	
	text_edit.focus_previous = key_edit.get_path()
	text_edit.focus_neighbor_left = key_edit.get_path()
	text_edit.focus_next = text_edit_btn.get_path()
	
	text_edit_btn.focus_previous = text_edit.get_path()
	
	text_edit_btn.pressed.connect(_on_edit_cases_pressed.bind(text_edit, key_edit, text_edit_btn))


func add_new_case(case: String = "", case_text: String = "") -> void:
	var new_case: LineEdit = LineEdit.new()
	var case_result: HBoxContainer = new_case_result_node()
	var result_line: LineEdit = case_result.get_child(0)
	
	new_case.caret_blink = true
	new_case.placeholder_text = "Case"
	new_case.custom_minimum_size.y = 32.0
	new_case.text = case
	
	result_line.text = case_text
	
	case_node_container.add_child(new_case)
	result_node_container.add_child(case_result)
	
	new_case.focus_neighbor_right = result_line.get_path()
	result_line.focus_neighbor_left = new_case.get_path()
	new_case.focus_next = result_line.get_path()
	result_line.focus_previous = new_case.get_path()
	
	if 0 < result_node_container.get_child_count() - 1:
		var prev_case_result: LineEdit = result_node_container.get_child(-2).get_child(0)
		prev_case_result.focus_next = new_case.get_path()
		new_case.focus_previous = prev_case_result.get_path()
	else:
		new_case.focus_previous = default_case_ln_edt.get_path()
		default_case_ln_edt.focus_next = new_case.get_path()
	
	new_case.text_changed.connect(_on_case_line_text_changed)


func new_key_container(key: StringName = &"") -> HBoxContainer:
	var new_key: HBoxContainer = HBoxContainer.new()
	var key_line: LineEdit = LineEdit.new()
	var erase_button: Button = Button.new()
	
	if key.is_empty():
		key_line.set_meta(&"phrase_key", StringName(UUID.generate_new()))
	else:
		key_line.set_meta(&"phrase_key", key)
	
	key_line.caret_blink = true
	key_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_line.custom_minimum_size.y = 32.0
	key_line.placeholder_text = "Key"
	key_line.text = String(key)
	
	erase_button.icon = get_theme_icon("Remove", "EditorIcons")
	erase_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	erase_button.tooltip_text = "Erase key"
	erase_button.flat = true
	erase_button.custom_minimum_size = Vector2(32.0, 32.0)
	
	key_line.text_changed.connect(_on_key_line_text_changed)
	erase_button.pressed.connect(_on_erase_key_button_pressed.bind(key_line))
	
	new_key.add_child(erase_button)
	new_key.add_child(key_line)
	
	return new_key


func new_text_field(text: String = "") -> HBoxContainer:
	var new_text: HBoxContainer = HBoxContainer.new()
	var new_line: LineEdit = LineEdit.new()
	var edit_button: Button = Button.new()
	
	new_line.text = text
	
	new_text.add_child(new_line)
	new_text.add_child(edit_button)
	
	new_line.caret_blink = true
	new_line.custom_minimum_size.y = 32.0
	new_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_line.placeholder_text = "Phrase Text"
	edit_button.custom_minimum_size = Vector2(32.0, 32.0)
	edit_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit_button.flat = true
	edit_button.icon = get_theme_icon("Edit", "EditorIcons")
	edit_button.tooltip_text = "Edit Cases"
	
	new_line.text_submitted.connect(_on_text_line_text_submitted.bind(edit_button))
	new_line.text_changed.connect(_on_file_edited)
	
	return new_text


func new_case_result_node() -> HBoxContainer:
	var new_case: HBoxContainer = HBoxContainer.new()
	var case_text: LineEdit = LineEdit.new()
	var erase_case_btn: Button = Button.new()
	
	case_text.caret_blink = true
	case_text.placeholder_text = "Case format"
	case_text.custom_minimum_size.y = 32.0
	case_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	erase_case_btn.tooltip_text = "Erase case"
	erase_case_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	erase_case_btn.flat = true
	erase_case_btn.icon = get_theme_icon("Remove", "EditorIcons")
	erase_case_btn.custom_minimum_size = Vector2(32.0, 32.0)
	erase_case_btn.pressed.connect(_on_erase_case_button_pressed.bind(case_text))
	
	new_case.add_child(case_text)
	new_case.add_child(erase_case_btn)
	
	case_text.text_changed.connect(_on_file_edited)
	
	return new_case


func erase_case(index: int) -> void:
	var case: LineEdit = case_node_container.get_child(index)
	var text: Control = result_node_container.get_child(index)
	
	if case_node_container.get_child_count() - 1 <= 0:
		new_case_btn.focus_next = ^""
	else:
		if index == 0: # It's the first item
			var target_ln: LineEdit = case_node_container.get_child(1)
			new_text_button.focus_next = target_ln.get_path()
			target_ln.focus_previous = new_text_button.get_path()
		elif case_node_container.get_child_count() - 1 == index: # It's the last item
			var target_text: LineEdit = result_node_container.get_child(-2).get_child(0)
			target_text.focus_next = ^""
		else: # It's between 2 items
			var line_up: LineEdit = result_node_container.get_child(index - 1).get_child(0)
			var line_down: LineEdit = case_node_container.get_child(index + 1)
			line_up.focus_next = line_down.get_path()
			line_down.focus_previous = line_up.get_path()
	
	case_node_container.remove_child(case)
	result_node_container.remove_child(text)
	
	case.queue_free()
	text.queue_free()


func erase_key(index: int) -> void:
	var key: Control = key_container.get_child(index)
	var text: Control = text_container.get_child(index)
	
	if key_container.get_child_count() - 1 <= 0:
		new_text_button.focus_next = ^""
	else:
		if index == 0: # It's the first item
			var target_ln: LineEdit = text_container.get_child(1).get_child(0)
			new_text_button.focus_next = target_ln.get_path()
			target_ln.focus_previous = new_text_button.get_path()
		elif key_container.get_child_count() - 1 == index: # It's the last item
			var target_btn: Button = text_container.get_child(-2).get_child(1)
			target_btn.focus_next = ^""
		else: # It's between 2 items
			var button_up: Button = text_container.get_child(index - 1).get_child(1)
			var line_down: LineEdit = text_container.get_child(index + 1).get_child(0)
			button_up.focus_next = line_down.get_path()
			line_down.focus_previous = button_up.get_path()
	
	key_container.remove_child(key)
	text_container.remove_child(text)
	
	key.queue_free()
	text.queue_free()


#func used_keys() -> Array[String]:
	#var keys: Array[String] = []
	#for item in key_container.get_children():
		#keys.append(
				#item.get_child(1).text)
	#return keys


func save_current_resource(fix_keys: bool = false) -> void:
	if selected_format != "":
		save_current_phrase_key(fix_keys)
	
	map.language = language_opt_btn.get_selected_metadata()
	map.region = region_opt_btn.get_selected_metadata()
	
	# Correct key: Current text
	var keys: Dictionary[String, String] = {}
	
	# Correct key: Line field
	var node_map: Dictionary[String, LineEdit] = {}
	
	var idx: int = -1
	var key_line: LineEdit = null
	var current_text: String = ""
	var desired: String = ""
	var iteration: int = 0
	for key_node in key_container.get_children():
		idx += 1
		key_line = key_node.get_child(1)
		current_text = key_line.text.strip_edges()
		desired = current_text
		iteration = 0
		while keys.has(desired):
			iteration += 1
			desired = current_text + str(iteration)
		
		keys[desired] = text_container.get_child(idx).get_child(0).text
		node_map[desired] = key_line
	
	# Duplicate old map for separate key reassignement.
	var old_phrases: Dictionary[StringName, Dictionary] = map._phrases.duplicate()
	map._phrases.clear()
	
	# Separate key reassignement is important, because if we have {a:{}, b:{}}
	# And we changed the key a -> b and b -> a, on a single dictionary we would
	# do Dictionary[b] = [a] Dictionary.erase(a), and then we would only have
	# {b: {}} so when it came to do b -> a we would've lost data of the original
	# a. So instead we duplicate the dictionary and assign the new key to the
	# old value. No data lost.
	for key in keys.keys():
		var fixed_key: StringName = StringName(key)
		map._phrases[fixed_key] = old_phrases[node_map[key].get_meta(&"phrase_key")]
	
	for key in keys.keys():
		var strnm_key: StringName = StringName(key)
		
		
		if map.get_phrase_text(strnm_key) != keys[key]:
			map.set_phrase_text(strnm_key, keys[key])
 		
		node_map[key].set_meta(&"phrase_key", keys[key])
		if fix_keys and node_map[key].text.strip_edges() != key:
			node_map[key].text = key
	
	if fix_keys:
		_on_key_line_text_changed()


func has_unsaved_files() -> bool:
	return files_tree.has_unsaved()


func save_all() -> void:
	for resource:PhraseMap in files_tree.get_unsaved_resources():
		if resource == map:
			save_current_resource(true)
		ResourceSaver.save(resource)
	files_tree.set_save_required_all(false)
	save_required = false
