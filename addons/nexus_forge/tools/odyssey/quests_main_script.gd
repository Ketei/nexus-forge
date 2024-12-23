@tool
extends Control


var quest_resource: NFQuestRes = null
var current_quest: String = "":
	set(new_quest):
		current_quest = new_quest
		quest_id_lbl.text = Strings.title_case(new_quest.replace("_", " "))
		quest_tab_container.visible = not current_quest.is_empty()
var is_main_quest: bool = true
var current_stage: int = -1:
	set(new_stage):
		current_stage = new_stage
		quest_tab_container.set_tab_disabled(2, current_stage == -1)
		if quest_tab_container.is_tab_disabled(2) and quest_tab_container.current_tab == 2:
			quest_tab_container.current_tab = 0
var pool_idx: int = -1

@onready var completion_limit_spn_bx: SpinBox = $MainContainer/QuestPanel/MainContainer/QuestTabContainer/SettingsMargin/SettingsContainer/LimitContainer/CompletionLimitSpnBx
@onready var quest_tab_container: TabContainer = $MainContainer/QuestPanel/MainContainer/QuestTabContainer
@onready var quest_id_lbl: Label = $MainContainer/QuestPanel/MainContainer/QuestIDLbl
@onready var quest_title_ln_edt: LineEdit = $MainContainer/QuestPanel/MainContainer/QuestTabContainer/SettingsMargin/SettingsContainer/DataContainer/QuestTitleLnEdt
@onready var quest_tree: Tree = $MainContainer/QuestsContainer/QuestTree
@onready var quest_desc_txt_edt: TextEdit = $MainContainer/QuestPanel/MainContainer/QuestTabContainer/SettingsMargin/SettingsContainer/DataContainer/QuestDescTxtEdt
@onready var stage_title_ln_edt: LineEdit = $MainContainer/QuestPanel/MainContainer/QuestTabContainer/StageReqContainer/TitleDescContainer/StageTitleLnEdt
@onready var stage_desc_txt_edt: TextEdit = $MainContainer/QuestPanel/MainContainer/QuestTabContainer/StageReqContainer/TitleDescContainer/StageDescTxtEdt
@onready var events_tree: Tree = $MainContainer/QuestPanel/MainContainer/QuestTabContainer/EventsTree
@onready var limit_container: HBoxContainer = $MainContainer/QuestPanel/MainContainer/QuestTabContainer/SettingsMargin/SettingsContainer/LimitContainer
@onready var search_ln_edt: LineEdit = $MainContainer/QuestsContainer/SearchLnEdt
@onready var requirements_tree: Tree = $MainContainer/QuestPanel/MainContainer/QuestTabContainer/StageReqContainer/RequirementsContainer/RequirementsTree


func _ready() -> void:
	quest_resource = NFQuestRes.new() # Remove once testing is done
	quest_tab_container.current_tab = 0
	quest_tab_container.set_tab_title(0, "Quest Settings")
	quest_tab_container.set_tab_title(1, "Quest Events")
	quest_tab_container.set_tab_title(2, "Stage Settings")
	quest_tab_container.set_tab_disabled(2, true)
	quest_tab_container.visible = false
	
	stage_title_ln_edt.focus_exited.connect(_on_title_focus_lost)
	
	quest_tree.quest_selected.connect(_on_quest_selected)
	quest_tree.quest_created.connect(_on_quest_created)
	quest_tree.quest_stage_created.connect(_on_quest_stage_created)
	quest_tree.quest_stage_pool_item_created.connect(_on_quest_stage_pool_item_created)
	quest_tree.quest_stage_selected.connect(_on_quest_stage_selected)
	quest_tree.quest_id_changed.connect(_on_quest_id_changed)
	quest_tree.quest_deleted.connect(_on_quest_deleted)
	
	search_ln_edt.text_changed.connect(_on_search_line_changed)


func _on_search_line_changed(update_text: String) -> void:
	quest_tree.search_for_text(update_text)


func _on_quest_deleted(quest_id: String, is_main: bool) -> void:
	if is_main:
		quest_resource.erase_main_quest(quest_id)
	else:
		quest_resource.erase_boiler_quest(quest_id)
	
	if current_quest == quest_id and is_main_quest == is_main:
		current_quest = ""


