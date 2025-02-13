@tool
extends Tree


signal item_deleted

const VAR_RANGE: int = 9999
const FLOAT_STEP: float = 0.01
const ICON_PLUS = preload("res://addons/nexus_forge/common_icons/plus_icon.svg")
const ICON_BOOL = preload("res://addons/nexus_forge/common_icons/variables/bool.svg")
const ICON_FLOAT = preload("res://addons/nexus_forge/common_icons/variables/float.svg")
const ICON_INT = preload("res://addons/nexus_forge/common_icons/variables/int.svg")
const ICON_STRING = preload("res://addons/nexus_forge/common_icons/variables/string.svg")
const ICON_ADD_BOOL = preload("res://addons/nexus_forge/common_icons/variables/add_bool.svg")
const ICON_ADD_FLOAT = preload("res://addons/nexus_forge/common_icons/variables/add_float.svg")
const ICON_ADD_INT = preload("res://addons/nexus_forge/common_icons/variables/add_int.svg")
const ICON_ADD_STRING = preload("res://addons/nexus_forge/common_icons/variables/add_string.svg")
const TRASH_BIN = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")
const ICON_VARIABLE = preload("res://addons/nexus_forge/common_icons/variables/variable_icon.svg")

var required_items: TreeItem = null
var required_triggers: TreeItem = null
var required_variables: TreeItem = null
var required_data: TreeItem = null


func _ready() -> void:
	create_item()
	
	set_column_expand(0, true)
	set_column_expand(1, false)
	set_column_expand(2, true)
	
	set_column_custom_minimum_width(1, 48)
	
	required_items = get_root().create_child()
	required_triggers = get_root().create_child()
	required_variables = get_root().create_child()
	required_data = get_root().create_child()
	
	required_items.set_text(0, "Items")
	required_triggers.set_text(0, "Triggers")
	required_variables.set_text(0, "Variables")
	required_data.set_text(0, "Data")
	
	required_items.add_button(2, ICON_PLUS, 0, false, "Add Item")
	required_triggers.add_button(2, ICON_PLUS, 1, false, "Add Trigger")
	
	required_variables.add_button(2, ICON_ADD_INT, 2, false, "Add Int")
	required_variables.add_button(2, ICON_ADD_FLOAT, 3, false, "Add Float")
	required_variables.add_button(2, ICON_ADD_BOOL, 4, false, "Add Bool")
	required_variables.add_button(2, ICON_ADD_STRING, 5, false, "Add String")
	
	required_data.add_button(2, ICON_ADD_INT, 11, false, "Add Int")
	required_data.add_button(2, ICON_ADD_FLOAT, 12, false, "Add Float")
	required_data.add_button(2, ICON_ADD_BOOL, 13, false, "Add Bool")
	required_data.add_button(2, ICON_ADD_STRING, 14, false, "Add String")
	
	required_data.set_selectable(0, false)
	required_data.set_selectable(1, false)
	required_data.set_selectable(2, false)
	
	required_items.set_selectable(0, false)
	required_items.set_selectable(1, false)
	required_items.set_selectable(2, false)
	
	required_triggers.set_selectable(0, false)
	required_triggers.set_selectable(1, false)
	required_triggers.set_selectable(2, false)
	
	required_variables.set_selectable(0, false)
	required_variables.set_selectable(1, false)
	required_variables.set_selectable(2, false)
	
	button_clicked.connect(_on_button_clicked)


