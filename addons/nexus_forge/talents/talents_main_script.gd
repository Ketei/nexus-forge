@tool
extends PanelContainer


const DATA_FLOAT_STEP: float = 0.01
const UNDO_MAX_STEPS: int = 50

var _skills_resource: SkillCatalog
var _traits_resource: TraitCatalog
var _stats_resource: StatCatalog

var _skills_unsaved: bool = false
var _traits_unsaved: bool = false
var _stats_unsaved: bool = false

var loaded_skill: StringName = &""
var loaded_trait: StringName = &""
var loaded_stat: StringName = &""

var undo: UndoRedo = null

@onready var skill_opt_btn: OptionButton = $MainContainer/StatSkillContainer/SkillsPanel/SkillsContainer/SkillSelectContainer/SkillContainer/SkillOptBtn
@onready var skill_ln_edt: LineEdit = $MainContainer/StatSkillContainer/SkillsPanel/SkillsContainer/NameContainer/SkillLnEdt
@onready var skill_desc_txt_edt: TextEdit = $MainContainer/StatSkillContainer/SkillsPanel/SkillsContainer/DesContainer/SkillDescTxtEdt
@onready var skill_data_tree: IDTree = $MainContainer/StatSkillContainer/SkillsPanel/SkillsContainer/DataContainer/SkillDataTree
@onready var skill_int_btn: Button = $MainContainer/StatSkillContainer/SkillsPanel/SkillsContainer/DataContainer/DataHeader/ButtonContainer/SkillIntBtn
@onready var skill_flt_btn: Button = $MainContainer/StatSkillContainer/SkillsPanel/SkillsContainer/DataContainer/DataHeader/ButtonContainer/SkillFltBtn
@onready var skill_bool_btn: Button = $MainContainer/StatSkillContainer/SkillsPanel/SkillsContainer/DataContainer/DataHeader/ButtonContainer/SkillBoolBtn
@onready var skill_str_btn: Button = $MainContainer/StatSkillContainer/SkillsPanel/SkillsContainer/DataContainer/DataHeader/ButtonContainer/SkillStrBtn
@onready var skill_dict_button: Button = $MainContainer/StatSkillContainer/SkillsPanel/SkillsContainer/DataContainer/DataHeader/ButtonContainer/AddDictButton

@onready var trait_opt_btn: OptionButton = $MainContainer/TraitsPanel/TraitsContainerContainer/TraitSelectContainer/TraitContainer/TraitOptBtn
@onready var trait_ln_edt: LineEdit = $MainContainer/TraitsPanel/TraitsContainerContainer/NameContainer/TraitLnEdt
@onready var trait_desc_txt_edt: TextEdit = $MainContainer/TraitsPanel/TraitsContainerContainer/DesContainer/TraitDescTxtEdt
@onready var trait_dict_btn: Button = $MainContainer/TraitsPanel/TraitsContainerContainer/DataContainer/DataHeader/ButtonContainer/TraitDictBtn
@onready var trait_int_btn: Button = $MainContainer/TraitsPanel/TraitsContainerContainer/DataContainer/DataHeader/ButtonContainer/TraitIntBtn
@onready var trait_flt_btn: Button = $MainContainer/TraitsPanel/TraitsContainerContainer/DataContainer/DataHeader/ButtonContainer/TraitFltBtn
@onready var trait_bool_btn: Button = $MainContainer/TraitsPanel/TraitsContainerContainer/DataContainer/DataHeader/ButtonContainer/TraitBoolBtn
@onready var trait_str_btn: Button = $MainContainer/TraitsPanel/TraitsContainerContainer/DataContainer/DataHeader/ButtonContainer/TraitStrBtn
@onready var trait_data_tree: Tree = $MainContainer/TraitsPanel/TraitsContainerContainer/DataContainer/TraitDataTree

@onready var stat_opt_btn: OptionButton = $MainContainer/StatSkillContainer/StatsPanel/StatsContainer/StatSelectContainer/StatContainer/StatOptBtn
@onready var stat_ln_edt: LineEdit = $MainContainer/StatSkillContainer/StatsPanel/StatsContainer/NameContainer/StatLnEdt
@onready var stat_desc_txt_edt: TextEdit = $MainContainer/StatSkillContainer/StatsPanel/StatsContainer/DesContainer/StatDescTxtEdt
@onready var stat_dict_button: Button = $MainContainer/StatSkillContainer/StatsPanel/StatsContainer/DataContainer/DataHeader/ButtonContainer/StatDictButton
@onready var stat_int_btn: Button = $MainContainer/StatSkillContainer/StatsPanel/StatsContainer/DataContainer/DataHeader/ButtonContainer/StatIntBtn
@onready var stat_flt_btn: Button = $MainContainer/StatSkillContainer/StatsPanel/StatsContainer/DataContainer/DataHeader/ButtonContainer/StatFltBtn
@onready var stat_bool_btn: Button = $MainContainer/StatSkillContainer/StatsPanel/StatsContainer/DataContainer/DataHeader/ButtonContainer/StatBoolBtn
@onready var stat_str_btn: Button = $MainContainer/StatSkillContainer/StatsPanel/StatsContainer/DataContainer/DataHeader/ButtonContainer/StatStrBtn
@onready var stat_data_tree: Tree = $MainContainer/StatSkillContainer/StatsPanel/StatsContainer/DataContainer/StatDataTree

@onready var edit_stats_btn: Button = $MainContainer/StatSkillContainer/StatsPanel/StatsContainer/StatSelectContainer/StatContainer/EditStatsBtn
@onready var edit_skills_btn: Button = $MainContainer/StatSkillContainer/SkillsPanel/SkillsContainer/SkillSelectContainer/SkillContainer/EditSkillsBtn
@onready var edit_traits_btn: Button = $MainContainer/TraitsPanel/TraitsContainerContainer/TraitSelectContainer/TraitContainer/EditTraitsBtn