func _on_quest_id_changed(from: String, to: String, is_main: bool) -> void:
	if is_main:
		quest_resource.quests_main[to] = quest_resource.quests_main[from]
		quest_resource.quests_main.erase(from)
	else:
		quest_resource.quests_boiler[to] = quest_resource.quests_boiler[from]
		quest_resource.quests_boiler.erase(from)
	
	if current_quest == from and is_main_quest == is_main:
		current_quest = to


func _on_quest_stage_selected(quest_id: String, stage_id: int, is_main: bool, pool_item_idx: int = -1) -> void:
	if current_quest == quest_id and current_stage == stage_id and is_main_quest == is_main and pool_item_idx == pool_idx:
		return
	var is_on_stage_settings: bool = quest_tab_container.current_tab == 2
	
	# Ensure stage title is passed down correctly.
	if current_stage != -1:
		var current_text: String = stage_title_ln_edt.text.strip_edges()
		if is_main_quest:
			if quest_tree.get_main_quest_stage_title(current_quest, current_stage) != current_text:
				quest_tree.set_main_quest_stage_title(current_quest, current_stage, current_text)
		else:
			if quest_tree.get_boiler_quest_stage_title(current_quest, current_stage, pool_idx) != current_text:
				quest_tree.set_boiler_quest_stage_title(current_quest, current_stage, pool_idx, current_text)
		
	if current_quest != quest_id:
		_on_quest_selected(quest_id, is_main)
	
	current_stage = stage_id
	pool_idx = pool_item_idx
	requirements_tree.clear_requirements()
	
	if is_main:
		stage_title_ln_edt.text = quest_resource.get_main_stage_title(quest_id, stage_id)
		stage_desc_txt_edt.text = quest_resource.get_main_stage_desc(quest_id, stage_id)
	else:
		stage_title_ln_edt.text = quest_resource.get_boiler_stage_title(quest_id, stage_id, pool_idx)
		stage_desc_txt_edt.text = quest_resource.get_boiler_stage_desc(quest_id, stage_id, pool_idx)
	
	if is_on_stage_settings:
		quest_tab_container.current_tab = 2


func _on_quest_selected(quest_id: String, is_main: bool) -> void:
	if quest_id == current_quest and is_main_quest == is_main:
		return
	
	if not current_quest.is_empty():
		save_current_quest()
	
	current_quest = quest_id
	is_main_quest = is_main
	events_tree.clear_events()
	
	
	if is_main:
		quest_title_ln_edt.text = quest_resource.get_main_quest_title(quest_id)
		quest_desc_txt_edt.text = quest_resource.get_main_quest_desc(quest_id)
		if quest_resource.has_main_quest_event(quest_id, "quest_started"):
			events_tree.load_on_started_events(
					quest_resource.get_main_quest_events(quest_id, "quest_started"))
		if quest_resource.has_main_quest_event(quest_id, "quest_finished"):
			events_tree.load_on_finished_events(
					quest_resource.get_main_quest_events(quest_id, "quest_finished"))
		if quest_resource.has_main_quest_event(quest_id, "quest_progressed"):
			events_tree.load_on_progressed_events(
					quest_resource.get_main_quest_events(quest_id, "quest_progressed"))
		if quest_resource.has_main_quest_event(quest_id, "quest_successful"):
			events_tree.load_on_success_events(
					quest_resource.get_main_quest_events(quest_id, "quest_successful"))
		if quest_resource.has_main_quest_event(quest_id, "quest_failed"):
			events_tree.load_on_failed_events(
					quest_resource.get_main_quest_events(quest_id, "quest_failed"))
	else:
		quest_title_ln_edt.text = quest_resource.get_boiler_quest_title(quest_id)
		quest_desc_txt_edt.text = quest_resource.get_boiler_quest_desc(quest_id)
		completion_limit_spn_bx.value = quest_resource.get_boiler_quest_completion_limit(quest_id)
		if quest_resource.has_boiler_quest_event(quest_id, "quest_started"):
			events_tree.load_on_started_events(
					quest_resource.get_boiler_quest_events(quest_id, "quest_started"))
		if quest_resource.has_boiler_quest_event(quest_id, "quest_finished"):
			events_tree.load_on_finished_events(
					quest_resource.get_boiler_quest_events(quest_id, "quest_finished"))
		if quest_resource.has_boiler_quest_event(quest_id, "quest_progressed"):
			events_tree.load_on_progressed_events(
					quest_resource.get_boiler_quest_events(quest_id, "quest_progressed"))
		if quest_resource.has_boiler_quest_event(quest_id, "quest_successful"):
			events_tree.load_on_success_events(
					quest_resource.get_boiler_quest_events(quest_id, "quest_successful"))
		if quest_resource.has_boiler_quest_event(quest_id, "quest_failed"):
			events_tree.load_on_failed_events(
					quest_resource.get_boiler_quest_events(quest_id, "quest_failed"))
	
	quest_title_ln_edt.editable = true
	quest_desc_txt_edt.editable = true
	
	current_stage = -1
	pool_idx = -1
	
	limit_container.visible = not is_main