func create_required_variable(var_path: String, var_value: Variant, operator: int = OP_EQUAL) -> void:
	var new_variable: TreeItem = required_variables.create_child()
	
	new_variable.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_variable.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_variable.set_text(1, "==,!=,<,<=,>,>=")
	new_variable.set_range(1, operator_to_range(operator))
	new_variable.set_text(0, var_path)
	
	match typeof(var_value):
		TYPE_INT:
			new_variable.set_icon(0, ICON_INT)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_variable.set_range_config(2, -VAR_RANGE, VAR_RANGE, 1.0)
			new_variable.set_range(2, var_value)
			new_variable.set_editable(2, true)
			new_variable.set_metadata(0, TYPE_INT)
		TYPE_FLOAT:
			new_variable.set_icon(0, ICON_FLOAT)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_variable.set_range_config(2, -VAR_RANGE, VAR_RANGE, FLOAT_STEP)
			new_variable.set_range(2, var_value)
			new_variable.set_editable(2, true)
			new_variable.set_metadata(0, TYPE_FLOAT)
		TYPE_BOOL:
			new_variable.set_icon(0, ICON_BOOL)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_CHECK)
			new_variable.set_text(2, "Enabled")
			new_variable.set_checked(2, var_value)
			new_variable.set_editable(2, true)
			new_variable.set_metadata(0, TYPE_BOOL)
		TYPE_STRING:
			new_variable.set_icon(0, ICON_STRING)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
			new_variable.set_text(2, var_value)
			new_variable.set_editable(2, true)
			new_variable.set_metadata(0, TYPE_STRING)
		_:
			new_variable.set_icon(0, ICON_VARIABLE)
			new_variable.set_metadata(0, TYPE_NIL)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
			new_variable.set_text(2, type_string(typeof(var_value)))
			new_variable.set_metadata(2, var_value)
			new_variable.set_editable(2, false)
	
	new_variable.set_editable(0, true)
	new_variable.set_editable(1, true)
	
	new_variable.add_button(2, TRASH_BIN, 6, false, "Delete Variable")


func create_required_data(data_id: String, data: Variant) -> void:
	var new_variable: TreeItem = required_data.create_child()
	
	new_variable.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_variable.set_text(0, data_id)
	
	new_variable.set_selectable(1, false)
	
	match typeof(data):
		TYPE_INT:
			new_variable.set_icon(0, ICON_INT)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_variable.set_range_config(2, -VAR_RANGE, VAR_RANGE, 1.0)
			new_variable.set_range(2, data)
			new_variable.set_editable(2, true)
			new_variable.set_metadata(0, TYPE_INT)
		TYPE_FLOAT:
			new_variable.set_icon(0, ICON_FLOAT)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_variable.set_range_config(2, -VAR_RANGE, VAR_RANGE, FLOAT_STEP)
			new_variable.set_range(2, data)
			new_variable.set_editable(2, true)
			new_variable.set_metadata(0, TYPE_FLOAT)
		TYPE_BOOL:
			new_variable.set_icon(0, ICON_BOOL)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_CHECK)
			new_variable.set_text(2, "Enabled")
			new_variable.set_checked(2, data)
			new_variable.set_editable(2, true)
			new_variable.set_metadata(0, TYPE_BOOL)
		TYPE_STRING:
			new_variable.set_icon(0, ICON_STRING)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
			new_variable.set_text(2, data)
			new_variable.set_editable(2, true)
			new_variable.set_metadata(0, TYPE_STRING)
		_:
			new_variable.set_icon(0, ICON_VARIABLE)
			new_variable.set_metadata(0, TYPE_NIL)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
			new_variable.set_text(2, type_string(typeof(data)))
			new_variable.set_metadata(2, data)
			new_variable.set_editable(2, false)
	
	new_variable.set_editable(0, true)
	
	new_variable.add_button(2, TRASH_BIN, 6, false, "Delete Variable")


func create_item_property(on_item: TreeItem, key_name: String, value: Variant, operator: int = OP_EQUAL) -> void:
	var new_variable: TreeItem = on_item.create_child()
	
	new_variable.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_variable.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_variable.set_text(1, "==,!=,<,<=,>,>=")
	new_variable.set_range(1, operator_to_range(operator))
	new_variable.set_text(0, key_name)
	
	match typeof(value):
		TYPE_INT:
			new_variable.set_icon(0, ICON_INT)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_variable.set_range_config(2, -VAR_RANGE, VAR_RANGE, 1.0)
			new_variable.set_range(2, value)
			new_variable.set_metadata(0, TYPE_INT)
			new_variable.set_editable(2, true)
		TYPE_FLOAT:
			new_variable.set_icon(0, ICON_FLOAT)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_variable.set_range_config(2, -VAR_RANGE, VAR_RANGE, FLOAT_STEP)
			new_variable.set_range(2, value)
			new_variable.set_metadata(0, TYPE_FLOAT)
			new_variable.set_editable(2, true)
		TYPE_BOOL:
			new_variable.set_icon(0, ICON_BOOL)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_CHECK)
			new_variable.set_text(2, "Enabled")
			new_variable.set_checked(2, value)
			new_variable.set_metadata(0, TYPE_BOOL)
			new_variable.set_editable(2, true)
		TYPE_STRING:
			new_variable.set_icon(0, ICON_STRING)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
			new_variable.set_text(2, value)
			new_variable.set_metadata(0, TYPE_STRING)
			new_variable.set_editable(2, true)
		_:
			new_variable.set_icon(0, ICON_VARIABLE)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
			new_variable.set_text(2, type_string(typeof(value)))
			new_variable.set_metadata(0, TYPE_NIL)
			new_variable.set_editable(2, false)
	
	new_variable.set_editable(0, true)
	new_variable.set_editable(1, true)
	
	new_variable.add_button(2, TRASH_BIN, 6, false, "Delete Property")


