@tool
extends PanelContainer


enum QuestModeType {
	NONE = 0,
	QUEST = 1,
	STAGE = 2,
	OBJECTIVE = 3}

const MAX_UNDO_STEPS: int = 50

static var quest_path: String = ""
static var stage_path: String = ""
static var objecive_path: String = ""

var quest_mode: QuestModeType = QuestModeType.NONE
var quest_resource: Quest = null
var undo: UndoRedo = null

var selected_stage: StringName = &""
var selected_objective: StringName = &""

var _open_files: Dictionary[int, Dictionary] = {}

@onready var obj_req_chk_bx: CheckBox = $MainContainer/DataContainer/DataContainer/LogicContainer/TargetLogicContainer/ObjReqChkBx
@onready var crumbs_label: Label = $MainContainer/TitleContainer/CrumbsContainer/CrumbsLabel
@onready var file_search_ln_edt: LineEdit = $MainContainer/DataContainer/NavigationContainer/FileBarContainer/FileSearchLnEdt
@onready var new_quest_btn: Button = $MainContainer/DataContainer/NavigationContainer/FileBarContainer/NewQuestBtn
@onready var files_tree: Tree = $MainContainer/DataContainer/NavigationContainer/NavigationSplitContainer/FilesTree
@onready var quest_search_ln_edit: LineEdit = $MainContainer/DataContainer/NavigationContainer/NavigationSplitContainer/QuestsContainer/QuestSearchLnEdit
@onready var quest_tree: Tree = $MainContainer/DataContainer/NavigationContainer/NavigationSplitContainer/QuestsContainer/QuestTree
@onready var type_opt_btn: OptionButton = $MainContainer/DataContainer/DataContainer/BasicDataContainer/TypeContainer/TypeOptBtn
@onready var title_ln_edt: LineEdit = $MainContainer/DataContainer/DataContainer/BasicDataContainer/TitleContainer/TitleLnEdt
@onready var description_txt_edt: TextEdit = $MainContainer/DataContainer/DataContainer/BasicDataContainer/DescContainer/DescriptionTxtEdt
@onready var add_dict_button: Button = $MainContainer/DataContainer/DataContainer/BasicDataContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddDictButton
@onready var add_int_button: Button = $MainContainer/DataContainer/DataContainer/BasicDataContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddIntButton
@onready var add_float_button: Button = $MainContainer/DataContainer/DataContainer/BasicDataContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddFloatButton
@onready var add_bool_button: Button = $MainContainer/DataContainer/DataContainer/BasicDataContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddBoolButton
@onready var add_string_button: Button = $MainContainer/DataContainer/DataContainer/BasicDataContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddStringButton
@onready var custom_data_search_line: LineEdit = $MainContainer/DataContainer/DataContainer/BasicDataContainer/CustomDataContainer/CustomDataSearchLine
@onready var custom_data_tree: Tree = $MainContainer/DataContainer/DataContainer/BasicDataContainer/CustomDataContainer/CustomDataTree
@onready var events_tree: Tree = $MainContainer/DataContainer/DataContainer/LogicContainer/EventsContainer/EventsTree
@onready var success_pointer_opt_btn: OptionButton = $MainContainer/DataContainer/DataContainer/LogicContainer/StageLogicContainer/SuccessContainer/SuccessPointerOptBtn
@onready var failure_pointer_opt_btn: OptionButton = $MainContainer/DataContainer/DataContainer/LogicContainer/StageLogicContainer/FailureContainer/FailurePointerOptBtn
@onready var search_event_ln_edt: LineEdit = $MainContainer/DataContainer/DataContainer/LogicContainer/EventsContainer/EventsHeader/SearchEventLnEdt
@onready var requirement_search_ln_edt: LineEdit = $MainContainer/DataContainer/DataContainer/LogicContainer/TargetLogicContainer/RequirementsCotnainer/HeaderContainer/RequirementSearchLnEdt
@onready var edit_types_btn: Button = $MainContainer/DataContainer/DataContainer/BasicDataContainer/TypeContainer/EditTypesBtn

@onready var target_logic_container: VBoxContainer = $MainContainer/DataContainer/DataContainer/LogicContainer/TargetLogicContainer
@onready var stage_logic_container: VBoxContainer = $MainContainer/DataContainer/DataContainer/LogicContainer/StageLogicContainer

@onready var add_req_dict_button: Button = $MainContainer/DataContainer/DataContainer/LogicContainer/TargetLogicContainer/RequirementsCotnainer/HeaderContainer/AddButtonsContainer/AddReqDictButton
@onready var add_req_int_button: Button = $MainContainer/DataContainer/DataContainer/LogicContainer/TargetLogicContainer/RequirementsCotnainer/HeaderContainer/AddButtonsContainer/AddReqIntButton
@onready var add_req_float_button: Button = $MainContainer/DataContainer/DataContainer/LogicContainer/TargetLogicContainer/RequirementsCotnainer/HeaderContainer/AddButtonsContainer/AddReqFloatButton
@onready var add_req_bool_button: Button = $MainContainer/DataContainer/DataContainer/LogicContainer/TargetLogicContainer/RequirementsCotnainer/HeaderContainer/AddButtonsContainer/AddReqBoolButton
@onready var add_req_string_button: Button = $MainContainer/DataContainer/DataContainer/LogicContainer/TargetLogicContainer/RequirementsCotnainer/HeaderContainer/AddButtonsContainer/AddReqStringButton
@onready var obj_req_tree: Tree = $MainContainer/DataContainer/DataContainer/LogicContainer/TargetLogicContainer/RequirementsCotnainer/ObjReqTree


static func _static_init() -> void:
	update_script_path()


