@tool
extends PanelContainer

const LineEditConfirmationDialog = preload("res://addons/nexus_forge/dialogs/lineedit_confirmation_dialog.gd")
var loaded_quest: StringName = &""
var loaded_stage: StringName = &""
var loaded_step: StringName = &""

var listen_quest_selected: bool = true

var _quest_resource: QuestCatalog = null
var _unsaved: bool = false

@onready var new_quest_btn: Button = $MainContainer/TreeContainer/HBoxContainer/NewQuestBtn
@onready var quest_search_ln_edt: LineEdit = $MainContainer/TreeContainer/HBoxContainer/QuestSearchLnEdt
@onready var quest_tree: Tree = $MainContainer/TreeContainer/QuestTree
@onready var quest_title_ln_edt: LineEdit = $MainContainer/BasicContainer/QuestTitleContainer/QuestTitleLnEdt
@onready var quest_type_opt_btn: OptionButton = $MainContainer/BasicContainer/QuestTypeContainer/QuestTypeOptBtn
@onready var quest_desc_txt_edt: TextEdit = $MainContainer/BasicContainer/QuestDescriptionContainer/QuestDescTxtEdt
@onready var add_qst_dict_button: Button = $MainContainer/BasicContainer/CustomDataContainer/QDHeaderContainer/AddButtonsContainer/AddQstDictButton
@onready var add_qst_int_button: Button = $MainContainer/BasicContainer/CustomDataContainer/QDHeaderContainer/AddButtonsContainer/AddQstIntButton
@onready var add_qst_float_button: Button = $MainContainer/BasicContainer/CustomDataContainer/QDHeaderContainer/AddButtonsContainer/AddQstFloatButton
@onready var add_qst_bool_button: Button = $MainContainer/BasicContainer/CustomDataContainer/QDHeaderContainer/AddButtonsContainer/AddQstBoolButton
@onready var add_qst_string_button: Button = $MainContainer/BasicContainer/CustomDataContainer/QDHeaderContainer/AddButtonsContainer/AddQstStringButton
@onready var quest_custom_data_search_line: LineEdit = $MainContainer/BasicContainer/CustomDataContainer/QuestCustomDataSearchLine
@onready var quest_data_tree: Tree = $MainContainer/BasicContainer/CustomDataContainer/QuestDataTree

@onready var search_stg_ln_edt: LineEdit = $MainContainer/StageContainer/MainCotnainer/SearchStageContainer/SearchStgLnEdt
@onready var new_stage_btn: Button = $MainContainer/StageContainer/MainCotnainer/SearchStageContainer/NewStageBtn
@onready var stages_tree: Tree = $MainContainer/StageContainer/MainCotnainer/StagesTree
@onready var stage_title_ln_edt: LineEdit = $MainContainer/StageContainer/TitleContainer/StageTitleLnEdt
@onready var stage_type_opt_btn: OptionButton = $MainContainer/StageContainer/TypeContainer/StageTypeOptBtn
@onready var add_stg_dict_button: Button = $MainContainer/StageContainer/CustomDataContainer/SDHeaderContainer/AddButtonsContainer/AddStgDictButton
@onready var add_stg_int_button: Button = $MainContainer/StageContainer/CustomDataContainer/SDHeaderContainer/AddButtonsContainer/AddStgIntButton
@onready var add_stg_float_button: Button = $MainContainer/StageContainer/CustomDataContainer/SDHeaderContainer/AddButtonsContainer/AddStgFloatButton
@onready var add_stg_bool_button: Button = $MainContainer/StageContainer/CustomDataContainer/SDHeaderContainer/AddButtonsContainer/AddStgBoolButton
@onready var add_stg_string_button: Button = $MainContainer/StageContainer/CustomDataContainer/SDHeaderContainer/AddButtonsContainer/AddStgStringButton
@onready var stage_custom_data_search_ln_edt: LineEdit = $MainContainer/StageContainer/CustomDataContainer/StageCustomDataSearchLnEdt
@onready var stage_data_tree: Tree = $MainContainer/StageContainer/CustomDataContainer/StageDataTree
@onready var stage_flags_container: VBoxContainer = $MainContainer/StageContainer/FlagsContainer/FlagsScroll/StageFlagsContainer

