@tool
extends PanelContainer


signal recipes_loaded

const MAX_UNDO_STEPS: int = 50

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
		recipe_custom_data_tree.enabled = valid
var _unsaved: bool = false
var undo: UndoRedo

@onready var search_recipes_ln_edt: LineEdit = $CraftingContainer/RecipeSelectContainer/MainContainer/SearchRecipesLnEdt
@onready var create_recipe_btn: Button = $CraftingContainer/RecipeSelectContainer/MainContainer/CreateRecipeBtn
@onready var recipe_tree: Tree = $CraftingContainer/RecipeSelectContainer/RecipeTree
@onready var search_recipe_items_ln_edt: LineEdit = $CraftingContainer/RecipeDataContainer/RecipeItemTreeContainer/SearchRecipeItemsLnEdt
@onready var recipe_items_tree: Tree = $CraftingContainer/RecipeDataContainer/RecipeItemTreeContainer/RecipeItemsTree
@onready var recipe_input_tree: Tree = $CraftingContainer/RecipeDataContainer/RecipeRecipeeContainer/IOContainer/InputContainer/RecipeInputTree
@onready var recipe_output_tree: Tree = $CraftingContainer/RecipeDataContainer/RecipeRecipeeContainer/IOContainer/OutputContainer/RecipeOutputTree
@onready var add_rcp_fldr_btn: Button = $CraftingContainer/RecipeDataContainer/RecipeRecipeeContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddRcpFldrBtn
@onready var add_rcp_int_btn: Button = $CraftingContainer/RecipeDataContainer/RecipeRecipeeContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddRcpIntBtn
@onready var add_rcp_float_btn: Button = $CraftingContainer/RecipeDataContainer/RecipeRecipeeContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddRcpFloatBtn
@onready var add_rcp_bool_btn: Button = $CraftingContainer/RecipeDataContainer/RecipeRecipeeContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddRcpBoolBtn
@onready var add_rcp_str_btn: Button = $CraftingContainer/RecipeDataContainer/RecipeRecipeeContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddRcpStrBtn
@onready var recipe_custom_data_tree: Tree = $CraftingContainer/RecipeDataContainer/RecipeRecipeeContainer/CustomDataContainer/RecipeCustomDataTree


func _ready() -> void:
	set_process_input(false)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	
	if event is InputEventKey:
		if event.echo or not event.pressed:
			return
		
		if event.keycode == KEY_DELETE and not event.ctrl_pressed and not event.shift_pressed:
			
			if not active_recipe.is_empty():
				recipe_tree.remove_recipe(active_recipe)
				_on_recipe_erased(active_recipe)
			get_viewport().set_input_as_handled()
			return
		
		if not event.ctrl_pressed:
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
					_something_changed()
			else:
				if undo.has_undo():
					var action_name: String = undo.get_current_action_name()
					undo.undo()
					NFPluginGameHandler._log_msg(
						"",
						"Undo: " + action_name,
						NFPluginGameHandler._LogLevel.EDITOR)
					_something_changed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_Y and not event.shift_pressed:
			if undo.has_redo():
				var action_name: String = undo.get_action_name(undo.get_current_action() + 1)
				undo.redo()
				NFPluginGameHandler._log_msg(
						"",
						"Redo: " + action_name,
						NFPluginGameHandler._LogLevel.EDITOR)
				_something_changed()
			get_viewport().set_input_as_handled()


