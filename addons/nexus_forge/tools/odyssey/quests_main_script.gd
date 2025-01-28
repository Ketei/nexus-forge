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
var _unsaved: bool = false

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
	
	var path_quest_tab: NodePath = quest_tab_container.get_tab_bar().get_path()
	completion_limit_spn_bx.focus_next = path_quest_tab
	events_tree.focus_next = path_quest_tab
	
	stage_title_ln_edt.focus_exited.connect(_on_title_focus_lost)
	
	quest_tree.quest_selected.connect(_on_quest_selected)
	quest_tree.quest_created.connect(_on_quest_created)
	quest_tree.quest_stage_created.connect(_on_quest_stage_created)
	quest_tree.quest_stage_pool_item_created.connect(_on_quest_stage_pool_item_created)
	quest_tree.quest_stage_selected.connect(_on_quest_stage_selected)
	quest_tree.quest_id_changed.connect(_on_quest_id_changed)
	quest_tree.quest_deleted.connect(_on_quest_deleted)
	quest_tree.item_edited.connect(something_changed)
	events_tree.item_edited.connect(something_changed)
	requirements_tree.item_edited.connect(something_changed)
	stage_title_ln_edt.text_changed.connect(something_changed)
	stage_desc_txt_edt.text_changed.connect(something_changed)
	quest_title_ln_edt.text_changed.connect(something_changed)
	quest_desc_txt_edt.text_changed.connect(something_changed)
	
	search_ln_edt.text_changed.connect(_on_search_line_changed)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.is_action_pressed(&"ui_focus_next"):
		if quest_desc_txt_edt.has_focus():
			if event.shift_pressed:
				quest_title_ln_edt.grab_focus()
			else:
				if completion_limit_spn_bx.is_visible_in_tree():
					completion_limit_spn_bx.get_line_edit().grab_focus()
				else:
					quest_tab_container.get_tab_bar().grab_focus()
			get_viewport().set_input_as_handled()
		elif stage_desc_txt_edt.has_focus():
			if event.shift_pressed:
				stage_title_ln_edt.grab_focus()
			else:
				quest_tab_container.get_tab_bar().grab_focus()
			get_viewport().set_input_as_handled()


func _on_search_line_changed(update_text: String) -> void:
	quest_tree.search_for_text(update_text)


func _on_quest_deleted(quest_id: String, is_main: bool) -> void:
	if is_main:
		quest_resource.erase_main_quest(quest_id)
	else:
		quest_resource.erase_boiler_quest(quest_id)
	
	if current_quest == quest_id and is_main_quest == is_main:
		current_quest = ""
	
	something_changed()


func _on_quest_id_changed(from: String, to: String, is_main: bool) -> void:
	if is_main:
		quest_resource.quests_main[to] = quest_resource.quests_main[from]
		quest_resource.quests_main.erase(from)
	else:
		quest_resource.quests_boiler[to] = quest_resource.quests_boiler[from]
		quest_resource.quests_boiler.erase(from)
	
	if current_quest == from and is_main_quest == is_main:
		current_quest = to
	
	something_changed()


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
		if quest_resource.has_main_quest_requirement(quest_id, stage_id, "items"):
			for required_item in quest_resource.get_main_quest_stage_requirements(quest_id, stage_id, "items"):
				requirements_tree.create_required_item(required_item["item"], required_item["amount"], required_item["operator"], required_item["custom_data"])
		if quest_resource.has_main_quest_requirement(quest_id, stage_id, "variables"):
			for required_variable in quest_resource.get_main_quest_stage_requirements(quest_id, stage_id, "variables"):
				requirements_tree.create_required_variable(required_variable["path"], required_variable["value"], required_variable["operator"])
		if quest_resource.has_main_quest_requirement(quest_id, stage_id, "triggers"):
			for required_trigger in quest_resource.get_main_quest_stage_requirements(quest_id, stage_id, "triggers"):
				requirements_tree.create_required_trigger(required_trigger["trigger"], required_trigger["count"], required_trigger["operator"])
	else:
		stage_title_ln_edt.text = quest_resource.get_boiler_stage_title(quest_id, stage_id, pool_idx)
		stage_desc_txt_edt.text = quest_resource.get_boiler_stage_desc(quest_id, stage_id, pool_idx)
		if quest_resource.has_boiler_quest_requirement(quest_id, stage_id, pool_item_idx, "items"):
			for required_item in quest_resource.get_boiler_quest_stage_requirements(quest_id, stage_id, pool_idx, "items"):
				requirements_tree.create_required_item(required_item["item"], required_item["amount"], required_item["operator"], required_item["custom_data"])
		if quest_resource.has_boiler_quest_requirement(quest_id, stage_id, pool_item_idx, "variables"):
			for required_variable in quest_resource.get_boiler_quest_stage_requirements(quest_id, stage_id, pool_idx, "variables"):
				requirements_tree.create_required_variable(required_variable["path"], required_variable["value"], required_variable["operator"])
		if quest_resource.has_boiler_quest_requirement(quest_id, stage_id, pool_item_idx, "triggers"):
			for required_trigger in quest_resource.get_boiler_quest_stage_requirements(quest_id, stage_id, pool_idx, "triggers"):
				requirements_tree.create_required_trigger(required_trigger["trigger"], required_trigger["count"], required_trigger["operator"])
	
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
	
	something_changed()


