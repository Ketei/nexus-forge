extends Tree


const ICON_ADD = preload("res://addons/nexus_forge/common_icons/plus_icon.svg")
const ICON_ADD_BOOL = preload("res://addons/nexus_forge/common_icons/variables/add_bool.svg")
const ICON_ADD_FLOAT = preload("res://addons/nexus_forge/common_icons/variables/add_float.svg")
const ICON_ADD_INT = preload("res://addons/nexus_forge/common_icons/variables/add_int.svg")
const ICON_ADD_STRING = preload("res://addons/nexus_forge/common_icons/variables/add_string.svg")
const ICON_BIN = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")
const ICON_BOOL = preload("res://addons/nexus_forge/common_icons/variables/bool.svg")
const ICON_FLOAT = preload("res://addons/nexus_forge/common_icons/variables/float.svg")
const ICON_INT = preload("res://addons/nexus_forge/common_icons/variables/int.svg")
const ICON_STRING = preload("res://addons/nexus_forge/common_icons/variables/string.svg")
const MAX_ITEM_RANGE: int = 100
const MAX_CURRENCY_RANGE: int = 100

const VAR_VAL_RANGE: int = 9999
const FLOAT_STEP: float = 0.01

var root_tree: TreeItem = null
#var completion_tree: TreeItem = null
#var failure_tree: TreeItem = null

var completed_items: TreeItem = null
var completed_vars: TreeItem = null
var completed_currency: TreeItem = null

var failed_items: TreeItem = null
var failed_vars: TreeItem = null
var failed_currency: TreeItem = null

var started_items: TreeItem = null
var started_vars: TreeItem = null
var started_currency: TreeItem = null

var progressed_items: TreeItem = null
var progressed_vars: TreeItem = null
var progressed_currency: TreeItem = null

var finished_items: TreeItem = null
var finished_vars: TreeItem = null
var finished_currency: TreeItem = null


func _ready() -> void:
	root_tree = create_item()
	
	set_column_expand(0, true)
	set_column_expand(1, false)
	set_column_expand(2, true)
	
	set_column_custom_minimum_width(1, 48)
	
	var started_tree: TreeItem = root_tree.create_child()
	var quest_ended: TreeItem = root_tree.create_child()
	var quest_progressed: TreeItem = root_tree.create_child()
	var completion_tree: TreeItem = root_tree.create_child()
	var failure_tree: TreeItem = root_tree.create_child()
	
	completion_tree.set_text(0, "Quest Successful")
	failure_tree.set_text(0, "Quest Failed")
	
	started_tree.set_text(0, "Quest Started")
	quest_ended.set_text(0, "Quest Ended")
	quest_progressed.set_text(0, "Quest Progressed")
	
	started_items = started_tree.create_child()
	started_currency = started_tree.create_child()
	started_vars = started_tree.create_child()
	
	progressed_items = quest_progressed.create_child()
	progressed_currency = quest_progressed.create_child()
	progressed_vars = quest_progressed.create_child()
	
	finished_items = quest_ended.create_child()
	finished_currency = quest_ended.create_child()
	finished_vars = quest_ended.create_child()
	
	completed_items = completion_tree.create_child()
	completed_currency = completion_tree.create_child()
	completed_vars = completion_tree.create_child()
	
	failed_items = failure_tree.create_child()
	failed_currency = failure_tree.create_child()
	failed_vars = failure_tree.create_child()
	
	create_event_structure(started_tree, started_items, started_currency, started_vars)
	create_event_structure(quest_ended, finished_items, finished_currency, finished_vars)
	create_event_structure(quest_progressed, progressed_items, progressed_currency, progressed_vars)
	create_event_structure(completion_tree, completed_items, completed_currency, completed_vars)
	create_event_structure(failure_tree, failed_items, failed_currency, failed_vars)
	
	button_clicked.connect(_on_button_clicked)


func create_event_structure(on_tree: TreeItem, items: TreeItem, currency: TreeItem, vars: TreeItem) -> void:
	on_tree.set_selectable(0, false)
	on_tree.set_selectable(1, false)
	on_tree.set_selectable(2, false)
	
	items.set_text(0, "Items")
	vars.set_text(0, "Variables")
	currency.set_text(0, "Currency")
	
	items.add_button(2, ICON_ADD, 0, false, "Add Item")
	currency.add_button(2, ICON_ADD, 1, false, "Add Currency")
	vars.add_button(2, ICON_ADD_INT, 2, false, "Add Integer")
	vars.add_button(2, ICON_ADD_FLOAT, 3, false, "Add Float")
	vars.add_button(2, ICON_ADD_BOOL, 4, false, "Add Bool")
	vars.add_button(2, ICON_ADD_STRING, 5, false, "Add String")
	
	items.set_selectable(0, false)
	items.set_selectable(1, false)
	items.set_selectable(2, false)
	
	currency.set_selectable(0, false)
	currency.set_selectable(1, false)
	currency.set_selectable(2, false)
	
	vars.set_selectable(0, false)
	vars.set_selectable(1, false)
	vars.set_selectable(2, false)
	
	on_tree.collapsed = true
	
	


