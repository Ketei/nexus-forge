@tool
extends PanelContainer


#const FACTION_DIALOG = preload("res://addons/nexus_forge/tools/characters/factions/faction_dialog.tscn")


var factions_resource: NFFactionRes = null
var current_faction: int = -1
var current_rank: int = -1
var no_faction_panel: Control = null
var _unsaved: bool = false

@onready var faction_opt_btn: OptionButton = $MainContainer/FactionsContainer/FactionIDContainer/FactionSelect/FactionOptBtn
@onready var add_fact_button: Button = $MainContainer/FactionsContainer/FactionIDContainer/FactionSelect/AddFactButton
@onready var delete_faction_btn: Button = $MainContainer/FactionsContainer/FactionIDContainer/FactionSelect/DeleteFactionBtn
@onready var faction_name_ln_edt: LineEdit = $MainContainer/FactionsContainer/FactionIDContainer/FactionNameLnEdt
@onready var search_fac_ln_edt: LineEdit = $MainContainer/FactionsContainer/FactionIDContainer/RelationshipsContainer/SearchFacLnEdt
@onready var factions_tree: Tree = $MainContainer/FactionsContainer/FactionIDContainer/RelationshipsContainer/FactionsTree
@onready var main_container: HBoxContainer = $MainContainer
@onready var fac_data_tree: Tree = $MainContainer/FactionsDataContainer/FacDataTree
@onready var rank_name_ln_edt: LineEdit = $MainContainer/RanksContainer/RankNameLnEdt
@onready var rank_data_tree: Tree = $MainContainer/RanksContainer/RankDataTree
@onready var ranks_opt_btn: OptionButton = $MainContainer/RanksContainer/HeaderContainer/RanksOptBtn
@onready var add_rank_btn: Button = $MainContainer/RanksContainer/HeaderContainer/ButtonsContainer/AddRankBtn
@onready var delete_rank_btn: Button = $MainContainer/RanksContainer/HeaderContainer/ButtonsContainer/DeleteFactionBtn
#@onready var add_fact_button: Button = $MainContainer/FactionsContainer/FactionIDContainer/FactionSelect/AddFactButton
#@onready var add_rank_btn: Button = $MainContainer/RanksContainer/HeaderContainer/ButtonsContainer/AddRankBtn
@onready var add_fac_int_btn: Button = $MainContainer/FactionsDataContainer/HeaderContainer/ButtonsContainer/AddFacIntBtn
@onready var add_fac_flt_btn: Button = $MainContainer/FactionsDataContainer/HeaderContainer/ButtonsContainer/AddFacFltBtn
@onready var add_fac_bool_btn: Button = $MainContainer/FactionsDataContainer/HeaderContainer/ButtonsContainer/AddFacBoolBtn
@onready var add_fac_str_btn: Button = $MainContainer/FactionsDataContainer/HeaderContainer/ButtonsContainer/AddFacStrBtn
@onready var add_rank_int_btn: Button = $MainContainer/RanksContainer/DataHeader/HBoxContainer2/AddRankIntBtn
@onready var add_rank_flt_btn: Button = $MainContainer/RanksContainer/DataHeader/HBoxContainer2/AddRankFltBtn
@onready var add_rank_bool_btn: Button = $MainContainer/RanksContainer/DataHeader/HBoxContainer2/AddRankBoolBtn
@onready var add_rank_str_btn: Button = $MainContainer/RanksContainer/DataHeader/HBoxContainer2/AddRankStrBtn



func _ready() -> void:
	var resource_path: String = ProjectSettings.get_setting(NFFactionRes.SETTINGS_PATH, "")
	
	if not resource_path.is_empty() and ResourceLoader.exists(resource_path):
		var res_preload: Resource = load(resource_path)
		if res_preload is NFFactionRes:
			factions_resource = res_preload
		else:
			printerr("[FACTIONS] Defined factions resource isn't NFFactionRes")
	
	if factions_resource != null:
		_load_data()
		main_container.visible = true
	else:
		main_container.visible = false
		no_faction_panel = preload("res://addons/nexus_forge/scenes/no_db_container.tscn").instantiate()
		add_child(no_faction_panel)
		no_faction_panel.set_resource_type("NFFactionRes", "Factions", "Factions")
		no_faction_panel.create_resource_pressed.connect(_on_create_fac_db_pressed)
		no_faction_panel.load_resource_pressed.connect(_on_load_fact_db_pressed)
		no_faction_panel.visible = true
	
	faction_opt_btn.item_selected.connect(on_faction_selected)
	ranks_opt_btn.item_selected.connect(_on_rank_selected)
	
	add_fac_int_btn.pressed.connect(_on_add_faction_data_pressed.bind("new_int", 0))
	add_fac_flt_btn.pressed.connect(_on_add_faction_data_pressed.bind("new_flt", 0.0))
	add_fac_bool_btn.pressed.connect(_on_add_faction_data_pressed.bind("new_bool", false))
	add_fac_str_btn.pressed.connect(_on_add_faction_data_pressed.bind("new_str", ""))
	
	add_rank_int_btn.pressed.connect(_on_add_rank_data_pressed.bind("new_int", 0))
	add_rank_flt_btn.pressed.connect(_on_add_rank_data_pressed.bind("new_flt", 0.0))
	add_rank_bool_btn.pressed.connect(_on_add_rank_data_pressed.bind("new_bool", false))
	add_rank_str_btn.pressed.connect(_on_add_rank_data_pressed.bind("new_str", ""))
	
	delete_faction_btn.pressed.connect(_on_faction_delete_pressed)
	delete_rank_btn.pressed.connect(_on_rank_delete_pressed)
	add_fact_button.pressed.connect(_on_create_faction_pressed)
	add_rank_btn.pressed.connect(_on_create_rank_pressed)
	
	faction_name_ln_edt.text_changed.connect(something_changed)
	rank_name_ln_edt.text_changed.connect(something_changed)
	factions_tree.item_edited.connect(something_changed)
	fac_data_tree.item_edited.connect(something_changed)
	rank_data_tree.item_edited.connect(something_changed)