@onready var search_step_ln_edt: LineEdit = $MainContainer/StepContainer/StepsContainer/MainContainer/SearchStepLnEdt
@onready var new_step_btn: Button = $MainContainer/StepContainer/StepsContainer/MainContainer/NewStepBtn
@onready var steps_tree: Tree = $MainContainer/StepContainer/StepsContainer/StepsTree
@onready var step_title_ln_edt: LineEdit = $MainContainer/StepContainer/TitleContainer/StepTitleLnEdt
@onready var step_type_opt_btn: OptionButton = $MainContainer/StepContainer/TypeContainer/StepTypeOptBtn
@onready var add_stp_dict_button: Button = $MainContainer/StepContainer/CustomDataContainer/SDHeaderContainer/AddButtonsContainer/AddStpDictButton
@onready var add_stp_int_button: Button = $MainContainer/StepContainer/CustomDataContainer/SDHeaderContainer/AddButtonsContainer/AddStpIntButton
@onready var add_stp_float_button: Button = $MainContainer/StepContainer/CustomDataContainer/SDHeaderContainer/AddButtonsContainer/AddStpFloatButton
@onready var add_stp_bool_button: Button = $MainContainer/StepContainer/CustomDataContainer/SDHeaderContainer/AddButtonsContainer/AddStpBoolButton
@onready var add_stp_string_button: Button = $MainContainer/StepContainer/CustomDataContainer/SDHeaderContainer/AddButtonsContainer/AddStpStringButton
@onready var step_data_search_ln_edt: LineEdit = $MainContainer/StepContainer/CustomDataContainer/StepDataSearchLnEdt
@onready var step_data_tree: Tree = $MainContainer/StepContainer/CustomDataContainer/StepDataTree
@onready var step_flags_container: VBoxContainer = $MainContainer/StepContainer/FlagsContainer/FlagsScroll/StepFlagsContainer


func _ready() -> void:
	if Engine.is_editor_hint() and get_tree().edited_scene_root == self:
		return
	
	add_stg_dict_button.icon = get_theme_icon("FolderCreate", "EditorIcons")
	add_stp_dict_button.icon = get_theme_icon("FolderCreate", "EditorIcons")
	add_qst_dict_button.icon = get_theme_icon("FolderCreate", "EditorIcons")
	
	new_stage_btn.icon = get_theme_icon("Add", "EditorIcons")
	new_step_btn.icon = get_theme_icon("Add", "EditorIcons")
	
	search_step_ln_edt.right_icon = get_theme_icon("Search", "EditorIcons")
	search_stg_ln_edt.right_icon = get_theme_icon("Search", "EditorIcons")
	quest_search_ln_edt.right_icon = get_theme_icon("Search", "EditorIcons")
	quest_custom_data_search_line.right_icon = get_theme_icon("Search", "EditorIcons")
	
	stage_custom_data_search_ln_edt.right_icon = get_theme_icon("Search", "EditorIcons")
	step_data_search_ln_edt.right_icon = get_theme_icon("Search", "EditorIcons")
	
	#_quest_resource = QuestCatalog.new()
	
	var res_path: String = ProjectSettings.get_setting(
			EditorNFPlugin.get_project_settings_path("quests"),
			"")
	
	if res_path != "" and FileAccess.file_exists(res_path):
		var preload_res: Resource = load(res_path)
		if preload_res is QuestCatalog:
			_quest_resource = preload_res
	
	if _quest_resource == null:
		$MainContainer.visible = false
		new_quest_btn.disabled = true
		var no_db = preload("res://addons/nexus_forge/no_db_container.tscn").instantiate()
		add_child(no_db)
		no_db.message_minimum_size.x = 450
		no_db.set_resource_type("QuestCatalog", "Odyssey", "Quests")
		no_db.create_resource_pressed.connect(_on_create_database_pressed.bind(no_db))
		no_db.load_resource_pressed.connect(_on_load_database_pressed.bind(no_db))
		no_db.resource_dropped.connect(_on_resource_dropped.bind(no_db))
	else:
		$MainContainer.visible = true
		load_quest_resource()
	
	reload_quest_types()
	reload_quest_stage()
	reload_quest_steps()
	
	set_quest_ui_enabled(false)
	set_stage_ui_enabled(false)
	set_step_ui_enabled(false)
	
	new_quest_btn.pressed.connect(_on_new_quest_pressed)
	quest_search_ln_edt.text_changed.connect(_on_quest_search_text_changed)
	quest_tree.quest_erased.connect(_on_quest_erased)
	quest_tree.quest_id_changed.connect(_on_quest_id_changed)
	quest_tree.item_selected.connect(_on_quest_selected)
	quest_title_ln_edt.text_changed.connect(something_changed)
	quest_type_opt_btn.item_selected.connect(something_changed)
	quest_desc_txt_edt.text_changed.connect(something_changed)
	add_qst_int_button.pressed.connect(_on_add_quest_data_pressed.bind("new_integer", 0))
	add_qst_float_button.pressed.connect(_on_add_quest_data_pressed.bind("new_float", 0.0))
	add_qst_bool_button.pressed.connect(_on_add_quest_data_pressed.bind("new_bool", false))
	add_qst_string_button.pressed.connect(_on_add_quest_data_pressed.bind("new_string", ""))
	add_qst_dict_button.pressed.connect(_on_add_quest_data_pressed.bind("new_level", {}))
	quest_custom_data_search_line.text_changed.connect(_on_search_quest_data_text_changed)
	quest_data_tree.data_changed.connect(something_changed)
	
	new_stage_btn.pressed.connect(_on_new_stage_pressed)
	search_stg_ln_edt.text_changed.connect(_on_stage_search_text_changed)
	stages_tree.quest_id_changed.connect(_on_stage_id_changed)
	stages_tree.quest_erased.connect(_on_stage_erased)
	stages_tree.quest_selected.connect(_on_stage_selected)
	stage_title_ln_edt.text_changed.connect(something_changed)
	stage_type_opt_btn.item_selected.connect(something_changed)
	add_stg_int_button.pressed.connect(_on_add_stage_data_pressed.bind("new_integer", 0))
	add_stg_float_button.pressed.connect(_on_add_stage_data_pressed.bind("new_float", 0.0))
	add_stg_bool_button.pressed.connect(_on_add_stage_data_pressed.bind("new_bool", false))
	add_stg_string_button.pressed.connect(_on_add_stage_data_pressed.bind("new_string", ""))
	add_stg_dict_button.pressed.connect(_on_add_stage_data_pressed.bind("new_level", {}))
	stage_custom_data_search_ln_edt.text_changed.connect(_on_search_stage_data_text_changed)
	stage_data_tree.data_changed.connect(something_changed)
	
	new_step_btn.pressed.connect(_on_new_step_pressed)
	search_step_ln_edt.text_changed.connect(_on_step_search_text_changed)
	steps_tree.quest_id_changed.connect(_on_step_id_changed)
	steps_tree.quest_erased.connect(_on_step_erased)
	steps_tree.quest_selected.connect(_on_step_selected)
	step_title_ln_edt.text_changed.connect(something_changed)
	step_type_opt_btn.item_selected.connect(something_changed)
	add_stp_int_button.pressed.connect(_on_add_step_data_pressed.bind("new_integer", 0))
	add_stp_float_button.pressed.connect(_on_add_step_data_pressed.bind("new_float", 0.0))
	add_stp_bool_button.pressed.connect(_on_add_step_data_pressed.bind("new_bool", false))
	add_stp_string_button.pressed.connect(_on_add_step_data_pressed.bind("new_string", ""))
	add_stp_dict_button.pressed.connect(_on_add_step_data_pressed.bind("new_level", {}))
	step_data_search_ln_edt.text_changed.connect(_on_search_step_data_text_changed)
	step_data_tree.data_changed.connect(something_changed)