static func update_script_path(quest: bool = true, stage: bool = true, objective: bool = true) -> void:
	if not quest and not stage and not objective:
		return
	
	var all_classes: Array[Dictionary] = ProjectSettings.get_global_class_list()
	for class_entry in all_classes:
		if class_entry["class"] == "Quest":
			if quest:
				quest_path = class_entry["path"]
		elif class_entry["class"] == "QuestStage":
			if stage:
				stage_path = class_entry["path"]
		elif class_entry["class"] == "QuestObjective":
			if objective:
				objecive_path = class_entry["path"]
		
		if (not quest_path.is_empty() or not quest) and\
				(not stage_path.is_empty() or not stage) and\
				(not objecive_path.is_empty() or not objective):
			break


func _ready() -> void:
	set_process_input(false)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	
	if event is InputEventKey:
		if event.echo or not event.pressed or not event.ctrl_pressed:
			return
		
		var current_focus: Control = get_viewport().gui_get_focus_owner()
		
		if current_focus != null:
			if current_focus is LineEdit:
				if current_focus.is_editing():
					return
			elif current_focus is TextEdit:
				return
		
		if event.keycode == KEY_Z:
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_Y and not event.shift_pressed:
			get_viewport().set_input_as_handled()


func ready_plugin() -> void:
	set_process_input(true)
	obj_req_tree.ready_plugin()
	files_tree.ready_plugin()
	quest_tree.ready_plugin()
	events_tree.ready_plugin()
	custom_data_tree.ready_plugin()
	
	if custom_data_tree.has_undo():
		custom_data_tree._undo.free()
		custom_data_tree._undo = null
	
	add_req_dict_button.icon = get_theme_icon("FolderCreate", "EditorIcons")
	add_dict_button.icon = get_theme_icon("FolderCreate", "EditorIcons")
	file_search_ln_edt.right_icon = get_theme_icon("Search", "EditorIcons")
	quest_search_ln_edit.right_icon = get_theme_icon("Search", "EditorIcons")
	search_event_ln_edt.right_icon = get_theme_icon("Search", "EditorIcons")
	requirement_search_ln_edt.right_icon = get_theme_icon("Search", "EditorIcons")
	edit_types_btn.icon = get_theme_icon("Edit", "EditorIcons")
	
	success_pointer_opt_btn.add_item("Quest End")
	failure_pointer_opt_btn.add_item("Quest End")
	
	success_pointer_opt_btn.set_item_metadata(0, &"")
	failure_pointer_opt_btn.set_item_metadata(0, &"")
	
	set_quest_mode(QuestModeType.NONE)
	
	new_quest_btn.pressed.connect(_on_new_quest_file_pressed)
	file_search_ln_edt.text_changed.connect(_on_search_files_text_changed)
	files_tree.quest_selected.connect(_on_quest_resource_selected)
	files_tree.quest_close_pressed.connect(_on_quest_close_pressed)
	
	quest_search_ln_edit.text_changed.connect(_on_search_quest_text_changed)
	
	quest_tree.quest_selected.connect(_on_quest_root_selected)
	quest_tree.stage_selected.connect(_on_stage_selected)
	quest_tree.objective_selected.connect(_on_objective_selected)
	quest_tree.stage_created.connect(_on_stage_created)
	quest_tree.objective_created.connect(_on_objective_created)
	quest_tree.quest_id_changed.connect(_on_quest_id_changed)
	quest_tree.stage_id_changed.connect(_on_stage_id_changed)
	quest_tree.objective_id_changed.connect(_on_objective_id_changed)
	quest_tree.objective_rearranged.connect(_on_objective_rearranged)
	quest_tree.stage_erased.connect(_on_stage_erased)
	quest_tree.objective_erased.connect(_on_objective_erased)
	quest_tree.entry_stage_selected.connect(_on_entry_stage_selected)
	quest_tree.stage_duplicated.connect(_on_stage_duplicated)
	quest_tree.objective_duplicated.connect(_on_objective_duplicated)
	
	edit_types_btn.pressed.connect(_on_edit_types_pressed)
	
	add_int_button.pressed.connect(_on_add_custom_data_pressed.bind("new_int", 0))
	add_float_button.pressed.connect(_on_add_custom_data_pressed.bind("new_float", 0.0))
	add_bool_button.pressed.connect(_on_add_custom_data_pressed.bind("new_bool", false))
	add_string_button.pressed.connect(_on_add_custom_data_pressed.bind("new_string", ""))
	add_dict_button.pressed.connect(_on_add_custom_data_pressed.bind("new_folder", {}))
	
	custom_data_search_line.text_changed.connect(_on_custom_data_search_text_changed)
	
	requirement_search_ln_edt.text_changed.connect(_on_search_requirement_text_changed)
	search_event_ln_edt.text_changed.connect(_on_search_event_text_changed)
	
	add_req_dict_button.pressed.connect(_add_quest_requirement_data_pressed.bind({}))
	add_req_int_button.pressed.connect(_add_quest_requirement_data_pressed.bind(0))
	add_req_float_button.pressed.connect(_add_quest_requirement_data_pressed.bind(0.0))
	add_req_bool_button.pressed.connect(_add_quest_requirement_data_pressed.bind(false))
	add_req_string_button.pressed.connect(_add_quest_requirement_data_pressed.bind(""))
	
	# Unsaved triggers
	obj_req_tree.data_changed.connect(_on_something_changed)
	custom_data_tree.data_changed.connect(_on_something_changed)
	events_tree.data_changed.connect(_on_something_changed)
	type_opt_btn.item_selected.connect(_on_something_changed)
	title_ln_edt.text_changed.connect(_on_something_changed)
	description_txt_edt.text_changed.connect(_on_something_changed)
	obj_req_chk_bx.pressed.connect(_on_something_changed)
	success_pointer_opt_btn.item_selected.connect(_on_something_changed)
	failure_pointer_opt_btn.item_selected.connect(_on_something_changed)
	quest_tree.tree_changed.connect(_on_something_changed)