func _on_quest_created(quest_id: String, is_main: bool) -> void:
	if is_main:
		quest_resource.create_main_quest(quest_id)
	else:
		quest_resource.create_boiler_quest(quest_id)


func _on_quest_stage_created(quest_id: String, quest_idx: int, is_main: bool, stage_title: String) -> void:
	if is_main:
		quest_resource.create_main_quest_stage(quest_id, stage_title)
	else:
		quest_resource.create_boiler_quest_stage_pool(quest_id)


func _on_quest_stage_pool_item_created(quest_id: String, stage_id: int, pool_idx: int, stage_title: String) -> void:
	quest_resource.create_boiler_quest_pool_stage(quest_id, stage_id, stage_title)


func _on_title_focus_lost() -> void:
	if current_stage == -1:
		return
	
	var stage_title: String = stage_title_ln_edt.text.strip_edges()
	
	if is_main_quest:
		quest_tree.set_main_quest_stage_title(current_quest, current_stage, stage_title)
	else:
		quest_tree.set_boiler_quest_stage_title(current_quest, current_stage, pool_idx, stage_title)


func save_current_quest() -> void:
	if is_main_quest:
		quest_resource.set_main_quest_title(current_quest, quest_title_ln_edt.text.strip_edges())
		quest_resource.set_main_quest_desc(current_quest, quest_desc_txt_edt.text.strip_edges())
		if events_tree.has_on_started_events():
			quest_resource.register_main_quest_event(
					current_quest,
					"quest_started",
					events_tree.get_on_started_events())
		else:
			if quest_resource.has_main_quest_event(current_quest, "quest_started"):
				quest_resource.remove_main_quest_event(current_quest, "quest_started")
		if events_tree.has_on_success_events():
			quest_resource.register_main_quest_event(
					current_quest,
					"quest_successful",
					events_tree.get_on_success_events())
		else:
			if quest_resource.has_main_quest_event(current_quest, "quest_successful"):
				quest_resource.remove_main_quest_event(current_quest, "quest_successful")
		if events_tree.has_on_failed_events():
			quest_resource.register_main_quest_event(
					current_quest,
					"quest_failed",
					events_tree.get_on_failed_events())
		else:
			if quest_resource.has_main_quest_event(current_quest, "quest_failed"):
				quest_resource.remove_main_quest_event(current_quest, "quest_failed")
		if events_tree.has_on_finished_events():
			quest_resource.register_main_quest_event(
					current_quest,
					"quest_finished",
					events_tree.get_on_finished_events())
		else:
			if quest_resource.has_main_quest_event(current_quest, "quest_finished"):
				quest_resource.remove_main_quest_event(current_quest, "quest_finished")
		if events_tree.has_on_progressed_events():
			quest_resource.register_main_quest_event(
					current_quest,
					"quest_progressed",
					events_tree.get_on_progressed_events())
		else:
			if quest_resource.has_main_quest_event(current_quest, "quest_progressed"):
				quest_resource.remove_main_quest_event(current_quest, "quest_progressed")
	else:
		quest_resource.set_boiler_quest_title(current_quest, quest_title_ln_edt.text.strip_edges())
		quest_resource.set_boiler_quest_desc(current_quest, quest_desc_txt_edt.text.strip_edges())
		quest_resource.set_boiler_quest_completion_limit(current_quest, completion_limit_spn_bx.value)
		if events_tree.has_on_started_events():
			quest_resource.register_boiler_quest_event(
					current_quest,
					"quest_started",
					events_tree.get_on_started_events())
		else:
			if quest_resource.has_boiler_quest_event(current_quest, "quest_started"):
				quest_resource.remove_boiler_quest_event(current_quest, "quest_started")
		if events_tree.has_on_success_events():
			quest_resource.register_boiler_quest_event(
					current_quest,
					"quest_successful",
					events_tree.get_on_success_events())
		else:
			if quest_resource.has_boiler_quest_event(current_quest, "quest_successful"):
				quest_resource.remove_boiler_quest_event(current_quest, "quest_successful")
		if events_tree.has_on_failed_events():
			quest_resource.register_boiler_quest_event(
					current_quest,
					"quest_failed",
					events_tree.get_on_failed_events())
		else:
			if quest_resource.has_boiler_quest_event(current_quest, "quest_failed"):
				quest_resource.remove_boiler_quest_event(current_quest, "quest_failed")
		if events_tree.has_on_finished_events():
			quest_resource.register_boiler_quest_event(
					current_quest,
					"quest_finished",
					events_tree.get_on_finished_events())
		else:
			if quest_resource.has_boiler_quest_event(current_quest, "quest_finished"):
				quest_resource.remove_boiler_quest_event(current_quest, "quest_finished")
		if events_tree.has_on_progressed_events():
			quest_resource.register_boiler_quest_event(
					current_quest,
					"quest_progressed",
					events_tree.get_on_progressed_events())
		else:
			if quest_resource.has_boiler_quest_event(current_quest, "quest_progressed"):
				quest_resource.remove_boiler_quest_event(current_quest, "quest_progressed")
	
	if current_stage == -1:
		return
	
	if is_main_quest:
		quest_resource.set_main_quest_stage_title(current_quest, current_stage, stage_title_ln_edt.text.strip_edges())
		quest_resource.set_main_quest_stage_desc(current_quest, current_stage, stage_desc_txt_edt.text.strip_edges())
		quest_resource.quests_main[current_quest]["stages"][current_stage]["requirements"] = requirements_tree.get_requirements()
	else:
		quest_resource.set_boiler_quest_stage_title(current_quest, current_stage, pool_idx, stage_title_ln_edt.text.strip_edges())
		quest_resource.set_boiler_quest_stage_desc(current_quest, current_stage, pool_idx, stage_desc_txt_edt.text.strip_edges())
		quest_resource.quests_boiler[current_quest]["stages"][current_stage][pool_idx]["requirements"] = requirements_tree.get_requirements()