func _on_quest_search_text_changed(text: String) -> void:
	quest_tree.search_item(text.strip_edges())


func _on_stage_search_text_changed(text: String) -> void:
	stages_tree.search_quest(text.strip_edges())


func _on_step_search_text_changed(text: String) -> void:
	steps_tree.search_quest(text.strip_edges())


func _on_create_database_pressed(node: Control) -> void:
	var database_creator := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	database_creator.file_mode = database_creator.FILE_MODE_SAVE_FILE
	add_child(database_creator)
	database_creator.show()
	
	var result = await database_creator.dialog_finished
	
	if result[0]:
		_quest_resource = QuestCatalog.new()
		ResourceSaver.save(_quest_resource, result[1])
		_quest_resource.resource_path = result[1]
		ProjectSettings.set_setting(
				EditorNFPlugin.get_project_settings_path("quests"),
				result[1])
		if Engine.is_editor_hint():
			ProjectSettings.save()
		load_quest_resource()
		$MainContainer.visible = true
		node.visible = false
		node.queue_free()
	
	database_creator.queue_free()


func _on_load_database_pressed(node: Control) -> void:
	var database_creator := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	database_creator.file_mode = database_creator.FILE_MODE_OPEN_FILE
	add_child(database_creator)
	database_creator.show()
	
	var result = await database_creator.dialog_finished
	
	if result[0]:
		var res_pre: Resource = load(result[1])
		if res_pre != null and res_pre is QuestCatalog:
			_quest_resource = res_pre
			ProjectSettings.set_setting(
					EditorNFPlugin.get_project_settings_path("quests"),
					result[1])
			if Engine.is_editor_hint():
				ProjectSettings.save()
			load_quest_resource()
			$MainContainer.visible = true
			node.visible = false
			node.queue_free()
	
	database_creator.queue_free()


func _on_resource_dropped(resource: Resource, panel: Control) -> void:
	_quest_resource = resource
	ProjectSettings.set_setting(
			EditorNFPlugin.get_project_settings_path("quests"),
			resource.resource_path)
	if Engine.is_editor_hint():
		ProjectSettings.save()
	panel.visible = false
	panel.queue_free()
	$MainContainer.visible = true
	load_quest_resource()


func _on_stage_flag_changed(is_checked: bool, flag: QuestStage.StageFlag) -> void:
	_quest_resource.set_stage_flag(loaded_quest, loaded_stage, flag, is_checked)
	something_changed()


func _on_step_flag_changed(is_checked: bool, flag: QuestStep.StepFlag) -> void:
	_quest_resource.set_step_flag(loaded_quest, loaded_stage, loaded_step, flag, is_checked)
	something_changed()


func _on_quest_selected() -> void:
	if not listen_quest_selected:
		return
	if not loaded_quest.is_empty():
		save_current_quest()
	var selected: TreeItem = quest_tree.get_selected()
	loaded_quest = selected.get_metadata(0)
	load_quest(loaded_quest)
	set_quest_ui_enabled(true)
	set_stage_ui_enabled(true)
	set_stage_data_ui_enabled(false)
	set_step_ui_enabled(false)