func _on_create_fac_db_pressed() -> void:
	var new_res_selector := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").new()
	
	new_res_selector.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	new_res_selector.title = "Save Factions..."
	
	add_child(new_res_selector)
	new_res_selector.show()
	
	var result = await new_res_selector.dialog_finished
	
	if result[0]:
		factions_resource = NFFactionRes.new()
		ResourceSaver.save(factions_resource, result[1])
		ProjectSettings.set_setting(NFFactionRes.SETTINGS_PATH, result[1])
		ProjectSettings.save()
		main_container.visible = true
	
	new_res_selector.queue_free()


func _on_load_fact_db_pressed() -> void:
	var new_res_selector := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").new()
	
	new_res_selector.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	new_res_selector.title = "Select Factions..."
	
	add_child(new_res_selector)
	new_res_selector.show()
	
	var result = await new_res_selector.dialog_finished
	
	if result[0]:
		var pre_res: Resource = load(result[1])
		
		if pre_res != null and pre_res is NFFactionRes:
			factions_resource = pre_res
			ProjectSettings.set_setting(NFFactionRes.SETTINGS_PATH, result[1])
			ProjectSettings.save()
			main_container.visible = true
	
	new_res_selector.queue_free()


func _load_data() -> void:
	for faction in factions_resource.get_factions():
		faction_opt_btn.add_item(faction)
		factions_tree.add_faction(faction)
	
	if 0 < faction_opt_btn.item_count:
		faction_opt_btn.select(0)
		on_faction_selected(0)


func _on_add_faction_data_pressed(data_name: String, data: Variant) -> void:
	fac_data_tree.add_data(data_name, data)
	something_changed()


func _on_add_rank_data_pressed(data_name: String, data: Variant) -> void:
	rank_data_tree.add_data(data_name, data)
	something_changed()


func something_changed(_arg: Variant = null) -> void:
	if not _unsaved:
		_unsaved = true


func save_current_faction() -> void:
	if 0 <= current_rank:
		save_current_rank()
	
	var faction_id: String = faction_opt_btn.get_item_text(current_faction)
	
	factions_resource.set_faction_name(faction_id, faction_name_ln_edt.text.strip_edges())
	factions_resource.factions[faction_id]["relations"] = factions_tree.get_faction_relations()
	factions_resource.factions[faction_id]["data"] = fac_data_tree.get_data()


func save_current_rank() -> void:
	var faction_id: String = faction_opt_btn.get_item_text(current_faction)
	
	factions_resource.factions[faction_id]["ranks"][current_rank] = {
		"name": rank_name_ln_edt.text.strip_edges(),
		"data": rank_data_tree.get_data()}


func on_faction_selected(faction_idx: int) -> void:
	if current_faction != -1:
		save_current_faction()
	load_faction(faction_idx)


func load_faction(faction_idx: int) -> void:
	fac_data_tree.clear_data()
	ranks_opt_btn.clear()
	factions_tree.reset_relationships()
	
	if faction_idx == -1:
		factions_tree.set_active_faction("")
		factions_tree.tree_enabled = false
		current_faction = -1
		faction_name_ln_edt.clear()
		faction_name_ln_edt.editable = false
		delete_faction_btn.disabled = true
		ranks_opt_btn.disabled = true
		add_fac_int_btn.disabled = true
		add_fac_flt_btn.disabled = true
		add_fac_bool_btn.disabled = true
		add_fac_str_btn.disabled = true
		faction_name_ln_edt.editable = false
		add_rank_btn.disabled = true
		load_rank(-1)
		return
	else:
		if not faction_name_ln_edt.editable:
			faction_name_ln_edt.editable = true
		if delete_faction_btn.disabled:
			delete_faction_btn.disabled = false
		if add_fac_int_btn.disabled:
			add_fac_int_btn.disabled = false
		if add_fac_flt_btn.disabled:
			add_fac_flt_btn.disabled = false
		if add_fac_bool_btn.disabled:
			add_fac_bool_btn.disabled = false
		if add_fac_str_btn.disabled:
			add_fac_str_btn.disabled = false
		if ranks_opt_btn.disabled:
			ranks_opt_btn.disabled = false
		if add_rank_btn.disabled:
			add_rank_btn.disabled = false
	
	var faction_id: String = faction_opt_btn.get_item_text(faction_idx)
	
	faction_name_ln_edt.text = factions_resource.get_faction_name(faction_id)
	
	for faction in factions_resource.get_factions():
		factions_tree.set_faction_relationship(
				faction,
				factions_resource.get_faction_relationship(faction_id, faction))
	
	factions_tree.set_active_faction(faction_id)
	factions_tree.tree_enabled = true
	
	for data_key in factions_resource.get_faction_data_keys(faction_id):
		fac_data_tree.add_data(
				data_key,
				factions_resource.get_faction_data(faction_id, data_key))
	
	current_faction = faction_idx
	
	var current_rank: int = -1
	for rank in factions_resource.get_faction_rank_count(faction_id):
		current_rank += 1
		ranks_opt_btn.add_item(str(current_rank))
		
	if ranks_opt_btn.item_count == 0:
		ranks_opt_btn.disabled = true
		load_rank(-1)
	else:
		ranks_opt_btn.disabled = false
		ranks_opt_btn.select(0)
		load_rank(0)


