@tool
extends Control


const ID_SELECT_DIALOG = preload("res://addons/nexus_forge/tools/talents/dialogs/confirmation_dialog.tscn")
const DATA_RANGE_LIMIT: int = 9999
const DATA_FLOAT_STEP: float = 0.01

var talents_resource: NFTalentsRes
var no_talents_panel: PanelContainer = null

var current_skill: int = -1
var _unsaved: bool = false

@onready var skill_opt_btn: OptionButton = $MainPanel/MainMargin/MainContainer/SkillsContainer/SkillSelectContainer/SkillContainer/SkillOptBtn
@onready var create_skill_btn: Button = $MainPanel/MainMargin/MainContainer/SkillsContainer/SkillSelectContainer/SkillContainer/CreateSkillBtn
@onready var delete_skill_btn: Button = $MainPanel/MainMargin/MainContainer/SkillsContainer/SkillSelectContainer/SkillContainer/DeleteSkillBtn
@onready var skill_ln_edt: LineEdit = $MainPanel/MainMargin/MainContainer/SkillsContainer/NameContainer/SkillLnEdt
@onready var skill_desc_txt_edt: TextEdit = $MainPanel/MainMargin/MainContainer/SkillsContainer/DesContainer/SkillDescTxtEdt
@onready var initial_skill_level_spn_bx: SpinBox = $MainPanel/MainMargin/MainContainer/SkillsContainer/RangeContainer/InitialContainer/InitialSkillLevelSpnBx
@onready var skill_limit_spn_bx: SpinBox = $MainPanel/MainMargin/MainContainer/SkillsContainer/RangeContainer/MaxContainer/SkillLimitSpnBx
@onready var skill_data_tree: IDTree = $MainPanel/MainMargin/MainContainer/SkillsContainer/DataContainer/SkillDataTree
@onready var skill_int_btn: Button = $MainPanel/MainMargin/MainContainer/SkillsContainer/DataContainer/DataHeader/ButtonContainer/SkillIntBtn
@onready var skill_flt_btn: Button = $MainPanel/MainMargin/MainContainer/SkillsContainer/DataContainer/DataHeader/ButtonContainer/SkillFltBtn
@onready var skill_bool_btn: Button = $MainPanel/MainMargin/MainContainer/SkillsContainer/DataContainer/DataHeader/ButtonContainer/SkillBoolBtn
@onready var skill_str_btn: Button = $MainPanel/MainMargin/MainContainer/SkillsContainer/DataContainer/DataHeader/ButtonContainer/SkillStrBtn


func _ready() -> void:
	skill_data_tree.create_item()
	
	skill_data_tree.set_column_title(0, "Data ID")
	skill_data_tree.set_column_title(1, "Data Value")
	
	var res_path: String = ProjectSettings.get_setting(NFTalentsRes.SETTINGS_PATH, "")
	
	if not res_path.is_empty() and ResourceLoader.exists(res_path):
		var preload_res: Resource = load(res_path)
		if preload_res is NFTalentsRes:
			talents_resource = preload_res
	
	if talents_resource != null:
		load_resource()
	else:
		no_talents_panel = load("res://addons/nexus_forge/scenes/no_db_container.tscn").instantiate()
		add_child(no_talents_panel)
		no_talents_panel.set_resource_type("NFTalentsRes", "Talents", "Talents")
	
	skill_ln_edt.text_changed.connect(something_changed)
	skill_desc_txt_edt.text_changed.connect(something_changed)
	initial_skill_level_spn_bx.value_changed.connect(something_changed)
	skill_limit_spn_bx.value_changed.connect(something_changed)
	skill_limit_spn_bx.value_changed.connect(_on_max_level_changed)
	
	delete_skill_btn.pressed.connect(on_skill_deleted)
	create_skill_btn.pressed.connect(on_create_skill_pressed)
	skill_int_btn.pressed.connect(_on_add_skill_data_pressed.bind("new_int", 0))
	skill_flt_btn.pressed.connect(_on_add_skill_data_pressed.bind("new_float", 0.0))
	skill_bool_btn.pressed.connect(_on_add_skill_data_pressed.bind("new_bool", false))
	skill_str_btn.pressed.connect(_on_add_skill_data_pressed.bind("new_string", ""))
	skill_opt_btn.item_selected.connect(_on_skill_selected, CONNECT_DEFERRED)