func _on_stage_selected(stage_id: String) -> void:
	if not listen_quest_selected:
		return
	var stage_key: StringName = StringName(stage_id)
	if not loaded_stage.is_empty():
		save_current_stage()
	loaded_stage = stage_key
	load_stage(loaded_quest, stage_key)
	set_step_ui_enabled(true)
	set_step_data_ui_enabled(false)
	set_stage_data_ui_enabled(true)


func _on_step_selected(step_name: String) -> void:
	if not listen_quest_selected:
		return
	var step_id: StringName = StringName(step_name)
	if not loaded_step.is_empty():
		save_current_step()
	loaded_step = step_id
	load_step(loaded_quest, loaded_stage, step_id)
	set_step_data_ui_enabled(true)


func _on_new_quest_pressed() -> void:
	var id_creator := LineEditConfirmationDialog.new()
	id_creator.line_placeholder_text = "Quest ID"
	id_creator.allow_empty = false
	id_creator.use_blacklist = true
	id_creator.character_blacklist.append(" ")
	id_creator.text_blacklist.assign(_quest_resource.quests())
	id_creator.title = "Create Quest"
	id_creator.ok_button_text = "Create"
	add_child(id_creator)
	id_creator.show()
	id_creator.grab_text_focus()
	
	var result = await id_creator.dialog_finished
	
	if result[0]:
		listen_quest_selected = false
		if not loaded_quest.is_empty():
			save_current_quest() # This saves the whole thing
		
		set_quest_ui_enabled(true)
		set_step_ui_enabled(false)
		set_stage_ui_enabled(true)
		set_stage_data_ui_enabled(false)
		
		var quest_id: StringName = StringName(result[1])
		_quest_resource.create_quest(quest_id)
		quest_tree.add_quest(quest_id, true)
		load_quest(quest_id)
		loaded_quest = quest_id
		loaded_stage = &""
		loaded_step = &""
		listen_quest_selected = true
		something_changed()
	id_creator.queue_free()


func _on_new_stage_pressed() -> void:
	var id_creator := LineEditConfirmationDialog.new()
	id_creator.line_placeholder_text = "Stage ID"
	id_creator.allow_empty = false
	id_creator.use_blacklist = true
	id_creator.character_blacklist.append(" ")
	id_creator.text_blacklist.assign(_quest_resource.stages(loaded_quest))
	id_creator.title = "Create Stage"
	id_creator.ok_button_text = "Create"
	add_child(id_creator)
	id_creator.show()
	id_creator.grab_text_focus()
	
	var result = await id_creator.dialog_finished
	
	if result[0]:
		listen_quest_selected = false
		if not loaded_stage.is_empty():
			save_current_stage()
		
		set_step_ui_enabled(true)
		set_step_data_ui_enabled(false)
		set_stage_data_ui_enabled(true)
		
		var stage_id: StringName = StringName(result[1])
		_quest_resource.create_stage(loaded_quest, stage_id)
		stages_tree.create_quest(result[1], true)
		loaded_stage = stage_id
		loaded_step = &""
		load_stage(loaded_quest, stage_id)
		clear_steps()
		
		listen_quest_selected = true
		something_changed()
	id_creator.queue_free()


func _on_new_step_pressed() -> void:
	var id_creator := LineEditConfirmationDialog.new()
	id_creator.line_placeholder_text = "Step ID"
	id_creator.allow_empty = false
	id_creator.use_blacklist = true
	id_creator.character_blacklist.append(" ")
	id_creator.text_blacklist.assign(_quest_resource.steps(loaded_quest, loaded_stage))
	id_creator.title = "Create Step"
	id_creator.ok_button_text = "Create"
	add_child(id_creator)
	id_creator.show()
	id_creator.grab_text_focus()
	
	var result = await id_creator.dialog_finished
	
	if result[0]:
		listen_quest_selected = false
		if not loaded_step.is_empty():
			save_current_step()
		
		set_step_ui_enabled(true)
		
		var step_id: StringName = StringName(result[1])
		_quest_resource.create_step(loaded_quest, loaded_stage, step_id)
		steps_tree.create_quest(result[1], true)
		loaded_step = step_id
		load_step(loaded_quest, loaded_stage, step_id)
		
		listen_quest_selected = true
		something_changed()
	id_creator.queue_free()


func _on_quest_erased(quest_id: StringName) -> void:
	_quest_resource.erase_quest(quest_id)
	if loaded_quest == quest_id:
		loaded_quest = &""
		loaded_stage = &""
		loaded_step = &""
		clear_quests()
		clear_stages()
		clear_steps()
		set_quest_ui_enabled(false)
		set_stage_ui_enabled(false)
		set_step_ui_enabled(false)


func _on_quest_id_changed(from: StringName, to: StringName) -> void:
	_quest_resource._quests[to] = _quest_resource._quest_resource[from]
	_quest_resource._quests.erase(from)
	if loaded_quest == from:
		loaded_quest = to
	something_changed()


func _on_add_quest_data_pressed(title: String, data: Variant) -> void:
	quest_data_tree.add_data(title, data)
	something_changed()