#func _on_desc_focus_lost() -> void:
	#if is_main_quest:
		#quest_resource.set_main_quest_desc(current_quest, quest_desc_txt_edt.text.strip_edges())
	#else:
		#quest_resource.set_boiler_quest_desc(current_quest, quest_desc_txt_edt.text.strip_edges())




#func _on_title_focus_lost() -> void:
	


#var current_quest: String = "":
	#set(new_quest):
		#current_quest = new_quest
		#var valid_quest: bool = not new_quest.is_empty()
		#search_obj_ln_edt.editable = valid_quest
		#add_obj_btn.disabled = not valid_quest
		#quest_label.text = current_quest
#var current_obj: String = "":
	#set(new_obj):
		#current_obj = new_obj
		#obj_id_lbl.text = new_obj
		#var valid_obj: bool = not new_obj.is_empty()
		#obj_title_ln_edt.editable = valid_obj
		#obj_desc_txt_edt.editable = valid_obj
		#add_item_btn.disabled = not valid_obj
		#add_trigger_btn.disabled = not valid_obj
		#search_item_ln_edt.editable = not valid_obj
		#search_trigger_ln_edt.editable = not valid_obj
		#search_var_ln_edt.editable = not valid_obj
		#add_int_btn.disabled = not valid_obj
		#add_flt_btn.disabled = not valid_obj
		#add_bool_btn.disabled = not valid_obj
		#add_str_btn.disabled = not valid_obj