#func _on_item_edited() -> void:
	#var item: TreeItem = get_edited()
	#match item:
		#repeat_limit_tree:
			#completion_limit_updated.emit(repeat_limit_tree.get_range(2))


func create_tree_item(on_tree: TreeItem, item_id: String = "", item_op: int = 0, item_count: int = 1) -> void:
	var new_item: TreeItem = on_tree.create_child()
	new_item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	
	new_item.set_range_config(1, 0, 2, 1)
	new_item.set_range_config(2, 1, MAX_ITEM_RANGE, 1)
	new_item.set_range(2, item_count)
	
	new_item.set_text(0, item_id)
	new_item.set_text(1, "=,+,-")
	new_item.set_range(1, 1)
	new_item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_CENTER)
	
	new_item.set_editable(0, true)
	new_item.set_editable(1, true)
	new_item.set_editable(2, true)
	
	new_item.add_button(
			2,
			ICON_BIN,
			6,
			false,
			"Remove Item")


func create_tree_currency(on_tree: TreeItem, currency_id: String = "", item_op: int = 0, item_count: int = 1) -> void:
	var new_item: TreeItem = on_tree.create_child()
	new_item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	
	new_item.set_range_config(1, 0, 2, 1)
	new_item.set_range_config(2, 1, MAX_ITEM_RANGE, 1)
	
	new_item.set_text(0, currency_id)
	new_item.set_text(1, "=,+,-")
	new_item.set_range(1, 1)
	
	new_item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_CENTER)
	
	new_item.set_editable(0, true)
	new_item.set_editable(1, true)
	new_item.set_editable(2, true)
	
	new_item.add_button(
			2,
			ICON_BIN,
			7,
			false,
			"Remove Currency")


func create_tree_variable(on_tree: TreeItem, path: String, item_op: int, value: Variant) -> void:
	var new_item: TreeItem = on_tree.create_child()
	new_item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	
	new_item.set_text(1, "=,+,-")
	
	match typeof(value):
		TYPE_INT:
			new_item.set_icon(0, ICON_INT)
			new_item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_item.set_range_config(2, -VAR_VAL_RANGE, VAR_VAL_RANGE, 1.0)
			new_item.set_range(2, value)
		TYPE_FLOAT:
			new_item.set_icon(0, ICON_FLOAT)
			new_item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_item.set_range_config(2, -VAR_VAL_RANGE, VAR_VAL_RANGE, FLOAT_STEP)
			new_item.set_range(2, value)
		TYPE_BOOL:
			new_item.set_icon(0, ICON_BOOL)
			new_item.set_cell_mode(2, TreeItem.CELL_MODE_CHECK)
			new_item.set_checked(2, value)
			new_item.set_text(2, "Enabled")
			new_item.set_text(1, "=")
		TYPE_STRING:
			new_item.set_icon(0, ICON_STRING)
			new_item.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
			new_item.set_text(2, value)
			new_item.set_text(1, "=")
	
	new_item.set_text(0, path)
	
	new_item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_CENTER)
	
	new_item.set_editable(0, true)
	new_item.set_editable(1, true)
	new_item.set_editable(2, true)
	
	new_item.add_button(
			2,
			ICON_BIN,
			8,
			false,
			"Remove Variable")


func operator_to_range(operator: int) -> int:
	match operator:
		OP_EQUAL:
			return 0
		OP_ADD:
			return 1
		OP_SUBTRACT:
			return 2
		_:
			return 0


func range_to_operator(range: int) -> int:
	match range:
		0:
			return OP_EQUAL
		1:
			return OP_ADD
		2:
			return OP_SUBTRACT
		_:
			return OP_ADD


#func clear_events() -> void:
	#for event in completed_items.get_children():
		#event.free()
	#for event in completed_currency.get_children():
		#event.free()
	#for event in completed_vars.get_children():
		#event.free()
	#for event in failed_items.get_children():
		#event.free()
	#for event in failed_currency.get_children():
		#event.free()
	#for event in failed_vars.get_children():
		#event.free()


func _get_tree_events(item_tree: TreeItem, currency_tree: TreeItem, variables_tree: TreeItem) -> Dictionary:
	var items: Array[Dictionary] = []
	var variables: Array[Dictionary] = []
	var currencies: Array[Dictionary] = []
	
	for item in item_tree.get_children():
		items.append({
			"item": item.get_text(0),
			"operator": range_to_operator(item.get_range(1)),
			"amount": int(item.get_range(2))
		})
	
	for currency in currency_tree.get_children():
		currencies.append({
			"currency": currency.get_text(0),
			"operator": range_to_operator(currency.get_range(1)),
			"amount": int(currency.get_range(2))
		})
	
	for variable in variables_tree.get_children():
		var var_val: Variant = null
		match variable.get_cell_mode(2):
			TreeItem.CELL_MODE_STRING:
				var_val = variable.get_text(2)
			TreeItem.CELL_MODE_RANGE:
				var_val = int(variable.get_range(2)) if variable.get_range_config(2)["step"] == 1.0 else float(variable.get_range(2))
			TreeItem.CELL_MODE_CHECK:
				var_val = variable.is_checked(2)
		
		variables.append({
			"path": variable.get_text(0),
			"operator": range_to_operator(variable.get_range(1)),
			"value": var_val
		})
	
	return {
		"items": items,
		"currency": currencies,
		"variables": variables
		}