func _on_add_stage_data_pressed(title: String, data: Variant) -> void:
	stage_data_tree.add_data(title, data)
	something_changed()


func _on_add_step_data_pressed(title: String, data: Variant) -> void:
	step_data_tree.add_data(title, data)
	something_changed()


func _on_search_quest_data_text_changed(text: String) -> void:
	var clean_text: String = text.strip_edges()
	quest_data_tree.search_data(clean_text)


func _on_search_stage_data_text_changed(text: String) -> void:
	var clean_text: String = text.strip_edges()
	stage_data_tree.search_data(clean_text)


func _on_search_step_data_text_changed(text: String) -> void:
	var clean_text: String = text.strip_edges()
	step_data_tree.search_data(clean_text)


func _on_stage_id_changed(from: String, to: String) -> void:
	var to_id: StringName = StringName(to)
	var from_id: StringName = StringName(from)
	_quest_resource._quests[loaded_quest]["stages"][to_id] = _quest_resource._quests[loaded_quest]["stages"][from_id]
	_quest_resource._quests[loaded_quest]["stages"].erase(from_id)
	if loaded_stage == from_id:
		loaded_stage = to_id
	something_changed()


func _on_stage_erased(id: String) -> void:
	var stage_id: StringName = StringName(id)
	_quest_resource.erase_stage(loaded_quest, stage_id)
	
	if loaded_stage == stage_id:
		loaded_stage = &""
		loaded_step = &""
		search_stg_ln_edt.text = ""
		stage_title_ln_edt.text = ""
		stage_type_opt_btn.select(0)
		set_stage_flags_checked(false)
		stage_data_tree.clear_data()
		clear_steps()
		set_step_ui_enabled(false)
		set_stage_data_ui_enabled(false)
	
	something_changed()


func _on_step_id_changed(from: String, to: String) -> void:
	var to_id: StringName = StringName(to)
	var from_id: StringName = StringName(from)
	_quest_resource._quests[loaded_quest]["stages"][loaded_stage]["steps"][to_id] = _quest_resource._quests[loaded_quest]["stages"][loaded_stage]["steps"][from_id]
	_quest_resource._quests[loaded_quest]["stages"][loaded_stage]["steps"].erase(from_id)
	if loaded_step == from_id:
		loaded_step = to_id
	something_changed()


func _on_step_erased(id: String) -> void:
	var step_id: StringName = StringName(id)
	_quest_resource.erase_step(loaded_quest, loaded_stage, step_id)
	if loaded_step == step_id:
		loaded_step = &""
		search_step_ln_edt.text = ""
		step_title_ln_edt.text = ""
		step_type_opt_btn.select(0)
		set_step_flags_checked(false)
		step_data_tree.clear_data()
		set_step_data_ui_enabled(false)
		


func something_changed(_arg: Variant = null) -> void:
	if not _unsaved:
		_unsaved = true


func reload_quest_types() -> void:
	var quest: QuestData = QuestData.new()
	var constants: Dictionary = quest.get_script().get_script_constant_map()
	var quest_types: Dictionary = constants[&"QuestType"]
	var quest_type_keys: Array = quest_types.keys()
	var selected: String = quest_type_opt_btn.get_selected_metadata() if loaded_quest != &"" else &""
	var new_idx: int = -1
	
	quest_type_keys.sort_custom(func(a,b): return a.naturalnocasecmp_to(b) < 0)
	
	quest_type_opt_btn.clear()
	
	if selected != "":
		new_idx = quest_type_keys.find(selected)
	
	for type_key:String in quest_type_keys:
		quest_type_opt_btn.add_item(
				type_key.capitalize())
		quest_type_opt_btn.set_item_metadata(
				-1,
				quest_types[type_key])
	
	if new_idx != -1:
		quest_type_opt_btn.select(new_idx)


func reload_quest_stage() -> void:
	var stage: QuestStage = QuestStage.new()
	var constants: Dictionary = stage.get_script().get_script_constant_map()
	var stage_types: Dictionary = constants[&"StageType"]
	var stage_type_keys: Array = stage_types.keys()
	var selected_stage: String = stage_type_opt_btn.get_selected_metadata() if loaded_stage != &"" else &""
	var stage_idx: int = -1
	var stage_flags: Dictionary = constants[&"StageFlag"]
	var stage_flag_keys: Array = stage_flags.keys()
	
	stage_type_keys.sort_custom(func(a,b): return a.naturalnocasecmp_to(b) < 0)
	stage_flag_keys.sort_custom(func(a,b): return a.naturalnocasecmp_to(b) < 0)
	
	if selected_stage != "":
		stage_idx = stage_type_keys.find(selected_stage)
	
	stage_type_opt_btn.clear()
	
	for stage_type in stage_type_keys:
		stage_type_opt_btn.add_item(stage_type.capitalize())
		stage_type_opt_btn.set_item_metadata(
				-1,
				stage_types[stage_type])
	
	if stage_idx != -1:
		stage_type_opt_btn.select(stage_idx)
	
	var flag_map: Dictionary[String, Control] = {}
	for existing_flag: CheckBox in stage_flags_container.get_children():
		stage_flags_container.remove_child(existing_flag)
		var flag_id: String = existing_flag.get_meta(&"stage_id")
		if stage_flag_keys.has(flag_id):
			flag_map[flag_id] = existing_flag
		else:
			existing_flag.queue_free()
	
	for stage_flag in stage_flag_keys:
		if flag_map.has(stage_flag):
			stage_flags_container.add_child(flag_map[stage_flag])
			flag_map.erase(stage_flag)
		else:
			var flag: CheckBox = new_stage_flag_checkbox(stage_flag, stage_flags[stage_flag])
			flag.text = stage_flag.capitalize()
			stage_flags_container.add_child(flag)
	
	for remaining_flag in flag_map.keys():
		flag_map[remaining_flag].queue_free()


