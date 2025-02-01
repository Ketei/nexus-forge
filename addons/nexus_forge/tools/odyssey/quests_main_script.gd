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
var _no_resource_window: Control = null

@onready var completion_limit_spn_bx: SpinBox = $MainContainer/QuestPanel/MainContainer/QuestTabContainer/SettingsMargin/SettingsContainer/LimitContainer/CompletionLimitSpnBx
@onready var quest_tab_container: TabContainer = $MainContainer/QuestPanel/MainContainer/QuestTabContainer
@onready var quest_id_lbl: Label = $MainContainer/QuestPanel/MainContainer/QuestIDLbl
@onready var quest_title_ln_edt: LineEdit = $MainContainer/QuestPanel/MainContainer/QuestTabContainer/SettingsMargin/SettingsContainer/DataContainer/QuestTitleLnEdt
@onready var quest_tree: Tree = $MainContainer/QuestsContainer/QuestTree
@onready var quest_desc_txt_edt: TextEdit = $MainContainer/QuestPanel/MainContainer/QuestTabContainer/SettingsMargin/SettingsContainer/DataContainer/QuestDescTxtEdt
@onready var stage_title_ln_edt: LineEdit = $MainContainer/QuestPanel/MainContainer/QuestTabContainer/StageReqContainer/TitleDescContainer/StageTitleLnEdt
@onready var stage_desc_txt_edt: TextEdit = $MainContainer/QuestPanel/MainContainer/QuestTabContainer/StageReqContainer/TitleDescContainer/StageDescTxtEdt
@onready var limit_container: HBoxContainer = $MainContainer/QuestPanel/MainContainer/QuestTabContainer/SettingsMargin/SettingsContainer/LimitContainer
@onready var search_ln_edt: LineEdit = $MainContainer/QuestsContainer/SearchLnEdt
@onready var requirements_tree: Tree = $MainContainer/QuestPanel/MainContainer/QuestTabContainer/StageReqContainer/RequirementsContainer/RequirementsTree
@onready var main_container: HBoxContainer = $MainContainer
@onready var create_event_btn: Button = $MainContainer/QuestPanel/MainContainer/QuestTabContainer/EventsPanel/EventsContainer/HeaderContainer/CreateEventBtn
@onready var events_tree: Tree = $MainContainer/QuestPanel/MainContainer/QuestTabContainer/EventsPanel/EventsContainer/EventsTree


func _ready() -> void:
	var quest_path: String = ProjectSettings.get_setting(NFQuestRes.SETTINGS_PATH, "")
	
	if not quest_path.is_empty() and ResourceLoader.exists(quest_path):
		var res_pre: Resource = load(quest_path)
		if res_pre != null and res_pre is NFQuestRes:
			quest_resource = res_pre
	
	if quest_resource != null:
		main_container.visible = true
		load_resource()
	else:
		main_container.visible = false
		_no_resource_window = load("res://addons/nexus_forge/scenes/no_db_container.tscn").instantiate()
		add_child(_no_resource_window)
		_no_resource_window.load_resource_pressed.connect(_on_load_resource_pressed)
		_no_resource_window.create_resource_pressed.connect(_on_create_resource_pressed)
		_no_resource_window.set_resource_type("NFQuestRes", "Quests", "Quests")
	
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
	quest_tree.quest_stage_deleted.connect(_on_quest_stage_deleted)
	quest_tree.quest_pool_item_deleted.connect(_on_quest_pool_item_deleted)
	events_tree.item_deleted.connect(something_changed)
	requirements_tree.item_deleted.connect(something_changed)
	
	create_event_btn.pressed.connect(_on_create_event_pressed)


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
	elif Input.is_action_just_pressed(&"ui_home"):
		save()


func _on_create_event_pressed() -> void:
	events_tree.create_event()
	something_changed()


func _on_create_resource_pressed() -> void:
	var res_loader := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").new()
	res_loader.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	res_loader.title = "Create Quests"
	res_loader.ok_button_text = "Save"
	add_child(res_loader)
	res_loader.show()
	
	var result = await res_loader.dialog_finished
	
	if result[0]:
		quest_resource = NFQuestRes.new()
		ResourceSaver.save(quest_resource, result[1])
		ProjectSettings.set_setting(NFQuestRes.SETTINGS_PATH, result[1])
		ProjectSettings.save()
		main_container.visible = true
		_no_resource_window.queue_free()
		_no_resource_window.visible = false
		load_resource()
	
	res_loader.queue_free()


