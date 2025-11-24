@tool
extends PanelContainer


signal recipes_loaded

const LineEditConfirmationDialog = preload("res://addons/nexus_forge/dialogs/lineedit_confirmation_dialog.gd")

var recipes_resource: RecipeCatalog = null

var active_recipe: StringName = &"":
	set(new_active):
		active_recipe = new_active
		var valid: bool = active_recipe != &""
		recipe_input_tree.recipe_selected = valid
		recipe_output_tree.recipe_selected = valid
		add_rcp_int_btn.disabled = not valid
		add_rcp_float_btn.disabled = not valid
		add_rcp_bool_btn.disabled = not valid
		add_rcp_str_btn.disabled = not valid
		add_rcp_fldr_btn.disabled = not valid
var _active_input_rcp: int = -1:
	set(active_item):
		_active_input_rcp = active_item
		var invalid_item: bool = _active_input_rcp == -1
		add_rcp_in_int_btn.disabled = invalid_item
		add_rcp_in_float_btn.disabled = invalid_item
		add_rcp_in_bool_btn.disabled = invalid_item
		add_rcp_in_str_btn.disabled = invalid_item
var _active_output_rcp: int = -1:
	set(active_item):
		_active_output_rcp = active_item
		var invalid_item: bool = _active_output_rcp == -1
		add_rcp_out_int_btn.disabled = invalid_item
		add_rcp_out_float_btn.disabled = invalid_item
		add_rcp_out_bool_btn.disabled = invalid_item
		add_rcp_out_str_btn.disabled = invalid_item
var _unsaved: bool = false

@onready var search_recipes_ln_edt: LineEdit = $CraftingContainer/RecipeSelectContainer/MainContainer/SearchRecipesLnEdt
@onready var create_recipe_btn: Button = $CraftingContainer/RecipeSelectContainer/MainContainer/CreateRecipeBtn
@onready var recipe_tree: Tree = $CraftingContainer/RecipeSelectContainer/RecipeTree
@onready var search_recipe_items_ln_edt: LineEdit = $CraftingContainer/RecipeDataContainer/RecipeItemTreeContainer/SearchRecipeItemsLnEdt
@onready var recipe_items_tree: Tree = $CraftingContainer/RecipeDataContainer/RecipeItemTreeContainer/RecipeItemsTree
@onready var add_rcp_in_int_btn: Button = $CraftingContainer/RecipeDataContainer/RecipeRecipeeContainer/IOContainer/InputContainer/DataBtnCtnr/ButtonContainer/AddRcpInIntBtn
@onready var add_rcp_in_float_btn: Button = $CraftingContainer/RecipeDataContainer/RecipeRecipeeContainer/IOContainer/InputContainer/DataBtnCtnr/ButtonContainer/AddRcpInFloatBtn
@onready var add_rcp_in_bool_btn: Button = $CraftingContainer/RecipeDataContainer/RecipeRecipeeContainer/IOContainer/InputContainer/DataBtnCtnr/ButtonContainer/AddRcpInBoolBtn
@onready var add_rcp_in_str_btn: Button = $CraftingContainer/RecipeDataContainer/RecipeRecipeeContainer/IOContainer/InputContainer/DataBtnCtnr/ButtonContainer/AddRcpInStrBtn
@onready var recipe_input_tree: Tree = $CraftingContainer/RecipeDataContainer/RecipeRecipeeContainer/IOContainer/InputContainer/RecipeInputTree
@onready var add_rcp_out_int_btn: Button = $CraftingContainer/RecipeDataContainer/RecipeRecipeeContainer/IOContainer/OutputContainer/DataBtnCtnr/ButtonContainer/AddRcpOutIntBtn
@onready var add_rcp_out_float_btn: Button = $CraftingContainer/RecipeDataContainer/RecipeRecipeeContainer/IOContainer/OutputContainer/DataBtnCtnr/ButtonContainer/AddRcpOutFloatBtn
@onready var add_rcp_out_bool_btn: Button = $CraftingContainer/RecipeDataContainer/RecipeRecipeeContainer/IOContainer/OutputContainer/DataBtnCtnr/ButtonContainer/AddRcpOutBoolBtn
@onready var add_rcp_out_str_btn: Button = $CraftingContainer/RecipeDataContainer/RecipeRecipeeContainer/IOContainer/OutputContainer/DataBtnCtnr/ButtonContainer/AddRcpOutStrBtn
@onready var recipe_output_tree: Tree = $CraftingContainer/RecipeDataContainer/RecipeRecipeeContainer/IOContainer/OutputContainer/RecipeOutputTree
@onready var add_rcp_fldr_btn: Button = $CraftingContainer/RecipeDataContainer/RecipeRecipeeContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddRcpFldrBtn
@onready var add_rcp_int_btn: Button = $CraftingContainer/RecipeDataContainer/RecipeRecipeeContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddRcpIntBtn
@onready var add_rcp_float_btn: Button = $CraftingContainer/RecipeDataContainer/RecipeRecipeeContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddRcpFloatBtn
@onready var add_rcp_bool_btn: Button = $CraftingContainer/RecipeDataContainer/RecipeRecipeeContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddRcpBoolBtn
@onready var add_rcp_str_btn: Button = $CraftingContainer/RecipeDataContainer/RecipeRecipeeContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddRcpStrBtn
@onready var recipe_custom_data_tree: Tree = $CraftingContainer/RecipeDataContainer/RecipeRecipeeContainer/CustomDataContainer/RecipeCustomDataTree