func reload_quest_steps() -> void:
	var types: QuestStep = QuestStep.new()
	var constants: Dictionary = types.get_script().get_script_constant_map()
	var step_types: Dictionary = constants[&"StepType"]
	var step_type_keys: Array = step_types.keys()
	var selected_type: String = step_type_opt_btn.get_selected_metadata() if loaded_step != &"" else ""
	var new_index: int = -1
	
	var step_flags: Dictionary = constants[&"StepFlag"]
	var step_flag_keys: Array = step_flags.keys()
	
	step_type_keys.sort_custom(func(a,b): return a.naturalnocasecmp_to(b) < 0)
	step_flag_keys.sort_custom(func(a,b): return a.naturalnocasecmp_to(b) < 0)
	
	if selected_type != "":
		new_index = step_type_keys.find(selected_type)
	
	step_type_opt_btn.clear()
	
	for step_type in step_type_keys:
		step_type_opt_btn.add_item(step_type.capitalize())
		step_type_opt_btn.set_item_metadata(
			-1,
			step_types[step_type])
	
	if new_index != -1:
		step_type_opt_btn.select(new_index)
	
	var flag_map: Dictionary[String, Control] = {}
	for existing_flag in step_flags_container.get_children():
		step_flags_container.remove_child(existing_flag)
		var step_id: String = existing_flag.get_meta(&"step_id")
		if step_flag_keys.has(step_id):
			flag_map[step_id] = existing_flag
		else:
			existing_flag.queue_free()
	
	for step_flag in step_flag_keys:
		if flag_map.has(step_flag):
			step_flags_container.add_child(flag_map[step_flag])
			flag_map.erase(step_flag)
		else:
			var flag: CheckBox = new_step_flag_checkbox(step_flag, step_flags[step_flag])
			flag.text = step_flag.capitalize()
			step_flags_container.add_child(flag)
	for remaining_flag in flag_map.keys():
		flag_map[remaining_flag].queue_free()


func load_quest_resource() -> void:
	new_quest_btn.disabled = false
	for existing_quest: StringName in _quest_resource.quests():
		quest_tree.add_quest(existing_quest)



func load_quest(quest_id: StringName) -> void:
	quest_title_ln_edt.text = _quest_resource.get_quest_title(quest_id)
	quest_desc_txt_edt.text = _quest_resource.get_quest_description(quest_id)
	var type: QuestData.QuestType = _quest_resource.get_quest_type(quest_id)
	
	for type_idx in range(quest_type_opt_btn.item_count):
		if quest_type_opt_btn.get_item_metadata(type_idx) == type:
			quest_type_opt_btn.select(type_idx)
			break
	
	quest_data_tree.clear_data()
	
	for data_key in _quest_resource.quest_data_keys(quest_id):
		quest_data_tree.add_data(
				data_key,
				_quest_resource.get_quest_data(quest_id, data_key))
	
	clear_stages()
	clear_steps()
	
	for stage in _quest_resource.stages(quest_id):
		stages_tree.create_quest(stage)


func load_stage(of_quest: StringName, stage_id: StringName) -> void:
	search_stg_ln_edt.text = ""
	stage_title_ln_edt.text = _quest_resource.get_stage_title(of_quest, stage_id)
	select_stage_type(_quest_resource.get_stage_type(of_quest, stage_id))
	
	for flag_item in stage_flags_container.get_children():
		if flag_item is CheckBox:
			flag_item.set_pressed_no_signal(
					_quest_resource.has_stage_flag(
							of_quest,
							stage_id,
							flag_item.get_meta(&"stage_flag")))
	
	stage_data_tree.clear_data()
	
	for data_key in _quest_resource.stage_data_keys(of_quest, stage_id):
		stage_data_tree.add_data(
				data_key,
				_quest_resource.get_stage_data(
						of_quest,
						stage_id,
						data_key))
	
	clear_steps()
	
	for step in _quest_resource.steps(of_quest, stage_id):
		steps_tree.create_quest(step)


