@tool
extends DiscourseGraphNode


const ICON_BOOL = preload("res://addons/nexus_forge/common_icons/variables/bool.svg")
const ICON_FLOAT = preload("res://addons/nexus_forge/common_icons/variables/float.svg")
const ICON_INT = preload("res://addons/nexus_forge/common_icons/variables/int.svg")
const ICON_STRING = preload("res://addons/nexus_forge/common_icons/variables/string.svg")

var _current_variant: int = TYPE_INT

@onready var val_spn_bx: SpinBox = $PanelContainer/ValSpnBx
@onready var bool_chk_btn: CheckButton = $PanelContainer/BoolChkBtn
@onready var string_ln_edt: LineEdit = $PanelContainer/StringLnEdt
@onready var path_ln_edt: LineEdit = $HBoxContainer/PathLnEdt

@onready var variant_mn_btn: MenuButton = $HBoxContainer/VariantMnBtn


func _ready() -> void:
	graph_type = GraphType.VAR_SET
	
	register_output_connection("variable", 0, true)
	register_input_connection("value", 0, true)
	
	#variant_panel.visible = false
	
	var variant_popup := variant_mn_btn.get_popup()
	variant_popup.clear()
	variant_popup.add_icon_item(ICON_INT, "",  TYPE_INT)
	variant_popup.add_icon_item(ICON_FLOAT, "", TYPE_FLOAT)
	variant_popup.add_icon_item(ICON_BOOL, "", TYPE_BOOL)
	variant_popup.add_icon_item(ICON_STRING, "", TYPE_STRING)
	add_utility()
	
	bool_chk_btn.toggled.connect(on_bool_changed)
	variant_popup.id_pressed.connect(on_type_selected)
	path_ln_edt.text_changed.connect(on_field_updated)
	string_ln_edt.text_changed.connect(on_field_updated)
	bool_chk_btn.toggled.connect(on_field_updated)
	val_spn_bx.value_changed.connect(on_field_updated)
	variant_popup.id_pressed.connect(on_field_updated)


func on_field_updated(_arg: Variant = null) -> void:
	node_updated.emit()


func on_type_selected(data_type: int) -> void:
	_current_variant = data_type
	
	match data_type:
		TYPE_INT:
			variant_mn_btn.icon = ICON_INT
		TYPE_FLOAT:
			variant_mn_btn.icon = ICON_FLOAT
		TYPE_BOOL:
			variant_mn_btn.icon = ICON_BOOL
		TYPE_STRING:
			variant_mn_btn.icon = ICON_STRING
	
	set_type(data_type)


func set_type(data_type: int, lock_type: bool = false) -> void:
	_current_variant = data_type
	val_spn_bx.visible = data_type == TYPE_INT or data_type == TYPE_FLOAT
	if val_spn_bx.visible:
		val_spn_bx.step = 0.01 if data_type == TYPE_FLOAT else 1.0
	bool_chk_btn.visible = data_type == TYPE_BOOL
	string_ln_edt.visible = data_type == TYPE_STRING
	
	variant_mn_btn.disabled = lock_type
	
	if has_any_input_connection("value"):
		var variable_set := get_input_connections("value")[0]
		if variable_set.graph_type == GraphType.VALUE:
			variable_set.set_type(
				variable_set.op_native_to_type(data_type), true)


func set_value(value: Variant) -> void:
	match typeof(value):
		TYPE_INT:
			val_spn_bx.value = value
		TYPE_FLOAT:
			val_spn_bx.value = value
		TYPE_BOOL:
			bool_chk_btn.button_pressed = value
		TYPE_STRING:
			string_ln_edt.text = value


func get_variant_type() -> int:
	return _current_variant


func set_var_path(new_path: String) -> void:
	path_ln_edt.text = new_path


func _connection_set(is_input: bool, _connection_id: String, node: DiscourseGraphNode) -> void:
	if is_input:
		val_spn_bx.editable = node == null
		bool_chk_btn.disabled = node != null
		string_ln_edt.editable = node == null
		if node != null and node.graph_type == GraphType.VALUE:
			node.set_type(
				node.op_native_to_type(_current_variant), true)


func _get_node_data() -> Dictionary:
	var return_data: Dictionary = {
		"_offset": position_offset,
		"_type": graph_type,
		"path": path_ln_edt.text.strip_edges(),
		"var_type": _current_variant
		}
	
	if has_any_input_connection("value"):
		return_data["direct"] = false
		return_data["value"] = get_input_connections("value")[0].node_id
	else:
		return_data["direct"] = true
		match _current_variant:
			TYPE_FLOAT:
				return_data["value"] = val_spn_bx.value
			TYPE_INT:
				return_data["value"] = int(val_spn_bx.value)
			TYPE_BOOL:
				return_data["value"] = bool_chk_btn.button_pressed
			TYPE_STRING:
				return_data["value"] = string_ln_edt.text.strip_edges()
	
	return return_data


func _is_orphan() -> bool:
	if has_any_output_connection("variable"):
		for out_con in get_output_connections("variable"):
			if not out_con._is_orphan():
				return false
	return true


func on_bool_changed(is_toggled: bool) -> void:
	bool_chk_btn.text = "True" if is_toggled else "False"
