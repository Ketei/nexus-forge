@tool
extends PanelContainer


const LineEditConfirmationDialog = preload("res://addons/nexus_forge/dialogs/lineedit_confirmation_dialog.gd")
const DATA_RANGE_LIMIT: int = 9999
const DATA_FLOAT_STEP: float = 0.01

var _skills_resource: SkillCatalog
var _traits_resource: TraitCatalog

var loaded_skill: StringName = &""
var loaded_trait: StringName = &""
var _skills_unsaved: bool = false
var _traits_unsaved: bool = false

@onready var skill_opt_btn: OptionButton = $MainContainer/SkillsPanel/SkillsContainer/SkillSelectContainer/SkillContainer/SkillOptBtn
@onready var skill_ln_edt: LineEdit = $MainContainer/SkillsPanel/SkillsContainer/NameContainer/SkillLnEdt
@onready var skill_desc_txt_edt: TextEdit = $MainContainer/SkillsPanel/SkillsContainer/DesContainer/SkillDescTxtEdt
@onready var skill_data_tree: IDTree = $MainContainer/SkillsPanel/SkillsContainer/DataContainer/SkillDataTree
@onready var skill_int_btn: Button = $MainContainer/SkillsPanel/SkillsContainer/DataContainer/DataHeader/ButtonContainer/SkillIntBtn
@onready var skill_flt_btn: Button = $MainContainer/SkillsPanel/SkillsContainer/DataContainer/DataHeader/ButtonContainer/SkillFltBtn
@onready var skill_bool_btn: Button = $MainContainer/SkillsPanel/SkillsContainer/DataContainer/DataHeader/ButtonContainer/SkillBoolBtn
@onready var skill_str_btn: Button = $MainContainer/SkillsPanel/SkillsContainer/DataContainer/DataHeader/ButtonContainer/SkillStrBtn
@onready var skill_dict_button: Button = $MainContainer/SkillsPanel/SkillsContainer/DataContainer/DataHeader/ButtonContainer/AddDictButton

@onready var trait_opt_btn: OptionButton = $MainContainer/TraitsPanel/TraitsContainerContainer/TraitSelectContainer/TraitContainer/TraitOptBtn
@onready var trait_ln_edt: LineEdit = $MainContainer/TraitsPanel/TraitsContainerContainer/NameContainer/TraitLnEdt
@onready var trait_desc_txt_edt: TextEdit = $MainContainer/TraitsPanel/TraitsContainerContainer/DesContainer/TraitDescTxtEdt
@onready var trait_dict_btn: Button = $MainContainer/TraitsPanel/TraitsContainerContainer/DataContainer/DataHeader/ButtonContainer/TraitDictBtn
@onready var trait_int_btn: Button = $MainContainer/TraitsPanel/TraitsContainerContainer/DataContainer/DataHeader/ButtonContainer/TraitIntBtn
@onready var trait_flt_btn: Button = $MainContainer/TraitsPanel/TraitsContainerContainer/DataContainer/DataHeader/ButtonContainer/TraitFltBtn
@onready var trait_bool_btn: Button = $MainContainer/TraitsPanel/TraitsContainerContainer/DataContainer/DataHeader/ButtonContainer/TraitBoolBtn
@onready var trait_str_btn: Button = $MainContainer/TraitsPanel/TraitsContainerContainer/DataContainer/DataHeader/ButtonContainer/TraitStrBtn
@onready var trait_data_tree: Tree = $MainContainer/TraitsPanel/TraitsContainerContainer/DataContainer/TraitDataTree

@onready var edit_skills_btn: Button = $MainContainer/SkillsPanel/SkillsContainer/SkillSelectContainer/SkillContainer/EditSkillsBtn
@onready var edit_traits_btn: Button = $MainContainer/TraitsPanel/TraitsContainerContainer/TraitSelectContainer/TraitContainer/EditTraitsBtn