func load_step(of_quest: StringName, stage_id: StringName, step_id: StringName) -> void:
	search_step_ln_edt.text = ""
	step_title_ln_edt.text = _quest_resource.get_step_title(of_quest, stage_id, step_id)
	select_step_type(_quest_resource.get_step_type(of_quest, stage_id, step_id))
	
	for flag_item in step_flags_container.get_children():
		if flag_item is CheckBox:
			flag_item.set_pressed_no_signal(
					_quest_resource.has_step_flag(
							of_quest,
							stage_id,
							step_id,
							flag_item.get_meta(&"step_flag")))
	
	step_data_tree.clear_data()
	
	for data_key in _quest_resource.step_data_keys(of_quest, stage_id, step_id):
		step_data_tree.add_data(
				data_key,
				_quest_resource.get_step_data(
						of_quest,
						stage_id,
						step_id,
						data_key))


func select_stage_type(type: QuestStage.StageType) -> void:
	for item_idx in range(stage_type_opt_btn.item_count):
		if stage_type_opt_btn.get_item_metadata(item_idx) == type:
			stage_type_opt_btn.select(item_idx)
			return
	stage_type_opt_btn.select(0)


func select_step_type(type: QuestStep.StepType) -> void:
	for item_idx in range(step_type_opt_btn.item_count):
		if step_type_opt_btn.get_item_metadata(item_idx) == type:
			step_type_opt_btn.select(item_idx)
			return
	step_type_opt_btn.select(0)


func set_quest_ui_enabled(enabled: bool) -> void:
	var disabled: bool = not enabled
	
	quest_title_ln_edt.editable = enabled
	quest_type_opt_btn.disabled = disabled
	quest_desc_txt_edt.editable = enabled
	
	add_qst_int_button.disabled = disabled
	add_qst_float_button.disabled = disabled
	add_qst_bool_button.disabled = disabled
	add_qst_string_button.disabled = disabled
	add_qst_dict_button.disabled = disabled
	quest_custom_data_search_line.editable = enabled


func set_stage_ui_enabled(enabled: bool) -> void:
	var disabled: bool = not enabled
	search_stg_ln_edt.editable = enabled
	new_stage_btn.disabled = disabled
	stage_title_ln_edt.editable = enabled
	stage_type_opt_btn.disabled = disabled
	
	add_stg_int_button.disabled = disabled
	add_stg_float_button.disabled = disabled
	add_stg_bool_button.disabled = disabled
	add_stg_string_button.disabled = disabled
	add_stg_dict_button.disabled = disabled
	stage_custom_data_search_ln_edt.editable = enabled
	
	for existing_flag in stage_flags_container.get_children():
		if existing_flag is CheckBox:
			existing_flag.disabled = disabled


func set_stage_data_ui_enabled(enabled: bool) -> void:
	var disabled: bool = not enabled
	stage_title_ln_edt.editable = enabled
	stage_type_opt_btn.disabled = disabled
	
	add_stg_int_button.disabled = disabled
	add_stg_float_button.disabled = disabled
	add_stg_bool_button.disabled = disabled
	add_stg_string_button.disabled = disabled
	add_stg_dict_button.disabled = disabled
	stage_custom_data_search_ln_edt.editable = enabled
	
	for existing_flag in stage_flags_container.get_children():
		if existing_flag is CheckBox:
			existing_flag.disabled = disabled


func set_step_ui_enabled(enabled: bool) -> void:
	var disabled: bool = not enabled
	search_step_ln_edt.editable = enabled
	new_step_btn.disabled = disabled
	step_title_ln_edt.editable = enabled
	step_type_opt_btn.disabled = disabled
	
	add_stp_int_button.disabled = disabled
	add_stp_float_button.disabled = disabled
	add_stp_bool_button.disabled = disabled
	add_stp_string_button.disabled = disabled
	add_stp_dict_button.disabled = disabled
	step_data_search_ln_edt.editable = enabled
	
	for existing_flag in step_flags_container.get_children():
		if existing_flag is CheckBox:
			existing_flag.disabled = disabled


func set_step_data_ui_enabled(enabled: bool) -> void:
	var disabled: bool = not enabled
	step_title_ln_edt.editable = enabled
	step_type_opt_btn.disabled = disabled
	
	add_stp_int_button.disabled = disabled
	add_stp_float_button.disabled = disabled
	add_stp_bool_button.disabled = disabled
	add_stp_string_button.disabled = disabled
	add_stp_dict_button.disabled = disabled
	step_data_search_ln_edt.editable = enabled
	
	for existing_flag in step_flags_container.get_children():
		if existing_flag is CheckBox:
			existing_flag.disabled = disabled


func clear_stage_flags() -> void:
	for flag in stage_flags_container.get_children():
		if flag is CheckBox:
			flag.toggled.disconnect(_on_stage_flag_changed)
			stage_flags_container.remove_child(flag)
			flag.queue_free()


func set_stage_flags_checked(checked: bool = false) -> void:
	for flag in stage_flags_container.get_children():
		if flag is CheckBox:
			flag.set_pressed_no_signal(checked)


func clear_step_flags() -> void:
	for flag in step_flags_container.get_children():
		if flag is CheckBox:
			flag.toggled.disconnect(_on_step_flag_changed)
			stage_flags_container.remove_child(flag)
			flag.queue_free()