func _clear_tree(tree_item: TreeItem) -> void:
	for item in tree_item.get_children():
		item.free()


func _load_tree_events(item_tree: TreeItem, currency_tree: TreeItem, variable_tree: TreeItem, event_data: Dictionary) -> void:
	for item in event_data["items"]:
		create_tree_item(
				item_tree, item["item"],
				operator_to_range(item["operator"]),
				item["amount"])
	
	for currency in event_data["currency"]:
		create_tree_currency(
				currency_tree,
				currency["currency"],
				operator_to_range(currency["operator"]),
				currency["amount"])
	
	for variable in event_data["variables"]:
		create_tree_variable(
				variable_tree,
				variable["path"],
				variable["operator"],
				variable["value"])
	


#func load_on_completed_events(event_dict: Dictionary) -> void:
	#_load_tree_events(completed_items, completed_currency, completed_vars, event_dict)
#
#
#func get_on_completed_events() -> Dictionary:
	#return _get_tree_events(completed_items, completed_currency, completed_vars)


func get_on_finished_events() -> Dictionary:
	return _get_tree_events(finished_items, finished_currency, finished_vars)


func load_on_finished_events(event_dict: Dictionary) -> void:
	_load_tree_events(finished_items, finished_currency, finished_vars, event_dict)


func has_on_finished_events() -> bool:
	return 0 < finished_items.get_child_count() or 0 < finished_currency.get_child_count() or 0 < finished_vars.get_child_count() 


func get_on_progressed_events() -> Dictionary:
	return _get_tree_events(progressed_items, progressed_currency, progressed_vars)


func load_on_progressed_events(event_dict: Dictionary) -> void:
	_load_tree_events(progressed_items, progressed_currency, progressed_vars, event_dict)


func has_on_progressed_events() -> bool:
	return 0 < progressed_items.get_child_count() or 0 < progressed_currency.get_child_count() or 0 < progressed_vars.get_child_count() 


func get_on_success_events() -> Dictionary:
	return _get_tree_events(completed_items, completed_currency, completed_vars)


func load_on_success_events(event_dict: Dictionary) -> void:
	_load_tree_events(completed_items, completed_currency, completed_vars, event_dict)


func has_on_success_events() -> bool:
	return 0 < completed_items.get_child_count() or 0 < completed_currency.get_child_count() or 0 < completed_vars.get_child_count() 


func get_on_failed_events() -> Dictionary:
	return _get_tree_events(failed_items, failed_currency, failed_vars)


func load_on_failed_events(event_dict: Dictionary) -> void:
	_load_tree_events(failed_items, failed_currency, failed_vars, event_dict)


func has_on_failed_events() -> bool:
	return 0 < failed_items.get_child_count() or 0 < failed_currency.get_child_count() or 0 < failed_vars.get_child_count() 


func get_on_started_events() -> Dictionary:
	return _get_tree_events(started_items, started_currency, started_vars)


func load_on_started_events(event_dict: Dictionary) -> void:
	_load_tree_events(started_items, started_currency, started_vars, event_dict)


func has_on_started_events() -> bool:
	return 0 < started_items.get_child_count() or 0 < started_currency.get_child_count() or 0 < started_vars.get_child_count() 


func clear_events() -> void:
	_clear_tree(started_items)
	_clear_tree(started_currency)
	_clear_tree(started_vars)
	_clear_tree(finished_items)
	_clear_tree(finished_currency)
	_clear_tree(finished_vars)
	_clear_tree(progressed_items)
	_clear_tree(progressed_currency)
	_clear_tree(progressed_vars)
	_clear_tree(completed_items)
	_clear_tree(completed_currency)
	_clear_tree(completed_vars)
	_clear_tree(failed_items)
	_clear_tree(failed_currency)
	_clear_tree(failed_vars)


func _on_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	match id:
		0:
			create_tree_item(item)
			#event_item_created.emit("", 0, item == completed_items)
		1:
			create_tree_currency(item)
			#event_currency_created.emit("", 0, item == completed_currency)
		2:
			create_tree_variable(item, "", 0, 0)
			#event_variable_created.emit("", 0, 0, item == completed_vars)
		3:
			create_tree_variable(item, "", 0, 0.0)
			#event_variable_created.emit("", 0.0, 0, item == completed_vars)
		4:
			create_tree_variable(item, "", 0, false)
			#event_variable_created.emit("", false, 0, item == completed_vars)
		5:
			create_tree_variable(item, "", 0, "")
			#event_variable_created.emit("", "", 0, item == completed_vars)
		6:
			#event_item_removed.emit(item.get_index(), item.get_parent() == completed_items)
			item.free()
		7:
			#event_currency_removed.emit(item.get_index(), item.get_parent() == completed_currency)
			item.free()
		8:
			#event_variable_removed.emit(item.get_index(), item.get_parent() == completed_vars)
			item.free()
