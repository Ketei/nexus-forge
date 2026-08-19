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
			if event.shift_pressed:
				if undo.has_redo():
					var action_name: String = undo.get_action_name(undo.get_current_action() + 1)
					undo.redo()
					NFPluginGameHandler._log_msg(
						"",
						"Redo: " + action_name,
						NFPluginGameHandler._LogLevel.EDITOR)
					_on_something_changed()
			else:
				if undo.has_undo():
					var action_name: String = undo.get_current_action_name()
					undo.undo()
					NFPluginGameHandler._log_msg(
						"",
						"Undo: " + action_name,
						NFPluginGameHandler._LogLevel.EDITOR)
					_on_something_changed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_Y and not event.shift_pressed:
			if undo.has_redo():
				var action_name: String = undo.get_action_name(undo.get_current_action() + 1)
				undo.redo()
				NFPluginGameHandler._log_msg(
					"",
					"Redo: " + action_name,
					NFPluginGameHandler._LogLevel.EDITOR)
				_on_something_changed()
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
	title_ln_edt.text_changed.connect(_on_something_changed)
	description_txt_edt.text_changed.connect(_on_something_changed)
	success_pointer_opt_btn.item_selected.connect(_on_something_changed)
	failure_pointer_opt_btn.item_selected.connect(_on_something_changed)
	
	title_ln_edt.editing_toggled.connect(_on_title_edit_toggled)
	description_txt_edt.focus_exited.connect(_on_description_focus_lost)
	type_opt_btn.item_selected.connect(_on_quest_type_selected)
	obj_req_chk_bx.toggled.connect(_on_objective_required_toggled)
	custom_data_tree.data_changed.connect(_on_custom_data_changed)
	
	# Creation
	quest_tree.stage_created.connect(_on_stage_created)
	quest_tree.objective_created.connect(_on_objective_created)
	
	# Renaming
	quest_tree.quest_id_changed.connect(_on_quest_id_changed)
	quest_tree.stage_id_changed.connect(_on_stage_id_changed)
	quest_tree.objective_id_changed.connect(_on_objective_id_changed)
	
	# Deletion
	quest_tree.stage_erased.connect(_on_stage_erased)
	quest_tree.objective_erased.connect(_on_objective_erased)
	
	# Movement
	quest_tree.stage_moved.connect(_on_stage_moved)
	quest_tree.objective_moved.connect(_on_objective_moved)
	
	# Duplication
	quest_tree.stage_duplicated.connect(_on_stage_duplicated)
	quest_tree.objective_duplicated.connect(_on_objective_duplicated)
	
	# Specialty
	quest_tree.entry_stage_selected.connect(_on_entry_stage_selected)
	
	# Selection & UI
	quest_tree.quest_selected.connect(_on_quest_root_selected)
	quest_tree.stage_selected.connect(_on_stage_selected)
	quest_tree.objective_selected.connect(_on_objective_selected)
	
	# Events Tree Connections
	events_tree.data_created.connect(_on_event_data_created)
	events_tree.data_moved.connect(_on_event_data_moved)
	events_tree.data_renamed.connect(_on_event_data_renamed)
	events_tree.data_updated.connect(_on_event_data_updated)
	events_tree.data_erased.connect(_on_event_data_erased)

	# Objective Requirements Tree Connections
	obj_req_tree.data_created.connect(_on_objective_data_created)
	obj_req_tree.data_moved.connect(_on_objective_data_moved)
	obj_req_tree.data_renamed.connect(_on_objective_data_renamed)
	obj_req_tree.data_updated.connect(_on_objective_data_updated)
	obj_req_tree.data_erased.connect(_on_objective_data_erased)
	obj_req_tree.data_operator_changed.connect(_on_data_data_operator_changed)


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


func update_stage_target_pointers(reselect: bool = true) -> void:
	var new_pointers: Array[StringName] = []
	new_pointers.assign(quest_resource.stages())
	new_pointers.sort_custom(
			func (a: StringName,b: StringName):
				return a.naturalnocasecmp_to(String(b)) < 0)
	set_stage_target_pointers(new_pointers, reselect)


func set_stage_target_pointers(pointers: Array[StringName], reselect: bool = false) -> void:
	var reselect_success: bool = success_pointer_opt_btn.selected != -1 if reselect else false
	var reselect_failure: bool = failure_pointer_opt_btn.selected != -1 if reselect else false
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
	
	_open_files[quest_resource.get_instance_id()]["structure"] = quest_tree.get_quest_structure()
	
	if quest_mode == QuestModeType.QUEST:
		quest_resource.type = type_opt_btn.get_selected_metadata() if -1 < type_opt_btn.selected else 0
		quest_resource.title = title_ln_edt.text.strip_edges()
		quest_resource.description = description_txt_edt.text.strip_edges()
		quest_resource.custom_data = custom_data_tree.get_data()
		
		quest_resource.events.clear()
		
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
	quest_tree.select_quest(false)