func ready_plugin() -> void:
	skill_data_tree.ready_plugin()
	trait_data_tree.ready_plugin()
	
	reload_traits(false)
	reload_skills(false)
	
	reload_trait_resource(true)
	reload_skill_resource(true)
	
	trait_dict_btn.icon = get_theme_icon("FolderCreate", "EditorIcons")
	skill_dict_button.icon = get_theme_icon("FolderCreate", "EditorIcons")
	edit_skills_btn.icon = get_theme_icon("Edit", "EditorIcons")
	edit_traits_btn.icon = get_theme_icon("Edit", "EditorIcons")
	
	skill_opt_btn.get_popup().max_size.y = 300
	trait_opt_btn.get_popup().max_size.y = 300
	
	skill_opt_btn.disabled = skill_opt_btn.item_count == 0
	trait_opt_btn.disabled = trait_opt_btn.item_count == 0
	
	set_skills_ui_enabled(0 < skill_opt_btn.item_count)
	set_traits_ui_enabled(0 < trait_opt_btn.item_count)
	
	skill_ln_edt.text_changed.connect(skills_changed)
	skill_desc_txt_edt.text_changed.connect(skills_changed)
	
	trait_ln_edt.text_changed.connect(traits_changed)
	trait_desc_txt_edt.text_changed.connect(traits_changed)
	
	skill_int_btn.pressed.connect(_on_add_skill_data_pressed.bind("new_int", 0))
	skill_flt_btn.pressed.connect(_on_add_skill_data_pressed.bind("new_float", 0.0))
	skill_bool_btn.pressed.connect(_on_add_skill_data_pressed.bind("new_bool", false))
	skill_str_btn.pressed.connect(_on_add_skill_data_pressed.bind("new_string", ""))
	skill_dict_button.pressed.connect(_on_add_skill_data_pressed.bind("new_folder", {}))
	skill_opt_btn.item_selected.connect(_on_skill_selected, CONNECT_DEFERRED)
	
	trait_opt_btn.item_selected.connect(_on_trait_selected, CONNECT_DEFERRED)
	trait_int_btn.pressed.connect(_on_add_trait_data_pressed.bind("new_int", 0))
	trait_flt_btn.pressed.connect(_on_add_trait_data_pressed.bind("new_float", 0.0))
	trait_bool_btn.pressed.connect(_on_add_trait_data_pressed.bind("new_bool", false))
	trait_str_btn.pressed.connect(_on_add_trait_data_pressed.bind("new_string", ""))
	trait_dict_btn.pressed.connect(_on_add_trait_data_pressed.bind("new_folder", {}))
	
	edit_skills_btn.pressed.connect(_on_edit_skillset_pressed)
	edit_traits_btn.pressed.connect(_on_edit_traitblock_pressed)
	
	skill_data_tree.data_changed.connect(skills_changed)
	trait_data_tree.data_changed.connect(traits_changed)


func _on_edit_skillset_pressed() -> void:
	EditorInterface.edit_script(SkillSet.new().get_script())
	if not EditorInterface.get_editor_settings().get_setting("text_editor/external/use_external_editor"):
		EditorInterface.set_main_screen_editor("Script")


func _on_edit_traitblock_pressed() -> void:
	EditorInterface.edit_script(TraitBlock.new().get_script())
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
			$MainContainer/SkillsPanel/SkillsContainer.visible = false
			var no_db = preload("res://addons/nexus_forge/no_db_container.tscn").instantiate()
			$MainContainer/SkillsPanel.add_child(no_db)
			no_db.message_minimum_size.x = 450
			no_db.set_resource_type("SkillCatalog", "Skills", "Skills")
			no_db.create_resource_pressed.connect(_on_create_skill_resource_pressed.bind(no_db))
			no_db.load_resource_pressed.connect(_on_load_skill_resource_pressed.bind(no_db))
			no_db.resource_dropped.connect(_on_skill_resource_dropped.bind(no_db))
	else:
		$MainContainer/SkillsPanel/SkillsContainer.visible = true
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
		var preload_traits_res: Resource = load(traits_path)
		if preload_traits_res is TraitCatalog:
			_traits_resource = preload_traits_res
	
	if _traits_resource == null:
		if not was_null or first_launch:
			$MainContainer/TraitsPanel/TraitsContainerContainer.visible = false
			var no_db = preload("res://addons/nexus_forge/no_db_container.tscn").instantiate()
			$MainContainer/TraitsPanel.add_child(no_db)
			no_db.message_minimum_size.x = 450
			no_db.set_resource_type("TraitCatalog", "Traits", "Traits")
			no_db.create_resource_pressed.connect(_on_create_traits_resource_pressed.bind(no_db))
			no_db.load_resource_pressed.connect(_on_load_traits_resource_pressed.bind(no_db))
			no_db.resource_dropped.connect(_on_traits_resource_dropped.bind(no_db))
	else:
		$MainContainer/TraitsPanel/TraitsContainerContainer.visible = true
		load_traits_resource()

#region Skills

func _on_create_skill_resource_pressed(panel: PanelContainer) -> void:
	var res_loader := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
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
		$MainContainer/SkillsPanel/SkillsContainer.visible = true
		panel.visible = false
		panel.queue_free()
		load_skills_resource()
	
	res_loader.queue_free()


func _on_load_skill_resource_pressed(panel: PanelContainer) -> void:
	var res_loader := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
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
			$MainContainer/SkillsPanel/SkillsContainer.visible = true
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
	$MainContainer/SkillsPanel/SkillsContainer.visible = true
	load_skills_resource()



func _on_add_skill_data_pressed(data_name: String, data: Variant) -> void:
	skill_data_tree.add_data(data_name, data)
	skills_changed()


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
	skill_ln_edt.text = _skills_resource.get_skill_name(skill_id)
	skill_desc_txt_edt.text = _skills_resource.get_skill_description(skill_id)
	
	skill_data_tree.clear_data()
	
	for data_key in _skills_resource.skill_data_keys(skill_id):
		skill_data_tree.add_data(
			data_key,
			_skills_resource.get_skill_data(skill_id, data_key))


