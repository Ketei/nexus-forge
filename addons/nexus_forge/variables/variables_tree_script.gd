@tool
extends Tree


signal copy_path_pressed(variable_id: String)
signal variable_updated(variable_id: String, value: Variant)
signal variable_renamed(from: String, to: String)
signal something_changed

#var INT_ICON: Texture2D = null
#var FLOAT_ICON: Texture2D = null
#var BOOL_ICON: Texture2D = null
#var STRING_ICON: Texture2D = null
#var DELETE_ICON: Texture2D = null
#var COPY_ICON: Texture2D = null
#var any_icon: Texture2D = null

const VALUE_MAX_RANGE: int = 9999
const FLOAT_STEP: float = 0.01
#var root_tree: TreeItem
var _current_selected: TreeItem = null
var current_folder: String = ""
var sorting_column: int = 0


func ready_plugin() -> void:
	add_theme_stylebox_override(&"title_button_normal", get_theme_stylebox("title_button_normal", "Tree"))
	add_theme_stylebox_override(&"title_button_hover", get_theme_stylebox("title_button_hover", "Tree"))
	add_theme_stylebox_override(&"title_button_pressed", get_theme_stylebox("title_button_pressed", "Tree"))
	add_theme_stylebox_override(&"panel", get_theme_stylebox("panel", "Tree"))
	
	create_item()
	set_column_title(0, "Name")
	set_column_title(1, "Default Value")
	set_column_title_alignment(0, HORIZONTAL_ALIGNMENT_LEFT)
	set_column_title_alignment(1, HORIZONTAL_ALIGNMENT_LEFT)
	set_column_expand(0, true)
	set_column_expand(1, true)
	set_column_expand_ratio(0, 8)
	set_column_expand_ratio(1, 7)
	item_edited.connect(_on_item_edited)
	button_clicked.connect(_on_button_pressed)
	column_title_clicked.connect(_on_column_title_clicked)


func _get_drag_data(at_position: Vector2) -> Variant:
	var item: TreeItem = get_item_at_position(at_position)
	if item == null:
		return null
	var preview: Label = Label.new()
	preview.text = "  Variable: " + item.get_text(0)
	set_drag_preview(preview)
	
	return {"type": "blackboard_item", "class": "variable", "item": item, "folder": current_folder}


