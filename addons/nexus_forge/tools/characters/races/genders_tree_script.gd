extends Tree


signal item_checked

var root_tree: TreeItem = null
var _editable_status: bool = false

func _ready() -> void:
	root_tree = create_item()
	set_column_expand(0, true)
	set_column_expand(1, false)
	
	set_column_custom_minimum_width(1, 32)
	
	var gender_names: Array = NFRacesRes.Genders.keys()
	
	for gender in NFRacesRes.Genders.values():
		var gender_icon: Texture2D = null
		if not NFRacesRes.GENDER_DATA[gender]["icon"].is_empty():
			gender_icon = load(NFRacesRes.GENDER_DATA[gender]["icon"])
		add_gender(Strings.capitalize(NFRacesRes.get_gender_name(gender)), gender, gender_icon)
	item_edited.connect(on_item_edited)


func add_gender(gender_text: String, gender_id: int, icon: Texture2D = null) -> void:
	var new_gender: TreeItem = create_item(root_tree)
	
	new_gender.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	new_gender.set_cell_mode(1, TreeItem.CELL_MODE_ICON)
	
	new_gender.set_text(0, gender_text)
	
	new_gender.set_editable(0, _editable_status)
	
	new_gender.set_metadata(0, gender_id)
	
	new_gender.set_selectable(1, false)
	
	if icon != null:
		new_gender.set_icon(1, icon)


func on_item_edited() -> void:
	item_checked.emit()


func get_gender_data() -> Array:
	var selected_genders: Array = []
	for gender in root_tree.get_children():
		if gender.is_checked(0):
			selected_genders.append(gender.get_metadata(0))
	return selected_genders


func clear_gender_checks() -> void:
	for gender_item in root_tree.get_children():
		if gender_item.is_checked(0):
			gender_item.set_checked(0, false)


func set_gender_chekced(gender_idx: int, set_checked: bool) -> void:
	for gender_item in root_tree.get_children():
		if gender_item.get_metadata(0) == gender_idx:
			gender_item.set_checked(0, set_checked)
			break


func set_editable(is_editable: bool) -> void:
	_editable_status = is_editable
	for gender in root_tree.get_children():
		gender.set_editable(0, is_editable)
