@tool
extends Control


const CHECK_ICON = preload("res://addons/nexus_forge/common_icons/check_icon.svg")
const ERROR_ICON = preload("res://addons/nexus_forge/common_icons/error_icon.svg")
const RED_MODULATE = Color(0.882, 0.196, 0.235)
const GREEN_MODULATE = Color(0.392, 0.843, 0.196)

var current_faction: String = ""
var _factions_resource: NFFactionRes = null
var _create_faction_mode: bool = true
var no_faction_panel: PanelContainer = null
var factions_resource_dialog: FileDialog = null

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
@onready var save_res_button: Button = $MainContainer/FactionDataContainer/HBoxContainer/MenuContainer/SaveResButton

@onready var select_id_panel: PanelContainer = $SelectIDPanel

#@onready var create_db_button: Button = $NoFactionPanel/CenterContainer/InfoContainer/ButtonContainer2/CreateDBButton
#@onready var load_db_button: Button = $NoFactionPanel/CenterContainer/InfoContainer/ButtonContainer2/LoadDBButton

@onready var main_container: HBoxContainer = $MainContainer

#@onready var main_menu_btn: MenuButton = $MainContainer/FactionDataContainer/HBoxContainer/MenuContainer/MainMenuMnBtn


func _ready() -> void:
	var resource_path: String = ProjectSettings.get_setting(NFFactionRes.SETTINGS_PATH, "")
	#var menu_popup: PopupMenu = main_menu_btn.get_popup()
	
	if not resource_path.is_empty() and ResourceLoader.exists(resource_path):
		var res_preload: Resource = load(resource_path)
		if res_preload is NFFactionRes:
			_factions_resource = res_preload
		else:
			printerr("[FACTIONS] Defined factions resource isn't NFFactionRes")
	
	main_container.visible = _factions_resource != null
	
	if _factions_resource != null:
		_load_resource()
	else:
		factions_resource_dialog = FileDialog.new()
		factions_resource_dialog.add_filter("*.tres", "Resource")
		factions_resource_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
		factions_resource_dialog.size = Vector2i(500, 350)
		factions_resource_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		factions_resource_dialog.file_selected.connect(on_faction_path_selected)
		add_child(factions_resource_dialog)
		
		no_faction_panel = preload("res://addons/nexus_forge/scenes/no_db_container.tscn").instantiate()
		add_child(no_faction_panel)
		no_faction_panel.set_resource_type("NFFactionRes", "Factions", "Factions")
		no_faction_panel.create_resource_pressed.connect(on_create_fac_db_pressed)
		no_faction_panel.load_resource_pressed.connect(on_load_fact_db_pressed)
		no_faction_panel.visible = true
	
	#menu_popup.id_pressed.connect(on_menu_id_selected)
	save_res_button.pressed.connect(on_save_resource_pressed)
	id_line.text_changed.connect(on_id_line_changed)
	id_line.text_submitted.connect(on_id_text_submitted)
	accept_button.pressed.connect(on_faction_created)
	add_fact_button.pressed.connect(on_create_faction_pressed)
	add_rank_btn.pressed.connect(on_create_rank_pressed)
	cancel_button.pressed.connect(select_id_panel.hide)
	faction_rank_tree.rank_renamed.connect(on_rank_renamed)
	search_ally_ln_edt.text_changed.connect(on_search_faction.bind(ally_faction_tree))
	search_enemy_ln_edt.text_changed.connect(on_search_faction.bind(enemy_faction_tree))
	rank_search_ln_edt.text_changed.connect(on_search_rank)
	flags_ln_edt.text_changed.connect(on_search_flag)
	faction_opt_btn.item_selected.connect(on_faction_selected)
	ally_faction_tree.faction_selected.connect(on_faction_checked.bind(enemy_faction_tree))
	enemy_faction_tree.faction_selected.connect(on_faction_checked.bind(ally_faction_tree))


func on_faction_checked(faction_id: String, opposite: Tree) -> void:
	opposite.set_faction_checked(faction_id, false)


func on_search_flag(flag_text: String) -> void:
	flags_tree.search_flags(flag_text.strip_edges())


func on_search_rank(rank: String) -> void:
	faction_rank_tree.search_rank(rank.strip_edges())


func on_search_faction(faction_search: String, faction_tree: Tree) -> void:
	faction_tree.search_faction(faction_search.strip_edges())


func on_save_resource_pressed() -> void:
	if faction_opt_btn.selected != -1:
		save_current()
	save_resource()


#func on_menu_id_selected(id: int) -> void:
	#match id:
		#0:
			#if faction_opt_btn.selected != -1:
				#save_current()
			#save_resource()


func _load_resource() -> void:
	faction_opt_btn.clear()
	
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
		ProjectSettings.set_setting(NFFactionRes.SETTINGS_PATH, file_path)
		ProjectSettings.save()
		no_faction_panel.visible = false
		main_container.visible = true
		no_faction_panel.queue_free()
		factions_resource_dialog.queue_free()
		_load_resource()