func ready_plugin() -> void:
	undo = UndoRedo.new()
	undo.max_steps = MAX_UNDO_STEPS
	
	recipe_custom_data_tree.undo_redo_steps = MAX_UNDO_STEPS
	
	set_process_input(true)
	
	recipe_tree.ready_plugin()
	recipe_items_tree.ready_plugin()
	recipe_input_tree.ready_plugin()
	recipe_output_tree.ready_plugin()
	recipe_custom_data_tree.ready_plugin()
	
	add_rcp_fldr_btn.icon = get_theme_icon("FolderCreate", "EditorIcons")
	search_recipes_ln_edt.right_icon = get_theme_icon("Search", "EditorIcons")
	search_recipe_items_ln_edt.right_icon = get_theme_icon("Search", "EditorIcons")
	
	reload_recipe_resource(true)
	reload_items()
	
	add_rcp_int_btn.pressed.connect(_on_custom_data_button_pressed.bind("new_int", 0))
	add_rcp_float_btn.pressed.connect(_on_custom_data_button_pressed.bind("new_float", 0.0))
	add_rcp_bool_btn.pressed.connect(_on_custom_data_button_pressed.bind("new_bool", false))
	add_rcp_str_btn.pressed.connect(_on_custom_data_button_pressed.bind("new_string", ""))
	add_rcp_fldr_btn.pressed.connect(_on_custom_data_button_pressed.bind("new_folder", {}))
	
	create_recipe_btn.pressed.connect(_on_recipe_create_pressed)
	
	recipe_tree.recipe_selected.connect(_on_recipe_selected)
	recipe_tree.recipe_id_changed.connect(_on_recipe_id_changed)
	recipe_tree.recipe_erased.connect(_on_recipe_erased)
	
	search_recipes_ln_edt.text_changed.connect(_on_recipe_lnedt_text_changed)
	search_recipe_items_ln_edt.text_changed.connect(_on_item_lnedt_text_changed)
	
	recipe_custom_data_tree.data_changed.connect(_on_recipe_data_changed)
	
	recipe_input_tree.ingredient_added.connect(_on_ingredient_added.bind(true))
	recipe_input_tree.ingredient_amount_changed.connect(_on_ingredient_amount_changed.bind(true))
	recipe_input_tree.ingredient_moved.connect(_on_ingredient_moved.bind(true))
	recipe_input_tree.ingredient_erase_pressed.connect(_on_ingredient_erase_pressed.bind(true))
	recipe_input_tree.metadata_added.connect(_on_recipe_item_metadata_added.bind(true))
	recipe_input_tree.metadata_moved.connect(_on_recipe_ingredient_metadata_moved.bind(true))
	recipe_input_tree.metadata_removed.connect(_on_recipe_ingredient_metadata_removed.bind(true))
	recipe_input_tree.metadata_changed.connect(_on_ingredient_metadata_changed.bind(true))
	recipe_input_tree.metadata_renamed.connect(_on_ingredient_metadata_renamed.bind(true))
	
	recipe_output_tree.ingredient_added.connect(_on_ingredient_added.bind(false))
	recipe_output_tree.ingredient_amount_changed.connect(_on_ingredient_amount_changed.bind(false))
	recipe_output_tree.ingredient_moved.connect(_on_ingredient_moved.bind(false))
	recipe_output_tree.ingredient_erase_pressed.connect(_on_ingredient_erase_pressed.bind(false))
	recipe_output_tree.metadata_added.connect(_on_recipe_item_metadata_added.bind(false))
	recipe_output_tree.metadata_moved.connect(_on_recipe_ingredient_metadata_moved.bind(false))
	recipe_output_tree.metadata_removed.connect(_on_recipe_ingredient_metadata_removed.bind(false))
	recipe_output_tree.metadata_changed.connect(_on_ingredient_metadata_changed.bind(false))
	recipe_output_tree.metadata_renamed.connect(_on_ingredient_metadata_renamed.bind(false))


func _on_recipe_lnedt_text_changed(text: String) -> void:
	recipe_tree.search_text(text)


func _on_item_lnedt_text_changed(text: String) -> void:
	recipe_items_tree.search_for(text)


func _on_recipe_selected(recipe_id: StringName) -> void:
	if active_recipe == recipe_id:
		return
	switch_to_recipe(recipe_id)


func _something_changed(arg: Variant = null) -> void:
	if _unsaved:
		return
	_unsaved = true


func _on_custom_data_button_pressed(id: String, data: Variant) -> void:
	recipe_custom_data_tree.add_data(id, data)
	_something_changed()