func _on_quest_stage_deleted(quest_id: String, stage_idx: int, is_main: bool) -> void:
	if is_main:
		quest_resource.erase_main_quest_stage(quest_id, stage_idx)
	else:
		quest_resource.erase_boiler_quest_stage(quest_id, stage_idx)
	
	if quest_id == current_quest and stage_idx == current_stage and is_main == is_main_quest:
		current_stage = -1
		if quest_tab_container.current_tab == 2:
			quest_tab_container.current_tab = 1
		quest_tab_container.set_tab_disabled(2, true)
	something_changed()


func _on_quest_pool_item_deleted(quest_id: String, stage_idx: int, item_idx: int) -> void:
	quest_resource.remove_boiler_quest_stage_pool_item(quest_id, stage_idx, item_idx)
	if is_main_quest == false and current_stage == stage_idx and pool_idx == item_idx:
		current_stage = -1
		pool_idx = -1
		quest_tab_container.set_tab_disabled(2, true)
	something_changed()


func _on_load_resource_pressed() -> void:
	var res_loader := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").new()
	res_loader.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	res_loader.title = "Open Quests"
	res_loader.ok_button_text = "Load"
	add_child(res_loader)
	res_loader.show()
	
	var result = await res_loader.dialog_finished
	
	if result[0]:
		var res_pre: Resource = load(result[1])
		if res_pre != null and res_pre is NFQuestRes:
			quest_resource = res_pre
			ProjectSettings.set_setting(NFQuestRes.SETTINGS_PATH, result[1])
			ProjectSettings.save()
			main_container.visible = true
			_no_resource_window.queue_free()
			_no_resource_window.visible = false
			load_resource()
	
	res_loader.queue_free()


func _on_search_line_changed(update_text: String) -> void:
	quest_tree.search_for_text(update_text)


func _on_quest_deleted(quest_id: String, is_main: bool) -> void:
	if is_main:
		quest_resource.erase_main_quest(quest_id)
	else:
		quest_resource.erase_boiler_quest(quest_id)
	
	if current_quest == quest_id and is_main_quest == is_main:
		current_quest = ""
		current_stage = -1
		pool_idx = -1
	
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
	
	if not current_quest.is_empty():
		if current_quest != quest_id:
			save_current_quest() # Contains save_current_stage
		elif current_stage != -1:
			# It means we're in the same quest, just changing stages.
			save_current_stage()
	
	if current_quest != quest_id:
		load_quest(quest_id, is_main)
		if quest_tree.is_unopened(quest_id, is_main):
			events_tree.load_default_events()
			quest_tree.remove_unopened(quest_id, is_main)
	
	load_stage(quest_id, stage_id, is_main, pool_item_idx)
	
	if is_on_stage_settings:
		quest_tab_container.current_tab = 2


func load_stage(quest_id: String, stage_id: int, is_main: bool, pool_item_idx: int = -1) -> void:
	current_stage = stage_id
	pool_idx = pool_item_idx
	requirements_tree.clear_requirements()
	
	if is_main:
		stage_title_ln_edt.text = quest_resource.get_main_quest_stage_title(quest_id, stage_id)
		stage_desc_txt_edt.text = quest_resource.get_main_quest_stage_description(quest_id, stage_id)
		requirements_tree.load_requirements(quest_resource.quests_main[quest_id]["stages"][stage_id]["requirements"])
		
	else:
		stage_title_ln_edt.text = quest_resource.get_boiler_quest_pool_item_title(quest_id, stage_id, pool_idx)
		stage_desc_txt_edt.text = quest_resource.get_boiler_quest_pool_item_description(quest_id, stage_id, pool_idx)
		requirements_tree.load_requirements(quest_resource.quests_boiler[quest_id]["stages"][stage_id]["pool_items"][pool_idx]["requirements"])


func _on_quest_selected(quest_id: String, is_main: bool, load_defaults: bool) -> void:
	if quest_id == current_quest and is_main_quest == is_main:
		return
	
	if not current_quest.is_empty():
		save_current_quest()
	
	load_quest(quest_id, is_main)
	
	if load_defaults:
		events_tree.load_default_events()


func load_quest(quest_id: String, is_main: bool) -> void:
	current_quest = quest_id
	is_main_quest = is_main
	events_tree.clear_events()
	
	if is_main:
		quest_title_ln_edt.text = quest_resource.get_main_quest_title(quest_id)
		quest_desc_txt_edt.text = quest_resource.get_main_quest_description(quest_id)
		
		for event in quest_resource.get_main_quest_events(quest_id):
			events_tree.load_event(
					event,
					quest_resource.quests_main[quest_id]["events"][event])
	else:
		quest_title_ln_edt.text = quest_resource.get_boiler_quest_title(quest_id)
		quest_desc_txt_edt.text = quest_resource.get_boiler_quest_description(quest_id)
		completion_limit_spn_bx.value = quest_resource.get_boiler_quest_completion_limit(quest_id)
		
		for event in quest_resource.get_boiler_quest_events(quest_id):
			events_tree.load_event(
					event,
					quest_resource.quests_boiler[quest_id]["events"][event])
	
	quest_title_ln_edt.editable = true
	quest_desc_txt_edt.editable = true
	
	current_stage = -1
	pool_idx = -1
	
	limit_container.visible = not is_main
	events_tree.collapse_all()