func _on_column_title_clicked(column: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT or sorting_column == column:
		return
	
	var items: Array[TreeItem] = get_root().get_children()
	var item_size: int = items.size()
	
	if item_size < 2:
		return
	
	if column == 0:
		items.sort_custom(
				func(a:TreeItem,b: TreeItem):
						return a.get_text(0).naturalnocasecmp_to(b.get_text(0)) < 0)
	elif column == 1:
		items.sort_custom(_sort_data_column)
	
	if items[0].get_index() != 0:
		items[0].move_before(get_root().get_first_child())
	
	for item_idx in range(1, item_size):
		items[item_idx].move_after(items[item_idx - 1])
	
	sorting_column = column


func _sort_data_column(a: TreeItem, b: TreeItem) -> bool:
	var a_type: int = get_variable_type(a) #typeof(a.get_metadata(1)["data"]) if a.get_metadata(1)["type"] == TYPE_NIL else a.get_metadata(1)["type"]
	var b_type: int = get_variable_type(b)#typeof(b.get_metadata(1)["data"]) if b.get_metadata(1)["type"] == TYPE_NIL else b.get_metadata(1)["type"]
	
	if a_type == b_type:
		return a.get_text(0).naturalnocasecmp_to(b.get_text(0)) < 0
	else:
		return a_type < b_type

		#if a_type != b_type:
			#return a_type < b_type
		#elif a_type == TYPE_STRING and b_type == TYPE_STRING:
			#return a.get_text(1).naturalnocasecmp_to(b.get_text(1)) < 0
		#elif a_type == TYPE_BOOL and b_type == TYPE_BOOL:
			#return int(a.is_checked(1)) < int(b.is_checked(1))
		#else:
			#return a.get_range(1) < b.get_range(1)


func _on_button_pressed(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	match id:
		0:
			copy_path_pressed.emit(item.get_text(0))
		1:
			variable_updated.emit(item.get_metadata(0), null)
			item.free()


func _on_item_edited() -> void:
	var edited: TreeItem = get_edited()
	match get_edited_column():
		0: # Var name edited
			if edited.get_metadata(0) == edited.get_text(0):
				return
			var valid_name: String = validate_var_name(edited.get_text(0), edited)
			edited.set_text(0, valid_name)
			variable_renamed.emit(edited.get_metadata(0), valid_name)
			edited.set_metadata(0, valid_name)
			if sorting_column == 0:
				sort_single_item(edited)
				ensure_cursor_is_visible()
		1: # Var value changed
			variable_updated.emit(edited.get_text(0), get_tree_variant(edited))
	something_changed.emit()


func create_variable(variable_value: Variant, variable_name: String = "new_variable") -> String:
	var unique_name: String = validate_var_name(variable_name)
	var new_variable: TreeItem = get_root().create_child()
	var variable_typeof: int = typeof(variable_value)
	
	var editable_id: bool = true
	var editable_value: bool = true
	
	# Setting the initial name
	new_variable.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_variable.set_text(0, unique_name)
	new_variable.set_metadata(0, unique_name)
	# ------------------------
	
	# Setting cell modes and icon
	match typeof(variable_value): 
		TYPE_INT:
			new_variable.set_icon(0, get_theme_icon("int", "EditorIcons"))
			new_variable.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
			new_variable.set_range_config(1, -VALUE_MAX_RANGE, VALUE_MAX_RANGE, 1.0)
			new_variable.set_range(1, variable_value)
			new_variable.set_metadata(1, {"type": TYPE_INT})
		TYPE_FLOAT:
			new_variable.set_icon(0, get_theme_icon("float", "EditorIcons"))
			new_variable.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
			new_variable.set_range_config(1, -VALUE_MAX_RANGE, VALUE_MAX_RANGE, FLOAT_STEP)
			new_variable.set_range(1, variable_value)
			new_variable.set_metadata(1, {"type": TYPE_FLOAT})
		TYPE_BOOL:
			new_variable.set_icon(0, get_theme_icon("bool", "EditorIcons"))
			new_variable.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
			new_variable.set_text(1, "Enabled")
			new_variable.set_checked(1, variable_value)
			new_variable.set_metadata(1, {"type": TYPE_BOOL})
		TYPE_STRING:
			new_variable.set_icon(0, get_theme_icon("String", "EditorIcons"))
			new_variable.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
			new_variable.set_text(1, variable_value)
			new_variable.set_metadata(1, {"type": TYPE_STRING})
		_:
			new_variable.set_icon(0, get_theme_icon("Variant", "EditorIcons"))
			editable_value = false
			new_variable.set_metadata(1, {"type": TYPE_NIL, "data": variable_value})
			new_variable.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
			new_variable.set_text(1, StringUtils.title_case(type_string(typeof(variable_value))))
	# ------------------
	
	# Setting editability
	new_variable.set_editable(0, editable_id) # The name
	new_variable.set_editable(1, editable_value) # The value
	# -------------------
	
	# Buttons
	new_variable.add_button(0, get_theme_icon("ActionCopy", "EditorIcons"), 0, false, "Copy path to variable")
	new_variable.add_button(1, get_theme_icon("Remove", "EditorIcons"), 1, false, "Delete variable.")
	# -------------
	
	sort_single_item(new_variable)
	
	return unique_name


func clear_variables() -> void:
	clear()
	create_item()


func validate_var_name(var_name: String, skip_tree: TreeItem = null) -> String:
	if var_name.is_empty():
		var_name = "new_variable"
	
	var tweaked_name: String = var_name.replace("/", "_")
	var iteration: int = 0
	
	while has_variable(tweaked_name, skip_tree):
		iteration += 1
		tweaked_name = str(var_name, "_", iteration)
	
	return tweaked_name


func has_variable(folder_name: String, exception: TreeItem) -> bool:
	for child in get_root().get_children():
		if child == exception:
			continue
		if child.get_text(0) == folder_name:
			return true
	return false


func get_variables() -> Dictionary[String, Variant]:
	var variables: Dictionary[String, Variant] = {}
	
	for variable_tree in get_root().get_children():
		variables[variable_tree.get_metadata(0)] = get_tree_variant(variable_tree)
	
	return variables


# Shouldn't be needed anymore
func get_variables_as_array() -> Array[Dictionary]:
	var variables_array: Array[Dictionary] = []
	
	for variable in get_root().get_children():
		variables_array.append({
				"name": variable.get_text(0),
				"type": get_variable_type(variable),
				"variable": get_tree_variant(variable)})
	
	return variables_array


func get_tree_variant(tree_var: TreeItem) -> Variant:
	match tree_var.get_metadata(1)["type"]:
		TYPE_INT:
			return int(tree_var.get_range(1))
		TYPE_FLOAT:
			return float(tree_var.get_range(1))
		TYPE_BOOL:
			return tree_var.is_checked(1)
		TYPE_STRING:
			return tree_var.get_text(1)
		TYPE_NIL:
			return tree_var.get_metadata(1)["data"]
		_:
			return null


func get_variable_type(variable_cell: TreeItem) -> int:
	if variable_cell.get_metadata(1)["type"] == TYPE_NIL:
		return typeof(variable_cell.get_metadata(1)["data"])
	else:
		return variable_cell.get_metadata(1)["type"]


func search_for_var(text_to_search: String) -> void:
	for var_tree in get_root().get_children():
		var_tree.visible = var_tree.get_text(0).contains(text_to_search)


func search_for_pattern(pattern: String) -> void:
	if pattern.is_empty():
		show_all_vars()
		return
	
	var column_range: Array = range(columns)
	for item in get_root().get_children():
		var match_found: bool = false
		var text: String = ""
		for column in column_range:
			match item.get_cell_mode(column):
				TreeItem.CELL_MODE_STRING:
					text = item.get_text(column)
				TreeItem.CELL_MODE_RANGE:
					text = str(item.get_range(column))
				TreeItem.CELL_MODE_CHECK:
					text = "true" if item.is_checked(column) else "false"
				_:
					continue
			if text.containsn(pattern):
				match_found = true
				break
		item.visible = match_found


func show_all_vars() -> void:
	for var_tree in get_root().get_children():
		var_tree.visible = true


func sort_single_item(item: TreeItem) -> void:
	var before_item: TreeItem = null
	
	if sorting_column == 0:
		for child in item.get_parent().get_children():
			if child == item:
				continue # We ignore the item we just added
			
			if item.get_text(0).naturalnocasecmp_to(child.get_text(0)) < 0:
				before_item = child
				break
	else:
		for child in item.get_parent().get_children():
			if child == item:
				continue
			
			var a_type: int = get_variable_type(child)
			var b_type: int = get_variable_type(item)
			
			if a_type == b_type:
				if item.get_text(0).naturalnocasecmp_to(child.get_text(0)) < 0:
					before_item = child
					break
			else:
				if b_type < a_type:
					before_item = child
					break
	
	if before_item != null:
		item.move_before(before_item)
	else:
		if item.get_index() != item.get_parent().get_child_count() - 1:
			item.move_after(get_root().get_child(-1))


func remove_variable(variable_id: String) -> void:
	for item in get_root().get_children():
		if item.get_text(0) == variable_id:
			item.free()
			return