func _on_quest_stage_created(quest_id: String, quest_idx: int, is_main: bool, stage_title: String) -> void:
	if is_main:
		quest_resource.create_main_quest_stage(quest_id, stage_title)
	else:
		quest_resource.create_boiler_quest_stage_pool(quest_id)
	
	something_changed()


func _on_quest_stage_pool_item_created(quest_id: String, stage_id: int, pool_idx: int, stage_title: String) -> void:
	quest_resource.create_boiler_quest_pool_stage(quest_id, stage_id, stage_title)
	something_changed()


func _on_title_focus_lost() -> void:
	if current_stage == -1:
		return
	
	var stage_title: String = stage_title_ln_edt.text.strip_edges()
	
	if is_main_quest:
		quest_tree.set_main_quest_stage_title(current_quest, current_stage, stage_title)
	else:
		quest_tree.set_boiler_quest_stage_title(current_quest, current_stage, pool_idx, stage_title)


func something_changed(_arg: Variant = null) -> void:
	if not _unsaved:
		_unsaved = true


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
	
	var requirements: Dictionary = requirements_tree.get_requirements()
	
	if is_main_quest:
		quest_resource.set_main_quest_stage_title(current_quest, current_stage, stage_title_ln_edt.text.strip_edges())
		quest_resource.set_main_quest_stage_desc(current_quest, current_stage, stage_desc_txt_edt.text.strip_edges())
		if not requirements["items"].is_empty():
			quest_resource.set_main_quest_requirement(current_quest, current_stage, "items", requirements["items"])
		else:
			if quest_resource.has_main_quest_requirement(current_quest, current_stage, "items"):
				quest_resource.remove_main_quest_requirement(current_quest, current_stage, "items")
		if not requirements["variables"].is_empty():
			quest_resource.set_main_quest_requirement(current_quest, current_stage, "variables", requirements["variables"])
		else:
			if quest_resource.has_main_quest_requirement(current_quest, current_stage, "variables"):
				quest_resource.remove_main_quest_requirement(current_quest, current_stage, "variables")
		if not requirements["triggers"].is_empty():
			quest_resource.set_main_quest_requirement(current_quest, current_stage, "triggers", requirements["triggers"])
		else:
			if quest_resource.has_main_quest_requirement(current_quest, current_stage, "triggers"):
				quest_resource.remove_main_quest_requirement(current_quest, current_stage, "triggers")
	else:
		quest_resource.set_boiler_quest_stage_title(current_quest, current_stage, pool_idx, stage_title_ln_edt.text.strip_edges())
		quest_resource.set_boiler_quest_stage_desc(current_quest, current_stage, pool_idx, stage_desc_txt_edt.text.strip_edges())
		if not requirements["items"].is_empty():
			quest_resource.set_boiler_quest_requirement(current_quest, current_stage, pool_idx, "items", requirements["items"])
		else:
			if quest_resource.has_boiler_quest_requirement(current_quest, current_stage, pool_idx, "items"):
				quest_resource.remove_boiler_quest_requirement(current_quest, current_stage, pool_idx, "items")
		if not requirements["variables"].is_empty():
			quest_resource.set_boiler_quest_requirement(current_quest, current_stage, pool_idx, "variables", requirements["variables"])
		else:
			if quest_resource.has_boiler_quest_requirement(current_quest, current_stage, pool_idx, "variables"):
				quest_resource.remove_boiler_quest_requirement(current_quest, current_stage, pool_idx, "variables")
		if not requirements["triggers"].is_empty():
			quest_resource.set_boiler_quest_requirement(current_quest, current_stage, pool_idx, "triggers", requirements["triggers"])
		else:
			if quest_resource.has_boiler_quest_requirement(current_quest, current_stage, pool_idx, "triggers"):
				quest_resource.remove_boiler_quest_requirement(current_quest, current_stage, pool_idx, "triggers")


func has_unsaved_changes() -> bool:
	return _unsaved


func save() -> void:
	if not current_quest.is_empty():
		save_current_quest()
	quest_resource.save()
	_unsaved = false