func _on_rank_selected(rank_idx: int) -> void:
	if 0 <= current_rank:
		save_current_rank()
	load_rank(rank_idx)


func load_rank(rank_idx: int) -> void:
	rank_data_tree.clear_data()
	
	if rank_idx == -1:
		delete_rank_btn.disabled = true
		rank_name_ln_edt.editable = false
		rank_name_ln_edt.clear()
		current_rank = -1
		add_rank_int_btn.disabled = true
		add_rank_flt_btn.disabled = true
		add_rank_bool_btn.disabled = true
		add_rank_str_btn.disabled = true
		return
	else:
		if not rank_name_ln_edt.editable:
			rank_name_ln_edt.editable = true
		if delete_rank_btn.disabled:
			delete_rank_btn.disabled = false
		if ranks_opt_btn.disabled:
			ranks_opt_btn.disabled = false
		if add_rank_int_btn.disabled:
			add_rank_int_btn.disabled = false
		if add_rank_flt_btn.disabled:
			add_rank_flt_btn.disabled = false
		if add_rank_bool_btn.disabled:
			add_rank_bool_btn.disabled = false
		if add_rank_str_btn.disabled:
			add_rank_str_btn.disabled = false
	
	var faction: String = faction_opt_btn.get_item_text(current_faction)
	
	rank_name_ln_edt.text = factions_resource.get_rank_name(faction, rank_idx)
	for data_key in factions_resource.get_rank_data_keys(faction, rank_idx):
		rank_data_tree.add_data(
				data_key,
				factions_resource.get_rank_data(faction, rank_idx, data_key))
	current_rank = rank_idx


func _on_rank_delete_pressed():
	var next_rank: int = clampi(current_rank, -1, ranks_opt_btn.item_count - 2)
	
	factions_resource.erase_faction_rank(
			faction_opt_btn.get_item_text(current_faction),
			current_rank)
	
	ranks_opt_btn.select(next_rank)
	load_rank(next_rank)
	something_changed()


func _on_faction_delete_pressed() -> void:
	var next_faction: int = clampi(current_faction, -1, faction_opt_btn.item_count - 2)
	
	factions_resource.erase_faction(faction_opt_btn.get_item_text(current_faction))
	
	faction_opt_btn.select(next_faction)
	load_faction(next_faction)
	something_changed()


func _on_create_faction_pressed() -> void:
	var fac_conf :=  preload("res://addons/nexus_forge/scenes/line_edit_confirmation_dialog.gd").new()
	
	fac_conf.clean_string = true
	fac_conf.accept_empty = false
	fac_conf.invalid_strings = factions_resource.get_factions()
	add_child(fac_conf)
	fac_conf.show()
	fac_conf.focus_line_edit()
	
	var result = await fac_conf.dialog_confirmed
	
	if result[0]:
		factions_resource.create_faction(result[1])
		faction_opt_btn.add_item(result[1])
		factions_tree.add_faction(result[1])
		if 0 <= current_faction:
			save_current_faction()
		faction_opt_btn.select(faction_opt_btn.item_count - 1)
		load_faction(faction_opt_btn.item_count - 1)
		something_changed()
	
	fac_conf.queue_free()


func _on_create_rank_pressed() -> void:
	ranks_opt_btn.add_item(str(ranks_opt_btn.item_count))
	factions_resource.create_faction_rank(
			faction_opt_btn.get_item_text(current_faction),
			"")
	if 0 <= current_rank:
		save_current_rank()
	ranks_opt_btn.select(ranks_opt_btn.item_count - 1)
	load_rank(ranks_opt_btn.item_count - 1)
	something_changed()


func has_unsaved_changes() -> bool:
	return _unsaved


func save() -> void:
	if factions_resource == null:
		return
	
	if current_faction != -1:
		save_current_faction()
	factions_resource.save()
	_unsaved = false