#var resource_file_dialog: FileDialog = null
#var on_main_quests: bool = true
#var no_resource_panel: PanelContainer = null
#var loading_quest: bool = false
#
#@onready var search_qst_ln_edt: LineEdit = $MainContainer/QuestsContainer/SearchPanel/SearchContainer/SearchLnEdt
#@onready var quest_title_ln_edt: LineEdit = $MainContainer/QuestDescContainer/DataContainer/TitleContainer/QuestTitleLnEdt
#@onready var search_obj_ln_edt: LineEdit = $MainContainer/QuestDescContainer/ObjectiveContainer/ObjSrchLnEdt
#@onready var search_item_ln_edt: LineEdit = $MainContainer/ObjectiveContainer/ObjReqContainer/ItemTriggerContainer/ItemsContainer/SearchItemLnEdt
#@onready var search_trigger_ln_edt: LineEdit = $MainContainer/ObjectiveContainer/ObjReqContainer/ItemTriggerContainer/TriggerContainer/SearchTriggerLnEdt
#@onready var obj_title_ln_edt: LineEdit = $MainContainer/ObjectiveContainer/ObjReqContainer/VBoxContainer/ObjTitleDescContainer/TitleLineEdt/ObjTitleLnEdt
#@onready var search_var_ln_edt: LineEdit = $MainContainer/ObjectiveContainer/ObjReqContainer/VBoxContainer/VariablesCotnainer/SearchVarLnEdt
#
#@onready var create_quest_btn: Button = $MainContainer/QuestsContainer/SearchPanel/SearchContainer/CreateQuestBtn
#@onready var add_obj_btn: Button = $MainContainer/QuestDescContainer/ObjectiveContainer/ObjectiveHeader/AddObjBtn
#@onready var add_item_btn: Button = $MainContainer/ObjectiveContainer/ObjReqContainer/ItemTriggerContainer/ItemsContainer/ItemsHeader/AddItemBtn
#@onready var add_int_btn: Button = $MainContainer/ObjectiveContainer/ObjReqContainer/VBoxContainer/VariablesCotnainer/VariablesHeader/ButtonContainer/AddIntBtn
#@onready var add_flt_btn: Button = $MainContainer/ObjectiveContainer/ObjReqContainer/VBoxContainer/VariablesCotnainer/VariablesHeader/ButtonContainer/AddFltBtn
#@onready var add_bool_btn: Button = $MainContainer/ObjectiveContainer/ObjReqContainer/VBoxContainer/VariablesCotnainer/VariablesHeader/ButtonContainer/AddBoolBtn
#@onready var add_str_btn: Button = $MainContainer/ObjectiveContainer/ObjReqContainer/VBoxContainer/VariablesCotnainer/VariablesHeader/ButtonContainer/AddStrBtn
#@onready var add_trigger_btn: Button = $MainContainer/ObjectiveContainer/ObjReqContainer/ItemTriggerContainer/TriggerContainer/HeaderContainer/AddTriggerBtn
#
#@onready var quest_tree: Tree = $MainContainer/QuestsContainer/QuestTree
#@onready var objectives_tree: Tree = $MainContainer/QuestDescContainer/ObjectiveContainer/ObjectivesTree
#@onready var item_tree: Tree = $MainContainer/ObjectiveContainer/ObjReqContainer/ItemTriggerContainer/ItemsContainer/ItemTree
#@onready var trigger_tree: Tree = $MainContainer/ObjectiveContainer/ObjReqContainer/ItemTriggerContainer/TriggerContainer/TriggerTree
#@onready var variables_tree: Tree = $MainContainer/ObjectiveContainer/ObjReqContainer/VBoxContainer/VariablesCotnainer/VariablesTree
#
#@onready var quest_desc_txt_edt: TextEdit = $MainContainer/QuestDescContainer/DataContainer/DescContainer/DescTextEdit
#@onready var desc_text_edit: TextEdit = $MainContainer/QuestDescContainer/DataContainer/DescContainer/DescTextEdit
#@onready var obj_desc_txt_edt: TextEdit = $MainContainer/ObjectiveContainer/ObjReqContainer/VBoxContainer/ObjTitleDescContainer/ObjDescTxtEdt
#
#@onready var quest_label: Label = $MainContainer/QuestDescContainer/DataContainer/InfoContainer/QuestLabel
#@onready var obj_id_lbl: Label = $MainContainer/ObjectiveContainer/ObjReqContainer/VBoxContainer/ObjTitleDescContainer/ObjHeader/IDLbl
#
#@onready var main_container: HBoxContainer = $MainContainer
#
#@onready var quest_type_opt_btn: OptionButton = $MainContainer/QuestsContainer/HBoxContainer/QuestTypeOptBtn
#@onready var save_button: Button = $MainContainer/QuestsContainer/HBoxContainer2/MenuContainer/SaveButton
#
#
#func _ready() -> void:
	#var res_path: String = ProjectSettings.get_setting(NFQuestRes.SETTINGS_PATH, "")
	#