func ready_plugin(stats_enabled: bool, skills_enabled: bool, traits_enabled: bool) -> void:
	undo = UndoRedo.new()
	undo.max_steps = UNDO_MAX_STEPS
	
	if stats_enabled:
		stat_data_tree.undo_redo_steps = UNDO_MAX_STEPS
		stat_data_tree.ready_plugin()
		reload_stats(true)
		reload_stat_resource(true)
	
	if skills_enabled:
		skill_data_tree.undo_redo_steps = UNDO_MAX_STEPS
		skill_data_tree.ready_plugin()
		reload_skills(false)
		reload_skill_resource(true)
	
	if traits_enabled:
		skill_data_tree.undo_redo_steps = UNDO_MAX_STEPS
		trait_data_tree.ready_plugin()
		reload_traits(false)
		reload_trait_resource(true)
	
	if not stats_enabled and not skills_enabled:
		$MainContainer/StatSkillContainer.visible = false
	else:
		if not stats_enabled:
			$MainContainer/StatSkillContainer/StatsPanel.visible = false
		if not skills_enabled:
			$MainContainer/StatSkillContainer/SkillsPanel.visible = false
	
	$MainContainer/TraitsPanel.visible = traits_enabled
	
	trait_dict_btn.icon = get_theme_icon("FolderCreate", "EditorIcons")
	skill_dict_button.icon = get_theme_icon("FolderCreate", "EditorIcons")
	stat_dict_button.icon = get_theme_icon("FolderCreate", "EditorIcons")
	edit_skills_btn.icon = get_theme_icon("Edit", "EditorIcons")
	edit_traits_btn.icon = get_theme_icon("Edit", "EditorIcons")
	edit_stats_btn.icon = get_theme_icon("Edit", "EditorIcons")
	
	skill_opt_btn.get_popup().max_size.y = 300
	trait_opt_btn.get_popup().max_size.y = 300
	skill_opt_btn.get_popup().max_size.y = 300
	
	stat_opt_btn.disabled = stat_opt_btn.item_count == 0 if stats_enabled else true
	skill_opt_btn.disabled = skill_opt_btn.item_count == 0 if skills_enabled else true
	trait_opt_btn.disabled = trait_opt_btn.item_count == 0 if traits_enabled else true
	
	set_skills_ui_enabled(0 < skill_opt_btn.item_count if skills_enabled else false)
	set_traits_ui_enabled(0 < trait_opt_btn.item_count if traits_enabled else false)
	set_stats_ui_enabled(0 < stat_opt_btn.item_count if stats_enabled else false)
	
	if stats_enabled:
		stat_ln_edt.text_changed.connect(_on_stats_changed)
		stat_ln_edt.editing_toggled.connect(_on_name_line_edit_toggled.bind(stat_ln_edt, 0))
		stat_desc_txt_edt.text_changed.connect(_on_stats_changed)
		stat_desc_txt_edt.focus_exited.connect(_on_text_edit_focus_lost.bind(stat_desc_txt_edt))
		stat_opt_btn.item_selected.connect(_on_stat_selected, CONNECT_DEFERRED)
		stat_int_btn.pressed.connect(_on_add_stat_data_pressed.bind("new_int", 0))
		stat_flt_btn.pressed.connect(_on_add_stat_data_pressed.bind("new_float", 0.0))
		stat_bool_btn.pressed.connect(_on_add_stat_data_pressed.bind("new_bool", false))
		stat_str_btn.pressed.connect(_on_add_stat_data_pressed.bind("new_string", ""))
		stat_dict_button.pressed.connect(_on_add_stat_data_pressed.bind("new_folder", {}))
		edit_stats_btn.pressed.connect(_on_edit_statblock_pressed)
		stat_data_tree.data_changed.connect(_on_data_tree_updated.bind(0))
	
	if skills_enabled:
		skill_ln_edt.text_changed.connect(_on_skills_changed)
		skill_ln_edt.editing_toggled.connect(_on_name_line_edit_toggled.bind(skill_ln_edt, 1))
		skill_desc_txt_edt.text_changed.connect(_on_skills_changed)
		skill_desc_txt_edt.focus_exited.connect(_on_text_edit_focus_lost.bind(skill_desc_txt_edt))
		skill_int_btn.pressed.connect(_on_add_skill_data_pressed.bind("new_int", 0))
		skill_flt_btn.pressed.connect(_on_add_skill_data_pressed.bind("new_float", 0.0))
		skill_bool_btn.pressed.connect(_on_add_skill_data_pressed.bind("new_bool", false))
		skill_str_btn.pressed.connect(_on_add_skill_data_pressed.bind("new_string", ""))
		skill_dict_button.pressed.connect(_on_add_skill_data_pressed.bind("new_folder", {}))
		skill_opt_btn.item_selected.connect(_on_skill_selected, CONNECT_DEFERRED)
		edit_skills_btn.pressed.connect(_on_edit_skillset_pressed)
		skill_data_tree.data_changed.connect(_on_data_tree_updated.bind(1))
	
	if traits_enabled:
		trait_ln_edt.text_changed.connect(_on_traits_changed)
		trait_ln_edt.editing_toggled.connect(_on_name_line_edit_toggled.bind(trait_ln_edt, 3))
		trait_desc_txt_edt.text_changed.connect(_on_traits_changed)
		trait_desc_txt_edt.focus_exited.connect(_on_text_edit_focus_lost.bind(trait_desc_txt_edt))
		trait_opt_btn.item_selected.connect(_on_trait_selected, CONNECT_DEFERRED)
		trait_int_btn.pressed.connect(_on_add_trait_data_pressed.bind("new_int", 0))
		trait_flt_btn.pressed.connect(_on_add_trait_data_pressed.bind("new_float", 0.0))
		trait_bool_btn.pressed.connect(_on_add_trait_data_pressed.bind("new_bool", false))
		trait_str_btn.pressed.connect(_on_add_trait_data_pressed.bind("new_string", ""))
		trait_dict_btn.pressed.connect(_on_add_trait_data_pressed.bind("new_folder", {}))
		edit_traits_btn.pressed.connect(_on_edit_traitblock_pressed)
		trait_data_tree.data_changed.connect(_on_data_tree_updated.bind(2))


func _input(event: InputEvent) -> void:
	if undo == null:
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
			else:
				if undo.has_undo():
					var action_name: String = undo.get_current_action_name()
					undo.undo()
					NFPluginGameHandler._log_msg(
							"",
							"Undo: " + action_name,
							NFPluginGameHandler._LogLevel.EDITOR)
		elif event.keycode == KEY_Y and not event.shift_pressed:
			if undo.has_redo():
					var action_name: String = undo.get_action_name(undo.get_current_action() + 1)
					undo.redo()
					NFPluginGameHandler._log_msg(
							"",
							"Redo: " + action_name,
							NFPluginGameHandler._LogLevel.EDITOR)


func _on_edit_skillset_pressed() -> void:
	EditorInterface.edit_script(SkillSet.new().get_script())
	if not EditorInterface.get_editor_settings().get_setting("text_editor/external/use_external_editor"):
		EditorInterface.set_main_screen_editor("Script")


func _on_edit_traitblock_pressed() -> void:
	EditorInterface.edit_script(TraitBlock.new().get_script())
	if not EditorInterface.get_editor_settings().get_setting("text_editor/external/use_external_editor"):
		EditorInterface.set_main_screen_editor("Script")


func _on_edit_statblock_pressed() -> void:
	EditorInterface.edit_script(StatBlock.new().get_script())
	if not EditorInterface.get_editor_settings().get_setting("text_editor/external/use_external_editor"):
		EditorInterface.set_main_screen_editor("Script")


