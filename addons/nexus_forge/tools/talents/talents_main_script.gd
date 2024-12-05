@tool
extends Control


const ID_SELECT_DIALOG = preload("res://addons/nexus_forge/tools/talents/dialogs/confirmation_dialog.tscn")

var talents_resource: NFTalentsRes
var _skill_mode: bool = false

var current_level: int = -1
var current_perk: String = ""
var no_talents_panel: PanelContainer = null

@onready var skill_opt_btn: OptionButton = $MainPanel/MainMargin/MainContainer/SkillsContainer/SkillSelectContainer/SkillContainer/SkillOptBtn
@onready var create_skill_btn: Button = $MainPanel/MainMargin/MainContainer/SkillsContainer/SkillSelectContainer/SkillContainer/CreateSkillBtn
@onready var skill_ln_edt: LineEdit = $MainPanel/MainMargin/MainContainer/SkillsContainer/NameContainer/SkillLnEdt
@onready var icon_path_ln_edt: LineEdit = $MainPanel/MainMargin/MainContainer/SkillsContainer/HBoxContainer3/IconPathPanel/DataContainer/IconPathLnEdt
@onready var skill_limit_spn_bx: SpinBox = $MainPanel/MainMargin/MainContainer/SkillsContainer/LimitContainer/SkillLimitSpnBx
@onready var skill_desc_txt_edt: TextEdit = $MainPanel/MainMargin/MainContainer/SkillsContainer/DesContainer/DescTxtEdt

@onready var perk_tree: Tree = $MainPanel/MainMargin/MainContainer/PerksContainer/DataContainer/LeftContainer/PerkAndFlagsContainer/PerksContainer/PerkTree
@onready var main_container: HBoxContainer = $MainPanel/MainMargin/MainContainer
@onready var talents_resource_dialog: FileDialog = $Components/TalentsResourceDialog
@onready var flags_tree: Tree = $MainPanel/MainMargin/MainContainer/PerksContainer/DataContainer/LeftContainer/PerkDescContainer/FlagsContainer/FlagsTree
@onready var perk_desc_txt_edt: TextEdit = $MainPanel/MainMargin/MainContainer/PerksContainer/DataContainer/LeftContainer/PerkDescContainer/DataContainer/PerkDescTxtEdt
@onready var skills_reqirement_tree: Tree = $MainPanel/MainMargin/MainContainer/PerksContainer/DataContainer/ReqContainer/Stats/SkillsReqTree
@onready var perk_lvl_spn_bx: SpinBox = $MainPanel/MainMargin/MainContainer/PerksContainer/DataContainer/ReqContainer/LevelRequirement/LevelContainer/PerkLvlSpnBx
@onready var perk_requirement_tree: Tree = $MainPanel/MainMargin/MainContainer/PerksContainer/DataContainer/ReqContainer/PerksCotainer/PerkReqTree
@onready var variables_tree: Tree = $MainPanel/MainMargin/MainContainer/PerksContainer/DataContainer/ReqContainer/Variables/VariablesTree
@onready var add_int_btn: Button = $MainPanel/MainMargin/MainContainer/PerksContainer/DataContainer/ReqContainer/Variables/VariableBtnContainer/ButtonContainer/AddIntBtn
@onready var add_flt_btn: Button = $MainPanel/MainMargin/MainContainer/PerksContainer/DataContainer/ReqContainer/Variables/VariableBtnContainer/ButtonContainer/AddFltBtn
@onready var add_bool_btn: Button = $MainPanel/MainMargin/MainContainer/PerksContainer/DataContainer/ReqContainer/Variables/VariableBtnContainer/ButtonContainer/AddBoolBtn
@onready var add_str_btn: Button = $MainPanel/MainMargin/MainContainer/PerksContainer/DataContainer/ReqContainer/Variables/VariableBtnContainer/ButtonContainer/AddStrBtn
@onready var search_skill_ln_edt: LineEdit = $MainPanel/MainMargin/MainContainer/PerksContainer/DataContainer/ReqContainer/Stats/StatLineContainer/SearchSkillLnEdt
@onready var perk_search_ln_edt: LineEdit = $MainPanel/MainMargin/MainContainer/PerksContainer/DataContainer/ReqContainer/PerksCotainer/PerkSearchContainer/PerkSearchLnEdt
@onready var create_perk_btn: Button = $MainPanel/MainMargin/MainContainer/PerksContainer/DataContainer/LeftContainer/PerkAndFlagsContainer/PerksContainer/PerkBarContainer/CreatePerkBtn
@onready var browse_icon_btn: Button = $MainPanel/MainMargin/MainContainer/SkillsContainer/HBoxContainer3/IconPathPanel/DataContainer/BrowseIconBtn
@onready var delete_skill_btn: Button = $MainPanel/MainMargin/MainContainer/SkillsContainer/SkillSelectContainer/SkillContainer/DeleteSkillBtn
@onready var save_btn: Button = $MainPanel/MainMargin/MainContainer/PerksContainer/HBoxContainer/SaveBtn
@onready var current_perk_lbl: Label = $MainPanel/MainMargin/MainContainer/PerksContainer/DataContainer/LeftContainer/PerkInfo/CurrentPerkLbl