#
	#if not res_path.is_empty() and ResourceLoader.exists(res_path):
		#var res_preload: Resource = load(res_path)
		#if res_preload is NFQuestRes:
			#quest_resource = res_preload
	#
	#quest_type_opt_btn.item_selected.connect(on_quest_type_changed)
	#search_qst_ln_edt.text_changed.connect(on_search_line_changed.bind(quest_tree))
	#search_item_ln_edt.text_changed.connect(on_search_line_changed.bind(item_tree))
	#search_obj_ln_edt.text_changed.connect(on_search_line_changed.bind(objectives_tree))
	#search_trigger_ln_edt.text_changed.connect(on_search_line_changed.bind(trigger_tree))
	#search_var_ln_edt.text_changed.connect(on_search_line_changed.bind(variables_tree))
	#create_quest_btn.pressed.connect(on_create_button_pressed.bind(quest_tree, "new_quest"))
	#add_item_btn.pressed.connect(on_create_button_pressed.bind(item_tree, "new_item"))
	#add_trigger_btn.pressed.connect(on_create_button_pressed.bind(trigger_tree, "new_trigger"))
	#add_obj_btn.pressed.connect(on_create_button_pressed.bind(objectives_tree, "new_objective"))
	#add_int_btn.pressed.connect(on_create_button_pressed.bind(variables_tree, "new_int", 0))
	#add_flt_btn.pressed.connect(on_create_button_pressed.bind(variables_tree, "new_float", 0.0))
	#add_bool_btn.pressed.connect(on_create_button_pressed.bind(variables_tree, "new_bool", false))
	#add_str_btn.pressed.connect(on_create_button_pressed.bind(variables_tree, "new_string", ""))
	#quest_tree.quest_renamed.connect(on_quest_renamed)
	#quest_tree.quest_deleted.connect(on_quest_deleted)
	#quest_tree.quest_created.connect(on_quest_created)
	#quest_tree.quest_selected.connect(on_quest_selected)
	#objectives_tree.objective_deleted.connect(on_objective_deleted)
	#objectives_tree.objective_selected.connect(on_objective_selected)
	#objectives_tree.objective_id_changed.connect(on_objective_renamed)
	#objectives_tree.objectives_reordered.connect(on_objectives_reordered)
	#objectives_tree.objective_created.connect(on_objective_created)
	#save_button.pressed.connect(on_save_pressed)
	#
	#if quest_resource != null:
		#load_resource()
		#main_container.visible = true
	#else:
		#no_resource_panel = preload("res://addons/nexus_forge/scenes/no_db_container.tscn").instantiate()
		#add_child(no_resource_panel)
		#no_resource_panel.set_resource_type("NFQuestRes", "Odyssey", "Quests")
		#no_resource_panel.create_resource_pressed.connect(on_create_res_pressed)
		#no_resource_panel.load_resource_pressed.connect(on_load_res_pressed)
		#main_container.visible = false
		#no_resource_panel.visible = true
		#resource_file_dialog = FileDialog.new()
		#resource_file_dialog.add_filter("*.tres", "Resources")
		#resource_file_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
		#resource_file_dialog.size = Vector2i(500, 350)
		#resource_file_dialog.file_selected.connect(on_file_path_selected)
		#add_child(resource_file_dialog)
#
#
#func on_save_pressed() -> void:
	#save()
#
#
#func on_quest_type_changed(quest_idx: int) -> void:
	#on_main_quests = quest_type_opt_btn.get_item_id(quest_idx) == 0
	#quest_tree.clear_items()
	#clear_quest()
	#current_quest = ""
	#for quest in quest_resource.get_quests(on_main_quests):
		#quest_tree.add_item(quest)
#
#
#func on_objectives_reordered() -> void:
	#quest_resource.quests[current_quest]["order"] = objectives_tree.get_objectives()
#
#
#func on_quest_created(quest_id: String) -> void:
	#if not quest_resource.has_quest(quest_id, on_main_quests):
		#quest_resource.create_quest(quest_id, on_main_quests)
#
#
#func on_quest_renamed(from: String, to: String) -> void:
	#if on_main_quests:
		#quest_resource.quests_unique[to] = quest_resource.quests_unique[from]
	#else:
		#quest_resource.quests_boiler[to] = quest_resource.quests_boiler[from]
	#
	#if current_quest == from:
		#current_quest = to
	#
	#quest_resource.erase_quest(from, on_main_quests)
#
#
#func on_objective_created(objective_id: String) -> void:
	#if loading_quest:
		#return
	#if not quest_resource.has_quest_objective(current_quest, objective_id, on_main_quests):
		#quest_resource.create_objective(
				#current_quest,
				#-1,
				#objective_id,
				#on_main_quests)