func display_quest(quest_id: int) -> void:
	if not _open_files.has(quest_id) or _open_files[quest_id]["resource"] == quest_resource:
		return
	
	if quest_resource != null:
		save_current_quest()
	
	var quest: Quest = _open_files[quest_id]["resource"]
	quest_resource = quest
	undo = _open_files[quest_id]["quest_undo"]
	custom_data_tree.set_undo(_open_files[quest_id]["data_undo"])
	quest_tree.set_quest(quest, true, false)
	quest_tree.set_quest_structure(_open_files[quest_id]["structure"])
	update_stage_target_pointers(false)
	
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
	
	var success_events: Dictionary[String, Variant] = {}
	var failure_events: Dictionary[String, Variant] = {}
	
	if quest_resource.events.has(&"success"):
		success_events = quest_resource.events[&"success"]
	if quest_resource.events.has(&"failure"):
		failure_events = quest_resource.events[&"failure"]
	
	events_tree.add_data(
			"Success Events",
			success_events)
	events_tree.add_data(
			"Failure Events",
			failure_events)


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
	
	var success_events: Dictionary[String, Variant] = {}
	var failure_events: Dictionary[String, Variant] = {}
	
	if stage.events.has(&"success"):
		success_events = stage.events[&"success"]
	if stage.events.has(&"failure"):
		failure_events = stage.events[&"failure"]
	
	events_tree.add_data(
			"Success Events",
			success_events)
	events_tree.add_data(
			"Failure Events",
			failure_events)
	
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
	
	var success_events: Dictionary[String, Variant] = {}
	var failure_events: Dictionary[String, Variant] = {}
	
	if objective.events.has(&"success"):
		success_events = objective.events[&"success"]
	if objective.events.has(&"failure"):
		failure_events = objective.events[&"failure"]
	
	events_tree.add_data(
			"Success Events",
			success_events)
	events_tree.add_data(
			"Failure Events",
			failure_events)
	
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
	var instance_id: int = quest.get_instance_id()
	var quest_undo: UndoRedo = UndoRedo.new()
	var data_undo: UndoRedo = UndoRedo.new()
	var structure: Array[Dictionary] = get_layout_config_for_file(quest.resource_path)
	
	_open_files[instance_id] = {
		"resource": quest,
		"quest_undo": quest_undo,
		"data_undo": data_undo,
		"structure": structure}
	
	files_tree.add_quest(
			instance_id,
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
			structure.append(item)
	
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


func _on_quest_resource_selected(quest_id: int) -> void:
	display_quest(quest_id)


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
			_open_files[old_id]["quest_undo"].free()
			_open_files[old_id]["data_undo"].free()
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
	
	update_stage_target_pointers(false)
	load_quest_data() # Loads the quest data


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


func _on_add_custom_data_pressed(id: String, data) -> void:
	custom_data_tree.add_data(id, data)
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


# ------ UNDO/REDO ------

func switch_to(stage: StringName = &"", objective: StringName = &"") -> void:
	if selected_stage == stage and selected_objective == objective:
		return
	
	save_current_quest()
	if stage.is_empty() and objective.is_empty():
		load_quest_data()
	elif objective.is_empty():
		load_stage_data(stage)
	else:
		load_objective_data(stage, objective)


func _on_quest_type_selected(type: int) -> void:
	var new_value: int = type_opt_btn.get_item_metadata(type)
	var old_value: int = type_opt_btn.get_meta(&"old_value")
	
	if new_value == old_value:
		return
	
	type_opt_btn.set_meta(&"old_value", new_value)
	
	undo.create_action("Set Quest Type")
	undo.add_do_method(_do_update_quest_type.bind(new_value))
	undo.add_undo_method(_do_update_quest_type.bind(old_value))
	undo.commit_action(false)
	
	_on_something_changed()


func _do_update_quest_type(type: int) -> void:
	switch_to()
	select_type(type)


func _on_title_edit_toggled(is_toggled: bool) -> void:
	if is_toggled:
		return
	
	var new_value: String = title_ln_edt.text
	var old_value: String = title_ln_edt.get_meta(&"old_value")
	
	if new_value == old_value:
		return
	
	title_ln_edt.set_meta(&"old_value", new_value)
	
	var action_title: String = ""
	
	if selected_stage.is_empty() and selected_objective.is_empty():
		action_title = "Set Quest Title"
	elif selected_objective.is_empty():
		action_title = "Set Stage '%s' Objective '%s' Title" % [selected_stage, selected_objective]
	else:
		action_title = "Set Stage '%s' Title" % selected_stage
	
	undo.create_action(action_title)
	undo.add_do_method(_do_set_title_of.bind(
			selected_stage,
			selected_objective,
			new_value))
	undo.add_undo_method(_do_set_title_of.bind(
			selected_stage,
			selected_objective,
			old_value))
	undo.commit_action(false)


func _do_set_title_of(stage: StringName, objective: StringName, title: String) -> void:
	switch_to(stage, objective)
	
	title_ln_edt.text = title
	title_ln_edt.set_meta(&"old_value", title)


func _on_description_focus_lost() -> void:
	var new_value: String = description_txt_edt.text
	var old_value: String = description_txt_edt.get_meta(&"old_value")
	
	if new_value == old_value:
		return
	
	description_txt_edt.set_meta(&"old_value", new_value)
	
	var action_title: String = ""
	
	if selected_stage.is_empty() and selected_objective.is_empty():
		action_title = "Set Quest Description"
	elif selected_objective.is_empty():
		action_title = "Set Stage '%s' Objective '%s' Description" % [selected_stage, selected_objective]
	else:
		action_title = "Set Stage '%s' Description" % selected_stage
	
	undo.create_action(action_title)
	undo.add_do_method(_do_set_description_of.bind(
			selected_stage,
			selected_objective,
			new_value))
	undo.add_undo_method(_do_set_description_of.bind(
			selected_stage,
			selected_objective,
			old_value))
	undo.commit_action(false)


func _do_set_description_of(stage: StringName, objective: StringName, title: String) -> void:
	switch_to(stage, objective)
	
	description_txt_edt.text = title
	description_txt_edt.set_meta(&"old_value", title)


func _on_custom_data_changed() -> void:
	if custom_data_tree.has_undo():
		var action_name: String = ""
		if selected_stage.is_empty() and selected_objective.is_empty():
			action_name = "Set Quest Data"
		elif selected_objective.is_empty():
			action_name = "Set '%s' Stage '%s' Objective Data" % [selected_stage, selected_objective]
		else:
			action_name = "Set '%s' Stage Data" % selected_stage
		
		undo.create_action(action_name)
		undo.add_do_method(_do_custom_data_change.bind(
				selected_stage,
				selected_objective))
		undo.add_undo_method(_undo_custom_data_change.bind(
				selected_stage,
				selected_objective))
	_on_something_changed()


func _do_custom_data_change(stage: StringName, objective: StringName) -> void:
	switch_to(stage, objective)
	custom_data_tree.redo()


func _undo_custom_data_change(stage: StringName, objective: StringName) -> void:
	switch_to(stage, objective)
	custom_data_tree.undo()


func _on_event_data_created(path: String, index: int , data: Variant) -> void:
	var type: int = typeof(data)
	var can_dupe: bool = type == TYPE_DICTIONARY or type == TYPE_ARRAY
	var action_name: String = ""
	
	if selected_stage.is_empty() and selected_objective.is_empty():
		action_name = "Set Quest Event"
	elif selected_objective.is_empty():
		action_name = "Set Stage '%s' Event" % selected_stage
	else:
		action_name = "Set Stage '%s' Objective '%s' Event" % [selected_stage, selected_objective]
	
	undo.create_action(action_name)
	undo.add_do_method(_do_create_event_data.bind(
			selected_stage,
			selected_objective,
			path,
			data.duplicate(true) if can_dupe else data,
			index))
	undo.add_undo_method(_undo_create_event_data.bind(
			selected_stage,
			selected_objective,
			path))
	undo.commit_action(false)
	_on_something_changed()


func _do_create_event_data(stage: StringName, objective: StringName, path: String, data: Variant, index: int) -> void:
	switch_to(stage, objective)
	events_tree._do_add_data(
		path,
		data,
		index)


func _undo_create_event_data(stage: StringName, objective: StringName, path: String) -> void:
	switch_to(stage, objective)
	events_tree._undo_add_data(path)


func _on_event_data_moved(from_path: String, from_index: int, to_path: String, to_index: int) -> void:
	var action_name: String = ""
	
	if selected_stage.is_empty() and selected_objective.is_empty():
		action_name = "Move Quest Event"
	elif selected_objective.is_empty():
		action_name = "Move Stage '%s' Event" % selected_stage
	else:
		action_name = "Move Stage '%s' Objective '%s' Event" % [selected_stage, selected_objective]
	
	undo.create_action(action_name)
	undo.add_do_method(_do_move_event_data.bind(
			selected_stage,
			selected_objective,
			from_path,
			to_path,
			to_index))
	undo.add_undo_method(_do_move_event_data.bind(
			selected_stage,
			selected_objective,
			to_path,
			from_path,
			from_index))
	undo.commit_action(false)
	
	_on_something_changed()


func _do_move_event_data(stage: StringName, objective: StringName, from_path: String, to_path: String, to_index: int) -> void:
	switch_to(stage, objective)
	events_tree._do_move_item(
			from_path,
			to_path,
			to_index)


func _on_event_data_renamed(parent_path: String, old_name: String, new_name: String) -> void:
	var action_name: String = ""
	if selected_stage.is_empty() and selected_objective.is_empty():
		action_name = "Set Quest Event ID"
	elif selected_objective.is_empty():
		action_name = "Set Stage '%s' Event ID" % selected_stage
	else:
		action_name = "Set Stage '%s' Objective '%s' Event ID" % [selected_stage, selected_objective]
	
	undo.create_action(action_name)
	undo.add_do_method(_do_rename_event.bind(
			selected_stage,
			selected_objective,
			parent_path.path_join(old_name),
			new_name))
	undo.add_undo_method(_do_rename_event.bind(
			selected_stage,
			selected_objective,
			parent_path.path_join(new_name),
			old_name))
	undo.commit_action(false)
	
	_on_something_changed()


func _do_rename_event(stage: StringName, objective: StringName, path: String, new_name: String) -> void:
	switch_to(stage, objective)
	events_tree._do_rename_item(path, new_name)


func _on_event_data_updated(path: String, old_value: Variant, new_value: Variant) -> void:
	var action_name: String = ""
	if selected_stage.is_empty() and selected_objective.is_empty():
		action_name = "Set Quest Event Data"
	elif selected_objective.is_empty():
		action_name = "Set Stage '%s' Event Data" % selected_stage
	else:
		action_name = "Set Stage '%s' Objective '%s' Event Data" % [selected_stage, selected_objective]
	
	undo.create_action(action_name)
	undo.add_do_method(_do_update_event_data.bind(
			selected_stage,
			selected_objective,
			path,
			new_value))
	undo.add_undo_method(_do_update_event_data.bind(
			selected_stage,
			selected_objective,
			path,
			old_value))
	undo.commit_action(false)
	
	_on_something_changed()


func _do_update_event_data(stage: StringName, objective: StringName, path: String, data: Variant) -> void:
	switch_to(stage, objective)
	events_tree._do_update_item_data(
			path,
			data)


func _on_event_data_erased(path: String, index: int, data: Variant) -> void:
	var action_name: String = ""
	var type: int = typeof(data)
	var can_dupe: bool = type == TYPE_DICTIONARY or type == TYPE_ARRAY
	
	if selected_stage.is_empty() and selected_objective.is_empty():
		action_name = "Erase Quest Event Data"
	elif selected_objective.is_empty():
		action_name = "Erase Stage '%s' Event Data" % selected_stage
	else:
		action_name = "Erase Stage '%s' Objective '%s' Event Data" % [selected_stage, selected_objective]
	
	undo.create_action(action_name)
	undo.add_do_method(_do_erase_event.bind(
			selected_stage,
			selected_objective,
			path))
	undo.add_undo_method(_undo_erase_event.bind(
			selected_stage,
			selected_objective,
			path,
			data.duplicate(true) if can_dupe else data,
			index))
	undo.commit_action(false)
	
	_on_something_changed()


func _do_erase_event(stage: StringName, objective: StringName, path: String) -> void:
	switch_to(stage, objective)
	events_tree._do_erase_data(path)


func _undo_erase_event(stage: StringName, objective: StringName, path: String, data: Variant, index: int) -> void:
	switch_to(stage, objective)
	events_tree._undo_erase_data(
			path,
			data,
			index)


func _on_objective_data_created(path: String, index: int , data: Variant, operator: int) -> void:
	var type: int = typeof(data)
	var can_dupe: bool = type == TYPE_DICTIONARY or type == TYPE_ARRAY
	undo.create_action("Add Objective '%s' Requirement" % selected_objective)
	undo.add_do_method(_do_create_objective_data.bind(
			selected_stage,
			selected_objective,
			path,
			data.duplicate(true) if can_dupe else data,
			operator,
			index))
	undo.add_undo_method(_undo_create_objective_data.bind(
			selected_stage,
			selected_objective,
			path))
	_on_something_changed()


func _do_create_objective_data(stage: StringName, objective: StringName, path: String, data: Variant, operator: int, index: int) -> void:
	switch_to(stage, objective)
	obj_req_tree._do_add_data(
			path,
			data,
			operator,
			index)


func _undo_create_objective_data(stage: StringName, objective: StringName, path: String) -> void:
	switch_to(stage, objective)
	obj_req_tree._undo_add_data(path)


func _on_objective_data_moved(from_path: String, from_index: int, to_path: String, to_index: int) -> void:
	undo.create_action("Move Objective '%s' Requirement" % selected_objective)
	undo.add_do_method(_do_move_objective_data.bind(
			selected_stage,
			selected_objective,
			from_path,
			to_path,
			to_index))
	undo.add_undo_method(_do_move_objective_data.bind(
			selected_stage,
			selected_objective,
			to_path,
			from_path,
			from_index))
	undo.commit_action(false)
	
	_on_something_changed()


func _do_move_objective_data(stage: StringName, objective: StringName, from_path: String, to_path: String, to_index: int) -> void:
	switch_to(stage, objective)
	obj_req_tree._do_move_item(
			from_path,
			to_path,
			to_index)


func _on_objective_data_renamed(parent_path: String, old_name: String, new_name: String) -> void:
	undo.create_action("Set Objective '%s' Requirement ID" % selected_objective)
	undo.add_do_method(_do_rename_objecive_requirement.bind(
			selected_stage,
			selected_objective,
			parent_path.path_join(old_name),
			new_name))
	undo.add_undo_method(_do_rename_objecive_requirement.bind(
			selected_stage,
			selected_objective,
			parent_path.path_join(new_name),
			old_name))
	undo.commit_action(false)
	
	_on_something_changed()


func _do_rename_objecive_requirement(stage: StringName, objective: StringName, path: String, new_name: String) -> void:
	switch_to(stage, objective)
	obj_req_tree._do_rename_item(path, new_name)


func _on_objective_data_updated(path: String, old_value: Variant, new_value: Variant) -> void:
	undo.create_action("Set Objective '%s' Requirement Data" % selected_objective)
	undo.add_do_method(_do_update_objective_requirement_data.bind(
		selected_stage,
		selected_objective,
		path,
		new_value))
	undo.add_undo_method(_do_update_objective_requirement_data.bind(
		selected_stage,
		selected_objective,
		path,
		old_value))
	undo.commit_action(false)
	_on_something_changed()


func _do_update_objective_requirement_data(stage: StringName, objective: StringName, path: String, data: Variant) -> void:
	switch_to(stage, objective)
	obj_req_tree._do_update_item_data(
			path,
			data)


func _on_objective_data_erased(path: String, index: int, data: Variant, operator: int) -> void:
	var type: int = typeof(data)
	var can_dupe: bool = type == TYPE_DICTIONARY or type == TYPE_ARRAY
	
	undo.create_action("Erase Objective '%s' Requirement Data" % selected_objective)
	undo.add_do_method(_do_erase_objective_requirement.bind(
		selected_stage,
		selected_objective,
		path))
	undo.add_undo_method(_undo_erase_objective_requirement.bind(
			selected_stage,
			selected_objective,
			path,
			data.duplicate(true) if can_dupe else data,
			operator,
			index))
	undo.commit_action(false)
	
	_on_something_changed()


func _do_erase_objective_requirement(stage: StringName, objective: StringName, path: String) -> void:
	switch_to(stage, objective)
	obj_req_tree._do_erase_data(path)


func _undo_erase_objective_requirement(stage: StringName, objective: StringName, path: String, data: Variant, operator: int, index: int) -> void:
	switch_to(stage, objective)
	obj_req_tree._undo_erase_data(
			path,
			data,
			operator,
			index)


func _on_data_data_operator_changed(path: String, old_operator: int, new_operator: int) -> void:
	undo.create_action("Set Objective '%s' Requirement Operator" % selected_objective)
	undo.add_do_method(_do_update_objective_operator.bind(
			selected_stage,
			selected_objective,
			path,
			new_operator))
	undo.add_undo_method(_do_update_objective_operator.bind(
			selected_stage,
			selected_objective,
			path,
			old_operator))
	undo.commit_action(false)
	
	_on_something_changed()


func _do_update_objective_operator(stage: StringName, objective: StringName, path: String, operator: int) -> void:
	switch_to(stage, objective)
	obj_req_tree.set_data_operator(path, operator)


func _on_objective_required_toggled(is_toggled: bool) -> void:
	undo.create_action("Set Stage '%s' Objective '%s' Required" % [selected_stage, selected_objective])
	undo.add_do_method(_do_update_objective_required.bind(
			selected_stage,
			selected_objective,
			is_toggled))
	undo.add_undo_method(_do_update_objective_required.bind(
			selected_stage,
			selected_objective,
			not is_toggled))
	undo.commit_action(false)
	_on_something_changed()


func _do_update_objective_required(stage: StringName, objective: StringName, is_required: bool) -> void:
	switch_to(stage, objective)
	obj_req_chk_bx.set_pressed_no_signal(is_required)


func _on_stage_created(stage_id: StringName) -> void:
	var new_stage: QuestStage = QuestStage.new()
	new_stage.id = stage_id
	quest_resource.add_stage(new_stage)
	
	update_stage_target_pointers()
	
	undo.create_action("Create Stage '%s'" % stage_id)
	undo.add_do_method(_do_create_stage.bind(stage_id))
	undo.add_undo_method(_undo_create_stage.bind(stage_id))
	undo.commit_action(false)
	
	_on_something_changed()


func _do_create_stage(stage_id: StringName) -> void:
	var new_stage: QuestStage = QuestStage.new()
	new_stage.id = stage_id
	quest_resource.add_stage(new_stage)
	quest_tree.add_stage(stage_id)
	
	update_stage_target_pointers()


func _undo_create_stage(stage_id: StringName) -> void:
	quest_resource.remove_stage(stage_id)
	quest_tree.erase_stage(stage_id)
	
	update_stage_target_pointers()
	
	if selected_stage == stage_id:
		quest_tree.select_quest(false)
		load_quest_data()


func _on_objective_created(stage_id: StringName, objective_id: StringName) -> void:
	var new_objective: QuestObjective = QuestObjective.new()
	new_objective.id = objective_id
	quest_resource.get_stage(stage_id).add_objective(new_objective, true)
	
	undo.create_action("Create Stage '%s' Objective '%s'" % [stage_id, objective_id])
	undo.add_do_method(_do_create_objective.bind(stage_id, objective_id))
	undo.add_undo_method(_undo_create_objective.bind(stage_id, objective_id))
	undo.commit_action(false)
	
	_on_something_changed()


func _do_create_objective(on_stage: StringName, objective_id: StringName) -> void:
	var new_objective: QuestObjective = QuestObjective.new()
	new_objective.id = objective_id
	quest_resource.get_stage(on_stage).add_objective(new_objective, true)
	quest_tree.add_objective(on_stage, objective_id)


func _undo_create_objective(on_stage: StringName, objective_id: StringName) -> void:
	var stage: QuestStage = quest_resource.get_stage(on_stage)
	if stage != null:
		stage.remove_objective(objective_id)
	quest_tree.erase_objective(on_stage, objective_id)
	
	if selected_stage == on_stage and selected_objective == objective_id:
		quest_tree.select_stage(on_stage, false)
		load_stage_data(on_stage)


func _on_quest_id_changed(from: StringName, to: StringName) -> void:
	undo.create_action("Set Quest ID")
	undo.add_do_method(_do_update_quest_id.bind(to))
	undo.add_undo_method(_do_update_quest_id.bind(from))
	undo.commit_action()
	_on_something_changed()


func _do_update_quest_id(to: StringName) -> void:
	quest_resource.id = to
	update_crumbs_label()


func _on_stage_id_changed(from: StringName, to: StringName) -> void:
	if quest_resource.has_stage(from):
		quest_resource.get_stage(from).id = to
		quest_resource._stages[to] = quest_resource._stages[from]
		quest_resource._stages.erase(from)
	
	if quest_resource.entry_stage == from:
		quest_resource.entry_stage = to
	
	if selected_stage == from:
		selected_stage = to
		update_crumbs_label()
	
	undo.create_action("Set Stage ID")
	undo.add_do_method(_do_update_stage_id.bind(from, to))
	undo.add_undo_method(_do_update_stage_id.bind(to, from))
	undo.commit_action(false)
	
	_on_something_changed() 


func _do_update_stage_id(from: StringName, to: StringName) -> void:
	if not quest_resource.has_stage(from):
		NFPluginGameHandler._log_msg(
				"odyssey - editor",
				"Couldn't set ID of stage '%s'. Stage not found",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	quest_resource.get_stage(from).id = to
	quest_resource._stages[to] = quest_resource._stages[from]
	quest_resource._stages.erase(from)
	
	quest_tree.set_stage_id(from, to)
	
	if quest_resource.entry_stage == from:
		quest_resource.entry_stage = to
	
	if selected_stage == from:
		selected_stage = to
		update_crumbs_label()


func _on_objective_id_changed(on_stage: StringName, from: StringName, to: StringName) -> void:
	if not quest_resource.has_stage(on_stage):
		NFPluginGameHandler._log_msg(
				"odyssey - editor",
				"Couldn't set objective '%s' ID. Stage '%s' not found",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	elif not quest_resource.get_stage(on_stage).has_objective(from):
		NFPluginGameHandler._log_msg(
				"odyssey - editor",
				"Couldn't set objective '%s' ID. Objective not found",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	var obj_dict: Dictionary = quest_resource.get_stage(on_stage)._objectives
	obj_dict[from]["objective"].id = to
	obj_dict[to] = obj_dict[from]
	obj_dict.erase(from)
	
	if selected_stage == on_stage and selected_objective == from:
		selected_objective = to
		update_crumbs_label()
	
	undo.create_action("Set Objective ID")
	undo.add_do_method(_do_update_objective_id.bind(on_stage, from, to))
	undo.add_undo_method(_do_update_objective_id.bind(on_stage, to, from))
	undo.commit_action(false)
	
	_on_something_changed()


func _do_update_objective_id(on_stage: StringName, from: StringName, to: StringName) -> void:
	if not quest_resource.has_stage(on_stage):
		NFPluginGameHandler._log_msg(
				"odyssey - editor",
				"Couldn't set objective '%s' ID. Stage '%s' not found",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	elif not quest_resource.get_stage(on_stage).has_objective(from):
		NFPluginGameHandler._log_msg(
				"odyssey - editor",
				"Couldn't set objective '%s' ID. Objective not found",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	var obj_dict: Dictionary = quest_resource.get_stage(on_stage)._objectives
	obj_dict[from]["objective"].id = to
	obj_dict[to] = obj_dict[from]
	obj_dict.erase(from)
	
	quest_tree.set_objective_id(on_stage, from, to)
	
	if selected_stage == on_stage and selected_objective == from:
		selected_objective = to
		update_crumbs_label()


func _on_entry_stage_selected(stage_id: StringName) -> void:
	var old_entry: StringName = quest_resource.entry_stage
	quest_resource.entry_stage = stage_id
	undo.create_action("Set Entry Stage")
	undo.add_do_method(_do_update_entry_stage.bind(stage_id))
	undo.add_undo_method(_do_update_entry_stage.bind(old_entry))
	undo.commit_action(false)
	_on_something_changed()


func _do_update_entry_stage(stage_id: StringName) -> void:
	if not stage_id.is_empty() and not quest_resource.has_stage(stage_id):
		NFPluginGameHandler._log_msg(
				"odyssey - editor",
				"Can't set entry stage to '%s'. Stage not found",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	quest_resource.entry_stage = stage_id
	quest_tree.set_entry_stage(stage_id)


func _on_stage_duplicated(from: StringName, duplicate_id: StringName) -> void:
	var stage_obj: QuestStage = quest_resource.get_stage(from)
	var duplicate_obj: QuestStage = stage_obj.duplicate(true)
	duplicate_obj.id = duplicate_id
	# --- Godot 4.4 Compatibility code ---
	# A quest stage saves objectives as subresoruces. To ensure duplication
	# is true we will go and duplicate the resources too. This is solved in
	# Godot 4.5, but NexusForge 1.X will support 4.4. On version 2.0, supported
	# versions will be changed just ahead enough to solve old issues like this.
	for objective_id in duplicate_obj.objectives():
		var original_obj: QuestObjective = stage_obj.get_objective(objective_id)
		duplicate_obj._objectives[objective_id]["objective"] = original_obj.duplicate(true)
	# ------------------------------------
	quest_resource.add_stage(duplicate_obj)
	
	update_stage_target_pointers()
	
	undo.create_action("Duplicate Stage '%s'" % from)
	undo.add_do_method(_do_duplicate_stage.bind(from, duplicate_id))
	undo.add_undo_method(_undo_duplicate_stage.bind(duplicate_id))
	undo.commit_action(false)
	
	_on_something_changed()


func _do_duplicate_stage(target: StringName, new_id: StringName) -> void:
	if not quest_resource.has_stage(target):
		NFPluginGameHandler._log_msg(
				"odyssey - editor",
				"Failed to duplicate stage '%s'. Stage not found" % target,
				NFPluginGameHandler._LogLevel.ERROR)
		return
	elif quest_resource.has_stage(new_id):
		NFPluginGameHandler._log_msg(
				"odyssey - editor",
				"Failed to duplicate stage '%s' with new ID '%s'. ID already assigned" % [target, new_id],
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	var stage_obj: QuestStage = quest_resource.get_stage(target)
	var duplicate_obj: QuestStage = quest_resource.duplicate(true)
	duplicate_obj.id = new_id
	# --- Godot 4.4 Compatibility code ---
	# A quest stage saves objectives as subresoruces. To ensure duplication
	# is true we will go and duplicate the resources too. This is solved in
	# Godot 4.5, but NexusForge 1.X will support 4.4. On version 2.0, supported
	# versions will be changed just ahead enough to solve old issues like this.
	for objective_id in duplicate_obj.objectives():
		var original_obj: QuestObjective = stage_obj.get_objective(objective_id)
		duplicate_obj._objectives[objective_id]["objective"] = original_obj.duplicate(true)
	# ------------------------------------
	
	quest_resource.add_stage(duplicate_obj)
	quest_tree.add_stage(new_id)
	update_stage_target_pointers()


func _undo_duplicate_stage(duplicate_id: StringName) -> void:
	if not quest_resource.has_stage(duplicate_id):
		return
	
	quest_resource.remove_stage(duplicate_id)
	quest_tree.erase_stage(duplicate_id)
	update_stage_target_pointers()
	if selected_stage == duplicate_id:
		load_quest_data()


func _on_objective_duplicated(from_stage: StringName, objective: StringName, duplicate_id: StringName) -> void:
	var stage: QuestStage = quest_resource.get_stage(from_stage)
	var objective_dupe: QuestObjective = stage.get_objective(objective).duplicate(true)
	objective_dupe.id = duplicate_id
	stage.add_objective(objective_dupe, stage.is_objective_required(objective))
	
	undo.create_action("Duplicate Stage '%s' Objective '%s'" % [from_stage, objective])
	undo.add_do_method(_do_duplicate_objective.bind(from_stage, objective, duplicate_id))
	undo.add_undo_method(_undo_duplicate_objective.bind(from_stage, duplicate_id))
	undo.commit_action(false)
	
	_on_something_changed()


func _do_duplicate_objective(from_stage: StringName, objective_id: StringName, duplicate_id: StringName) -> void:
	if not quest_resource.has_stage(from_stage):
		NFPluginGameHandler._log_msg(
				"odyssey - editor",
				"Failed to duplicate objective '%s' from stage '%s'. Stage not found" % [objective_id, from_stage],
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	var stage: QuestStage = quest_resource.get_stage(from_stage)
	
	if not stage.has_objective(objective_id):
		NFPluginGameHandler._log_msg(
			"odyssey - editor",
			"Failed to duplicate objective '%s' from stage '%s'. Objective not found" % [objective_id, from_stage],
			NFPluginGameHandler._LogLevel.ERROR)
		return
	elif stage.has_objective(duplicate_id):
		NFPluginGameHandler._log_msg(
				"odyssey - editor",
				"Failed to duplicate objective '%s' with new ID '%s'. ID already assigned" % [objective_id, duplicate_id],
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	var duplicate_objective: QuestObjective = stage.get_objective(objective_id).duplicate(true)
	duplicate_objective.id = duplicate_id
	stage.add_objective(duplicate_objective, stage.is_objective_required(objective_id))
	
	quest_tree.add_objective(from_stage, duplicate_id)


func _undo_duplicate_objective(on_stage: StringName, objective_id: StringName) -> void:
	if not quest_resource.has_stage(on_stage):
		return
	
	var target: QuestStage = quest_resource.get_stage(on_stage)
	
	if not target.has_objective(objective_id):
		return
	
	target.remove_objective(objective_id)
	quest_tree.erase_objective(on_stage, objective_id)
	if selected_stage == on_stage and selected_objective == objective_id:
		load_stage_data(on_stage)


func _on_stage_moved(stage_id: StringName, from_index: int, to_index: int) -> void:
	undo.create_action("Move Stage '%s'" % stage_id)
	undo.add_do_method(_do_move_stage.bind(stage_id, to_index))
	undo.add_undo_method(_do_move_stage.bind(stage_id, from_index))
	undo.commit_action(false)
	_on_something_changed()


func _do_move_stage(stage_id: StringName, to_index: int) -> void:
	quest_tree.move_stage(stage_id, to_index)


func _on_objective_moved(objective_id: StringName, from_stage: StringName, from_index: int, to_stage: StringName, to_index: int) -> void:
	undo.create_action("Move Stage '%s' Objective '%s'" % [from_stage, objective_id])
	undo.add_do_method(_do_move_objective.bind(
			objective_id,
			from_stage,
			to_stage,
			to_index))
	undo.add_undo_method(_do_move_objective.bind(
			objective_id,
			to_stage,
			from_stage,
			from_index))
	undo.commit_action(false)
	_on_something_changed()


func _do_move_objective(objective_id: StringName, from_stage: StringName, to_stage: StringName, to_index: int) -> void:
	quest_tree.move_objective(
			objective_id,
			from_stage,
			to_stage,
			to_index)


func _on_stage_erased(stage_id: StringName, index: int) -> void:
	var original_stage: QuestStage = quest_resource.get_stage(stage_id)
	var duplicate_stage: QuestStage = original_stage.duplicate(true)
	# --- Godot 4.4 Compatibility code ---
	# A quest stage saves objectives as subresoruces. To ensure duplication
	# is true we will go and duplicate the resources too. This is solved in
	# Godot 4.5, but NexusForge 1.X will support 4.4. On version 2.0, supported
	# versions will be changed just ahead enough to solve old issues like this.
	for objective_id in original_stage.objectives():
		var original_obj: QuestObjective = original_stage.get_objective(objective_id)
		var dupe_objective: QuestObjective = original_obj.duplicate(true)
		duplicate_stage._objectives[objective_id]["objective"] = dupe_objective
	# ------------------------------------
	var targeted_stages: Dictionary[StringName, Dictionary] = {}
	# {"on_success": true, "on_failure": false}
	
	for id in quest_resource.stages():
		if id == stage_id:
			continue
		var stg: QuestStage = quest_resource.get_stage(id)
		var success_match: bool = false
		var failure_match: bool = false
		
		if stg.success_stage_id == stage_id:
			success_match = true
			stg.success_stage_id = &""
		
		if stg.failure_stage_id == stage_id:
			failure_match = true
			stg.failure_stage_id = &""
		
		if success_match or failure_match:
			if not targeted_stages.has(id):
				targeted_stages[id] = DictUtils.create_typed(TYPE_STRING, TYPE_BOOL)
			targeted_stages[id]["on_success"] = success_match
			targeted_stages[id]["on_failure"] = failure_match
	
	quest_resource.remove_stage(stage_id)
	if selected_stage == stage_id:
		quest_tree.select_quest(false)
		load_quest_data()
	
	undo.create_action("Erase Stage '%s'" % stage_id)
	undo.add_do_method(_do_erase_stage.bind(stage_id))
	undo.add_undo_method(_undo_erase_stage.bind(
			duplicate_stage,
			index,
			targeted_stages))
	undo.commit_action(false)
	
	_on_something_changed()


func _undo_erase_stage(stage_res: QuestStage, index: int, pointers_patch: Dictionary[StringName, Dictionary]) -> void:
	if quest_resource.has_stage(stage_res.id):
		NFPluginGameHandler._log_msg(
				"odyssey - editor",
				"Failed to restore stage '%s'. Stage already exists" % stage_res.id,
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	var restored_stage: QuestStage = stage_res.duplicate(true)
	# --- Godot 4.4 Compatibility code ---
	# A quest stage saves objectives as subresoruces. To ensure duplication
	# is true we will go and duplicate the resources too. This is solved in
	# Godot 4.5, but NexusForge 1.X will support 4.4. On version 2.0, supported
	# versions will be changed just ahead enough to solve old issues like this.
	for objective_id in stage_res.objectives():
		var saved_objective: QuestObjective = stage_res.get_objective(objective_id)
		var restored_objective: QuestObjective = saved_objective.duplicate(true)
		restored_stage._objectives[objective_id]["objective"] = restored_objective
	# ------------------------------------
	
	for stage_id in quest_resource.stages():
		if not pointers_patch.has(stage_id):
			continue
		var stage: QuestStage = quest_resource.get_stage(stage_id)
		if pointers_patch[stage_id]["on_success"]:
			stage.success_stage_id = stage_res.id
		if pointers_patch[stage_id]["on_failure"]:
			stage.failure_stage_id = stage_res.id
	
	quest_resource.add_stage(stage_res)
	quest_tree.add_stage(stage_res.id, index)
	
	update_stage_target_pointers()


func _do_erase_stage(stage_id: StringName) -> void:
	if not quest_resource.has_stage(stage_id):
		return
	
	for id in quest_resource.stages():
		if id == stage_id:
			continue
		var stg: QuestStage = quest_resource.get_stage(id)
		if stg.success_stage_id == stage_id:
			stg.success_stage_id = &""
		if stg.failure_stage_id == stage_id:
			stg.failure_stage_id = &""
	
	quest_resource.remove_stage(stage_id)
	quest_tree.erase_stage(stage_id)
	if selected_stage == stage_id:
		quest_tree.select_quest(false)
		load_quest_data()


func _on_objective_erased(from_stage: StringName, objective_id: StringName, index: int) -> void:
	var stage: QuestStage = quest_resource.get_stage(from_stage)
	var objective_backup: QuestObjective = stage.get_objective(objective_id).duplicate(true)
	var is_required: bool = stage.is_objective_required(objective_id)
	
	stage.remove_objective(objective_id)
	
	if selected_stage == from_stage and selected_objective == objective_id:
		quest_tree.select_stage(selected_stage, false)
		load_stage_data(from_stage)
	
	undo.create_action("Erase Stage '%s' Objective '%s'" % [from_stage, objective_id])
	undo.add_do_method(_do_erase_objective.bind(from_stage, objective_id))
	undo.add_undo_method(_undo_erase_objective.bind(
			from_stage,
			objective_backup,
			is_required,
			index))
	undo.commit_action(false)
	
	_on_something_changed()


func _undo_erase_objective(on_stage: StringName, objective_res: QuestObjective, required: bool, index: int) -> void:
	if not quest_resource.has_stage(on_stage):
		NFPluginGameHandler._log_msg(
				"odyssey - editor",
				"Failed to restore objective on stage '%s'. Stage not found" % on_stage,
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	var stage: QuestStage = quest_resource.get_stage(on_stage)
	
	if stage.has_objective(objective_res.id):
		NFPluginGameHandler._log_msg(
				"odyssey - editor",
				"Failed to restore objective '%s' on stage '%s'. Objective already exists" % [objective_res.id, on_stage],
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	var restored_objective: QuestObjective = objective_res.duplicate(true)
	stage.add_objective(restored_objective, required)
	quest_tree.add_objective(on_stage, objective_res.id, index)


func _do_erase_objective(from_stage: StringName, objective_id: StringName) -> void:
	if not quest_resource.has_stage(from_stage):
		return
	
	var stage: QuestStage = quest_resource.get_stage(from_stage)
	
	if not stage.has_objective(objective_id):
		return
	
	stage.remove_objective(objective_id)
	quest_tree.erase_objective(from_stage, objective_id)
	
	if selected_stage == from_stage and selected_objective == objective_id:
		quest_tree.select_stage(selected_stage, false)
		load_stage_data(from_stage)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for open_file in _open_files:
			if is_instance_valid(_open_files[open_file]["quest_undo"]):
				_open_files[open_file]["quest_undo"].free()
			if is_instance_valid(_open_files[open_file]["data_undo"]):
				_open_files[open_file]["data_undo"].free()