func _ready() -> void:
	var res_path: String = ProjectSettings.get_setting(NFTalentsRes.SETTINGS_PATH, "")
	
	if not res_path.is_empty() and ResourceLoader.exists(res_path):
		var preload_res: Resource = load(res_path)
		if preload_res is NFTalentsRes:
			talents_resource = preload_res
	
	if talents_resource != null:
		load_resource()
	else:
		no_talents_panel = preload("res://addons/nexus_forge/scenes/no_db_container.tscn").instantiate()
		add_child(no_talents_panel)
		no_talents_panel.set_resource_type("NFTalentsRes", "Talents", "Talents")
		no_talents_panel.create_resource_pressed.connect(on_create_talent_res_pressed)
		no_talents_panel.load_resource_pressed.connect(on_load_talent_res_pressed)
		
	main_container.visible = talents_resource != null
	
	perk_tree.perk_selected.connect(on_perk_selected)
	perk_tree.perk_deleted.connect(on_perk_deleted)
	perk_tree.id_edited.connect(on_perk_id_changed)
	perk_tree.perk_created.connect(on_perk_created)
	perk_tree.perk_max_level_changed.connect(on_current_perk_max_level_changed)
	create_perk_btn.pressed.connect(on_create_perk_pressed)
	#id_line_edit.text_submitted.connect(on_id_line_submitted)
	#id_line_edit.text_changed.connect(on_id_line_changed)
	delete_skill_btn.pressed.connect(on_skill_deleted)
	talents_resource_dialog.file_selected.connect(on_talent_path_selected)
	save_btn.pressed.connect(save_talents)
	perk_lvl_spn_bx.value_changed.connect(on_level_changed)
	create_skill_btn.pressed.connect(on_create_skill_pressed)
	#cancel_btn.pressed.connect(id_select_panel.hide)
	#create_btn.pressed.connect(on_panel_ok_button_pressed)
	add_int_btn.pressed.connect(on_create_variant_requirement_pressed.bind(0))
	add_flt_btn.pressed.connect(on_create_variant_requirement_pressed.bind(0.0))
	add_bool_btn.pressed.connect(on_create_variant_requirement_pressed.bind(false))
	add_str_btn.pressed.connect(on_create_variant_requirement_pressed.bind(""))


func load_resource() -> void:
	skill_opt_btn.clear()
	perk_tree.clear_perks()
	perk_requirement_tree.clear_perks()
	skills_reqirement_tree.clear_skills()
	
	for skill in talents_resource.get_skills():
		skill_opt_btn.add_item(skill)
		skills_reqirement_tree.add_skill(
			skill,
			0,
			OP_EQUAL)
	
	for perk in talents_resource.get_perks():
		perk_tree.add_perk(
				perk,
				talents_resource.get_perk_name(perk),
				talents_resource.get_perk_level(perk),
				false)
		perk_requirement_tree.add_perk(perk)
	
	
	if 0 < skill_opt_btn.item_count:
		skill_opt_btn.select(0)
		on_skill_selected(0)


func on_create_variant_requirement_pressed(variant: Variant) -> void:
	variables_tree.create_variable(variant)


func on_create_perk_pressed() -> void:
	perk_tree.add_perk("new_perk", "New Perk", 1, false)


func on_perk_created(perk_id: String) -> void:
	talents_resource.create_perk(perk_id)
	perk_requirement_tree.add_perk(perk_id)


func on_load_talent_res_pressed() -> void:
	talents_resource_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	talents_resource_dialog.show()


func on_create_talent_res_pressed() -> void:
	talents_resource_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	talents_resource_dialog.show()