func reload_skill_resource(first_launch: bool = false) -> void:
	var was_null: bool = _skills_resource == null
	_skills_resource = null
	var skills_path: String = ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("skills"),
			"")
	
	if not skills_path.is_empty() and ResourceLoader.exists(skills_path):
		var preload_skill_res: Resource = load(skills_path)
		if preload_skill_res is SkillCatalog:
			_skills_resource = preload_skill_res
	
	if _skills_resource == null:
		if not was_null or first_launch:
			$MainContainer/StatSkillContainer/SkillsPanel/SkillsContainer.visible = false
			var no_db: Control = load("res://addons/nexus_forge/no_db_container.tscn").instantiate()
			$MainContainer/StatSkillContainer/SkillsPanel.add_child(no_db)
			no_db.message_minimum_size.x = 450
			no_db.set_resource_type("SkillCatalog", "Skills", "Skills")
			no_db.create_resource_pressed.connect(_on_create_skill_resource_pressed.bind(no_db))
			no_db.load_resource_pressed.connect(_on_load_skill_resource_pressed.bind(no_db))
			no_db.resource_dropped.connect(_on_skill_resource_dropped.bind(no_db))
	else:
		$MainContainer/StatSkillContainer/SkillsPanel/SkillsContainer.visible = true
		load_skills_resource()


func reload_trait_resource(first_launch: bool = false) -> void:
	var was_null: bool = _traits_resource == null
	_traits_resource = null
	trait_ln_edt.text = ""
	trait_desc_txt_edt.text = ""
	trait_data_tree.clear_data()

	var traits_path: String = ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("traits"),
			"")
	
	if not traits_path.is_empty() and ResourceLoader.exists(traits_path):
		var preload_traits_res = load(traits_path)
		if preload_traits_res is TraitCatalog:
			_traits_resource = preload_traits_res
	
	if _traits_resource == null:
		if not was_null or first_launch:
			$MainContainer/TraitsPanel/TraitsContainerContainer.visible = false
			var no_db: Control = load("res://addons/nexus_forge/no_db_container.tscn").instantiate()
			$MainContainer/TraitsPanel.add_child(no_db)
			no_db.message_minimum_size.x = 450
			no_db.set_resource_type("TraitCatalog", "Traits", "Traits")
			no_db.create_resource_pressed.connect(_on_create_traits_resource_pressed.bind(no_db))
			no_db.load_resource_pressed.connect(_on_load_traits_resource_pressed.bind(no_db))
			no_db.resource_dropped.connect(_on_traits_resource_dropped.bind(no_db))
	else:
		$MainContainer/TraitsPanel/TraitsContainerContainer.visible = true
		load_traits_resource()


func reload_stat_resource(first_launch: bool = false) -> void:
	var was_null: bool = _stats_resource == null
	_stats_resource = null
	stat_ln_edt.text = ""
	stat_desc_txt_edt.text = ""
	stat_data_tree.clear_data()

	var stats_path: String = ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("stats"),
			"")
	if not stats_path.is_empty() and ResourceLoader.exists(stats_path):
		var preload_stats_res = load(stats_path)
		if preload_stats_res != null and preload_stats_res is StatCatalog:
			_stats_resource = preload_stats_res
	
	if _stats_resource == null:
		if not was_null or first_launch:
			$MainContainer/StatSkillContainer/StatsPanel/StatsContainer.visible = false
			var no_db: Control = load("res://addons/nexus_forge/no_db_container.tscn").instantiate()
			$MainContainer/StatSkillContainer/StatsPanel.add_child(no_db)
			no_db.message_minimum_size.x = 450
			no_db.set_resource_type("StatCatalog", "Stats", "Stats")
			no_db.create_resource_pressed.connect(_on_create_stat_resource_pressed.bind(no_db))
			no_db.load_resource_pressed.connect(_on_load_stat_resource_pressed.bind(no_db))
			no_db.resource_dropped.connect(_on_stat_resource_dropped.bind(no_db))
	else:
		$MainContainer/StatSkillContainer/StatsPanel/StatsContainer.visible = true
		load_stats_resource()


#region Skills

