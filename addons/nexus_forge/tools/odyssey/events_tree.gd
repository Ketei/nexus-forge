@tool
extends IDTree


signal item_deleted

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
const ICON_VARIABLE = preload("res://addons/nexus_forge/common_icons/variables/variable_icon.svg")
const MAX_ITEM_RANGE: int = 100
const MAX_CURRENCY_RANGE: int = 100

const VAR_VAL_RANGE: int = 9999
const FLOAT_STEP: float = 0.01

# Change depending on what you want your default events to be.
const DEFAULT_EVENTS: PackedStringArray = [
	"quest_started",
	"quest_ended",
	"quest_progressed",
	"quest_successful",
	"quest_failed"]


func _ready() -> void:
	create_item()
	
	set_column_expand(0, true)
	set_column_expand(1, false)
	set_column_expand(2, true)
	
	set_column_custom_minimum_width(1, 48)
	
	clear_events()
	
	button_clicked.connect(_on_button_clicked)
	item_edited.connect(_on_item_edited)


func _on_item_edited() -> void:
	if get_edited_column() != 0:
		return
	
	var edited: TreeItem = get_edited()
	
	var new_id: String = get_unique_id(edited.get_parent(), edited.get_text(0), edited)
	
	edited.set_text(0, new_id)


func create_event(event_id: String = "new_event") -> TreeItem:
	var id: String = get_unique_id(get_root(), event_id, null)
	var new_event: TreeItem = get_root().create_child()
	new_event.set_text(0, id)
	
	new_event.set_editable(0, true)
	
	new_event.set_selectable(1, false)
	new_event.set_selectable(2, false)
	
	new_event.add_button(2, ICON_BIN, 13, false, "Delete Event")
	
	create_event_structure(new_event)
	return new_event


func create_event_structure(on_tree: TreeItem) -> void:
	var items: TreeItem = on_tree.create_child()
	var currency: TreeItem = on_tree.create_child()
	var vars: TreeItem = on_tree.create_child()
	var data: TreeItem = on_tree.create_child()
	
	items.set_text(0, "Items")
	vars.set_text(0, "Variables")
	currency.set_text(0, "Currency")
	data.set_text(0, "Data")
	
	items.set_metadata(0, 0)
	vars.set_metadata(0, 1)
	currency.set_metadata(0, 2)
	data.set_metadata(0, 3)
	
	items.add_button(2, ICON_ADD, 0, false, "Add Item")
	currency.add_button(2, ICON_ADD, 1, false, "Add Currency")
	vars.add_button(2, ICON_ADD_INT, 2, false, "Add Integer")
	vars.add_button(2, ICON_ADD_FLOAT, 3, false, "Add Float")
	vars.add_button(2, ICON_ADD_BOOL, 4, false, "Add Bool")
	vars.add_button(2, ICON_ADD_STRING, 5, false, "Add String")
	
	data.add_button(2, ICON_ADD_INT, 9, false, "Add Integer")
	data.add_button(2, ICON_ADD_FLOAT, 10, false, "Add Float")
	data.add_button(2, ICON_ADD_BOOL, 11, false, "Add Bool")
	data.add_button(2, ICON_ADD_STRING, 12, false, "Add String")
	
	data.set_selectable(0, false)
	data.set_selectable(1, false)
	data.set_selectable(2, false)
	
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


func create_event_item(on_tree: TreeItem, item_id: String = "", item_op: int = OP_ADD, item_count: int = 1) -> void:
	var new_item: TreeItem = on_tree.create_child()
	new_item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	
	new_item.set_range_config(1, 0, 2, 1)
	new_item.set_range_config(2, 1, MAX_ITEM_RANGE, 1)
	new_item.set_range(2, item_count)
	
	new_item.set_text(0, item_id)
	new_item.set_text(1, "=,+,-")
	new_item.set_range(1, operator_to_range(item_op))
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