#
#
#func on_objective_renamed(from: String, to: String) -> void:
	#var from_idx: int = 0
	#if on_main_quests:
		#from_idx = quest_resource.quests_unique[current_quest]["order"].find(from)
		#quest_resource.quests_unique[current_quest]["order"][from_idx] = to
		#quest_resource.quests_unique[current_quest]["objectives"][to] = quest_resource.quests_unique[current_quest]["objectives"][from]
		#quest_resource.erase_objective(current_quest, from, true)
	#else:
		#from_idx = quest_resource.quests_boiler[current_quest]["order"].find(from)
		#quest_resource.quests_boiler[current_quest]["order"][from_idx] = to
		#quest_resource.quests_boiler[current_quest]["objectives"][to] = quest_resource.quests_unique[current_quest]["objectives"][from]
		#quest_resource.erase_objective(current_quest, from, false)
	#
	#
	#if current_obj == from:
		#current_obj = to
#
#
#func on_create_res_pressed() -> void:
	#resource_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	#resource_file_dialog.show()
#
#
#func on_load_res_pressed() -> void:
	#resource_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	#resource_file_dialog.show()
#
#
#func on_file_path_selected(file_path: String) -> void:
	#if resource_file_dialog.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		#ProjectSettings.set_setting(NFQuestRes.SETTINGS_PATH, file_path)
		#ProjectSettings.save()
		#quest_resource = NFQuestRes.new()
		#quest_resource.save()
	#else:
		#var res_preload: Resource = load(file_path)
		#if res_preload is NFQuestRes:
			#ProjectSettings.set_setting(NFQuestRes.SETTINGS_PATH, file_path)
			#ProjectSettings.save()
			#quest_resource = res_preload
		#else:
			#printerr("[Odyssey] Selected resource isn't NFQuestRes")
	#
	#if quest_resource != null:
		#resource_file_dialog.queue_free()
		#no_resource_panel.queue_free()
		#main_container.visible = true
		#load_resource()
#
#
#func load_resource() -> void:
	#quest_tree.clear_items()
	#for quest in quest_resource.get_quests(on_main_quests):
		#quest_tree.add_item(quest)
#
#
#func save_quest() -> void:
	#if not quest_resource.has_quest(current_quest, on_main_quests):
		#quest_resource.create_quest(
			#current_quest,
			#on_main_quests,
			#quest_title_ln_edt.text.strip_edges(),
			#quest_desc_txt_edt.text.strip_edges())
	#else:
		#quest_resource.set_quest_title(current_quest, quest_title_ln_edt.text.strip_edges(), on_main_quests)
		#quest_resource.set_quest_desc(current_quest, quest_desc_txt_edt.text.strip_edges(), on_main_quests)
#
#
#func save_objective() -> void:
	#if not quest_resource.has_quest(current_quest, on_main_quests):
		#save_quest()
	#
	#if not quest_resource.has_quest_objective(current_quest, current_obj, on_main_quests):
		#quest_resource.create_objective(
				#current_quest,
				#objectives_tree.get_obj_index(current_obj),
				#current_obj,
				#on_main_quests,
				#obj_title_ln_edt.text.strip_edges(),
				#obj_desc_txt_edt.text.strip_edges())
	#else:
		#quest_resource.set_quest_objective_title(
				#current_quest,
				#current_obj,
				#obj_title_ln_edt.text.strip_edges(),
				#on_main_quests)
		#quest_resource.set_quest_objective_desc(
				#current_quest,
				#current_obj,
				#obj_desc_txt_edt.text.strip_edges(),
				#on_main_quests)
	#
	#quest_resource.clear_objective_requirements(current_quest, current_obj, on_main_quests)
	#
	#var item_data: Dictionary = item_tree.get_data()
	#var trigger_data: Dictionary = trigger_tree.get_data()
	#var var_data: Dictionary = variables_tree.get_data()
	#
	#for item in item_data:
		#quest_resource.add_objective_item(
				#current_quest,
				#current_obj,
				#on_main_quests,
				#item,
				#item_data[item]["exact"],
				#item_data[item]["amount"],
				#range_to_operator(item_data[item]["match"]))
	#for trigger in trigger_data:
		#quest_resource.add_objective_trigger(
				#current_quest,
				#current_obj,
				#on_main_quests,
				#trigger,
				#trigger_data[trigger]["amount"],
				#range_to_operator(trigger_data[trigger]["match"]))
	#for variable in var_data:
		#quest_resource.add_objective_variable(
				#current_quest,
				#current_obj,
				#on_main_quests,
				#variable,
				#var_data[variable]["value"],
				#range_to_operator(var_data[variable]["match"]))