func _on_create_skill_resource_pressed(panel: PanelContainer) -> void:
	var res_loader: FileDialog = load("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	res_loader.file_mode = res_loader.FILE_MODE_SAVE_FILE
	res_loader.title = "Create Talents"
	res_loader.ok_button_text = "Save"
	add_child(res_loader)
	res_loader.show()
	
	var result = await res_loader.dialog_finished
	
	if result[0]:
		_skills_resource = SkillCatalog.new()
		ResourceSaver.save(_skills_resource, result[1])
		_skills_resource.resource_path = result[1]
		if ResourceLoader.has_cached(result[1]):
			_skills_resource.take_over_path(result[1])
		ProjectSettings.set_setting(
				NFPluginGameHandler.get_setting_path("skills"),
				result[1])
		if Engine.is_editor_hint():
			ProjectSettings.save()
		$MainContainer/StatSkillContainer/SkillsPanel/SkillsContainer.visible = true
		panel.visible = false
		panel.queue_free()
		load_skills_resource()
	
	res_loader.queue_free()


func _on_load_skill_resource_pressed(panel: PanelContainer) -> void:
	var res_loader: FileDialog = load("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	res_loader.file_mode = res_loader.FILE_MODE_OPEN_FILE
	res_loader.title = "Open Talents"
	res_loader.ok_button_text = "Load"
	add_child(res_loader)
	res_loader.show()
	
	var result = await res_loader.dialog_finished
	
	if result[0]:
		var res_pre: Resource = load(result[1])
		if res_pre != null and res_pre is SkillCatalog:
			_skills_resource = res_pre
			ProjectSettings.set_setting(
					NFPluginGameHandler.get_setting_path("skills"),
					result[1])
			if Engine.is_editor_hint():
				ProjectSettings.save()
			$MainContainer/StatSkillContainer/SkillsPanel/SkillsContainer.visible = true
			panel.visible = false
			panel.queue_free()
			load_skills_resource()
	
	res_loader.queue_free()


func _on_skill_resource_dropped(resource: Resource, panel: Control) -> void:
	_skills_resource = resource
	ProjectSettings.set_setting(
			NFPluginGameHandler.get_setting_path("skills"),
			resource.resource_path)
	if Engine.is_editor_hint():
		ProjectSettings.save()
	panel.visible = false
	panel.queue_free()
	$MainContainer/StatSkillContainer/SkillsPanel/SkillsContainer.visible = true
	load_skills_resource()



func _on_add_skill_data_pressed(data_name: String, data: Variant) -> void:
	skill_data_tree.add_data(data_name, data)
	if skill_data_tree.has_undo():
		undo.create_action("Data Changed")
		undo.add_do_method(skill_data_tree.redo)
		undo.add_undo_method(skill_data_tree.undo)
		undo.commit_action(false)
	_on_skills_changed()


func _on_skill_selected(skill_idx: int) -> void:
	if not loaded_skill.is_empty():
		save_current_skill()
	
	var target_skill: StringName = skill_opt_btn.get_item_metadata(skill_idx)
	var valid_id: bool = skill_idx != -1
	var disabled = not valid_id
	
	skill_ln_edt.editable = valid_id
	skill_desc_txt_edt.editable = valid_id
	
	skill_int_btn.disabled = disabled
	skill_flt_btn.disabled = disabled
	skill_bool_btn.disabled = disabled
	skill_str_btn.disabled = disabled
	skill_dict_button.disabled = disabled
	
	if disabled:
		skill_ln_edt.clear()
		skill_desc_txt_edt.clear()
		skill_data_tree.clear_data()
		loaded_skill = &""
		return
	
	load_skill(target_skill)
	loaded_skill = target_skill


func load_skill(skill_id: StringName) -> void:
	var skill_name: String = _skills_resource.get_skill_name(skill_id)
	var skill_desc: String = _skills_resource.get_skill_description(skill_id)
	var data: Dictionary = DictUtils.get_nested_value(
			_skills_resource._skill_data,
			[skill_id, "data"],
			{},
			true)
	
	skill_ln_edt.text = skill_name
	skill_ln_edt.set_meta(&"old_value", skill_name)
	
	skill_desc_txt_edt.text = skill_desc
	skill_desc_txt_edt.set_meta(&"old_value", skill_desc)
	
	skill_data_tree.clear_data(false)
	
	for data_key in data.keys():
		skill_data_tree.add_data(
			data_key,
			data[data_key],
			true)


func load_skills_resource() -> void:
	skill_ln_edt.text = ""
	skill_data_tree.clear_data()
	
	var skills_exist: bool = 0 < skill_opt_btn.item_count
	var disabled: bool = not skills_exist
	
	
	var all_skills: Array[StringName] = SkillSet.skills()
	
	for skill in _skills_resource._skill_data.keys():
		if all_skills.has(skill):
			continue
		_skills_resource._skill_data.erase(skill)
	
	for new_skill in all_skills:
		if _skills_resource._skill_data.has(new_skill):
			continue
		var data: Dictionary[String, Variant] = {}
		_skills_resource._skill_data[new_skill] = {
			"name": "",
			"description": "",
			"data": data}
	
	skill_ln_edt.editable = skills_exist
	skill_desc_txt_edt.editable = skills_exist
	
	skill_int_btn.disabled = disabled
	skill_flt_btn.disabled = disabled
	skill_bool_btn.disabled = disabled
	skill_str_btn.disabled = disabled
	skill_dict_button.disabled = disabled
	
	if skills_exist:
		skill_opt_btn.select(0)
		load_skill(skill_opt_btn.get_item_metadata(0))
		loaded_skill = skill_opt_btn.get_item_metadata(0)


func sort_skills(reselect: bool = true) -> void:
	if skill_opt_btn.item_count <= 1:
		return
	var skills: Array[StringName] = []
	var current_skill: StringName = &"" if skill_opt_btn.selected == -1 else skill_opt_btn.get_item_metadata(skill_opt_btn.selected)
	var new_index: int = -1
	
	for item_idx in range(skill_opt_btn.item_count):
		skills.append(skill_opt_btn.get_item_metadata(item_idx))
	
	skills.sort_custom(func (a,b) -> bool: return String(a).naturalnocasecmp_to(String(b)) < 0)
	
	skill_opt_btn.clear()
	
	var idx: int = -1
	for skill_id in skills:
		idx += 1
		skill_opt_btn.add_item(String(skill_id))
		skill_opt_btn.set_item_metadata(idx, skill_id)
		if skill_id == current_skill:
			new_index = idx
	
	if reselect and new_index != -1:
		skill_opt_btn.select(new_index)


func set_skills_ui_enabled(set_enabled: bool) -> void:
	var disabled: bool = not set_enabled
	
	skill_desc_txt_edt.editable = set_enabled
	skill_int_btn.disabled = disabled
	skill_flt_btn.disabled = disabled
	skill_bool_btn.disabled = disabled
	skill_str_btn.disabled = disabled
	skill_dict_button.disabled = disabled
	skill_data_tree.enabled = set_enabled


# Use for comparing what skills exists when SkillSet is saved/changed.
func loaded_skills() -> Dictionary[String, int]:
	var all_skills: Dictionary[String, int]
	for skill_idx in range(skill_opt_btn.item_count):
		all_skills[String(skill_opt_btn.get_item_metadata(skill_idx))] = skill_idx
	return all_skills


# Call when SkillSet is saved/changed.
func reload_skills(reselect: bool = true) -> void:
	var current_skill: StringName = &"" if skill_opt_btn.selected == -1 else skill_opt_btn.get_item_metadata(skill_opt_btn.selected)
	
	var all_skills: Array[StringName] = SkillSet.skills()
	
	all_skills.sort_custom(func(a,b): return String(a).naturalnocasecmp_to(String(b)) < 0)
	var new_index: int = all_skills.find(current_skill) if reselect else -1
	
	if _skills_resource != null:
		for skill in _skills_resource.skills():
			if all_skills.has(skill):
				continue
			_skills_resource._skill_data.erase(skill)
	
	skill_opt_btn.clear()
	for skill in all_skills:
		skill_opt_btn.add_item(
				String(skill).capitalize())
		skill_opt_btn.set_item_metadata(-1, skill)
		
		if _skills_resource != null:
			if _skills_resource._skill_data.has(skill):
				continue
			var data: Dictionary[String, Variant] = {}
			data.assign(_skills_resource.DEFAULT_DATA.duplicate(true))
			_skills_resource._skill_data[skill] = {
				"name": "",
				"description": "",
				"data": data}
	
	if _skills_resource == null:
		return
	
	skill_opt_btn.disabled = skill_opt_btn.item_count == 0
	set_skills_ui_enabled(0 < skill_opt_btn.item_count)
	
	if new_index != -1:
		skill_opt_btn.select(new_index)
	else:
		if skill_opt_btn.item_count != 0:
			skill_opt_btn.select(0)
			load_skill(skill_opt_btn.get_item_metadata(0))
			loaded_skill = skill_opt_btn.get_item_metadata(0)

#endregion


#region Traits

func _on_create_traits_resource_pressed(panel: PanelContainer) -> void:
	var res_loader: FileDialog = load("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	res_loader.file_mode = res_loader.FILE_MODE_SAVE_FILE
	res_loader.title = "Create StatBlock"
	res_loader.ok_button_text = "Save"
	add_child(res_loader)
	res_loader.show()
	
	var result = await res_loader.dialog_finished
	
	if result[0]:
		_traits_resource = TraitCatalog.new()
		ResourceSaver.save(_traits_resource, result[1])
		_traits_resource.resource_path = result[1]
		if ResourceLoader.has_cached(result[1]):
			_traits_resource.take_over_path(result[1])
		ProjectSettings.set_setting(
				NFPluginGameHandler.get_setting_path("traits"),
				result[1])
		if Engine.is_editor_hint():
			ProjectSettings.save()
		$MainContainer/TraitsPanel/TraitsContainerContainer.visible = true
		panel.visible = false
		panel.queue_free()
		reload_traits(false)
		load_traits_resource()
	
	res_loader.queue_free()


func _on_load_traits_resource_pressed(panel: PanelContainer) -> void:
	var res_loader: FileDialog = load("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	res_loader.file_mode = res_loader.FILE_MODE_OPEN_FILE
	res_loader.title = "Open Talents"
	res_loader.ok_button_text = "Load"
	add_child(res_loader)
	res_loader.show()
	
	var result = await res_loader.dialog_finished
	
	if result[0]:
		var res_pre: Resource = load(result[1])
		if res_pre != null and res_pre is TraitCatalog:
			_traits_resource = res_pre
			ProjectSettings.set_setting(
					NFPluginGameHandler.get_setting_path("traits"),
					result[1])
			if Engine.is_editor_hint():
				ProjectSettings.save()
			$MainContainer/TraitsPanel/TraitsContainerContainer.visible = true
			panel.visible = false
			panel.queue_free()
			reload_traits(false)
			load_traits_resource()
	
	res_loader.queue_free()


func _on_traits_resource_dropped(resource: Resource, panel: Control) -> void:
	_traits_resource = resource
	ProjectSettings.set_setting(
			NFPluginGameHandler.get_setting_path("traits"),
			resource.resource_path)
	if Engine.is_editor_hint():
		ProjectSettings.save()
	panel.visible = false
	panel.queue_free()
	$MainContainer/TraitsPanel/TraitsContainerContainer.visible = true
	reload_traits(false)
	load_traits_resource()


func _on_add_trait_data_pressed(data_name: String, data: Variant) -> void:
	trait_data_tree.add_data(data_name, data)
	if trait_data_tree.has_undo():
		undo.create_action("Data Changed")
		undo.add_do_method(trait_data_tree.redo)
		undo.add_undo_method(trait_data_tree.undo)
		undo.commit_action(false)
	_on_traits_changed()


func _on_trait_selected(trait_idx: int) -> void:
	if not loaded_trait.is_empty():
		save_current_trait()
	
	var disabled: bool = trait_idx == -1
	
	trait_int_btn.disabled = disabled
	trait_flt_btn.disabled = disabled
	trait_bool_btn.disabled = disabled
	trait_str_btn.disabled = disabled
	trait_dict_btn.disabled = disabled
	
	if disabled:
		trait_ln_edt.clear()
		trait_desc_txt_edt.clear()
		trait_data_tree.clear_data()
		loaded_trait = &""
		return
	
	loaded_trait = trait_opt_btn.get_item_metadata(trait_idx)
	load_trait(loaded_trait)


func load_trait(trait_id: StringName) -> void:
	var trait_name: String = _traits_resource.get_trait_name(trait_id)
	var trait_desc: String = _traits_resource.get_trait_description(trait_id)
	var data: Dictionary = DictUtils.get_nested_value(
			_traits_resource._trait_data,
			[trait_id, "data"],
			{},
			true)
	
	trait_ln_edt.text = trait_name
	trait_ln_edt.set_meta(&"old_value", trait_name)
	
	trait_desc_txt_edt.text = trait_desc
	trait_desc_txt_edt.set_meta(&"old_value", trait_desc)
	
	trait_data_tree.clear_data(false)
	
	for data_key in data.keys():
		trait_data_tree.add_data(
			data_key,
			data[data_key],
			true)


func set_traits_ui_enabled(enabled: bool) -> void:
	var disabled: bool = not enabled
	trait_ln_edt.editable = enabled
	trait_desc_txt_edt.editable = enabled
	
	trait_int_btn.disabled = disabled
	trait_flt_btn.disabled = disabled
	trait_bool_btn.disabled = disabled
	trait_str_btn.disabled = disabled
	trait_data_tree.enabled = enabled


func save_current_trait() -> void:
	if loaded_trait.is_empty() or _traits_resource == null:
		return
	
	var target: Dictionary = {}
	
	if _traits_resource._trait_data.has(loaded_trait):
		target = _traits_resource._trait_data[loaded_trait]
	else:
		_traits_resource._trait_data[loaded_trait] = target
	
	target["name"] = trait_ln_edt.text.strip_edges()
	target["description"] = trait_desc_txt_edt.text.strip_edges()
	target["data"] = trait_data_tree.get_data()


func load_traits_resource() -> void:
	var traits_exist: bool = 0 < trait_opt_btn.item_count
	var disabled: bool = not traits_exist
	
	trait_ln_edt.text = ""
	trait_data_tree.clear_data()
	
	trait_opt_btn.disabled = disabled
	trait_ln_edt.editable = traits_exist
	trait_desc_txt_edt.editable = traits_exist
	
	trait_int_btn.disabled = disabled
	trait_flt_btn.disabled = disabled
	trait_bool_btn.disabled = disabled
	trait_str_btn.disabled = disabled
	trait_dict_btn.disabled = disabled
	
	var all_traits: Array[StringName] = TraitBlock.traits()
	
	for existing_trait in _traits_resource._trait_data.keys():
		if all_traits.has(existing_trait):
			continue
		_traits_resource._trait_data.erase(existing_trait)
	
	for new_trait in all_traits:
		if _traits_resource._trait_data.has(new_trait):
			continue
		else:
			var data: Dictionary[String, Variant] = {}
			_traits_resource._trait_data[new_trait] = {
				"name": "",
				"description": "",
				"data": data}
	
	if traits_exist:
		trait_opt_btn.select(0)
		load_trait(trait_opt_btn.get_item_metadata(0))
		loaded_trait = trait_opt_btn.get_item_metadata(0)


func sort_traits(reselect: bool = true) -> void:
	if trait_opt_btn.item_count <= 1:
		return
	var traits: Array[StringName] = []
	var selected: StringName = &"" if trait_opt_btn.selected == -1 else trait_opt_btn.get_item_metadata(trait_opt_btn.selected)
	var new_idx: int = -1
	
	for item_idx in range(trait_opt_btn.item_count):
		traits.append(trait_opt_btn.get_item_metadata(item_idx))
	
	traits.sort_custom(func (a,b) -> bool: return String(a).naturalnocasecmp_to(String(b)) < 0)
	
	trait_opt_btn.clear()
	
	var idx: int = -1
	for trait_id in traits:
		idx += 1
		trait_opt_btn.add_item(String(trait_id))
		trait_opt_btn.set_item_metadata(idx, trait_id)
		if trait_id == selected:
			new_idx = idx
	
	if reselect and new_idx != -1:
		trait_opt_btn.select(new_idx)


# Use for comparing what skills exists when TraitBlock is saved/changed.
func loaded_traits() -> Dictionary[String, int]:
	var all_traits: Dictionary[String, int] = {}
	for trait_idx in range(trait_opt_btn.item_count):
		all_traits[String(trait_opt_btn.get_item_metadata(trait_idx))] = trait_idx
	return all_traits


# Call when TraitBlock is saved/changed.
func reload_traits(reselect: bool = true) -> void:
	var current_trait: StringName = &"" if trait_opt_btn.selected == -1 else trait_opt_btn.get_item_metadata(trait_opt_btn.selected)
	
	var all_traits: Array[StringName] = TraitBlock.traits()
	
	all_traits.sort_custom(func(a,b): return String(a).naturalnocasecmp_to(String(b)) < 0)
	var new_index: int = all_traits.find(current_trait) if reselect else -1
	
	if _traits_resource != null:
		for existing_trait in _traits_resource._trait_data.keys():
			if all_traits.has(existing_trait):
				continue
			_traits_resource._trait_data.erase(existing_trait)
	
	trait_opt_btn.clear()
	for trait_id in all_traits:
		trait_opt_btn.add_item(
				String(trait_id).capitalize())
		trait_opt_btn.set_item_metadata(-1, trait_id)
		
		if _traits_resource != null:
			if _traits_resource._trait_data.has(trait_id):
				continue
			var data: Dictionary[String, Variant] = {}
			_traits_resource._trait_data[trait_id] = {
				"name": "",
				"description": "",
				"data": data}
	
	if _traits_resource == null:
		return
	
	trait_opt_btn.disabled = trait_opt_btn.item_count == 0
	set_traits_ui_enabled(0 < trait_opt_btn.item_count)
	
	if new_index != -1:
		trait_opt_btn.select(new_index)
	else:
		if trait_opt_btn.item_count != 0:
			trait_opt_btn.select(0)
			load_trait(trait_opt_btn.get_item_metadata(0))
			loaded_trait = trait_opt_btn.get_item_metadata(0)


#endregion


#region Stats

func _on_create_stat_resource_pressed(panel: PanelContainer) -> void:
	var res_loader: FileDialog = load("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	res_loader.file_mode = res_loader.FILE_MODE_SAVE_FILE
	res_loader.title = "Create Stats"
	res_loader.ok_button_text = "Save"
	add_child(res_loader)
	res_loader.show()
	
	var result = await res_loader.dialog_finished
	
	if result[0]:
		_stats_resource = StatCatalog.new()
		ResourceSaver.save(_stats_resource, result[1])
		_stats_resource.resource_path = result[1]
		if ResourceLoader.has_cached(result[1]):
			_stats_resource.take_over_path(result[1])
		ProjectSettings.set_setting(
				NFPluginGameHandler.get_setting_path("stats"),
				result[1])
		if Engine.is_editor_hint():
			ProjectSettings.save()
		$MainContainer/StatSkillContainer/StatsPanel/StatsContainer.visible = true
		panel.visible = false
		panel.queue_free()
		load_stats_resource()
	
	res_loader.queue_free()


func _on_load_stat_resource_pressed(panel: PanelContainer) -> void:
	var res_loader: FileDialog = load("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	res_loader.file_mode = res_loader.FILE_MODE_OPEN_FILE
	res_loader.title = "Open Stats"
	res_loader.ok_button_text = "Load"
	add_child(res_loader)
	res_loader.show()
	
	var result = await res_loader.dialog_finished
	
	if result[0]:
		var res_pre: Resource = load(result[1])
		if res_pre != null and res_pre is StatCatalog:
			_stats_resource = res_pre
			ProjectSettings.set_setting(
					NFPluginGameHandler.get_setting_path("stats"),
					result[1])
			if Engine.is_editor_hint():
				ProjectSettings.save()
			$MainContainer/StatSkillContainer/StatsPanel/StatsContainer.visible = true
			panel.visible = false
			panel.queue_free()
			load_stats_resource()
	
	res_loader.queue_free()


func _on_stat_resource_dropped(resource: Resource, panel: Control) -> void:
	_stats_resource = resource
	ProjectSettings.set_setting(
			NFPluginGameHandler.get_setting_path("stats"),
			resource.resource_path)
	if Engine.is_editor_hint():
		ProjectSettings.save()
	panel.visible = false
	panel.queue_free()
	$MainContainer/StatSkillContainer/StatsPanel/StatsContainer.visible = true
	load_skills_resource()


func _on_add_stat_data_pressed(data_name: String, data: Variant) -> void:
	stat_data_tree.add_data(data_name, data)
	if stat_data_tree.has_undo():
		undo.create_action("Data Changed")
		undo.add_do_method(stat_data_tree.redo)
		undo.add_undo_method(stat_data_tree.undo)
		undo.commit_action(false)
	_on_stats_changed()


func _on_stat_selected(stat_idx: int) -> void:
	if not loaded_stat.is_empty():
		save_current_stat()
	
	var target_stat: StringName = stat_opt_btn.get_item_metadata(stat_idx)
	
	var valid_id: bool = stat_idx != -1
	var disabled = not valid_id
	
	stat_ln_edt.editable = valid_id
	stat_desc_txt_edt.editable = valid_id
	
	stat_int_btn.disabled = disabled
	stat_flt_btn.disabled = disabled
	stat_bool_btn.disabled = disabled
	stat_str_btn.disabled = disabled
	stat_dict_button.disabled = disabled
	
	if disabled:
		stat_ln_edt.clear()
		stat_desc_txt_edt.clear()
		stat_data_tree.clear_data()
		loaded_stat = &""
		return
	
	load_stat(target_stat)
	loaded_stat = target_stat


func load_stat(stat_id: StringName) -> void:
	var stat_name: String = _stats_resource.get_stat_name(stat_id)
	var stat_desc: String = _stats_resource.get_stat_description(stat_id)
	var data: Dictionary = DictUtils.get_nested_value(
			_stats_resource._stat_data,
			[stat_id, "data"],
			{},
			true)
	
	stat_ln_edt.text = stat_name
	stat_ln_edt.set_meta(&"old_value", stat_name)
	
	stat_desc_txt_edt.text = stat_desc
	stat_desc_txt_edt.set_meta(&"old_value", stat_desc)
	
	stat_data_tree.clear_data(false)
	
	for data_key in data.keys():
		stat_data_tree.add_data(
			data_key,
			data[data_key],
			true)


func load_stats_resource() -> void:
	stat_ln_edt.text = ""
	stat_data_tree.clear_data()
	
	var stat_exist: bool = 0 < stat_opt_btn.item_count
	var disabled: bool = not stat_exist
	
	var stat_entries: Dictionary[StringName, int] = StatBlock.stats()
	var all_stats: Array[StringName] = []
	all_stats.assign(stat_entries.keys())
	
	for stat in _stats_resource._stat_data.keys():
		if all_stats.has(stat):
			continue
		_stats_resource._stat_data.erase(stat)
	
	for new_stat in all_stats:
		if _stats_resource._stat_data.has(new_stat):
			continue
		var data: Dictionary[String, Variant] = {}
		_stats_resource._stat_data[new_stat] = {
			"name": "",
			"description": "",
			"data": data}
	
	stat_ln_edt.editable = stat_exist
	stat_desc_txt_edt.editable = stat_exist
	
	stat_int_btn.disabled = disabled
	stat_flt_btn.disabled = disabled
	stat_bool_btn.disabled = disabled
	stat_str_btn.disabled = disabled
	stat_dict_button.disabled = disabled
	
	if stat_exist:
		stat_opt_btn.select(0)
		load_stat(stat_opt_btn.get_item_metadata(0))
		loaded_stat = stat_opt_btn.get_item_metadata(0)


func sort_stats(reselect: bool = true) -> void:
	if stat_opt_btn.item_count <= 1:
		return
	var stats: Array[StringName] = []
	var current_stat: StringName = &"" if stat_opt_btn.selected == -1 else stat_opt_btn.get_item_metadata(stat_opt_btn.selected)
	var new_index: int = -1
	
	for item_idx in range(stat_opt_btn.item_count):
		stats.append(stat_opt_btn.get_item_metadata(item_idx))
	
	stats.sort_custom(func (a,b) -> bool: return String(a).naturalnocasecmp_to(String(b)) < 0)
	
	stat_opt_btn.clear()
	
	var idx: int = -1
	for stat_id in stats:
		idx += 1
		skill_opt_btn.add_item(String(stat_id))
		skill_opt_btn.set_item_metadata(idx, stat_id)
		if stat_id == current_stat:
			new_index = idx
	
	if reselect and new_index != -1:
		stat_opt_btn.select(new_index)


func set_stats_ui_enabled(set_enabled: bool) -> void:
	var disabled: bool = not set_enabled
	
	stat_desc_txt_edt.editable = set_enabled
	stat_int_btn.disabled = disabled
	stat_flt_btn.disabled = disabled
	stat_bool_btn.disabled = disabled
	stat_str_btn.disabled = disabled
	stat_dict_button.disabled = disabled
	stat_data_tree.enabled = set_enabled


# Use for comparing what skills exists when SkillSet is saved/changed.
func loaded_stats() -> Dictionary[String, int]:
	var all_stats: Dictionary[String, int]
	for stat_idx in range(stat_opt_btn.item_count):
		all_stats[String(stat_opt_btn.get_item_metadata(stat_idx))] = stat_idx
	return all_stats


# Call when SkillSet is saved/changed.
func reload_stats(reselect: bool = true) -> void:
	var current_stat: StringName = &"" if stat_opt_btn.selected == -1 else stat_opt_btn.get_item_metadata(stat_opt_btn.selected)
	
	var existing_stats: Dictionary[StringName, int] = StatBlock.stats()
	var all_stats: Array[StringName] = []
	all_stats.assign(existing_stats.keys())
	
	all_stats.sort_custom(func(a,b): return String(a).naturalnocasecmp_to(String(b)) < 0)
	var new_index: int = all_stats.find(current_stat) if reselect else -1
	
	if _stats_resource != null:
		for stat in _stats_resource.stats():
			if all_stats.has(stat):
				continue
			_stats_resource._stat_data.erase(stat)
	
	stat_opt_btn.clear()
	for stat in all_stats:
		stat_opt_btn.add_item(
				String(stat).capitalize())
		stat_opt_btn.set_item_metadata(-1, stat)
		
		if _stats_resource != null:
			if _stats_resource._stat_data.has(stat):
				continue
			var data: Dictionary[String, Variant] = {}
			data.assign(_stats_resource.DEFAULT_DATA.duplicate(true))
			_stats_resource._stat_data[stat] = {
				"name": "",
				"description": "",
				"data": data}
	
	if _stats_resource == null:
		return
	
	stat_opt_btn.disabled = stat_opt_btn.item_count == 0
	set_stats_ui_enabled((0 < stat_opt_btn.item_count))
	
	if new_index != -1:
		stat_opt_btn.select(new_index)
	else:
		if stat_opt_btn.item_count != 0:
			stat_opt_btn.select(0)
			load_stat(stat_opt_btn.get_item_metadata(0))
			loaded_stat = stat_opt_btn.get_item_metadata(0)


func select_stat(stat_id: StringName) -> bool:
	if loaded_stat == stat_id:
		return true
	
	var missing: bool = true
	for idx in range(stat_opt_btn.item_count):
		if stat_opt_btn.get_item_metadata(idx) == stat_id:
			stat_opt_btn.select(idx)
			missing = false
			break
	
	if missing:
		return false
	if not loaded_stat.is_empty():
		save_current_stat()
	load_stat(stat_id)
	loaded_stat = stat_id
	return true


func select_skill(skill_id: StringName) -> bool:
	if loaded_skill == skill_id:
		return true
	
	var missing: bool = true
	for idx in range(skill_opt_btn.item_count):
		if skill_opt_btn.get_item_metadata(idx) == skill_id:
			skill_opt_btn.select(idx)
			missing = false
			return true
	if missing:
		return false
	if not loaded_skill.is_empty():
		save_current_skill()
	load_skill(skill_id)
	loaded_skill = skill_id
	return true


func select_trait(trait_id: StringName) -> bool:
	if loaded_trait == trait_id:
		return true
	var missing: bool = true
	for idx in range(trait_opt_btn.item_count):
		if trait_opt_btn.get_item_metadata(idx) == trait_id:
			trait_opt_btn.select(idx)
			missing = false
	if missing:
		return false
	
	if not loaded_trait.is_empty():
		save_current_trait()
	load_trait(trait_id)
	loaded_trait = trait_id
	return true

#endregion


func _on_stats_changed(_arg = null) -> void:
	if _stats_unsaved:
		return
	_stats_unsaved = true


func _on_skills_changed(_arg = null) -> void:
	if _skills_unsaved:
		return
	_skills_unsaved = true


func _on_traits_changed(_arg = null) -> void:
	if _traits_unsaved:
		return
	_traits_unsaved = true


func _on_name_line_edit_toggled(toggled: bool, line: LineEdit, type: int) -> void:
	if toggled:
		return
	var old_name: String = line.get_meta(&"old_value")
	var new_name: String = line.text
	
	if new_name == old_name:
		return
	
	line.set_meta(&"old_value", new_name)
	var action_name: String = "Set %s Name" % String(loaded_stat if type == 0 else loaded_skill if type == 1 else loaded_trait).capitalize()
	
	if type == 0:
		undo.create_action(action_name)
		undo.add_do_method(_do_update_stat.bind(loaded_stat, new_name))
		undo.add_undo_method(_do_update_stat.bind(loaded_stat, old_name))
		undo.commit_action(false)
		_on_stats_changed()
	elif type == 1:
		undo.create_action(action_name)
		undo.add_do_method(_do_update_skill.bind(loaded_skill, new_name))
		undo.add_undo_method(_do_update_skill.bind(loaded_skill, old_name))
		undo.commit_action(false)
		_on_skills_changed()
	else:
		undo.create_action(action_name)
		undo.add_do_method(_do_update_trait.bind(loaded_trait, new_name))
		undo.add_undo_method(_do_update_trait.bind(loaded_trait, old_name))
		undo.commit_action(false)
		_on_traits_changed()


func _on_text_edit_focus_lost(text: TextEdit) -> void:
	var mode: int = 0
	
	if text == stat_desc_txt_edt:
		mode = 0
	elif text == skill_desc_txt_edt:
		mode = 1
	else:
		mode = 2
	
	var old_text: String = text.get_meta(&"old_value")
	var new_text: String = text.text
	
	if new_text == old_text:
		return
	
	text.set_meta(&"old_value", new_text)
	undo.create_action("Set %s Description" % String(
			loaded_stat if mode == 0 else\
			loaded_skill if mode == 1 else\
			loaded_trait).capitalize())
	
	match mode:
		0:
			undo.add_do_method(_do_update_stat_description.bind(loaded_stat, new_text))
			undo.add_undo_method(_do_update_stat_description.bind(loaded_stat, old_text))
			undo.commit_action(false)
			_on_stats_changed()
		1:
			undo.add_do_method(_do_update_skill_description.bind(loaded_skill, new_text))
			undo.add_undo_method(_do_update_skill_description.bind(loaded_skill, old_text))
			undo.commit_action(false)
			_on_skills_changed()
		2:
			undo.add_do_method(_do_update_trait_description.bind(loaded_trait, new_text))
			undo.add_undo_method(_do_update_trait_description.bind(loaded_trait, old_text))
			undo.commit_action(false)
			_on_traits_changed()


func _do_update_stat_description(stat_id: StringName, to: String) -> void:
	if loaded_stat != stat_id:
		if not select_stat(stat_id):
			return
	stat_desc_txt_edt.text = to
	_on_stats_changed()


func _do_update_skill_description(skill_id: StringName, to: String) -> void:
	if loaded_skill != skill_id:
		if not select_skill(skill_id):
			return
	skill_desc_txt_edt.text = to
	_on_skills_changed()


func _do_update_trait_description(trait_id: StringName, to: String) -> void:
	if loaded_trait != trait_id:
		if not select_trait(trait_id):
			return
	trait_desc_txt_edt.text = to
	_on_traits_changed()


func _do_update_stat(stat_id: StringName, to: String) -> void:
	if loaded_stat != stat_id:
		if not select_stat(stat_id):
			return
	stat_ln_edt.text = to
	_on_stats_changed()


func _do_update_skill(skill_id: StringName, to: String) -> void:
	if loaded_skill != skill_id:
		if not select_skill(skill_id):
			return
	skill_ln_edt.text = to
	_on_skills_changed()


func _do_update_trait(trait_id: StringName, to: String) -> void:
	if loaded_trait != trait_id:
		if not select_trait(trait_id):
			return
	trait_ln_edt.text = to
	_on_traits_changed()


func _on_data_tree_updated(type: int, id: StringName) -> void:
	match type:
		0:
			if stat_data_tree.has_undo():
				undo.create_action("Data Changed")
				undo.add_do_method(_do_stat_data_tree.bind(loaded_stat))
				undo.add_undo_method(_undo_stat_data_tree.bind(loaded_stat))
				undo.commit_action(false)
			_on_stats_changed()
		1:
			if skill_data_tree.has_undo():
				undo.create_action("Data Changed")
				undo.add_do_method(_do_skill_data_tree.bind(loaded_skill))
				undo.add_undo_method(_undo_skill_data_tree.bind(loaded_skill))
				undo.commit_action(false)
			_on_skills_changed()
		2:
			if not _traits_unsaved:
				_traits_unsaved = true
			if trait_data_tree.has_undo():
				undo.create_action("Data Changed")
				undo.add_do_method(_do_trait_data_tree.bind(loaded_trait))
				undo.add_undo_method(_undo_trait_data_tree.bind(loaded_trait))
				undo.commit_action(false)
			_on_traits_changed()


func _do_stat_data_tree(stat_id: StringName) -> void:
	if select_stat(stat_id):
		stat_data_tree.redo()
		_on_stats_changed()


func _do_skill_data_tree(skill_id: StringName) -> void:
	if select_skill(skill_id):
		skill_data_tree.redo()
		_on_skills_changed()


func _do_trait_data_tree(trait_id: StringName) -> void:
	if select_trait(trait_id):
		trait_data_tree.redo()
		_on_traits_changed()


func _undo_stat_data_tree(stat_id: StringName) -> void:
	if select_stat(stat_id):
		stat_data_tree.undo()


func _undo_skill_data_tree(skill_id: StringName) -> void:
	if select_skill(skill_id):
		skill_data_tree.undo()


func _undo_trait_data_tree(trait_id: StringName) -> void:
	if select_trait(trait_id):
		trait_data_tree.undo()


func save_current_skill() -> void:
	if loaded_skill.is_empty() or _skills_resource == null:
		return
	
	var target: Dictionary = {}
	
	if _skills_resource._skill_data.has(loaded_skill):
		target = _skills_resource._skill_data[loaded_skill]
	else:
		_skills_resource._skill_data[loaded_skill] = target
	
	target["name"] = skill_ln_edt.text.strip_edges()
	target["description"] = skill_desc_txt_edt.text.strip_edges()
	target["data"] = skill_data_tree.get_data()


func save_current_stat() -> void:
	if loaded_stat.is_empty() or _stats_resource == null:
		return
	
	var target: Dictionary = {}
	
	if _stats_resource._stat_data.has(loaded_stat):
		target = _stats_resource._stat_data[loaded_stat]
	else:
		_stats_resource._stat_data[loaded_stat] = target
	
	target["name"] = stat_ln_edt.text.strip_edges()
	target["description"] = stat_desc_txt_edt.text.strip_edges()
	target["data"] = stat_data_tree.get_data()


func has_unsaved_changes() -> bool:
	return _traits_unsaved or _skills_unsaved or _stats_unsaved


func save() -> void:
	if _skills_resource != null and _skills_unsaved:
		if skill_opt_btn.selected != -1:
			save_current_skill()
		ResourceSaver.save(_skills_resource)
	
	if _traits_resource != null and _traits_unsaved:
		if trait_opt_btn.selected != -1:
			save_current_trait()
		ResourceSaver.save(_traits_resource)
	
	if _stats_resource != null and _stats_unsaved:
		if stat_opt_btn.selected != -1:
			save_current_stat()
		ResourceSaver.save(_stats_resource)
	
	_skills_unsaved = false
	_traits_unsaved = false
	_stats_unsaved = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if undo != null and is_instance_valid(undo):
			undo.clear_history()
			undo.free()