func _on_add_skill_data_pressed(data_name: String, data: Variant) -> void:
	skill_data_tree.add_data(data_name, data)
	something_changed()


func _on_max_level_changed(new_level: float) -> void:
	initial_skill_level_spn_bx.max_value = new_level


func something_changed(_arg: Variant = null) -> void:
	if not _unsaved:
		_unsaved = true

 
func load_resource() -> void:
	skill_opt_btn.clear()
	
	for skill in talents_resource.get_skills():
		skill_opt_btn.add_item(skill)
	
	if 0 < skill_opt_btn.item_count:
		skill_opt_btn.select(0)
		_on_skill_selected(0)


func on_skill_deleted() -> void:
	var new_current: int = clampi(skill_opt_btn.selected, -1, skill_opt_btn.item_count - 2)
	current_skill = -1
	talents_resource.erase_skill(skill_opt_btn.get_item_text(skill_opt_btn.selected))
	skill_opt_btn.remove_item(skill_opt_btn.selected)
	skill_opt_btn.select(new_current)
	_on_skill_selected(new_current)
	something_changed()


func _on_skill_selected(skill_idx: int) -> void:
	if current_skill != -1:
		save_current_skill()
	
	var valid_id: bool = skill_idx != -1
	
	skill_ln_edt.editable = valid_id
	skill_limit_spn_bx.editable = valid_id
	skill_desc_txt_edt.editable = valid_id
	delete_skill_btn.disabled = not valid_id
	
	initial_skill_level_spn_bx.editable = valid_id
	skill_limit_spn_bx.editable = valid_id
	
	skill_int_btn.disabled = not valid_id
	skill_flt_btn.disabled = not valid_id
	skill_bool_btn.disabled = not valid_id
	skill_str_btn.disabled = not valid_id
	
	if not valid_id:
		skill_ln_edt.clear()
		initial_skill_level_spn_bx.value = 0
		skill_limit_spn_bx.value = 100
		skill_desc_txt_edt.clear()
		skill_data_tree.clear_data()
		return
	
	var skill_id: String = skill_opt_btn.get_item_text(skill_idx)
	
	skill_ln_edt.text = talents_resource.get_skill_name(skill_id)
	skill_desc_txt_edt.text = talents_resource.get_skill_description(skill_id)
	initial_skill_level_spn_bx.value = talents_resource.get_skill_starting_value(skill_id)
	skill_limit_spn_bx.value = talents_resource.get_skill_limit(skill_id)
	
	skill_data_tree.clear_data()
	
	for data_key in talents_resource.get_skill_data_keys(skill_id):
		skill_data_tree.add_data(
			data_key,
			talents_resource.get_skill_data(skill_id, data_key))
	
	current_skill = skill_idx


func on_create_skill_pressed() -> void:
	var id_creator := ID_SELECT_DIALOG.instantiate()
	id_creator.existing_talents = talents_resource.get_skill_ids()
	add_child(id_creator)
	id_creator.show()
	id_creator.focus_line_edit()
	
	var result = await id_creator.dialog_finished
	
	if result[0]:
		talents_resource.create_skill(result[1])
		skill_opt_btn.add_item(result[1])
		skill_opt_btn.select(skill_opt_btn.item_count - 1)
		_on_skill_selected(skill_opt_btn.item_count - 1)
		something_changed()
	id_creator.queue_free()


func save_current_skill() -> void:
	var skill_id: String = skill_opt_btn.get_item_text(current_skill)
	talents_resource.set_skill_name(skill_id, skill_ln_edt.text.strip_edges())
	talents_resource.set_skill_description(skill_id, skill_desc_txt_edt.text.strip_edges())
	talents_resource.set_skill_limit(skill_id, skill_limit_spn_bx.value)
	talents_resource.set_skill_starting_value(skill_id, initial_skill_level_spn_bx.value)
	talents_resource._skill_data[skill_id]["data"] = skill_data_tree.get_data()


func has_unsaved_changes() -> bool:
	return _unsaved


func save() -> void:
	if skill_opt_btn.selected != -1:
		save_current_skill()
	
	talents_resource.save()
	_unsaved = false