func _on_quest_created(quest_id: String, is_main: bool) -> void:
	if is_main:
		quest_resource.create_main_quest(quest_id)
	else:
		quest_resource.create_boiler_quest(quest_id)
	
	something_changed()


func _on_quest_stage_created(quest_id: String, quest_idx: int, is_main: bool, stage_title: String) -> void:
	if is_main:
		var stage_idx: int = quest_resource.create_main_quest_stage(quest_id)
		quest_resource.set_main_quest_stage_title(quest_id, stage_idx, stage_title)
	else:
		quest_resource.create_boiler_quest_stage(quest_id)
	
	something_changed()


func _on_quest_stage_pool_item_created(quest_id: String, stage_id: int, pool_idx: int, stage_title: String) -> void:
	quest_resource.create_boiler_quest_stage_pool_item(quest_id, stage_id)
	quest_resource.set_boiler_quest_pool_item_title(quest_id, stage_id, pool_idx, stage_title)
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
		quest_resource.set_main_quest_description(current_quest, quest_desc_txt_edt.text.strip_edges())
		quest_resource.quests_main[current_quest]["events"] = events_tree.get_events()
	else:
		quest_resource.set_boiler_quest_title(current_quest, quest_title_ln_edt.text.strip_edges())
		quest_resource.set_boiler_quest_description(current_quest, quest_desc_txt_edt.text.strip_edges())
		quest_resource.set_boiler_quest_completion_limit(current_quest, completion_limit_spn_bx.value)
		quest_resource.quests_boiler[current_quest]["events"] = events_tree.get_events()
	
	if current_stage != -1:
		save_current_stage()


func save_current_stage() -> void:
	if is_main_quest:
		quest_resource.set_main_quest_stage_title(current_quest, current_stage, stage_title_ln_edt.text.strip_edges())
		quest_resource.set_main_quest_stage_description(current_quest, current_stage, stage_desc_txt_edt.text.strip_edges())
		quest_resource.quests_main[current_quest]["stages"][current_stage]["requirements"] = requirements_tree.get_requirements()
	else:
		quest_resource.set_boiler_quest_pool_item_title(current_quest, current_stage, pool_idx, stage_title_ln_edt.text.strip_edges())
		quest_resource.set_boiler_quest_pool_item_description(current_quest, current_stage, pool_idx, stage_desc_txt_edt.text.strip_edges())
		quest_resource.set_boiler_quest_stage_pool_name(
				current_quest,
				current_stage,
				quest_tree.get_boiler_quest_pool_title(current_quest, current_stage))
		quest_resource.quests_boiler[current_quest]["stages"][current_stage]["pool_items"][pool_idx]["requirements"] = requirements_tree.get_requirements()


func load_resource() -> void:
	for quest in quest_resource.get_main_quests():
		quest_tree.create_main_quest(quest)
		
		for stage in range(quest_resource.get_main_quest_stage_count(quest)):
			quest_tree.create_main_stage(
					quest,
					quest_resource.get_main_quest_stage_title(quest, stage))
	
	for boil_quest in quest_resource.get_boiler_quests():
		quest_tree.create_boiler_quest(boil_quest)
		for stage in range(quest_resource.get_boiler_quest_stage_count(boil_quest)):
			quest_tree.create_boiler_stage_pool(
					boil_quest,
					quest_resource.get_boiler_quest_stage_pool_name(boil_quest, stage))
			for pool_itm in range(quest_resource.get_boiler_quest_stage_pool_size(boil_quest, stage)):
				quest_tree.create_boiler_stage(
						boil_quest,
						stage,
						quest_resource.get_boiler_quest_pool_item_title(boil_quest, stage, pool_itm))
	
	quest_tree.collapse_all()
	requirements_tree.collapse_all()
	
	quest_tree.unopened_main_quests.clear()
	quest_tree.unopened_boiler_quests.clear()


func has_unsaved_changes() -> bool:
	return _unsaved


func save() -> void:
	if not current_quest.is_empty():
		save_current_quest()
	quest_resource.save()
	_unsaved = false
	