func on_talent_path_selected(talent_path: String) -> void:
	if talents_resource_dialog.file_mode == FileDialog.FileMode.FILE_MODE_SAVE_FILE:
		var new_talents := NFTalentsRes.new()
		talents_resource = new_talents
		talents_resource.save()
	else:
		var res_preload: Resource = load(talent_path)
		if res_preload is NFTalentsRes:
			talents_resource = res_preload
		else:
			printerr("[TALENTS] Selected resource isn't NFTalentsRes")
	
	if talents_resource != null:
		ProjectSettings.set_setting(NFTalentsRes.SETTINGS_PATH, talent_path)
		ProjectSettings.save()
		no_talents_panel.visible = false
		no_talents_panel.queue_free()
		main_container.visible = true
		load_resource()


func on_skill_deleted() -> void:
	talents_resource.erase_skill(skill_opt_btn.get_item_text(skill_opt_btn.selected))
	skill_opt_btn.remove_item(skill_opt_btn.selected)
	on_skill_selected(skill_opt_btn.selected)


func on_skill_selected(skill_idx: int) -> void:
	var valid_id: bool = skill_idx != -1
	
	skill_ln_edt.editable = valid_id
	browse_icon_btn.disabled = not valid_id
	skill_limit_spn_bx.editable = valid_id
	skill_desc_txt_edt.editable = valid_id
	delete_skill_btn.disabled = not valid_id
	
	if not valid_id:
		skill_ln_edt.clear()
		icon_path_ln_edt.clear()
		skill_limit_spn_bx.value = 1
		skill_desc_txt_edt.clear()
		return
	
	var skill_id: String = skill_opt_btn.get_item_text(skill_idx)
	
	skill_ln_edt.text = talents_resource.get_skill_name(skill_id)
	icon_path_ln_edt.text = talents_resource.get_skill_icon_path(skill_id)
	skill_limit_spn_bx.value = talents_resource.get_skill_limit(skill_id)
	skill_desc_txt_edt.text = talents_resource.get_skill_desc(skill_id)


func on_create_skill_pressed() -> void:
	var id_creator := ID_SELECT_DIALOG.instantiate()
	id_creator.talents_resource = talents_resource
	add_child(id_creator)
	id_creator.show()
	var result = await id_creator.dialog_finished
	if result[0]:
		talents_resource.create_skill(result[1])
		skills_reqirement_tree.add_skill(result[1], 0,OP_EQUAL)
		
		skill_opt_btn.add_item(result[1])
		skill_opt_btn.select(skill_opt_btn.item_count - 1)
		on_skill_selected(skill_opt_btn.item_count - 1)
	id_creator.queue_free()


func on_perk_id_changed(from: String, to: String) -> void:
	talents_resource.perks[to] = talents_resource.perks[from]
	talents_resource.erase_perk(from)
	talents_resource.perk_renamed.emit(from, to)
	perk_requirement_tree.rename_perk(from, to)
	if current_perk == from:
		current_perk = to
		current_perk_lbl.text = to


func on_perk_deleted(perk_id: String) -> void:
	perk_requirement_tree.remove_perk(perk_id)
	
	if perk_id == current_perk:
		set_perk_as_current("")


func set_perk_as_current(new_id: String) -> void:
	var invalid_id: bool = new_id.is_empty()
	current_perk = new_id
	current_perk_lbl.text = new_id
	
	#add_stat_btn.disabled = invalid_id
	add_int_btn.disabled = invalid_id
	add_flt_btn.disabled = invalid_id
	add_bool_btn.disabled = invalid_id
	add_str_btn.disabled = invalid_id
	flags_tree.set_editable(not invalid_id)
	perk_desc_txt_edt.editable = not invalid_id
	search_skill_ln_edt.editable = not invalid_id
	perk_search_ln_edt.editable = not invalid_id
	perk_lvl_spn_bx.editable = not invalid_id
	perk_requirement_tree.set_perks_enabled(not invalid_id)
	skills_reqirement_tree.set_skills_enabled(not invalid_id)
	
	search_skill_ln_edt.clear()
	perk_search_ln_edt.clear()
	variables_tree.clear_variables()
	perk_requirement_tree.reset_perks()
	skills_reqirement_tree.reset_skills()
	perk_lvl_spn_bx.set_value_no_signal(1)
	perk_lvl_spn_bx.get_line_edit().text = "1"
	
	if invalid_id:
		flags_tree.clear_checks()
		perk_desc_txt_edt.clear()
		perk_lvl_spn_bx.max_value = 1
		current_level = -1
	else:
		current_level = 0
		perk_desc_txt_edt.text = talents_resource.get_perk_desc(new_id)
		perk_lvl_spn_bx.max_value = talents_resource.get_perk_level(new_id)
		flags_tree.set_flags(talents_resource.get_perk_flags(new_id))
		perk_requirement_tree.set_perk_hidden(current_perk)
		
		var perk_req: Dictionary = talents_resource.get_perk_requirements(current_perk, 0)
		
		for stat in perk_req["skills"]:
			skills_reqirement_tree.add_requirement(
					stat,
					perk_req["skills"][stat]["value"],
					perk_req["skills"][stat]["operator"])
		
		for perk in perk_req["perks"]:
			perk_requirement_tree.set_perk(
					perk,
					perk_req["perks"][perk]["level"],
					perk_req["perks"][perk]["operator"])
		
		for variable in perk_req["variables"]:
			variables_tree.create_variable(
				perk_req["variables"][variable]["value"],
				variable,
				perk_req["variables"][variable]["operator"])