func _ready() -> void:
	if Engine.is_editor_hint() and get_tree().edited_scene_root == self:
		return
	add_rcp_fldr_btn.icon = get_theme_icon("FolderCreate", "EditorIcons")
	search_recipes_ln_edt.right_icon = get_theme_icon("Search", "EditorIcons")
	search_recipe_items_ln_edt.right_icon = get_theme_icon("Search", "EditorIcons")
	
	reload_recipe_resource(true)
	reload_items()
	
	add_rcp_in_int_btn.pressed.connect(_on_recipe_item_add_data_button_pressed.bind(true, "new_int", 0))
	add_rcp_in_float_btn.pressed.connect(_on_recipe_item_add_data_button_pressed.bind(true, "new_float", 0.0))
	add_rcp_in_bool_btn.pressed.connect(_on_recipe_item_add_data_button_pressed.bind(true, "new_bool", false))
	add_rcp_in_str_btn.pressed.connect(_on_recipe_item_add_data_button_pressed.bind(true, "new_string", ""))
	
	add_rcp_out_int_btn.pressed.connect(_on_recipe_item_add_data_button_pressed.bind(false, "new_int", 0))
	add_rcp_out_float_btn.pressed.connect(_on_recipe_item_add_data_button_pressed.bind(false, "new_float", 0.0))
	add_rcp_out_bool_btn.pressed.connect(_on_recipe_item_add_data_button_pressed.bind(false, "new_bool", false))
	add_rcp_out_str_btn.pressed.connect(_on_recipe_item_add_data_button_pressed.bind(false, "new_string", ""))
	
	recipe_input_tree.recipe_item_selected.connect(_on_input_item_selected)
	recipe_output_tree.recipe_item_selected.connect(_on_output_item_selected)
	
	add_rcp_int_btn.pressed.connect(_on_custom_data_button_pressed.bind("new_int", 0))
	add_rcp_float_btn.pressed.connect(_on_custom_data_button_pressed.bind("new_float", 0.0))
	add_rcp_bool_btn.pressed.connect(_on_custom_data_button_pressed.bind("new_bool", false))
	add_rcp_str_btn.pressed.connect(_on_custom_data_button_pressed.bind("new_string", ""))
	add_rcp_fldr_btn.pressed.connect(_on_custom_data_button_pressed.bind("new_folder", {}))
	
	recipe_input_tree.item_id_dropped.connect(_on_item_id_dropped.bind(true))
	recipe_input_tree.items_changed.connect(_something_changed)
	recipe_output_tree.item_id_dropped.connect(_on_item_id_dropped.bind(false))
	recipe_output_tree.items_changed.connect(_something_changed)
	
	create_recipe_btn.pressed.connect(_on_recipe_create_pressed)
	
	recipe_tree.recipe_selected.connect(_on_recipe_selected)
	recipe_tree.recipe_id_changed.connect(_on_recipe_id_changed)
	recipe_tree.recipe_erased.connect(_on_recipe_erased)
	
	search_recipes_ln_edt.text_changed.connect(_on_recipe_lnedt_text_changed)
	search_recipe_items_ln_edt.text_changed.connect(_on_item_lnedt_text_changed)


func _on_recipe_lnedt_text_changed(text: String) -> void:
	recipe_tree.search_text(text)