func create_required_item(item_id: String = "", amount: int = 1, operator: int = OP_EQUAL, item_data: Dictionary = {}, collapsed: bool = false) -> void:
	var new_item: TreeItem = required_items.create_child()
	new_item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	
	new_item.set_text(1, "==,!=,<,<=,>,>=")
	new_item.set_range_config(2, 0, VAR_RANGE, 1)
	new_item.set_range(1, operator_to_range(operator))
	
	new_item.set_range(2, amount)
	new_item.set_text(0, item_id)
	
	new_item.set_editable(0, true)
	new_item.set_editable(1, true)
	new_item.set_editable(2, true)
	
	new_item.add_button(2, ICON_ADD_INT, 7, false, "Create integer property")
	new_item.add_button(2, ICON_ADD_FLOAT, 8, false, "Create float property")
	new_item.add_button(2, ICON_ADD_BOOL, 9, false, "Create bool property")
	new_item.add_button(2, ICON_ADD_STRING, 10, false, "Create string property")
	new_item.add_button(2, TRASH_BIN, 6, false, "Delete Item")
	
	for data_key in item_data:
		create_item_property(
				new_item,
				data_key,
				item_data[data_key]["value"],
				item_data[data_key]["operator"])
	
	if collapsed:
		collapsed = true


func create_required_trigger(trigger_id: String = "", count: int = 1, operator: int = OP_EQUAL) -> void:
	var new_item: TreeItem = required_triggers.create_child()
	new_item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	
	new_item.set_text(0, trigger_id)
	
	new_item.set_text(1, "==,!=,<,<=,>,>=")
	new_item.set_range_config(2, 0, VAR_RANGE, 1)
	new_item.set_range(1, operator_to_range(operator))
	new_item.set_range(2, count)
	
	new_item.set_editable(0, true)
	new_item.set_editable(1, true)
	new_item.set_editable(2, true)
	
	new_item.add_button(2, TRASH_BIN, 6, false, "Delete Trigger")


func operator_to_range(operator: int) -> int:
	match operator:
		OP_EQUAL:
			return 0
		OP_NOT_EQUAL:
			return 1
		OP_LESS:
			return 2
		OP_LESS_EQUAL:
			return 3
		OP_GREATER:
			return 4
		OP_GREATER_EQUAL:
			return 5
		_:
			return 0


func range_to_operator(range: int) -> int:
	match range:
		0:
			return OP_EQUAL
		1:
			return OP_NOT_EQUAL
		2:
			return OP_LESS
		3:
			return OP_LESS_EQUAL
		4:
			return OP_GREATER
		5:
			return OP_GREATER_EQUAL
		_:
			return OP_EQUAL


func clear_requirements() -> void:
	for req in required_items.get_children():
		req.free()
	for req in required_triggers.get_children():
		req.free()
	for req in required_variables.get_children():
		req.free()
	for req in required_data.get_children():
		req.free()