func create_event_currency(on_tree: TreeItem, currency_id: String = "", item_op: int = OP_ADD, currency_count: int = 1) -> void:
	var new_item: TreeItem = on_tree.create_child()
	new_item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	
	new_item.set_range_config(1, 0, 2, 1)
	new_item.set_range_config(2, 1, MAX_ITEM_RANGE, 1)
	new_item.set_range(2, currency_count)
	
	new_item.set_text(0, currency_id)
	new_item.set_text(1, "=,+,-")
	new_item.set_range(1, operator_to_range(item_op))
	
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


func create_event_variable(on_tree: TreeItem, path: String, item_op: int, value: Variant) -> void:
	var new_item: TreeItem = on_tree.create_child()
	new_item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	
	new_item.set_range_config(1, 0, 2, 1)
	new_item.set_text(1, "=,+,-")
	new_item.set_range(1, operator_to_range(item_op))
	
	match typeof(value):
		TYPE_INT:
			new_item.set_icon(0, ICON_INT)
			new_item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_item.set_range_config(2, -VAR_VAL_RANGE, VAR_VAL_RANGE, 1.0)
			new_item.set_range(2, value)
			new_item.set_metadata(0, TYPE_INT)
			new_item.set_editable(2, true)
		TYPE_FLOAT:
			new_item.set_icon(0, ICON_FLOAT)
			new_item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_item.set_range_config(2, -VAR_VAL_RANGE, VAR_VAL_RANGE, FLOAT_STEP)
			new_item.set_range(2, value)
			new_item.set_metadata(0, TYPE_FLOAT)
			new_item.set_editable(2, true)
		TYPE_BOOL:
			new_item.set_icon(0, ICON_BOOL)
			new_item.set_cell_mode(2, TreeItem.CELL_MODE_CHECK)
			new_item.set_checked(2, value)
			new_item.set_text(2, "Enabled")
			new_item.set_text(1, "=")
			new_item.set_metadata(0, TYPE_BOOL)
			new_item.set_editable(2, true)
		TYPE_STRING:
			new_item.set_icon(0, ICON_STRING)
			new_item.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
			new_item.set_text(2, value)
			new_item.set_text(1, "=")
			new_item.set_metadata(0, TYPE_STRING)
			new_item.set_editable(2, true)
		_:
			new_item.set_icon(0, ICON_VARIABLE)
			new_item.set_metadata(0, TYPE_NIL)
			new_item.set_metadata(2, {"data": value})
			new_item.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
			new_item.set_text(2, type_string(typeof(value)))
			new_item.set_text(1, "=")
			new_item.set_editable(2, false)
	
	new_item.set_text(0, path)
	
	new_item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_CENTER)
	
	new_item.set_editable(0, true)
	new_item.set_editable(1, true)
	
	new_item.add_button(
			2,
			ICON_BIN,
			8,
			false,
			"Remove Variable")

# --- Data ---

func create_event_data(on_tree: TreeItem, data_key: String, data: Variant) -> void:
	var id: String = get_unique_id(on_tree, data_key, null)
	var new_data: TreeItem = on_tree.create_child()
	
	new_data.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_data.set_text(0, id)
	new_data.set_editable(0, true)
	new_data.set_selectable(1, false)
	
	match typeof(data):
		TYPE_INT:
			new_data.set_icon(0, ICON_INT)
			new_data.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_data.set_range_config(2, -VAR_VAL_RANGE, VAR_VAL_RANGE, 1.0)
			new_data.set_range(2, data)
			new_data.set_metadata(2, {"type": TYPE_INT})
			new_data.set_editable(2, true)
		TYPE_FLOAT:
			new_data.set_icon(0, ICON_FLOAT)
			new_data.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_data.set_range_config(2, -VAR_VAL_RANGE, VAR_VAL_RANGE, FLOAT_STEP)
			new_data.set_range(2, data)
			new_data.set_metadata(2, {"type": TYPE_FLOAT})
			new_data.set_editable(2, true)
		TYPE_BOOL:
			new_data.set_icon(0, ICON_BOOL)
			new_data.set_cell_mode(2, TreeItem.CELL_MODE_CHECK)
			new_data.set_text(2, "Enabled")
			new_data.set_checked(2, data)
			new_data.set_metadata(2, {"type": TYPE_BOOL})
			new_data.set_editable(2, true)
		TYPE_STRING:
			new_data.set_icon(0, ICON_STRING)
			new_data.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
			new_data.set_metadata(2, {"type": TYPE_STRING})
			new_data.set_text(2, data)
			new_data.set_editable(2, true)
		_:
			new_data.set_icon(0, ICON_VARIABLE)
			new_data.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
			new_data.set_metadata(2, {"type": TYPE_NIL, "data": data})
			new_data.set_text(2, type_string(data))
			new_data.set_editable(2, false)