func _on_item_lnedt_text_changed(text: String) -> void:
	recipe_items_tree.search_for(text)


func _on_recipe_create_pressed() -> void:
	var id_dialog := LineEditConfirmationDialog.new()
	id_dialog.title = "New Recipe"
	id_dialog.ok_button_text = "Create"
	id_dialog.allow_empty = false
	id_dialog.strip_edges = true
	id_dialog.use_blacklist = true
	id_dialog.text_blacklist.assign(recipe_tree.recipes())
	id_dialog.character_blacklist.append(" ")
	id_dialog.line_placeholder_text = "Recipe ID"
	add_child(id_dialog)
	id_dialog.show()
	id_dialog.grab_text_focus()
	var result: Array = await id_dialog.dialog_finished
	if result[0]:
		var id: StringName = StringName(result[1])
		recipes_resource.create_recipe(id)
		recipe_tree.add_recipe(id, true, false)
		recipe_input_tree.recipe_selected = true
		recipe_output_tree.recipe_selected = true
		load_recipe(id)
		active_recipe = id
		_something_changed()
	id_dialog.queue_free()


func _on_recipe_id_changed(from: StringName, to: StringName) -> void:
	recipes_resource._recipes[to] = recipes_resource._recipes[from]
	recipes_resource._recipes.erase(from)
	if active_recipe == from:
		active_recipe = to
	_something_changed()


func _on_recipe_selected(recipe_id: StringName) -> void:
	if active_recipe == recipe_id:
		return
	if not active_recipe.is_empty():
		save_current_recipe()
	recipe_input_tree.recipe_selected = true
	recipe_output_tree.recipe_selected = true
	load_recipe(recipe_id)
	active_recipe = recipe_id


func _something_changed(arg: Variant = null) -> void:
	if _unsaved:
		return
	_unsaved = true


func _on_item_id_dropped(item_id: StringName, on_index: int, on_input: bool) -> void:
	add_recipe_item(on_input, item_id, 1, RecipeItem.RECIPE_ITEM_DEFAULT_DATA.duplicate(true), on_index)
	_something_changed()


func _on_input_item_selected(index: int) -> void:
	_active_input_rcp = index


func _on_output_item_selected(index: int) -> void:
	_active_output_rcp = index


func _on_recipe_item_add_data_button_pressed(on_input: bool, id: String, data: Variant) -> void:
	add_data_to_active_recipe_item(on_input, data, id)
	_something_changed()


func _on_custom_data_button_pressed(id: String, data: Variant) -> void:
	recipe_custom_data_tree.add_data(id, data)
	_something_changed()


func _on_item_erased(item_id: StringName) -> void:
	recipe_items_tree.remove_item(item_id)
	recipe_input_tree.remove_item(item_id)
	recipe_output_tree.remove_item(item_id)
	_something_changed()


func change_item_name(item_id: StringName, new_name: String) -> void:
	recipe_items_tree.change_name(item_id, new_name)


func change_item_id(old: StringName, new: StringName) -> void:
	recipe_items_tree.change_id(old, new)
	recipe_input_tree.change_item_id(old, new)
	recipe_output_tree.change_item_id(old, new)
	_something_changed()
	
	if recipes_resource == null:
		return
	
	for recipe in recipes_resource.recipes():
		for input_item in recipes_resource[recipe]["input"]:
			if input_item["item_id"] == old:
				input_item["item_id"] = new
		for output_item in recipes_resource[recipe]["output"]:
			if output_item["item_id"] == old:
				output_item["item_id"] = new


func save_current_recipe() -> void:
	var data: Dictionary[String, Variant] = recipe_custom_data_tree.get_data()
	recipes_resource.clear_recipe_data(active_recipe)
	
	for data_key in data.keys():
		recipes_resource.set_recipe_data(
				active_recipe,
				data_key,
				data[data_key])
	
	var inputs: Array[Dictionary] = recipe_input_tree.get_recipe_items()
	var outputs: Array[Dictionary] = recipe_output_tree.get_recipe_items()
	
	var input_items: Array[RecipeItem] = []
	var output_items: Array[RecipeItem] = []
	
	for input in inputs:
		var item: RecipeItem = RecipeItem.new()
		item.id = input["item_id"]
		item.amount = input["amount"]
		item.data.assign(input["data"])
		input_items.append(item)
	
	for output in outputs:
		var item: RecipeItem = RecipeItem.new()
		item.id = output["item_id"]
		item.amount = output["amount"]
		item.data.assign(output["data"])
		output_items.append(item)
	
	recipes_resource.set_recipe_inputs(active_recipe, input_items)
	recipes_resource.set_recipe_outputs(active_recipe, output_items)