func filesystem_resource_removed(quest: Quest) -> void:
	var quest_id: int = quest.get_instance_id()
	if not _open_files.has(quest_id):
		return
	
	if quest_resource == quest:
		quest_resource = null
		quest_mode = QuestModeType.NONE
		set_quest_mode(QuestModeType.NONE)
		custom_data_tree.clear_data()
		events_tree.clear_data()
	
	_open_files[quest_id]["quest_undo"].free()
	_open_files[quest_id]["data_undo"].free()
	_open_files.erase(quest_id)
	files_tree.close_quest(quest)


func update_type_button(type: int) -> void:
	if quest_mode == QuestModeType.NONE:
		return
	
	if quest_mode == QuestModeType.QUEST and type == 1:
		set_quest_types(true)
	elif quest_mode == QuestModeType.STAGE and type == 2:
		set_stage_types(true)
	elif quest_mode == QuestModeType.OBJECTIVE and type == 3:
		set_objective_types(true)


func set_quest_types(reselect: bool = false) -> void:
	if not FileAccess.file_exists(quest_path):
		update_script_path(true, false, false)
		if not FileAccess.file_exists(quest_path):
			NFPluginGameHandler._log_msg(
					"odyssey - editor",
					"Unable to update quest types. Script not found.",
					NFPluginGameHandler._LogLevel.ERROR)
			return
	
	var script: Script = load(quest_path)
	
	if script == null:
		NFPluginGameHandler._log_msg(
				"odyssey - editor",
				"Unable to update quest types. Unable to load script.",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	var quest_constants: Dictionary = script.get_script_constant_map()
	
	if not quest_constants.has(&"QuestType"):
		type_opt_btn.clear()
		return
	
	var select: bool = 0 <= type_opt_btn.selected if reselect else false
	var selected: int = type_opt_btn.get_selected_metadata() if select else 0
	var new_index: int = -1
	var quest_types: Dictionary = quest_constants[&"QuestType"]
	var type_keys: Array = quest_types.keys()
	
	type_keys.sort_custom(func(a,b): return a.naturalnocasecmp_to(b) < 0)
	
	type_opt_btn.clear()
	
	var idx: int = -1
	for key in type_keys:
		idx += 1
		type_opt_btn.add_item(key.capitalize())
		type_opt_btn.set_item_metadata(idx, quest_types[key])
		if select and selected == quest_types[key]:
			new_index = idx
	
	if reselect and new_index != -1:
		type_opt_btn.select(new_index)


func set_stage_types(reselect: bool = false) -> void:
	if not FileAccess.file_exists(stage_path):
		update_script_path(false, true, false)
		if not FileAccess.file_exists(stage_path):
			NFPluginGameHandler._log_msg(
					"odyssey - editor",
					"Unable to update stage types. Script not found.",
					NFPluginGameHandler._LogLevel.ERROR)
			return
	
	var script: Script = load(stage_path)
	
	if script == null:
		NFPluginGameHandler._log_msg(
				"odyssey - editor",
				"Unable to update stage types. Unable to load script.",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	var stage_constants: Dictionary = script.get_script_constant_map()
	
	if not stage_constants.has(&"StageType"):
		type_opt_btn.clear()
		return
	
	var select: bool = 0 <= type_opt_btn.selected if reselect else false
	var selected: int = type_opt_btn.get_selected_metadata() if select else 0
	var new_index: int = -1
	var stage_types: Dictionary = stage_constants[&"StageType"]
	var type_keys: Array = stage_types.keys()
	
	type_keys.sort_custom(func(a,b): return a.naturalnocasecmp_to(b) < 0)
	
	type_opt_btn.clear()
	
	var idx: int = -1
	for key in type_keys:
		idx += 1
		type_opt_btn.add_item(key.capitalize())
		type_opt_btn.set_item_metadata(idx, stage_types[key])
		if select and selected == stage_types[key]:
			new_index = idx
	
	if reselect and new_index != -1:
		type_opt_btn.select(new_index)


func set_objective_types(reselect: bool = false) -> void:
	if not FileAccess.file_exists(objecive_path):
		update_script_path(false, true, false)
		if not FileAccess.file_exists(objecive_path):
			NFPluginGameHandler._log_msg(
					"odyssey - editor",
					"Unable to update objective types. Script not found.",
					NFPluginGameHandler._LogLevel.ERROR)
			return
	
	var script: Script = load(objecive_path)
	
	if script == null:
		NFPluginGameHandler._log_msg(
				"odyssey - editor",
				"Unable to update objective types. Unable to load script.",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	var objectitve_constants: Dictionary = script.get_script_constant_map()
	
	if not objectitve_constants.has(&"ObjectiveType"):
		type_opt_btn.clear()
		return
	
	var select: bool = 0 <= type_opt_btn.selected if reselect else false
	var selected: int = type_opt_btn.get_selected_metadata() if select else 0
	var new_index: int = -1
	var objectitve_types: Dictionary = objectitve_constants[&"ObjectiveType"]
	var type_keys: Array = objectitve_types.keys()
	
	type_keys.sort_custom(func(a,b): return a.naturalnocasecmp_to(b) < 0)
	
	type_opt_btn.clear()
	
	var idx: int = -1
	for key in type_keys:
		idx += 1
		type_opt_btn.add_item(key.capitalize())
		type_opt_btn.set_item_metadata(idx, objectitve_types[key])
		if select and selected == objectitve_types[key]:
			new_index = idx
	
	if reselect and new_index != -1:
		type_opt_btn.select(new_index)


func set_quest_mode(mode: QuestModeType) -> void:
	target_logic_container.visible = mode == QuestModeType.OBJECTIVE
	stage_logic_container.visible = mode == QuestModeType.STAGE
	$MainContainer/DataContainer/DataContainer/LogicContainer.collapsed = mode != QuestModeType.OBJECTIVE
	
	if mode == QuestModeType.QUEST:
		set_quest_types()
	elif mode == QuestModeType.STAGE:
		set_stage_types()
	elif mode == QuestModeType.OBJECTIVE:
		set_objective_types()
	else:
		type_opt_btn.clear()
	
	set_ui_enabled(mode != QuestModeType.NONE)


func set_ui_enabled(enabled: bool) -> void:
	var disabled: bool = not enabled
	type_opt_btn.disabled = disabled
	title_ln_edt.editable = enabled
	description_txt_edt.editable = enabled
	custom_data_tree.enabled = enabled
	events_tree.enabled = enabled
	edit_types_btn.disabled = disabled
	
	custom_data_tree.enabled = enabled
	add_int_button.disabled = disabled
	add_float_button.disabled = disabled
	add_bool_button.disabled = disabled
	add_string_button.disabled = disabled
	add_dict_button.disabled = disabled


func update_crumbs_label() -> void:
	if quest_resource == null:
		crumbs_label.text = ""
		return
	var items: Array[String] = [String(quest_resource.id)]
	if not selected_stage.is_empty():
		items.append(String(selected_stage))
	if not selected_objective.is_empty():
		items.append(String(selected_objective))
	crumbs_label.text = " / ".join(items)


func set_stage_target_disabled(target: StringName) -> void:
	for idx in range(1, success_pointer_opt_btn.item_count):
		var disabled: bool = success_pointer_opt_btn.get_item_metadata(idx) == target
		success_pointer_opt_btn.set_item_disabled(
				idx,
				disabled)
		failure_pointer_opt_btn.set_item_disabled(
				idx,
				disabled)


func set_stage_target_pointers(pointers: Array[StringName], reselect: bool = false) -> void:
	var reselect_success: bool = success_pointer_opt_btn.selected != -1
	var reselect_failure: bool = failure_pointer_opt_btn.selected != -1
	var success_id: StringName = success_pointer_opt_btn.get_selected_metadata() if reselect_success else &""
	var failure_id: StringName = failure_pointer_opt_btn.get_selected_metadata() if reselect_failure else &""
	
	success_pointer_opt_btn.clear()
	failure_pointer_opt_btn.clear()
	
	success_pointer_opt_btn.add_item("Quest End")
	failure_pointer_opt_btn.add_item("Quest End")
	
	success_pointer_opt_btn.set_item_metadata(0, &"")
	failure_pointer_opt_btn.set_item_metadata(0, &"")
	
	var idx: int = 0
	for item in pointers:
		idx += 1
		var text: String = String(item)
		success_pointer_opt_btn.add_item(text)
		success_pointer_opt_btn.set_item_metadata(idx, item)
		failure_pointer_opt_btn.add_item(text)
		failure_pointer_opt_btn.set_item_metadata(idx, item)
		if item == selected_stage:
			success_pointer_opt_btn.set_item_disabled(idx, true)
			failure_pointer_opt_btn.set_item_disabled(idx, true)
			
	
	if reselect:
		if reselect_success:
			var success_idx: int = pointers.find(success_id)
			success_pointer_opt_btn.select(0 if success_idx == -1 else success_idx)
		if reselect_failure:
			var failure_idx: int = pointers.find(failure_id)
			failure_pointer_opt_btn.select(0 if failure_idx == -1 else failure_idx)


func select_success_pointer(target: StringName) -> void:
	for idx in range(success_pointer_opt_btn.item_count):
		if success_pointer_opt_btn.get_item_metadata(idx) == target:
			success_pointer_opt_btn.set_meta(&"old_value", target)
			success_pointer_opt_btn.select(idx)
			return


func select_failure_pointer(target: StringName) -> void:
	for idx in range(failure_pointer_opt_btn.item_count):
		if failure_pointer_opt_btn.get_item_metadata(idx) == target:
			failure_pointer_opt_btn.set_meta(&"old_value", target)
			failure_pointer_opt_btn.select(idx)
			return


func save_current_quest() -> void:
	if quest_resource == null:
		return
	
	_open_files[quest_resource.get_instance_id()] = quest_tree.get_quest_structure()
	
	if quest_mode == QuestModeType.QUEST:
		quest_resource.type = type_opt_btn.get_selected_metadata() if -1 < type_opt_btn.selected else 0
		quest_resource.title = title_ln_edt.text.strip_edges()
		quest_resource.description = description_txt_edt.text.strip_edges()
		quest_resource.custom_data = custom_data_tree.get_data()
		
		quest_resource.on_success_events.clear()
		quest_resource.on_failure_events.clear()
		
		var events_data: Dictionary = events_tree.get_data()
		quest_resource.events[&"success"] = events_data["Success Events"]
		quest_resource.events[&"failure"] = events_data["Failure Events"]
	
	elif quest_mode == QuestModeType.STAGE:
		if not quest_resource.has_stage(selected_stage):
			return
		
		var stage: QuestStage = quest_resource.get_stage(selected_stage)
		
		stage.type = type_opt_btn.get_selected_metadata() if -1 < type_opt_btn.selected else 0
		stage.title = title_ln_edt.text.strip_edges()
		stage.description = description_txt_edt.text.strip_edges()
		stage.custom_data = custom_data_tree.get_data()
		
		stage.success_stage_id = success_pointer_opt_btn.get_selected_metadata()
		stage.failure_stage_id = failure_pointer_opt_btn.get_selected_metadata()
		
		var events_data: Dictionary = events_tree.get_data()
		stage.events[&"success"] = events_data["Success Events"]
		stage.events[&"failure"] = events_data["Failure Events"]
	
	elif quest_mode == QuestModeType.OBJECTIVE:
		if not quest_resource.has_stage(selected_stage) or not quest_resource.get_stage(selected_stage).has_objective(selected_objective):
			return
		
		var objective: QuestObjective = quest_resource.get_stage(selected_stage).get_objective(selected_objective)
		objective.type = type_opt_btn.get_selected_metadata() if -1 < type_opt_btn.selected else 0
		objective.title = title_ln_edt.text.strip_edges()
		objective.description = description_txt_edt.text.strip_edges()
		objective.custom_data.clear()
		objective.custom_data.assign(custom_data_tree.get_data())
		
		objective.clear_requirements()
		
		var events_data: Dictionary = events_tree.get_data()
		objective.events[&"success"] = events_data["Success Events"]
		objective.events[&"failure"] = events_data["Failure Events"]
		
		quest_resource.get_stage(selected_stage).set_objective_required(
				selected_objective,
				obj_req_chk_bx.button_pressed)
		
		objective._requirements = obj_req_tree.get_data()


func plugin_handle_resource(quest: Quest) -> void:
	if quest_resource != null and quest != quest_resource:
		save_current_quest()
		_open_files[quest_resource.get_instance_id()]["structure"] = quest_tree.get_quest_structure()
	
	var id: int = quest.get_instance_id()
	
	if not _open_files.has(id):
		add_quest_resource(quest)
	
	files_tree.select_quest(id, false)
	display_quest(id)


func display_quest(quest_id: int) -> void:
	if not _open_files.has(quest_id):
		return
	
	var quest: Quest = _open_files[quest_id]["resource"]
	
	var pointers: Array[StringName] = []
	pointers.assign(quest.stages())
	pointers.sort_custom(ArrayUtils.sort_custom_alphabetically_asc)
	set_stage_target_pointers(pointers)
	quest_tree.set_quest(quest)
	quest_tree.set_quest_structure(_open_files[quest_id]["structure"])
	quest_resource = quest
	set_quest_mode(QuestModeType.QUEST)
	load_quest_data()


func select_type(type: int) -> void:
	for idx in range(type_opt_btn.item_count):
		if type_opt_btn.get_item_metadata(idx) == type:
			type_opt_btn.select(idx)
			type_opt_btn.set_meta(&"old_value", type)
			return


func load_quest_data() -> void:
	quest_mode = QuestModeType.QUEST
	set_quest_mode(QuestModeType.QUEST)
	
	selected_stage = &""
	selected_objective = &""
	
	update_crumbs_label()
	
	title_ln_edt.text = quest_resource.title
	title_ln_edt.set_meta(&"old_value", quest_resource.title)
	select_type(quest_resource.type)
	description_txt_edt.text = quest_resource.description
	description_txt_edt.set_meta(&"old_value", quest_resource.description)
	
	events_tree.clear_data()
	custom_data_tree.clear_data(false)
	
	for data_key in quest_resource.custom_data.keys():
		custom_data_tree.add_data(
				data_key,
				quest_resource.custom_data[data_key],
				true)
	
	events_tree.add_data("Success Events", quest_resource.on_success_events, events_tree.get_root(), false, false, false)
	events_tree.add_data("Failure Events", quest_resource.on_failure_events, events_tree.get_root(), false, false, false)


func load_stage_data(stage_id: StringName) -> void:
	var stage: QuestStage = quest_resource.get_stage(stage_id)
	
	quest_mode = QuestModeType.STAGE
	set_quest_mode(QuestModeType.STAGE)
	
	title_ln_edt.text = stage.title
	title_ln_edt.set_meta(&"old_value", stage.title)
	description_txt_edt.text = stage.description
	description_txt_edt.set_meta(&"old_value", stage.description)
	select_type(stage.type)
	
	select_success_pointer(stage.success_stage_id)
	select_failure_pointer(stage.failure_stage_id)
	
	events_tree.clear_data()
	custom_data_tree.clear_data(false)
	
	for data_key in stage.custom_data.keys():
		custom_data_tree.add_data(
				data_key,
				stage.custom_data[data_key],
				true)
	
	events_tree.add_data("Success Events", stage.on_success_events, events_tree.get_root(), false, false, false)
	events_tree.add_data("Failure Events", stage.on_failure_events, events_tree.get_root(), false, false, false)
	
	selected_stage = stage_id
	selected_objective = &""
	
	update_crumbs_label()


func load_objective_data(stage_id: StringName, objective_id: StringName) -> void:
	var objective: QuestObjective = quest_resource.get_stage(stage_id).get_objective(objective_id)
	
	quest_mode = QuestModeType.OBJECTIVE
	set_quest_mode(QuestModeType.OBJECTIVE)
	
	title_ln_edt.text = objective.title
	title_ln_edt.set_meta(&"old_value", objective.title)
	description_txt_edt.text = objective.description
	description_txt_edt.set_meta(&"old_value", objective.description)
	select_type(objective.type)
	
	events_tree.clear_data()
	custom_data_tree.clear_data(false)
	
	obj_req_tree.set_data(objective._requirements)
	
	for data_key in objective.custom_data.keys():
		custom_data_tree.add_data(
				data_key,
				objective.custom_data[data_key],
				true)
	
	obj_req_chk_bx.set_pressed_no_signal(quest_resource.get_stage(stage_id).is_objective_required(objective_id))
	
	events_tree.add_data("Success Events", objective.on_success_events, events_tree.get_root(), false, false, false)
	events_tree.add_data("Failure Events", objective.on_failure_events, events_tree.get_root(), false, false, false)
	
	selected_stage = stage_id
	selected_objective = objective_id
	
	update_crumbs_label()


func has_unsaved_files() -> bool:
	return files_tree.has_unsaved_files()


func save_resource() -> void:
	if quest_resource != null:
		save_current_quest()
		_open_files[quest_resource.get_instance_id()]["structure"] = quest_tree.get_quest_structure()
	
	for unsaved_entries:Dictionary in files_tree.get_unsaved_files():
		var file: Quest = _open_files[unsaved_entries["id"]]["resource"]
		_save_cfg_for(
			file.resource_path,
			_open_files[unsaved_entries["id"]]["structure"])
		ResourceSaver.save(file)
	files_tree.set_all_saved()


func _save_cfg_for(filepath: String, structure: Array[Dictionary]) -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("Layout", "quest_structure", structure)
	var filename: String = filepath.get_file()
	var path_hash: String = filepath.md5_text()
	var absolute_path: String ="res://.godot/editor/"
	var cfg_filename: String = str(filename, "-treestate-", path_hash, ".cfg")
	
	if not DirAccess.dir_exists_absolute(absolute_path):
		DirAccess.make_dir_recursive_absolute(absolute_path)
	
	if cfg.save(absolute_path.path_join(cfg_filename)) != OK:
		NFPluginGameHandler._log_msg(
				"odyssey - editor",
				"Unable to save editor state to '%s'" % absolute_path.path_join(cfg_filename),
				NFPluginGameHandler._LogLevel.WARNING)


func get_open_files() -> Array[String]:
	var files: Array[String] = []
	for file_id in _open_files:
		files.append(_open_files[file_id]["resource"].resource_path)
	return files


func open_files(paths: Array[String]) -> void:
	for path in paths:
		open_quest_file(path)


func open_quest_file(file_path: String) -> void:
	if not ResourceLoader.exists(file_path):
		return
	
	var res: Resource = load(file_path)
	if res == null or res is not Quest:
		return
	
	var res_id: int = res.get_instance_id()
	
	if _open_files.has(res_id):
		return
	
	add_quest_resource(res)


func add_quest_resource(quest: Quest) -> void:
	var quest_undo: UndoRedo = UndoRedo.new()
	var data_undo: UndoRedo = UndoRedo.new()
	var structure: Array[Dictionary] = get_layout_config_for_file(quest.resource_path)
	
	_open_files[quest.get_instance_id()] = {
		"resource": quest,
		"quest_undo": quest_undo,
		"data_undo": data_undo,
		"structure": structure}
	
	files_tree.add_quest(
			quest,
			quest.resource_path)


func get_layout_config_for_file(file_path: String) -> Array[Dictionary]:
	var filename: String = file_path.get_file()
	var path_hash: String = file_path.md5_text()
	var absolute_path: String = "res://.godot/editor/"
	var cfg_filename: String = str(filename, "-treestate-", path_hash, ".cfg")
	var end_path: String = absolute_path.path_join(cfg_filename)
	return _get_layout_config(end_path)


func _get_layout_config(config_path: String) -> Array[Dictionary]:
	var structure: Array[Dictionary] = []
	
	if not FileAccess.file_exists(config_path):
		return structure
	
	var cfg: ConfigFile = ConfigFile.new()
	
	if not FileAccess.file_exists(config_path):
		return structure
		
	if cfg.load(config_path) != OK:
		return structure
	
	if not cfg.has_section_key("Layout", "quest_structure"):
		return structure
	
	var value = cfg.get_value("Layout", "quest_structure")
	
	if typeof(value) != TYPE_ARRAY:
		return structure
	
	for item in value:
		if typeof(item) == TYPE_DICTIONARY:
			structure.append(value)
	
	return structure


func _add_quest_requirement_data_pressed(data: Variant) -> void:
	obj_req_tree.add_data("new_requirement", data)


func _on_something_changed(_arg = null) -> void:
	files_tree.set_current_save_required(true)


func _on_quest_root_selected() -> void:
	if quest_resource == null:
		return
	save_current_quest()
	load_quest_data()


func _on_stage_selected(stage_id: StringName) -> void:
	if quest_resource == null or (selected_stage == stage_id and selected_objective == &""):
		return
	
	save_current_quest()
	load_stage_data(stage_id)
	set_stage_target_disabled(String(stage_id))


func _on_objective_selected(stage_id: StringName, objective_id: StringName) -> void:
	if quest_resource == null or (selected_stage == stage_id and selected_objective == objective_id):
		return
	
	save_current_quest()
	
	load_objective_data(stage_id, objective_id)


func _on_stage_created(stage_id: StringName) -> void:
	var new_stage: QuestStage = QuestStage.new()
	new_stage.id = stage_id
	quest_resource.add_stage(new_stage)
	var pointers: Array[StringName] = []
	pointers.assign(quest_resource.stages())
	pointers.sort_custom(ArrayUtils.sort_custom_alphabetically_asc)
	set_stage_target_pointers(pointers, true)
	_on_something_changed()


func _on_objective_created(stage_id: StringName, objective_id: StringName) -> void:
	var new_objective: QuestObjective = QuestObjective.new()
	
	new_objective.id = objective_id
	quest_resource.get_stage(stage_id).add_objective(new_objective, true)
	_on_something_changed()


func _on_quest_id_changed(_from: StringName, to: StringName) -> void:
	quest_resource.id = to
	_on_something_changed()
	update_crumbs_label()


func _on_stage_id_changed(from: StringName, to: StringName) -> void:
	if from == to:
		return
	quest_resource.get_stage(from).id = to
	quest_resource._stages[to] = quest_resource._stages[from]
	quest_resource._stages.erase(from)
	
	if quest_resource.entry_stage == from:
		quest_resource.entry_stage = to
	
	if selected_stage == from:
		selected_stage = to
	
	update_crumbs_label()
	
	_on_something_changed() 


func _on_objective_id_changed(on_stage: StringName, from: StringName, to: StringName) -> void:
	if from == to:
		return
	
	var obj_dict: Dictionary = quest_resource.get_stage(on_stage)._objectives
	obj_dict[from]["objective"].id = to
	obj_dict[to] = obj_dict[from]
	obj_dict.erase(from)
	
	if selected_stage == on_stage and selected_objective == from:
		selected_objective = to
	
	update_crumbs_label()
	
	_on_something_changed()


func _on_quest_resource_selected(quest_id: int) -> void:
	if quest_resource != null:
		save_current_quest()
	
	var resource: Quest = _open_files[quest_id]["resource"]
	quest_resource = resource
	undo = _open_files[quest_id]["quest_undo"]
	custom_data_tree.set_undo(_open_files[quest_id]["data_undo"])
	quest_tree.set_quest(resource, true, false)
	quest_tree.set_quest_structure(_open_files[quest_id]["structure"])
	
	var stages: Array[StringName] = resource.stages()
	stages.sort_custom(func(a:StringName,b:StringName): return a.naturalnocasecmp_to(String(b)) < 0)
	
	set_stage_target_pointers(stages)
	
	load_quest_data()


func _on_objective_rearranged(from_stage: StringName, to_stage: StringName, objective_id: StringName) -> void:
	if from_stage == to_stage:
		return
	
	var stage_source: QuestStage = quest_resource.get_stage(from_stage)
	var stage_target: QuestStage = quest_resource.get_stage(to_stage)
	var objective: QuestObjective = stage_source.get_objective(objective_id)
	var required: bool = stage_source.is_objective_required(objective_id)
	
	stage_source.remove_objective(objective_id)
	stage_target.add_objective(objective, required)
	
	_on_something_changed()


func _on_new_quest_file_pressed() -> void:
	var dialog: FileDialog = load("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	add_child(dialog)
	dialog.popup()
	
	var result: Array = await dialog.dialog_finished
	dialog.queue_free()
	
	if not result[0]:
		return
	
	if quest_resource != null:
		save_current_quest()
	
	var new_quest: Quest = Quest.new()
	var quest_undo: UndoRedo = UndoRedo.new()
	var data_undo: UndoRedo = UndoRedo.new()
	var quest_id: int = new_quest.get_instance_id()
	var take_over: bool = false
	
	quest_undo.max_steps = MAX_UNDO_STEPS
	data_undo.max_steps = MAX_UNDO_STEPS
	
	if new_quest.id.is_empty():
		new_quest.id = &"new_quest"
	
	if ResourceLoader.has_cached(result[1]):
		var cached_resource: Resource = ResourceLoader.get_cached_ref(result[1])
		var old_id: int = cached_resource.get_instance_id()
		take_over = true
		if _open_files.has(old_id):
			_open_files[old_id]["undo"].free()
			_open_files.erase(old_id)
			files_tree.remove_quest(old_id)
	else:
		new_quest.resource_path = result[1]
	
	ResourceSaver.save(new_quest, result[1])
	if take_over:
		new_quest.take_over_path(result[1])
	
	_open_files[quest_id] = {
		"resource": new_quest,
		"quest_undo": quest_undo,
		"data_undo": data_undo,
		"structure": ArrayUtils.create_typed(TYPE_DICTIONARY)}
	
	undo = quest_undo
	custom_data_tree.set_undo(data_undo)
	quest_resource = new_quest
	
	files_tree.add_quest(
			quest_id,
			result[1],
			true, # Select
			false) # Emit select
	
	quest_tree.set_quest(
			new_quest,
			true, # Select
			false) # Emit Select
	
	load_quest_data() # Loads the quest data
	var pointers: Array[StringName] = []
	pointers.assign(new_quest.stages())
	pointers.sort_custom(ArrayUtils.sort_custom_alphabetically_asc)
	set_stage_target_pointers(pointers)


func _on_search_files_text_changed(text: String) -> void:
	files_tree.search_for(text.strip_edges())


func _on_search_quest_text_changed(text: String) -> void:
	quest_tree.search_for(text.strip_edges())


func _on_custom_data_search_text_changed(text: String) -> void:
	custom_data_tree.search_data(text.strip_edges())


func _on_search_event_text_changed(text: String) -> void:
	var clean_text: String = text.strip_edges()
	for item in events_tree.get_root().get_children():
		item.visible = events_tree._child_has_data(item, clean_text)


func _on_search_requirement_text_changed(text: String) -> void:
	var clean_text: String = text.strip_edges()
	obj_req_tree.search_data(clean_text)


func _on_quest_close_pressed(quest_id: int, requires_save: bool, structure: Array[Dictionary]) -> void:
	if requires_save:
		var confirm_dialog: AcceptDialog = load("res://addons/nexus_forge/dialogs/unsaved_dialog_script.gd").new()
		confirm_dialog.dialog_text = "File has unsaved changes. Save before closing?"
		confirm_dialog.title = "Odyssey"
		add_child(confirm_dialog)
		confirm_dialog.popup()
		
		# 0 = save, 1 = don't save, 2 = cancel
		var result: int = await confirm_dialog.dialog_finished
		
		if result == 0:
			var quest_res: Quest = _open_files[quest_id]["resource"]
			if quest_res == quest_resource:
				save_current_quest()
			
			_save_cfg_for(
					quest_res.resource_path,
					structure)
			
			ResourceSaver.save(quest_res)
		elif result == 2:
			confirm_dialog.queue_free()
			return
	
	if quest_resource.get_instance_id() == quest_id:
		title_ln_edt.text = ""
		description_txt_edt.text = ""
		quest_resource = null
		quest_mode = QuestModeType.NONE
		set_quest_mode(QuestModeType.NONE)
		events_tree.clear_data()
		quest_tree.clear()
		custom_data_tree.clear_data(false)
		undo = null
		custom_data_tree.set_undo(null)
		update_crumbs_label()
	
	files_tree.remove_quest(quest_id)
	_open_files[quest_id]["quest_undo"].free()
	_open_files[quest_id]["data_undo"].free()
	_open_files.erase(quest_id)


func _on_stage_erased(stage_id: StringName) -> void:
	quest_resource.remove_stage(stage_id)
	if selected_stage == stage_id and selected_objective == &"":
		quest_tree.select_quest()
		load_quest_data()
	_on_something_changed()


func _on_objective_erased(from_stage: StringName, objective_id: StringName) -> void:
	quest_resource.get_stage(from_stage).remove_objective(objective_id)
	
	if selected_stage == from_stage and selected_objective == objective_id:
		quest_tree.select_stage(selected_stage, false)
		load_stage_data(from_stage)
	
	_on_something_changed()


func _on_add_custom_data_pressed(id: String, data) -> void:
	custom_data_tree.add_data(id, data)
	_on_something_changed()


func _on_entry_stage_selected(stage_id: StringName) -> void:
	quest_resource.entry_stage = stage_id
	_on_something_changed()


func _on_edit_types_pressed() -> void:
	match quest_mode:
		QuestModeType.QUEST:
			var quest_script: Script = Quest.new().get_script()
			var source_code: String = quest_script.source_code
			
			if source_code.is_empty():
				return
			
			var pattern: String = "enum\\s+QuestType\\s*\\{[^}]*\\}"
			var regex: RegEx = RegEx.new()
			regex.compile(pattern)
			
			var regex_match: RegExMatch = regex.search(source_code)
			
			if regex_match == null:
				return
			
			var match_start: int = regex_match.get_start()
			var match_string: String = regex_match.get_string()
			var brace_open_idx: int = match_start + match_string.find("{")
			var brace_close_index: int = regex_match.get_end() - 1
			
			var inner_length: int = brace_close_index - brace_open_idx - 1
			var inner_text: String = source_code.substr(brace_open_idx + 1, inner_length)
			var stripped_text: String = inner_text.strip_edges(false)
			
			var target_idx: int = brace_open_idx + stripped_text.length() + 1
			var text_before_target: String = source_code.substr(0, target_idx)
			
			var line: int  = text_before_target.count("\n") + 1
			var last_newline_idx: int = text_before_target.rfind("\n")
			var column: int = text_before_target.length() - last_newline_idx
			EditorInterface.edit_script(quest_script, line, column)
			
			if not EditorInterface.get_editor_settings().get_setting("text_editor/external/use_external_editor"):
				EditorInterface.set_main_screen_editor("Script")
		QuestModeType.STAGE:
			var stage_script: Script = QuestStage.new().get_script()
			var source_code: String = stage_script.source_code
			
			if source_code.is_empty():
				return
			
			var pattern: String = "enum\\s+StageType\\s*\\{[^}]*\\}"
			var regex: RegEx = RegEx.new()
			regex.compile(pattern)
			
			var regex_match: RegExMatch = regex.search(source_code)
			
			if regex_match == null:
				return
			
			var match_start: int = regex_match.get_start()
			var match_string: String = regex_match.get_string()
			var brace_open_idx: int = match_start + match_string.find("{")
			var brace_close_index: int = regex_match.get_end() - 1
			
			var inner_length: int = brace_close_index - brace_open_idx - 1
			var inner_text: String = source_code.substr(brace_open_idx + 1, inner_length)
			var stripped_text: String = inner_text.strip_edges(false)
			
			var target_idx: int = brace_open_idx + stripped_text.length() + 1
			var text_before_target: String = source_code.substr(0, target_idx)
			
			var line: int  = text_before_target.count("\n") + 1
			var last_newline_idx: int = text_before_target.rfind("\n")
			var column: int = text_before_target.length() - last_newline_idx
			EditorInterface.edit_script(stage_script, line, column)
			
			if not EditorInterface.get_editor_settings().get_setting("text_editor/external/use_external_editor"):
				EditorInterface.set_main_screen_editor("Script")
		QuestModeType.OBJECTIVE:
			EditorInterface.edit_script(QuestObjective.new().get_script())
			var objective_script: Script = QuestObjective.new().get_script()
			var source_code: String = objective_script.source_code
			
			if source_code.is_empty():
				return
			
			var pattern: String = "enum\\s+ObjectiveType\\s*\\{[^}]*\\}"
			var regex: RegEx = RegEx.new()
			regex.compile(pattern)
			
			var regex_match: RegExMatch = regex.search(source_code)
			
			if regex_match == null:
				return
			
			var match_start: int = regex_match.get_start()
			var match_string: String = regex_match.get_string()
			var brace_open_idx: int = match_start + match_string.find("{")
			var brace_close_index: int = regex_match.get_end() - 1
			
			var inner_length: int = brace_close_index - brace_open_idx - 1
			var inner_text: String = source_code.substr(brace_open_idx + 1, inner_length)
			var stripped_text: String = inner_text.strip_edges(false)
			
			var target_idx: int = brace_open_idx + stripped_text.length() + 1
			var text_before_target: String = source_code.substr(0, target_idx)
			
			var line: int  = text_before_target.count("\n") + 1
			var last_newline_idx: int = text_before_target.rfind("\n")
			var column: int = text_before_target.length() - last_newline_idx
			EditorInterface.edit_script(objective_script, line, column)
			
			if not EditorInterface.get_editor_settings().get_setting("text_editor/external/use_external_editor"):
				EditorInterface.set_main_screen_editor("Script")


func _on_stage_duplicated(from: StringName, duplicate_id: StringName) -> void:
	var stage: QuestStage = quest_resource.get_stage(from).duplicate(true)
	stage.id = duplicate_id
	quest_resource.add_stage(stage)
	_on_something_changed()


func _on_objective_duplicated(from_stage: StringName, objective_id: StringName, duplicate_id: StringName) -> void:
	var stage: QuestStage = quest_resource.get_stage(from_stage)
	var objective: QuestObjective = stage.get_objective(objective_id).duplicate(true)
	objective.id = duplicate_id
	
	stage.add_objective(objective, stage.is_objective_required(objective_id))
	_on_something_changed()


# ------ UNDO/REDO ------

func _on_quest_type_selected() -> void:
	pass


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for open_file in _open_files:
			if is_instance_valid(_open_files[open_file]["quest_undo"]):
				_open_files[open_file]["quest_undo"].free()
			if is_instance_valid(_open_files[open_file]["data_undo"]):
				_open_files[open_file]["data_undo"].free()