func load_skills_resource() -> void:
	skill_ln_edt.text = ""
	skill_data_tree.clear_data()
	
	var skills_exist: bool = 0 < skill_opt_btn.item_count
	var disabled: bool = not skills_exist
	
	var skill_block: SkillSet = SkillSet.new(false)
	var all_skills: Array[StringName] = skill_block.skills()
	
	for skill in _skills_resource._skills.keys():
		if all_skills.has(skill):
			continue
		_skills_resource._skills.erase(skill)
	
	for new_skill in all_skills:
		if _skills_resource._skills.has(new_skill):
			continue
		var data: Dictionary[String, Variant] = {}
		data.assign(_skills_resource.DEFAULT_DATA.duplicate(true))
		_skills_resource._skills[new_skill] = {
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
			_skills_resource._skills.erase(skill)
	
	skill_opt_btn.clear()
	for skill in all_skills:
		skill_opt_btn.add_item(
				String(skill).capitalize())
		skill_opt_btn.set_item_metadata(-1, skill)
		
		if _skills_resource != null:
			if _skills_resource._skills.has(skill):
				continue
			var data: Dictionary[String, Variant] = {}
			data.assign(_skills_resource.DEFAULT_DATA.duplicate(true))
			_skills_resource._skills[skill] = {
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
	var res_loader := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
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
	var res_loader := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
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
	traits_changed()


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
	trait_ln_edt.text = _traits_resource.get_trait_name(trait_id)
	trait_desc_txt_edt.text = _traits_resource.get_trait_description(trait_id)
	
	trait_data_tree.clear_data()
	
	for data_key in _traits_resource.trait_data_keys(trait_id):
		trait_data_tree.add_data(
			data_key,
			_traits_resource.get_trait_data(trait_id, data_key))


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
	var trait_data: Dictionary[String, Variant] = trait_data_tree.get_data()
	_traits_resource.set_trait_name(loaded_trait, trait_ln_edt.text.strip_edges())
	_traits_resource.set_trait_description(loaded_trait, trait_desc_txt_edt.text.strip_edges())
	_traits_resource.clear_trait_data(loaded_trait)
	for data_key in trait_data.keys():
		_traits_resource.set_trait_data(loaded_trait, data_key, trait_data[data_key])


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
	
	var block: TraitBlock = TraitBlock.new(false)
	var all_traits: Array[StringName] = block.traits()
	
	for existing_trait in _traits_resource._traits.keys():
		if all_traits.has(existing_trait):
			continue
		_traits_resource._traits.erase(existing_trait)
	
	for new_trait in all_traits:
		if _traits_resource._traits.has(new_trait):
			continue
		else:
			var data: Dictionary[String, Variant] = {}
			data.assign(_traits_resource.DEFAULT_DATA.duplicate(true))
			_traits_resource._traits[new_trait] = {
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
	#var trait_obj: TraitBlock = TraitBlock.new()
	var all_traits: Array[StringName] = TraitBlock.traits()
	
	all_traits.sort_custom(func(a,b): return String(a).naturalnocasecmp_to(String(b)) < 0)
	var new_index: int = all_traits.find(current_trait) if reselect else -1
	
	if _traits_resource != null:
		for existing_trait in _traits_resource._traits.keys():
			if all_traits.has(existing_trait):
				continue
			_traits_resource._traits.erase(existing_trait)
	
	trait_opt_btn.clear()
	for trait_id in all_traits:
		trait_opt_btn.add_item(
				String(trait_id).capitalize())
		trait_opt_btn.set_item_metadata(-1, trait_id)
		
		if _traits_resource != null:
			if _traits_resource._traits.has(trait_id):
				continue
			var data: Dictionary[String, Variant] = {}
			data.assign(_traits_resource.DEFAULT_DATA.duplicate(true))
			_traits_resource._traits[trait_id] = {
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


func skills_changed(_arg: Variant = null) -> void:
	if not _skills_unsaved:
		_skills_unsaved = true


func traits_changed(_arg: Variant = null) -> void:
	if not _traits_unsaved:
		_traits_unsaved = true


func save_current_skill() -> void:
	_skills_resource.set_skill_name(loaded_skill, skill_ln_edt.text.strip_edges())
	_skills_resource.set_skill_description(loaded_skill, skill_desc_txt_edt.text.strip_edges())
	_skills_resource.clear_skill_data(loaded_skill)
	var skill_data: Dictionary[String, Variant] = skill_data_tree.get_data()
	for data_key in skill_data.keys():
		_skills_resource.set_skill_data(loaded_skill, data_key, skill_data[data_key])


func has_unsaved_changes() -> bool:
	return _traits_unsaved or _skills_unsaved


func save() -> void:
	if _skills_resource != null and _skills_unsaved:
		if skill_opt_btn.selected != -1:
			save_current_skill()
		ResourceSaver.save(_skills_resource)
	
	if _traits_resource != null and _traits_unsaved:
		if trait_opt_btn.selected != -1:
			save_current_trait()
		ResourceSaver.save(_traits_resource)
	
	_skills_unsaved = false
	_traits_unsaved = false