func on_perk_selected(perk_id: String) -> void:
	if current_perk == perk_id:
		return
	
	if not current_perk.is_empty():
		save_current_perk()
	
	set_perk_as_current(perk_id)


func save_current_level() -> void:
	var skills_req: Dictionary = skills_reqirement_tree.get_current_skill_data()
	var perks_req: Dictionary = perk_requirement_tree.get_selected_perks()
	var var_req: Dictionary = variables_tree.get_variables()
	
	for val in skills_req:
		talents_resource.set_perk_skill_requirement(
				current_perk,
				current_level,
				val,
				skills_req[val]["value"],
				skills_req[val]["operator"])
	
	for perk in perks_req:
		talents_resource.set_perk_perk_requirement(
				current_perk,
				current_level,
				perk,
				perks_req[perk]["level"],
				perks_req[perk]["operator"])
	
	for variable in var_req:
		talents_resource.set_perk_var_requirement(
				current_perk,
				current_level,
				variable,
				var_req[variable]["value"],
			var_req[variable]["operator"])


func on_level_changed(new_level: float) -> void:
	if 0 <= current_level:
		save_current_level()
	
	current_level = new_level - 1
	
	skills_reqirement_tree.reset_skills()
	perk_requirement_tree.reset_perks()
	variables_tree.clear_variables()
	
	if current_level < 0:
		return
	
	var level_req: Dictionary = talents_resource.get_perk_requirements(current_perk, current_level)
	
	for skill in level_req["skills"]:
		skills_reqirement_tree.set_requirement(
			skill,
			true,
			level_req["skills"][skill]["value"],
			level_req["skills"][skill]["operator"])
	
	for perk in level_req["perks"]:
		perk_requirement_tree.set_perk(
				perk,
				level_req["perks"][perk]["level"],
				level_req["perks"][perk]["operator"])
	
	for variable in level_req["variables"]:
		variables_tree.create_variable(
			level_req["variables"][variable]["value"],
			variable,
			level_req["variables"][variable]["operator"])


func save_current_skill() -> void:
	var skill_id: String = skill_opt_btn.get_item_text(skill_opt_btn.selected)
	talents_resource.set_skill_name(skill_id, skill_ln_edt.text.strip_edges())
	talents_resource.set_skill_desc(skill_id, skill_desc_txt_edt.text.strip_edges())
	talents_resource.set_skill_icon_path(skill_id, icon_path_ln_edt.text)
	talents_resource.set_skill_limit(skill_id, skill_limit_spn_bx.value)


func save_current_perk() -> void:
	if 0 <= current_level:
		save_current_level()
	talents_resource.set_perk_flags(current_perk, flags_tree.get_flags())
	talents_resource.set_perk_desc(current_perk, perk_desc_txt_edt.text.strip_edges())


func on_current_perk_max_level_changed(perk_id: String, new_level: int) -> void:
	if perk_id == current_perk:
		perk_lvl_spn_bx.max_value = new_level
	talents_resource.set_perk_levels(perk_id, new_level)


func save_talents() -> void:
	if not current_perk.is_empty():
		save_current_perk()
	
	var perk_info: Dictionary = perk_tree.get_perk_data()
	
	for perk in perk_info:
		talents_resource.set_perk_name(perk, perk_info[perk]["name"])
	
	if skill_opt_btn.selected != -1:
		save_current_skill()
	
	talents_resource.save()
