extends Control


const CHECK_ICON = preload("res://addons/nexus_forge/common_icons/check_icon.svg")
const ERROR_ICON = preload("res://addons/nexus_forge/common_icons/error_icon.svg")
const RED_MODULATE = Color(0.882, 0.196, 0.235)
const GREEN_MODULATE = Color(0.392, 0.843, 0.196)

var _factions_resource: NFFactionRes = null:
	set(new_res):
		_factions_resource = new_res
		main_container.visible = new_res != null
		no_faction_panel.visible = new_res == null
var _create_faction_mode: bool = true

@onready var id_line: LineEdit = $SelectIDPanel/CenterContainer/ItemsContainer/DataPanel/ItemsContainer/IDContainer/IDLinePanel/IDLine
@onready var id_status_texture: TextureRect = $SelectIDPanel/CenterContainer/ItemsContainer/DataPanel/ItemsContainer/IDContainer/IDStatusTexture
@onready var cancel_button: Button = $SelectIDPanel/CenterContainer/ItemsContainer/DataPanel/ItemsContainer/ButtonsContainer/CancelButton
@onready var accept_button: Button = $SelectIDPanel/CenterContainer/ItemsContainer/DataPanel/ItemsContainer/ButtonsContainer/AcceptButton

@onready var faction_ln_edt: LineEdit = $MainContainer/FactionDataContainer/FactionIDContainer/FactionLnEdt
@onready var add_rank_btn: Button = $MainContainer/FactionDataContainer/RanksContainer/HeaderContainer/ButtonsContainer/AddRankBtn
@onready var rank_search_ln_edt: LineEdit = $MainContainer/FactionDataContainer/RanksContainer/RankSearchLnEdt
@onready var faction_desc_text_edt: TextEdit = $MainContainer/FactionDataContainer/DescriptionContainer/FactionDescTextEdt
@onready var flags_ln_edt: LineEdit = $MainContainer/FlagsContainer/FlagsLnEdt
@onready var flags_tree: Tree = $MainContainer/FlagsContainer/FlagsTree
@onready var search_ally_ln_edt: LineEdit = $MainContainer/FactionRelationContainer/HBoxContainer/AllyContainer/SearchAllyLnEdt
@onready var ally_faction_tree: Tree = $MainContainer/FactionRelationContainer/HBoxContainer/AllyContainer/AllyFactionTree
@onready var search_enemy_ln_edt: LineEdit = $MainContainer/FactionRelationContainer/HBoxContainer/EnemyContainer/SearchEnemyLnEdt
@onready var enemy_faction_tree: Tree = $MainContainer/FactionRelationContainer/HBoxContainer/EnemyContainer/EnemyFactionTree
@onready var faction_opt_btn: OptionButton = $MainContainer/FactionDataContainer/FactionIDContainer/FactionSelect/FactionOptBtn
@onready var faction_rank_tree: Tree = $MainContainer/FactionDataContainer/RanksContainer/FactionRankTree
@onready var delete_faction_btn: Button = $MainContainer/FactionDataContainer/FactionIDContainer/FactionSelect/DeleteFactionBtn
@onready var add_fact_button: Button = $MainContainer/FactionDataContainer/FactionIDContainer/HeaderContainer/ButtonsContainer/AddFactButton

@onready var select_id_panel: PanelContainer = $SelectIDPanel

@onready var factions_resource_dialog: FileDialog = $Elements/FactionsResourceDialog
@onready var create_db_button: Button = $NoFactionPanel/CenterContainer/InfoContainer/ButtonContainer2/CreateDBButton
@onready var load_db_button: Button = $NoFactionPanel/CenterContainer/InfoContainer/ButtonContainer2/LoadDBButton

@onready var no_faction_panel: PanelContainer = $NoFactionPanel
@onready var main_container: HBoxContainer = $MainContainer


func _ready() -> void:
	var resource_path: String = ProjectSettings.get_setting(NFFactionRes.FACTIONS_RESOURCE_PATH, "")
	
	if resource_path.is_empty() or not ResourceLoader.exists(resource_path):
		no_faction_panel.visible = true
		main_container.visible = false
	else:
		var res_preload: Resource = load(resource_path)
		if res_preload is NFFactionRes:
			_factions_resource = res_preload
		else:
			printerr("[FACTIONS] Defined factions resource isn't NFFactionRes")
	
	if _factions_resource != null:
		_load_resource()
	
	id_line.text_changed.connect(on_id_line_changed)
	accept_button.pressed.connect(on_faction_created)
	add_fact_button.pressed.connect(on_create_faction_pressed)
	add_rank_btn.pressed.connect(on_create_rank_pressed)
	factions_resource_dialog.file_selected.connect(on_faction_path_selected)
	create_db_button.pressed.connect(on_create_fac_db_pressed)
	load_db_button.pressed.connect(on_load_fact_db_pressed)


func _load_resource() -> void:
	for faction in _factions_resource.get_factions():
		faction_opt_btn.add_item(faction)
		ally_faction_tree.add_faction(faction)
		enemy_faction_tree.add_faction(faction)
	
	if 0 < faction_opt_btn.item_count:
		faction_opt_btn.select(0)
		on_faction_selected(0)


func on_create_fac_db_pressed() -> void:
	factions_resource_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	factions_resource_dialog.show()