func get_requirements() -> Dictionary:
	var requirements: Dictionary = {
		"items": {},
		"variables": Arrays.create_array_typed(TYPE_DICTIONARY),
		"triggers": {},
		"data": {}}
	
	for req_item in required_items.get_children():
		var custom_data: Dictionary = {}
		
		for custom_item in req_item.get_children():
			var req_val: Variant = null
			
			match custom_item.get_metadata(0):
				TYPE_INT:
					req_val = int(custom_item.get_range(2))
				TYPE_FLOAT:
					req_val = float(custom_item.get_range(2))
				TYPE_BOOL:
					req_val = custom_item.is_checked(2)
				TYPE_STRING:
					req_val = custom_item.get_text(2)
				TYPE_NIL:
					req_val = custom_item.get_metadata(2)
			
			custom_data[custom_item.get_text(0)] = {
				"operator": range_to_operator(custom_item.get_range(1)),
					"value": req_val}
		
		requirements["items"][req_item.get_text(0)] = {
			"amount": int(req_item.get_range(2)),
			"operator": range_to_operator(req_item.get_range(1)),
			"custom_data": custom_data}
	
	for req_trigger in required_triggers.get_children():
		requirements["triggers"][req_trigger.get_text(0)] = {
			"count": int(req_trigger.get_range(2)),
			"operator": range_to_operator(req_trigger.get_range(1))}

	for req_var in required_variables.get_children():
		var req_val: Variant = null
		
		match req_var.get_metadata(0):
			TYPE_INT:
				req_val = int(req_var.get_range(2))
			TYPE_FLOAT:
				req_val = float(req_var.get_range(2))
			TYPE_BOOL:
				req_val = req_var.is_checked(2)
			TYPE_STRING:
				req_val = req_var.get_text(2)
			TYPE_NIL:
				req_val = req_var.get_metadata(2)
		
		requirements["variables"].append({
			"path": req_var.get_text(0),
			"value": req_val,
			"operator": range_to_operator(req_var.get_range(1))})
	
	for req_data in required_data.get_children():
		var req_val: Variant = null
		
		match req_data.get_metadata(0):
			TYPE_INT:
				req_val = int(req_data.get_range(2))
			TYPE_FLOAT:
				req_val = float(req_data.get_range(2))
			TYPE_BOOL:
				req_val = req_data.is_checked(2)
			TYPE_STRING:
				req_val = req_data.get_text(2)
			TYPE_NIL:
				req_val = req_data.get_metadata(2)
		
		requirements["data"][req_data.get_text(0)] = req_val
	
	return requirements


func load_requirements(requirements: Dictionary) -> void:
	clear_requirements()
	
	for item in requirements["items"]:
		create_required_item(
				item,
				requirements["items"][item]["amount"],
				requirements["items"][item]["operator"],
				requirements["items"][item]["custom_data"],
				true)
	for variable in requirements["variables"]:
		create_required_variable(
				variable["path"],
				variable["value"],
				variable["operator"])
	for trigger in requirements["triggers"]:
		create_required_trigger(
				trigger,
				requirements["triggers"][trigger]["count"],
				requirements["triggers"][trigger]["operator"])
	for data in requirements["data"]:
		create_required_data(
				data,
				requirements["data"][data])


func collapse_all() -> void:
	for required in get_root().get_children():
		required.set_collapsed_recursive(true)


func _on_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	match id:
		0:
			create_required_item()
			if item.collapsed:
				item.collapsed = false
		1:
			create_required_trigger()
			if item.collapsed:
				item.collapsed = false
		2:
			create_required_variable("", 0)
			if item.collapsed:
				item.collapsed = false
		3:
			create_required_variable("", 0.0)
			if item.collapsed:
				item.collapsed = false
		4: 
			create_required_variable("", false)
			if item.collapsed:
				item.collapsed = false
		5:
			create_required_variable("", "")
			if item.collapsed:
				item.collapsed = false
		6: 
			item.free()
			item_deleted.emit()
		7:
			create_item_property(item, "property_int", 0)
			if item.collapsed:
				item.collapsed = false
		8:
			create_item_property(item, "property_float", 0.0)
			if item.collapsed:
				item.collapsed = false
		9:
			create_item_property(item, "property_bool", false)
			if item.collapsed:
				item.collapsed = false
		10:
			create_item_property(item, "property_string", "")
			if item.collapsed:
				item.collapsed = false
		11:
			create_required_data("new_int", 0)
			if item.collapsed:
				item.collapsed = false
		12:
			create_required_data("new_flaot", 0.0)
			if item.collapsed:
				item.collapsed = false
		13:
			create_required_data("new_bool", false)
			if item.collapsed:
				item.collapsed = false
		14:
			create_required_data("new_string", "")
			if item.collapsed:
				item.collapsed = false