func on_faction_created() -> void:
	select_id_panel.visible = false
	var selected_id: String = id_line.text.strip_edges()
	
	if _create_faction_mode:
		_factions_resource.create_faction(selected_id)
		faction_opt_btn.add_item(selected_id)
		ally_faction_tree.add_faction(selected_id)
		enemy_faction_tree.add_faction(selected_id)
		faction_opt_btn.select(faction_opt_btn.item_count - 1)
		on_faction_selected(faction_opt_btn.item_count - 1)
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


func on_rank_renamed(from: String, to: String) -> void:
	print(str(from, ",", to))
	var rank_idx: int = _factions_resource.get_rank_level(current_faction, from)
	if rank_idx == -1:
		print("fail")
		return
	_factions_resource.factions[current_faction]["ranks"][rank_idx]["id"] = to


func on_faction_selected(faction_idx: int) -> void:
	if not current_faction.is_empty():
		save_current()
	
	rank_search_ln_edt.clear()
	search_ally_ln_edt.clear()
	search_enemy_ln_edt.clear()
	faction_rank_tree.clear_ranks()
	ally_faction_tree.clear_checks()
	enemy_faction_tree.clear_checks()
	
	faction_ln_edt.editable = faction_idx != -1
	add_rank_btn.disabled = faction_idx == -1
	rank_search_ln_edt.editable = faction_idx != -1
	faction_desc_text_edt.editable = faction_idx != -1
	delete_faction_btn.disabled = faction_idx == -1
	search_ally_ln_edt.editable = faction_idx != -1
	search_enemy_ln_edt.editable = faction_idx != -1
	flags_tree.set_editable(faction_idx != -1)
	
	if 0 <= faction_idx:
		current_faction = faction_opt_btn.get_item_text(faction_opt_btn.selected)
		var faction_ranks: Array = _factions_resource.get_faction_ranks(current_faction)
		ally_faction_tree.set_current_faction(current_faction)
		enemy_faction_tree.set_current_faction(current_faction)
		
		faction_ln_edt.text = _factions_resource.get_faction_name(current_faction)
		for rank_idx in range(faction_ranks.size()):
			faction_rank_tree.add_rank(
					-1,
					faction_ranks[rank_idx],
					Strings.title_case(_factions_resource.get_rank_name(current_faction, rank_idx)))
		
		faction_desc_text_edt.text = _factions_resource.get_faction_description(current_faction)
		flags_tree.set_flags(_factions_resource.get_faction_flags(current_faction))
		
		for faction_relation in _factions_resource.get_factions():
			if faction_relation == current_faction:
				continue
			var relation: int = _factions_resource.get_faction_relationship(current_faction, faction_relation)
			ally_faction_tree.set_faction_checked(faction_relation, relation == 1)
			enemy_faction_tree.set_faction_checked(faction_relation, relation == -1)
	else:
		current_faction = ""
		var valid_faction: bool = not current_faction.is_empty()
		add_rank_btn.disabled = not valid_faction
		faction_desc_text_edt.editable = valid_faction
		flags_tree.clear_flags()
		faction_desc_text_edt.clear()
		faction_ln_edt.clear()


func on_create_faction_pressed() -> void:
	_create_faction_mode = true
	id_line.clear()
	
	select_id_panel.visible = true


func on_create_rank_pressed() -> void:
	_factions_resource.create_faction_rank(
			current_faction,
			faction_rank_tree.add_rank(-1, "new_rank", "New Rank"),
			-1)


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


func save_current() -> void:
	#var faction_id: String = faction_opt_btn.get_item_text(faction_opt_btn.selected)
	if not _factions_resource.has_faction(current_faction):
		_factions_resource.create_faction(current_faction)
	
	_factions_resource.set_faction_name(current_faction, faction_ln_edt.text.strip_edges())
	_factions_resource.set_faction_description(current_faction, faction_desc_text_edt.text.strip_edges())
	_factions_resource.set_faction_flags(current_faction, flags_tree.get_flags())
	_factions_resource.clear_faction_relationships(current_faction)
	
	for ally in ally_faction_tree.get_enabled_factions():
		_factions_resource.set_faction_ally(current_faction, ally)
	for enemy in enemy_faction_tree.get_enabled_factions():
		_factions_resource.set_faction_enemy(current_faction, enemy)
	
	var ranks: Array = faction_rank_tree.get_ranks() 
	for rank_idx in range(ranks.size()):
		if not _factions_resource.is_rank(
				current_faction,
				ranks[rank_idx]["id"],
				rank_idx):
			_factions_resource.set_faction_rank_level(
					current_faction,
					ranks[rank_idx]["id"],
					rank_idx)
		
		_factions_resource.set_faction_rank_name(
				current_faction,
				rank_idx,
				ranks[rank_idx]["name"])


func save_resource() -> void:
	_factions_resource.save()