#func create_event_data(on_event: String, data_key: String, data: Variant) -> void:
	#var on_tree: TreeItem = null
	#
	#for event in get_root().get_children():
		#if event.get_text(0) == on_event:
			#on_tree = event
			#break
	#
	#if on_tree == null:
		#return
	#
	#var id: String = get_unique_id(on_tree, data_key, null)
	#var new_data: TreeItem = on_tree.create_child()
	#
	#new_data.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	#new_data.set_text(0, id)
	#new_data.set_editable(0, true)
	#new_data.set_selectable(1, false)
	#
	#match typeof(data):
		#TYPE_INT:
			#new_data.set_icon(0, ICON_INT)
			#new_data.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			#new_data.set_range_config(2, -VAR_VAL_RANGE, VAR_VAL_RANGE, 1.0)
			#new_data.set_range(2, data)
			#new_data.set_metadata(2, {"type": TYPE_INT})
			#new_data.set_editable(2, true)
		#TYPE_FLOAT:
			#new_data.set_icon(0, ICON_FLOAT)
			#new_data.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			#new_data.set_range_config(2, -VAR_VAL_RANGE, VAR_VAL_RANGE, FLOAT_STEP)
			#new_data.set_range(2, data)
			#new_data.set_metadata(2, {"type": TYPE_FLOAT})
			#new_data.set_editable(2, true)
		#TYPE_BOOL:
			#new_data.set_icon(0, ICON_BOOL)
			#new_data.set_cell_mode(2, TreeItem.CELL_MODE_CHECK)
			#new_data.set_text(2, "Enabled")
			#new_data.set_checked(2, data)
			#new_data.set_metadata(2, {"type": TYPE_BOOL})
			#new_data.set_editable(2, true)
		#TYPE_STRING:
			#new_data.set_icon(0, ICON_STRING)
			#new_data.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
			#new_data.set_metadata(2, {"type": TYPE_STRING})
			#new_data.set_text(2, data)
			#new_data.set_editable(2, true)
		#_:
			#new_data.set_icon(0, ICON_VARIABLE)
			#new_data.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
			#new_data.set_metadata(2, {"type": TYPE_NIL, "data": data})
			#new_data.set_text(2, type_string(data))
			#new_data.set_editable(2, false)


# --- Convert ---


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


func get_events() -> Dictionary:
	var events: Dictionary = {}
	
	for event in get_root().get_children():
		var event_id: String = event.get_text(0)
		events[event_id] = {
			"items": {},
			"currency": {},
			"variables": Arrays.create_array_typed(TYPE_DICTIONARY),
			"data": {}}
		
		for event_class in event.get_children():
			if event_class.get_metadata(0) == 0: # items
				for event_item in event_class.get_children():
					events[event_id]["items"][event_item.get_text(0)] = {
						"count": int(event_item.get_range(2)),
						"operator": range_to_operator(event_item.get_range(1))}
			
			elif event_class.get_metadata(0) == 1: # Variables
				for event_var in event_class.get_children():
					var var_data: Variant = null
					
					match event_var.get_metadata(0):
						TYPE_INT:
							var_data = int(event_var.get_range(2))
						TYPE_FLOAT:
							var_data = float(event_var.get_range(2))
						TYPE_BOOL:
							var_data = event_var.is_checked(2)
						TYPE_STRING:
							var_data = event_var.get_text(2)
						TYPE_NIL:
							var_data = event_var.get_metadata(2)["data"]

					events[event_id]["variables"].append({
							"path": event_var.get_text(0),
							"operator": range_to_operator(event_var.get_range(1)),
							"value": var_data})
			
			
			elif event_class.get_metadata(0) == 2: # Currency
				for event_currency in event_class.get_children():
					events[event_id]["currency"][event_currency.get_text(0)] = {
						"count": int(event_currency.get_range(2)),
						"operator": range_to_operator(event_currency.get_range(1))}
			
			elif event_class.get_metadata(0) == 3: # Data
				for event_data in event_class.get_children():
					var var_data: Variant = null
					
					match event_data.get_metadata(2)["type"]:
						TYPE_INT:
							var_data = int(event_data.get_range(2))
						TYPE_FLOAT:
							var_data = float(event_data.get_range(2))
						TYPE_BOOL:
							var_data = event_data.is_checked(2)
						TYPE_STRING:
							var_data = event_data.get_text(2)
						TYPE_NIL:
							var_data = event_data.get_metadata(2)["data"]

					events[event_id]["data"][event_data.get_text(0)] = var_data
	return events