func _on_item_erased(item_id: StringName) -> void:
	if recipes_resource == null:
		return
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
	
	if recipes_resource == null:
		return
	
	_something_changed()
	for recipe in recipes_resource.recipes():
		for input_item in recipes_resource._recipes[recipe]["input"]:
			if input_item["item_id"] == old:
				input_item["item_id"] = new
		for output_item in recipes_resource._recipes[recipe]["output"]:
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
		item.custom_data.assign(input["data"])
		input_items.append(item)
	
	for output in outputs:
		var item: RecipeItem = RecipeItem.new()
		item.id = output["item_id"]
		item.amount = output["amount"]
		item.custom_data.assign(output["data"])
		output_items.append(item)
	
	recipes_resource.set_recipe_inputs(active_recipe, input_items)
	recipes_resource.set_recipe_outputs(active_recipe, output_items)


func save() -> void:
	_unsaved = false
	if recipes_resource == null:
		return
	if active_recipe != &"":
		save_current_recipe()
	ResourceSaver.save(recipes_resource)


func reload_recipe_resource(first_launch: bool = false) -> void:
	var was_null: bool = recipes_resource == null
	recipes_resource = null
	recipe_tree.clear_recipes()
	recipe_input_tree.clear_items()
	recipe_output_tree.clear_items()
	recipe_custom_data_tree.clear_data()
	
	var path: String = ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("recipes"),
			"")
	
	if path != "" and FileAccess.file_exists(path):
		var pre_res: Resource = load(path)
		if pre_res is RecipeCatalog:
			recipes_resource = pre_res
	
	$CraftingContainer.visible = recipes_resource != null
	create_recipe_btn.disabled = recipes_resource == null
	
	if recipes_resource == null:
		if not was_null or first_launch:
			var no_db: Control = load("res://addons/nexus_forge/no_db_container.tscn").instantiate()
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
				NFPluginGameHandler.get_setting_path("items"),
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
	var database_creator: FileDialog = load("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	database_creator.file_mode = database_creator.FILE_MODE_SAVE_FILE
	add_child(database_creator)
	database_creator.show()
	
	var result = await database_creator.dialog_finished
	
	if result[0]:
		recipes_resource = RecipeCatalog.new()
		ResourceSaver.save(recipes_resource, result[1])
		recipes_resource.resource_path = result[1]
		ProjectSettings.set_setting(
				NFPluginGameHandler.get_setting_path("recipes"),
				result[1])
		if Engine.is_editor_hint():
			ProjectSettings.save()
		load_recipe_resource()
		$CraftingContainer.visible = true
		node.visible = false
		node.queue_free()
	
	database_creator.queue_free()


func _on_load_database_pressed(node: Control) -> void:
	var database_creator: FileDialog = load("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	database_creator.file_mode = database_creator.FILE_MODE_OPEN_FILE
	add_child(database_creator)
	database_creator.show()
	
	var result = await database_creator.dialog_finished
	
	if result[0]:
		var res_pre: Resource = load(result[1])
		if res_pre != null and res_pre is RecipeCatalog:
			recipes_resource = res_pre
			ProjectSettings.set_setting(
					NFPluginGameHandler.get_setting_path("recipes"),
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
			NFPluginGameHandler.get_setting_path("recipes"),
			resource.resource_path)
	if Engine.is_editor_hint():
		ProjectSettings.save()
	panel.visible = false
	panel.queue_free()
	$CraftingContainer.visible = true
	load_recipe_resource()


func load_recipe(recipe_id: StringName) -> void:
	var recipe: RecipeSheet = recipes_resource.get_recipe(recipe_id)
	
	if recipe == null:
		NFPluginGameHandler._log_msg(
				"crafting - editor",
				"Error while loading recipe '%s'" % recipe_id,
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	recipe_input_tree.clear_items()
	recipe_output_tree.clear_items()
	
	for item in recipe.input:
		recipe_input_tree.add_item(
				item.id,
				item.amount,
				item.custom_data)
	
	for item in recipe.output:
		recipe_output_tree.add_item(
				item.id,
				item.amount,
				item.custom_data)
	
	recipe_custom_data_tree.clear_data(false)
	for data_entry in recipe.custom_data.keys():
		recipe_custom_data_tree.add_data(data_entry, recipe.custom_data[data_entry], true)


func switch_to_recipe(recipe_id: StringName) -> void:
	if not active_recipe.is_empty():
		save_current_recipe()
	recipe_input_tree.recipe_selected = true
	recipe_output_tree.recipe_selected = true
	load_recipe(recipe_id)
	active_recipe = recipe_id


# - Undo/Redo Operations -

func _on_recipe_create_pressed() -> void:
	var id_dialog: ConfirmationDialog = load("res://addons/nexus_forge/dialogs/lineedit_confirmation_dialog.gd").new()
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
		
		undo.create_action("Create Recipe")
		undo.add_do_method(_do_create_recipe.bind(id))
		undo.add_undo_method(_undo_create_recipe.bind(id))
		undo.commit_action(false)
		
		recipes_resource.create_recipe(id)
		recipe_tree.add_recipe(id, true, false)
		recipe_input_tree.recipe_selected = true
		recipe_output_tree.recipe_selected = true
		load_recipe(id)
		active_recipe = id
		_something_changed()
	id_dialog.queue_free()


func _do_create_recipe(recipe_id: StringName) -> void:
	recipes_resource.create_recipe(recipe_id)
	recipe_tree.add_recipe(recipe_id, false)


func _undo_create_recipe(recipe_id: StringName) -> void:
	recipes_resource.erase_recipe(recipe_id)
	recipe_tree.remove_recipe(recipe_id)
	if active_recipe == recipe_id:
		active_recipe = &""
		recipe_input_tree.recipe_selected = false
		recipe_output_tree.recipe_selected = false
		
		recipe_input_tree.clear_items()
		recipe_output_tree.clear_items()
		recipe_custom_data_tree.clear_data(false)


func _on_recipe_id_changed(from: StringName, to: StringName) -> void:
	if from == to:
		return
	
	undo.create_action("Set Recipe ID")
	undo.add_do_method(_do_update_recipe_id.bind(from, to))
	undo.add_undo_method(_do_update_recipe_id.bind(to, from))
	undo.commit_action()
	
	_something_changed()


func _do_update_recipe_id(from: StringName, to: StringName) -> void:
	recipes_resource._recipes[to] = recipes_resource._recipes[from]
	recipes_resource._recipes.erase(from)
	if active_recipe == from:
		active_recipe = to


func _on_recipe_erased(recipe_id: StringName) -> void:
	var recipe_data: Dictionary = {}
	
	if active_recipe == recipe_id:
		var inputs: Array[Dictionary] = recipe_input_tree.get_recipe_items()
		var outputs: Array[Dictionary] = recipe_output_tree.get_recipe_items()
		var custom_data: Dictionary[String, Variant] = recipe_custom_data_tree.get_data()
		
		recipe_data = {
			"input": inputs,
			"output": outputs,
			"custom_data": custom_data}
	else:
		recipe_data = recipes_resource._recipes[recipe_id].duplicate(true)
	
	undo.create_action("Erase Recipe")
	undo.add_do_method(_do_erase_recipe.bind(recipe_id))
	undo.add_undo_method(_undo_erase_recipe.bind(recipe_id, recipe_data))
	undo.commit_action(false)
	
	recipes_resource.erase_recipe(recipe_id)
	
	if active_recipe == recipe_id:
		active_recipe = &""
		recipe_input_tree.recipe_selected = false
		recipe_output_tree.recipe_selected = false
		
		recipe_input_tree.clear_items()
		recipe_output_tree.clear_items()
		recipe_custom_data_tree.clear_data(false)
	
	_something_changed()


func _undo_erase_recipe(recipe_id: StringName, recipe_data: Dictionary) -> void:
	recipes_resource._recipes[recipe_id] = recipe_data.duplicate(true)
	recipe_tree.add_recipe(recipe_id)


func _do_erase_recipe(recipe_id: StringName) -> void:
	recipes_resource.erase_recipe(recipe_id)
	recipe_tree.remove_recipe(recipe_id)
	
	if active_recipe == recipe_id:
		active_recipe = &""
		recipe_input_tree.recipe_selected = false
		recipe_output_tree.recipe_selected = false
		
		recipe_input_tree.clear_items()
		recipe_output_tree.clear_items()
		recipe_custom_data_tree.clear_data(false)


func _on_recipe_data_changed() -> void:
	if recipe_custom_data_tree.has_undo():
		undo.create_action("Data Changed")
		undo.add_do_method(_do_update_custom_data.bind(active_recipe, false))
		undo.add_undo_method(_do_update_custom_data.bind(active_recipe, true))
		undo.commit_action(false)
	_something_changed()


func _do_update_custom_data(recipe_id: StringName, is_undo: bool) -> void:
	if active_recipe != recipe_id:
		recipe_tree.select_recipe(recipe_id, false)
		switch_to_recipe(recipe_id)
	if is_undo:
		recipe_custom_data_tree.undo()
	else:
		recipe_custom_data_tree.redo()


func _on_ingredient_erase_pressed(index: int, on_input: bool) -> void:
	var data: Dictionary = (recipe_input_tree if on_input else recipe_output_tree).get_ingredient_data(index)
	
	undo.create_action("Erase '%s' %s Ingredient" % [active_recipe, "Input" if on_input else "Output"])
	undo.add_do_method(_do_erase_ingredient.bind(active_recipe, on_input, index))
	undo.add_undo_method(_undo_erase_ingredient.bind(active_recipe, on_input, data))
	undo.commit_action()
	
	_something_changed()


func _do_erase_ingredient(on_recipe: StringName, on_input: bool, ingredient_index: int) -> void:
	if on_recipe != active_recipe:
		recipe_tree.select_recipe(on_recipe, false)
		switch_to_recipe(on_recipe)
	
	if on_input:
		recipe_input_tree.remove_ingredient(ingredient_index)
	else:
		recipe_output_tree.remove_ingredient(ingredient_index)


func _undo_erase_ingredient(on_recipe: StringName, on_input: bool, ingredient_data: Dictionary) -> void:
	if on_recipe != active_recipe:
		recipe_tree.select_recipe(on_recipe, false)
		switch_to_recipe(on_recipe)
	
	var target: Tree = null
	
	if on_input:
		target = recipe_input_tree
	else:
		target = recipe_output_tree
	
	target._create_item(
			ingredient_data["item_id"],
			ingredient_data["item_count"],
			ingredient_data["metadata"].duplicate(true),
			ingredient_data["index"])


func _on_ingredient_added(index: int, on_input: bool) -> void:
	var data: Dictionary = {}
	
	if on_input:
		data = recipe_input_tree.get_ingredient_data(index)
	else:
		data = recipe_output_tree.get_ingredient_data(index)
	
	undo.create_action("Add %s Item to '%s'" % ["Input" if on_input else "Output", active_recipe])
	undo.add_do_method(_do_add_ingredient.bind(active_recipe, on_input, data["item_id"], data["item_count"], data["metadata"], data["index"]))
	undo.add_undo_method(_undo_add_ingredient.bind(active_recipe, on_input, data["index"]))
	undo.commit_action(false)
	
	_something_changed()


func _undo_add_ingredient(on_recipe: StringName, on_input: bool, ingredient_index: int) -> void:
	if active_recipe != on_recipe:
		switch_to_recipe(on_recipe)
		recipe_tree.select_recipe(on_recipe, false)
	
	if on_input:
		recipe_input_tree.remove_ingredient(ingredient_index)
	else:
		recipe_output_tree.remove_ingredient(ingredient_index)


func _do_add_ingredient(on_recipe: StringName, on_input: bool, item_id: StringName, item_amount: int, metadata: Dictionary, on_index: int) -> void:
	if active_recipe != on_recipe:
		switch_to_recipe(on_recipe)
		recipe_tree.select_recipe(on_recipe, false)
	
	if on_input:
		recipe_input_tree._create_item(
				item_id, item_amount,
				metadata,
				on_index)
	else:
		recipe_output_tree._create_item(
				item_id, item_amount,
				metadata,
				on_index)


func _on_ingredient_moved(from: int, to: int, on_input: bool) -> void:
	undo.create_action("Reorder '%s' %s Item" % [active_recipe, "Input" if on_input else "Output"])
	undo.add_do_method(_do_move_ingredient.bind(active_recipe, on_input, from, to))
	undo.add_undo_method(_do_move_ingredient.bind(active_recipe, on_input, to, from))
	undo.commit_action(false)
	
	_something_changed()


func _do_move_ingredient(from_recipe: StringName, on_input: bool, from_index: int, to_index: int) -> void:
	if active_recipe != from_recipe:
		switch_to_recipe(from_recipe)
		recipe_tree.select_recipe(from_recipe, false)
	
	if on_input:
		recipe_input_tree.move_ingredient(from_index, to_index)
	else:
		recipe_output_tree.move_ingredient(from_index, to_index)


func _on_recipe_item_metadata_added(index: int, path: String, data: Variant, on_input: bool) -> void:
	var is_dict: bool = typeof(data) == TYPE_DICTIONARY
	undo.create_action("Set '%s' %s Item Metadata" % [active_recipe, "Input" if on_input else "Output"])
	undo.add_do_method(_do_add_item_metadata.bind(active_recipe, on_input, index, path, data.duplicate(true) if is_dict else data))
	undo.add_undo_method(_undo_add_item_metadata.bind(active_recipe, on_input, index, path))
	undo.commit_action(false)
	_something_changed()


func _do_add_item_metadata(on_recipe: StringName, on_input: bool, on_ingredient: int, path: String, data: Variant) -> void:
	if active_recipe != on_recipe:
		switch_to_recipe(on_recipe)
		recipe_tree.select_recipe(on_recipe, false)
	
	var is_dict: bool = typeof(data) == TYPE_DICTIONARY
	if on_input:
		recipe_input_tree.add_metadata(on_ingredient, path, data.duplicate(true) if is_dict else data)
	else:
		recipe_output_tree.add_metadata(on_ingredient, path, data.duplicate(true) if is_dict else data)


func _undo_add_item_metadata(on_recipe: StringName, on_input: bool, on_ingredient: int, path: String) -> void:
	if active_recipe != on_recipe:
		switch_to_recipe(on_recipe)
		recipe_tree.select_recipe(on_recipe, false)
	
	if on_input:
		recipe_input_tree.remove_metadata(on_ingredient, path)
	else:
		recipe_output_tree.remove_metadata(on_ingredient, path)


func _on_recipe_ingredient_metadata_moved(from_ingredient: int, to_ingredient: int, from_path: String, to_path: String, from_child_idx: int, to_child_idx: int, on_input: bool) -> void:
	undo.create_action("Reorder '%s' %s Item Metadata" % [active_recipe, "Input" if on_input else "Output"])
	undo.add_do_method(_do_move_recipe_item_metadata.bind(
			active_recipe,
			on_input,
			from_ingredient,
			from_path,
			to_ingredient,
			to_path,
			to_child_idx))
	undo.add_undo_method(_do_move_recipe_item_metadata.bind(
			active_recipe,
			on_input,
			to_ingredient,
			to_path,
			from_ingredient,
			from_path,
			from_child_idx))
	undo.commit_action(false)
	_something_changed()


func _do_move_recipe_item_metadata(on_recipe: StringName, on_input: bool, from_ingredient: int, from_path: String, to_ingredient: int, to_path: String, to_index: int) -> void:
	if active_recipe != on_recipe:
		switch_to_recipe(on_recipe)
		recipe_tree.select_recipe(on_recipe, false)
	
	if on_input:
		recipe_input_tree.move_metadata(
			from_ingredient,
			from_path,
			to_ingredient,
			to_path,
			to_index)
	else:
		recipe_output_tree.move_metadata(
			from_ingredient,
			from_path,
			to_ingredient,
			to_path,
			to_index)


func _on_recipe_ingredient_metadata_removed(index: int, path: String, data: Variant, on_input: bool) -> void:
	var is_dict: bool = typeof(data) == TYPE_DICTIONARY
	undo.create_action("Erase '%s' %s Item Metadata" % [active_recipe, "Input" if on_input else "Output"])
	undo.add_do_method(_do_remove_ingredient_metadata.bind(active_recipe, on_input, index, path))
	undo.add_undo_method(_undo_remove_ingredient_metadata.bind(active_recipe, on_input, index, path, data.duplicate(true) if is_dict else data))
	undo.commit_action(false)
	_something_changed()


func _undo_remove_ingredient_metadata(on_recipe: StringName, on_input: bool, on_ingredient: int, path: String, data: Variant) -> void:
	if active_recipe != on_recipe:
		switch_to_recipe(on_recipe)
		recipe_tree.select_recipe(on_recipe, false)
	
	var is_dict: bool = typeof(data) == TYPE_DICTIONARY
	
	if on_input:
		recipe_input_tree.add_metadata(on_ingredient, path, data.duplicate(true) if is_dict else data)
	else:
		recipe_output_tree.add_metadata(on_ingredient, path, data.duplicate(true) if is_dict else data)


func _do_remove_ingredient_metadata(on_recipe: StringName, on_input: bool, on_ingredient: int, path: String) -> void:
	if active_recipe != on_recipe:
		switch_to_recipe(on_recipe)
		recipe_tree.select_recipe(on_recipe, false)
	
	if on_input:
		recipe_input_tree.remove_metadata(on_ingredient, path)
	else:
		recipe_output_tree.remove_metadata(on_ingredient, path)


func _on_ingredient_amount_changed(index: int, old_amount: int, new_amount: int, on_input: bool) -> void:
	undo.create_action("Set '%s' %s Amount" % [active_recipe, "Input" if on_input else "Output"])
	undo.add_do_method(_do_update_ingredient_amount.bind(active_recipe, on_input, index, new_amount))
	undo.add_undo_method(_do_update_ingredient_amount.bind(active_recipe, on_input, index, old_amount))
	undo.commit_action(false)
	_something_changed()


func _do_update_ingredient_amount(on_recipe: StringName, on_input: bool, ingredient_index: int, new_amount: int) -> void:
	if active_recipe != on_recipe:
		switch_to_recipe(on_recipe)
		recipe_tree.select_recipe(on_recipe, false)
	
	if on_input:
		recipe_input_tree.set_item_amount(ingredient_index, new_amount)
	else:
		recipe_output_tree.set_item_amount(ingredient_index, new_amount)


func _on_ingredient_metadata_changed(index: int, path: String, old_value: Variant, new_value: Variant, is_input: bool) -> void:
	undo.create_action("Set '%s' %s Metadata" % [active_recipe, "Input" if is_input else "Output"])
	undo.add_do_method(_do_update_ingredient_metadata.bind(active_recipe, is_input, index, path, new_value))
	undo.add_undo_method(_do_update_ingredient_metadata.bind(active_recipe, is_input, index, path, old_value))
	undo.commit_action(false)
	_something_changed()


func _do_update_ingredient_metadata(on_recipe: StringName, on_input: bool, on_ingredient: int, path: String, value: Variant) -> void:
	if active_recipe != on_recipe:
		switch_to_recipe(on_recipe)
		recipe_tree.select_recipe(on_recipe, false)
	
	if on_input:
		recipe_input_tree.set_metadata(on_ingredient, path, value)
	else:
		recipe_output_tree.set_metadata(on_ingredient, path, value)


func _on_ingredient_metadata_renamed(index: int, parent_path: String, old_name: String, new_name: String, on_input: bool) -> void:
	var new_path: String = parent_path
	var old_path: String = parent_path
	
	if not old_name.is_empty():
		old_path = old_path.path_join(old_name)
	if not new_name.is_empty():
		new_path = new_path.path_join(new_name)
	
	undo.create_action("Set '%s' %s Metadata ID" % [active_recipe, "Input" if on_input else "Output"])
	undo.add_do_method(_set_ingredient_metadata_id.bind(active_recipe, on_input, index, old_path, new_name))
	undo.add_undo_method(_set_ingredient_metadata_id.bind(active_recipe, on_input, index, new_path, old_name))
	undo.commit_action(false)
	
	_something_changed()


func _set_ingredient_metadata_id(on_recipe: StringName, on_input: bool, on_ingredient: int, path: String, new_name: String) -> void:
	if active_recipe != on_recipe:
		switch_to_recipe(on_recipe)
		recipe_tree.select_recipe(on_recipe, false)
	
	if on_input:
		recipe_input_tree.set_metadata_id(on_ingredient, path, new_name)
	else:
		recipe_output_tree.set_metadata_id(on_ingredient, path, new_name)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(undo):
			undo.clear_history()
			undo.free()
			undo = null