func save() -> void:
	if recipes_resource == null:
		return
	if active_recipe != &"":
		save_current_recipe()
	ResourceSaver.save(recipes_resource)
	_unsaved = false


func reload_recipe_resource(first_launch: bool = false) -> void:
	var was_null: bool = recipes_resource == null
	recipes_resource = null
	recipe_tree.clear_recipes()
	recipe_input_tree.clear_items()
	recipe_output_tree.clear_items()
	recipe_custom_data_tree.clear_data()
	
	var path: String = ProjectSettings.get_setting(
			EditorNFPlugin.get_project_settings_path("recipes"),
			"")
	
	if path != "" and FileAccess.file_exists(path):
		var pre_res: Resource = load(path)
		if pre_res is RecipeCatalog:
			recipes_resource = pre_res
	
	$CraftingContainer.visible = recipes_resource != null
	create_recipe_btn.disabled = recipes_resource == null
	
	if recipes_resource == null:
		if not was_null or first_launch:
			var no_db = preload("res://addons/nexus_forge/no_db_container.tscn").instantiate()
			add_child(no_db)
			no_db.message_minimum_size.x = 450
			no_db.set_resource_type("RecipeCatalog", "Recipes", "Recipes")
			no_db.create_resource_pressed.connect(_on_create_database_pressed.bind(no_db))
			no_db.load_resource_pressed.connect(_on_load_database_pressed.bind(no_db))
			no_db.resource_dropped.connect(_on_resource_dropped.bind(no_db))
	else:
		load_recipe_resource()


func add_item(item_id: StringName, item_name: String) -> void:
	recipe_items_tree.add_item(
			item_id,
			item_name)


func reload_items(items: ItemCatalog = null) -> void:
	recipe_items_tree.clear_items()
	
	if items == null:
		var item_path: String = ProjectSettings.get_setting(
				EditorNFPlugin.get_project_settings_path("items"),
				"")
		
		if item_path != "" and FileAccess.file_exists(item_path):
			var res_pre: Resource = load(item_path)
			if res_pre is ItemCatalog:
				for item in res_pre.items():
					recipe_items_tree.add_item(
							item,
							res_pre.get_item_name(item))
	else:
		for item in items.items():
			recipe_items_tree.add_item(
					item,
					items.get_item_name(item))
		


func load_recipe_resource() -> void:
	recipe_tree.clear_recipes()
	create_recipe_btn.disabled = false
	for recipe in recipes_resource.recipes():
		recipe_tree.add_recipe(recipe)
	recipes_loaded.emit()


func _on_create_database_pressed(node: Control) -> void:
	var database_creator := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	database_creator.file_mode = database_creator.FILE_MODE_SAVE_FILE
	add_child(database_creator)
	database_creator.show()
	
	var result = await database_creator.dialog_finished
	
	if result[0]:
		recipes_resource = RecipeCatalog.new()
		ResourceSaver.save(recipes_resource, result[1])
		recipes_resource.resource_path = result[1]
		ProjectSettings.set_setting(
				EditorNFPlugin.get_project_settings_path("recipes"),
				result[1])
		if Engine.is_editor_hint():
			ProjectSettings.save()
		load_recipe_resource()
		$CraftingContainer.visible = true
		node.visible = false
		node.queue_free()
	
	database_creator.queue_free()


func _on_load_database_pressed(node: Control) -> void:
	var database_creator := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	database_creator.file_mode = database_creator.FILE_MODE_OPEN_FILE
	add_child(database_creator)
	database_creator.show()
	
	var result = await database_creator.dialog_finished
	
	if result[0]:
		var res_pre: Resource = load(result[1])
		if res_pre != null and res_pre is RecipeCatalog:
			recipes_resource = res_pre
			ProjectSettings.set_setting(
					EditorNFPlugin.get_project_settings_path("recipes"),
					result[1])
			if Engine.is_editor_hint():
				ProjectSettings.save()
			load_recipe_resource()
			$CraftingContainer.visible = true
			node.visible = false
			node.queue_free()
	
	database_creator.queue_free()