func set_step_flags_checked(checked: bool) -> void:
	for flag in step_flags_container.get_children():
		if flag is CheckBox:
			flag.set_pressed_no_signal(checked)


func new_stage_flag_checkbox(id: String, flag: QuestStage.StageFlag) -> CheckBox:
	var new_flag: CheckBox = CheckBox.new()
	new_flag.toggled.connect(_on_stage_flag_changed.bind(flag))
	new_flag.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	new_flag.set_meta(&"stage_flag", flag)
	new_flag.set_meta(&"stage_id", id)
	return new_flag


func new_step_flag_checkbox(id: String, flag: QuestStep.StepFlag) -> CheckBox:
	var new_flag: CheckBox = CheckBox.new()
	new_flag.toggled.connect(_on_step_flag_changed.bind(flag))
	new_flag.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	new_flag.set_meta(&"step_flag", flag)
	new_flag.set_meta(&"step_id", id)
	return new_flag


func clear_quests() -> void:
	quest_title_ln_edt.text = ""
	quest_type_opt_btn.select(0)
	quest_desc_txt_edt.text = ""
	quest_data_tree.clear_data()


func clear_stages() -> void:
	search_stg_ln_edt.text = ""
	stages_tree.clear_quests()
	stage_title_ln_edt.text = ""
	stage_type_opt_btn.select(0)
	set_stage_flags_checked(false)
	stage_data_tree.clear_data()


func clear_steps() -> void:
	search_step_ln_edt.text = ""
	steps_tree.clear_quests()
	step_title_ln_edt.text = ""
	step_type_opt_btn.select(0)
	set_step_flags_checked(false)
	step_data_tree.clear_data()


func save_current_quest() -> void:
	var stages_array: Array[StringName] = stages_tree.get_quests()
	var array_size: int = stages_array.size()
	var entry_step: StringName = &"" if 0 == array_size else stages_array[0]
	
	_quest_resource.set_quest_first_stage(
			loaded_quest,
			entry_step)
	
	if 1 < array_size:
		for step_idx in range(1, array_size):
			_quest_resource.set_stage_link(
					loaded_quest,
					stages_array[step_idx - 1],
					stages_array[step_idx])
	
	_quest_resource.set_quest_title(
			loaded_quest,
			quest_title_ln_edt.text.strip_edges())
	_quest_resource.set_quest_type(
			loaded_quest,
			quest_type_opt_btn.get_item_metadata(quest_type_opt_btn.selected))
	_quest_resource.set_quest_description(
			loaded_quest,
			quest_desc_txt_edt.text.strip_edges())
	_quest_resource.clear_quest_data(loaded_quest)
	
	var data: Dictionary[String, Variant] = quest_data_tree.get_data()
	for data_key in data.keys():
		_quest_resource.set_quest_data(
				loaded_quest,
				data_key,
				data[data_key])
	
	if not loaded_stage.is_empty():
		save_current_stage()


func save_current_stage() -> void:
	var steps_array: Array[StringName] = steps_tree.get_quests()
	var array_size: int = steps_array.size()
	var entry_step: StringName = &"" if 0 == array_size else steps_array[0]
	
	_quest_resource.set_stage_first_step(
			loaded_quest,
			loaded_stage,
			entry_step)
	
	if 1 < array_size:
		for step_idx in range(1, array_size):
			_quest_resource.set_step_link(
					loaded_quest,
					loaded_stage,
					steps_array[step_idx - 1],
					steps_array[step_idx])
	
	_quest_resource.set_stage_title(
			loaded_quest,
			loaded_stage,
			stage_title_ln_edt.text.strip_edges())
	_quest_resource.set_stage_type(
			loaded_quest,
			loaded_stage,
			stage_type_opt_btn.get_item_metadata(stage_type_opt_btn.selected))
	
	_quest_resource.clear_stage_data(
			loaded_quest,
			loaded_stage)
	
	var data: Dictionary[String, Variant] = stage_data_tree.get_data()
	for data_key in data.keys():
		_quest_resource.set_stage_data(
				loaded_quest,
				loaded_stage,
				data_key,
				data[data_key])
	
	if not loaded_step.is_empty():
		save_current_step()


func save_current_step() -> void:
	_quest_resource.set_step_title(
			loaded_quest,
			loaded_stage,
			loaded_step,
			step_title_ln_edt.text.strip_edges())
	_quest_resource.set_step_type(
			loaded_quest,
			loaded_stage,
			loaded_step,
			step_type_opt_btn.get_item_metadata(step_type_opt_btn.selected))
	
	_quest_resource.clear_step_data(
			loaded_quest,
			loaded_stage,
			loaded_step)
	var data: Dictionary[String, Variant] = step_data_tree.get_data()
	
	for data_key in data.keys():
		_quest_resource.set_step_data(
				loaded_quest,
				loaded_stage,
				loaded_step,
				data_key,
				data[data_key])


func save() -> void:
	if _quest_resource == null:
		return
	if loaded_quest != &"":
		save_current_quest()
	ResourceSaver.save(_quest_resource)
	_unsaved = false