#
#
#func on_quest_deleted(quest_id: String) -> void:
	#quest_resource.erase_quest(quest_id, on_main_quests)
	#
	#if current_quest == quest_id:
		#clear_quest()
		#current_quest = ""
		#current_obj = ""
#
#
#func on_objective_deleted(objective_id: String) -> void:
	#quest_resource.erase_objective(current_quest, objective_id, on_main_quests)
	#if current_obj == objective_id:
		#clear_objectives()
		#current_obj = ""
#
#
#func clear_objectives() -> void:
	#current_obj = ""
	#item_tree.clear_items()
	#trigger_tree.clear_items()
	#variables_tree.clear_items()
	#search_item_ln_edt.clear()
	#search_trigger_ln_edt.clear()
	#search_var_ln_edt.clear()
	#obj_title_ln_edt.clear()
	#obj_desc_txt_edt.clear()
#
#
#func clear_quest() -> void:
	#clear_objectives()
	#objectives_tree.clear_items()
	#search_obj_ln_edt.clear()
	#quest_desc_txt_edt.clear()
	#quest_title_ln_edt.clear()
#
#
#func on_quest_selected(quest_id: String) -> void:
	#if loading_quest:
		#return
	#loading_quest = true
	#if not current_obj.is_empty():
		#save_objective()
	#
	#if not current_quest.is_empty():
		#save_quest()
	#
	#clear_quest()
	#
	#quest_title_ln_edt.text = quest_resource.get_quest_title(quest_id, on_main_quests)
	#quest_desc_txt_edt.text = quest_resource.get_quest_desc(quest_id, on_main_quests)
	#
	#for quest_obj in quest_resource.get_quest_objectives(quest_id, on_main_quests):
		#objectives_tree.add_item(quest_obj)
	#
	#current_quest = quest_id
	#loading_quest = false
#
#
#func on_objective_selected(obj_id: String) -> void:
	#if not current_obj.is_empty():
		#save_objective()
	#
	#clear_objectives()
	#
	#current_obj = obj_id
	#
	#obj_title_ln_edt.text = quest_resource.get_objective_title(current_quest, obj_id)
	#obj_desc_txt_edt.text = quest_resource.get_objective_desc(current_quest, obj_id)
	#
	#var conditions: Dictionary = quest_resource.get_objective_conditions(current_quest, obj_id, on_main_quests)
	#
	#for quest_item in conditions["items"]:
		#item_tree.add_item(
				#quest_item,
				#conditions["items"][quest_item]["amount"],
				#operator_to_range(conditions["items"][quest_item]["match"]))
	#
	#for quest_trigger in conditions["triggers"]:
		#trigger_tree.add_item(
				#quest_trigger,
				#conditions["triggers"][quest_trigger]["amount"],
				#operator_to_range(conditions["triggers"][quest_trigger]["match"]))
	#
	#for variable in conditions["variables"]:
		#variables_tree.add_item(
				#variable,
				#conditions["variables"][variable]["value"],
				#operator_to_range(conditions["variables"][variable]["match"]))
#
#
#func on_search_line_changed(text: String, target: Tree) -> void:
	#target.search_item(text.strip_edges())
#
#
#func on_create_button_pressed(tree: Tree, id: String, extra: Variant = null) -> void:
	#if extra == null:
		#tree.add_item(id)
	#else:
		#tree.add_item(id, extra)
#
#
#func operator_to_range(operator: NFQuestRes.ConnectFlags) -> int:
	#match operator:
		#OP_EQUAL:
			#return 0
		#OP_NOT_EQUAL:
			#return 1
		#OP_LESS:
			#return 2
		#OP_GREATER:
			#return 3
		#OP_LESS_EQUAL:
			#return 4
		#OP_GREATER_EQUAL:
			#return 5
		#_:
			#return 0
#
#
#func range_to_operator(range: int) -> int:
	#match range:
		#0:
			#return OP_EQUAL
		#1:
			#return OP_NOT_EQUAL
		#2:
			#return OP_LESS
		#3:
			#return OP_GREATER
		#4:
			#return OP_LESS_EQUAL
		#5:
			#return OP_GREATER_EQUAL
		#_:
			#return OP_EQUAL
#
#
#func save() -> void:
	#if not current_obj.is_empty():
		#save_objective()
	#if not current_quest.is_empty():
		#save_quest()
	#quest_resource.save()


func on_save() -> void:
	if not current_quest.is_empty():
		save_current_quest()
	quest_resource.save()