func on_load_fact_db_pressed() -> void:
	factions_resource_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	factions_resource_dialog.show()


func on_faction_path_selected(file_path: String) -> void:
	if factions_resource_dialog.file_mode == FileDialog.FileMode.FILE_MODE_SAVE_FILE:
		var new_faction_res := NFFactionRes.new()
		_factions_resource = new_faction_res
		ResourceSaver.save(_factions_resource, file_path)
	else:
		var fac_preload: Resource = load(file_path)
		if fac_preload is NFFactionRes:
			_factions_resource = fac_preload
		else:
			printerr("[FACTIONS] Defined factions resource isn't NFFactionRes")
	
	if _factions_resource != null:
		ProjectSettings.set_setting(NFFactionRes.FACTIONS_RESOURCE_PATH, file_path)
		ProjectSettings.save()
		_load_resource()


func on_faction_created() -> void:
	select_id_panel.visible = false
	var selected_id: String = id_line.text.strip_edges()
	
	if _create_faction_mode:
		_factions_resource.create_faction(selected_id)
		faction_opt_btn.add_item(selected_id)
		ally_faction_tree.add_faction(selected_id)
		enemy_faction_tree.add_faction(selected_id)
		faction_opt_btn.select(faction_opt_btn.item_count)
		on_faction_selected(faction_opt_btn.item_count)
	else:
		var faction_level: int = faction_rank_tree.get_rank_count()
		_factions_resource.create_faction_rank(
			faction_opt_btn.get_item_text(faction_opt_btn.selected),
			selected_id,
			faction_level)
		
		faction_rank_tree.add_rank(
				faction_level,
				selected_id,
				"")


func on_delete_faction_pressed() -> void:
	var faction_id: String = faction_opt_btn.get_item_text(faction_opt_btn.selected)
	
	_factions_resource.delete_faction(faction_id)
	ally_faction_tree.remove_faction(faction_id)
	enemy_faction_tree.remove_faction(faction_id)
	faction_opt_btn.remove_item(faction_opt_btn.selected)
	on_faction_selected(faction_opt_btn.selected)


func on_faction_selected(faction_idx: int) -> void:
	rank_search_ln_edt.clear()
	search_ally_ln_edt.clear()
	search_enemy_ln_edt.clear()
	faction_rank_tree.clear_ranks()
	
	faction_ln_edt.editable = faction_idx != -1
	add_rank_btn.disabled = faction_idx == -1
	rank_search_ln_edt.editable = faction_idx != -1
	faction_desc_text_edt.editable = faction_idx != -1
	delete_faction_btn.disabled = faction_idx == -1
	search_ally_ln_edt.editable = faction_idx != -1
	search_enemy_ln_edt.editable = faction_idx != -1
	flags_tree.set_editable(faction_idx != -1)
	
	if faction_idx != -1:
		var faction_id: String = faction_opt_btn.get_item_text(faction_opt_btn.selected)
		var faction_ranks: Dictionary = _factions_resource.get_faction_ranks(faction_id)
		var factions_relations: Dictionary = _factions_resource.get_factions_relationships(faction_id)
		faction_ln_edt.text = _factions_resource.get_faction_name(faction_id)
		for rank_id in faction_ranks:
			faction_rank_tree.add_rank(
					faction_ranks[rank_id]["level"],
					rank_id,
					Strings.title_case(faction_ranks[rank_id]["name"]))
		faction_desc_text_edt.text = _factions_resource.get_faction_description(faction_id)
		flags_tree.set_flags(_factions_resource.get_faction_flags(faction_id))
		for relation_id in factions_relations:
			ally_faction_tree.set_faction_checked(relation_id, factions_relations[faction_id] == NFFactionRes.FactionRelation.ALLY)
			enemy_faction_tree.set_faction_checked(relation_id, factions_relations[faction_id] == NFFactionRes.FactionRelation.ENEMY)
	else:
		flags_tree.clear_flags()
		faction_desc_text_edt.clear()
		faction_ln_edt.clear()
		ally_faction_tree.clear_checks()
		enemy_faction_tree.clear_checks()


func on_create_faction_pressed() -> void:
	_create_faction_mode = true
	id_line.clear()
	
	select_id_panel.visible = true


func on_create_rank_pressed() -> void:
	_create_faction_mode = false
	id_line.clear()
	
	select_id_panel.visible = true


func on_id_line_changed(new_text: String) -> void:
	var new_id: String = new_text.strip_edges()
	
	if new_id.is_empty():
		id_status_texture.texture = ERROR_ICON
		id_status_texture.modulate = RED_MODULATE
		accept_button.disabled = true
	else:
		var existing_id: bool = _factions_resource.has_faction(new_id) if _create_faction_mode else _factions_resource.has_rank(faction_opt_btn.get_item_text(faction_opt_btn.selected), new_id)
		
		if existing_id:
			id_status_texture.texture = ERROR_ICON
			id_status_texture.modulate = RED_MODULATE
		else:
			id_status_texture.texture = CHECK_ICON
			id_status_texture.modulate = GREEN_MODULATE
		
		accept_button.disabled = existing_id


func on_id_text_submitted(_text_submit: String) -> void:
	if accept_button.disabled == false:
		on_faction_created()