func clear_events() -> void:
	for event in get_root().get_children():
		event.free()


func load_default_events() -> void:
	for event in DEFAULT_EVENTS:
		var has_event: bool = false
		for event_tree in get_root().get_children():
			if event_tree.get_text(0) == event:
				has_event = true
				break
		if not has_event:
			create_event(event)


func load_event(event_id: String, event_data: Dictionary) -> void:
	var event: TreeItem = null
	
	for event_tree in get_root().get_children():
		if event_tree.get_text(0) == event_id:
			event = event_tree
			break
	
	if event == null:
		event = create_event(event_id)
	
	var items: TreeItem = null
	var currency: TreeItem = null
	var variables: TreeItem = null
	var data: TreeItem = null

	for event_class in event.get_children():
		match event_class.get_metadata(0):
			0:
				items = event_class
			1:
				variables = event_class
			2:
				currency = event_class
			3:
				data = event_class
	
	for event_item in event_data["items"]:
		create_event_item(
				items,
				event_item,
				event_data["items"][event_item]["operator"],
				event_data["items"][event_item]["count"])
	for event_currency in event_data["currency"]:
		create_event_currency(
				currency,
				event_currency,
				event_data["currency"][event_currency]["operator"],
				event_data["currency"][event_currency]["count"])
	for event_var in event_data["variables"]:
		create_event_variable(
				variables,
				event_var["path"],
				event_var["operator"],
				event_var["value"])
	for data_key in event_data["data"]:
		create_event_data(
				data,
				data_key,
				event_data["data"][data_key])


func collapse_all() -> void:
	for event in get_root().get_children():
		event.set_collapsed_recursive(true)


func _on_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	match id:
		0:
			create_event_item(item)
			if item.collapsed:
				item.collapsed = false
		1:
			create_event_currency(item)
			if item.collapsed:
				item.collapsed = false
		2:
			create_event_variable(item, "", 0, 0)
			if item.collapsed:
				item.collapsed = false
		3:
			create_event_variable(item, "", 0, 0.0)
			if item.collapsed:
				item.collapsed = false
		4:
			create_event_variable(item, "", 0, false)
			if item.collapsed:
				item.collapsed = false
		5:
			create_event_variable(item, "", 0, "")
			if item.collapsed:
				item.collapsed = false
		6:
			item.free()
			item_deleted.emit()
		7:
			item.free()
			item_deleted.emit()
		8:
			item.free()
			item_deleted.emit()
		9:
			create_event_data(item, "new_int", 0)
			if item.collapsed:
				item.collapsed = false
		10:
			create_event_data(item, "new_float", 0.0)
			if item.collapsed:
				item.collapsed = false
		11:
			create_event_data(item, "new_bool", false)
			if item.collapsed:
				item.collapsed = false
		12:
			create_event_data(item, "new_string", "")
			if item.collapsed:
				item.collapsed = false
		13: #Delete event
			item.free()
			item_deleted.emit()