func _on_resource_dropped(resource: Resource, panel: Control) -> void:
	recipes_resource = resource
	ProjectSettings.set_setting(
			EditorNFPlugin.get_project_settings_path("recipes"),
			resource.resource_path)
	if Engine.is_editor_hint():
		ProjectSettings.save()
	panel.visible = false
	panel.queue_free()
	$CraftingContainer.visible = true
	load_recipe_resource()


func _on_recipe_erased(recipe_id: StringName) -> void:
	recipes_resource.erase_recipe(recipe_id)
	if active_recipe == recipe_id:
		active_recipe = &""
		recipe_input_tree.recipe_selected = false
		recipe_output_tree.recipe_selected = false
		
		recipe_input_tree.clear_items()
		recipe_output_tree.clear_items()
		recipe_custom_data_tree.clear_data()


func load_recipe(recipe_id: StringName) -> void:
	var recipe: RecipeSheet = recipes_resource.get_recipe(recipe_id)
	recipe_input_tree.clear_items()
	recipe_output_tree.clear_items()
	
	for item in recipe.input:
		add_recipe_item(
			true,
			item.id,
			item.amount,
			item.data)
	
	for item in recipe.output:
		add_recipe_item(
				false,
				item.id,
				item.amount,
				item.data)
	
	recipe_custom_data_tree.clear_data()
	for data_entry in recipe.data.keys():
		recipe_custom_data_tree.add_data(data_entry, recipe.data[data_entry])


func add_recipe_item(to_input: bool, item_id: StringName, input_amount: int = 1, data: Dictionary = {}, index: int = -1) -> void:
	if to_input:
		recipe_input_tree.add_item(
				item_id,
				input_amount,
				data,
				true,
				true,
				index)
	else:
		recipe_output_tree.add_item(
				item_id,
				input_amount,
				data,
				true,
				true,
				index)


func add_data_to_active_recipe_item(on_input: bool, data: Variant, data_name: String = "new_data") -> void:
	if on_input and _active_input_rcp == null:
		return
	elif not on_input and _active_output_rcp == null:
		return
	
	var new_data: TreeItem = recipe_input_tree.get_root().get_child(_active_input_rcp).create_child() if on_input else recipe_output_tree.get_root().get_child(_active_output_rcp).create_child()
	var new_id: String = validate_data_id(data_name, new_data)
	
	new_data.set_text(0, new_id)
	
	match typeof(data):
		TYPE_INT:
			new_data.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
			new_data.set_range_config(1, -9999, 9999, 1.0)
			new_data.set_range(1, data)
			new_data.set_icon(0, get_theme_icon("int", "EditorIcons"))
			new_data.set_editable(1, true)
			new_data.set_metadata(1, TYPE_INT)
		TYPE_FLOAT:
			new_data.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
			new_data.set_range_config(1, -9999, 9999, 0.01)
			new_data.set_range(1, data)
			new_data.set_icon(0, get_theme_icon("float", "EditorIcons"))
			new_data.set_editable(1, true)
			new_data.set_metadata(1, TYPE_FLOAT)
		TYPE_BOOL:
			new_data.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
			new_data.set_checked(1, data)
			new_data.set_text(1, "Enabled")
			new_data.set_icon(0, get_theme_icon("bool", "EditorIcons"))
			new_data.set_editable(1, true)
			new_data.set_metadata(1, TYPE_BOOL)
		TYPE_STRING:
			new_data.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
			new_data.set_text(1, data)
			new_data.set_icon(0, get_theme_icon("String", "EditorIcons"))
			new_data.set_editable(1, true)
			new_data.set_metadata(1, TYPE_STRING)
		_:
			new_data.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
			new_data.set_text(1, "Data")
			new_data.set_metadata(0, {"data": data})
			new_data.set_editable(1, false)
			new_data.set_metadata(1, TYPE_NIL)
	
	new_data.set_editable(0, true)
	
	new_data.add_button(
			1,
			get_theme_icon("Remove", "EditorIcons"),
			1,
			false,
			"Delete Data")


func validate_data_id(desired_id: String, item: TreeItem = null) -> String:
	var used_ids: PackedStringArray = []
	
	for tree_item in item.get_parent().get_children():
		if tree_item == item:
			continue
		used_ids.append(tree_item.get_text(0))
	
	var current_index: int = 0
	var fixed_id: String = desired_id
	while used_ids.has(fixed_id):
		current_index += 1
		fixed_id = desired_id + "_" + str(current_index)
	return fixed_id
