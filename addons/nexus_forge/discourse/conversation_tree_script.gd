@tool
extends Tree


signal conversation_selected(dialog: EditorDiscourseDialog)
signal conversation_close_pressed(dialog: EditorDiscourseDialog, save_required: bool, offset_changed: bool)


const SELECTED_COLOR: Color = Color.SKY_BLUE

var active_conversation_item: TreeItem = null:
	set(new_conversation):
		if active_conversation_item != null:
			active_conversation_item.clear_custom_color(0)
			_last_opened = active_conversation_item
		active_conversation_item = new_conversation
		if new_conversation != null:
			new_conversation.set_custom_color(0, SELECTED_COLOR)
var active_offset_changed: bool = false:
	set(c):
		if active_offset_changed == c:
			return
		else:
			active_offset_changed = c
		
		if active_conversation_item == null:
			return
		active_conversation_item.get_metadata(0)["offset_changed"] = c
		active_offset_changed = c
	get():
		if active_conversation_item != null:
			return active_conversation_item.get_metadata(0)["offset_changed"]
		return false
var active_unsaved: bool = false:
	set(u):
		if active_unsaved == u:
			return
		else:
			active_unsaved = u
		
		if active_conversation_item == null:
			return
		
		var meta: Dictionary = active_conversation_item.get_metadata(0)
		if u and not meta["unsaved"]:
			active_conversation_item.set_text(0, active_conversation_item.get_text(0) + "*")
		elif not u and meta["unsaved"]:
			active_conversation_item.set_text(0, active_conversation_item.get_text(0).trim_suffix("*"))
		active_conversation_item.get_metadata(0)["unsaved"] = u
	get():
		if active_conversation_item != null:
			return active_conversation_item.get_metadata(0)["unsaved"]
		return false
var _last_opened: TreeItem = null

func ready_plugin() -> void:
	create_item()
	
	item_selected.connect(_on_conversation_selected)
	button_clicked.connect(_on_close_conversation_pressedbutton_clicked)


func _on_conversation_selected() -> void:
	var selected: TreeItem = get_selected()
	
	conversation_selected.emit(selected.get_metadata(0)["resource"])


func _on_close_conversation_pressedbutton_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	var data: Dictionary = item.get_metadata(0)
	if id == 0:
		conversation_close_pressed.emit(data["resource"], data["unsaved"], data["offset_changed"])


func get_active_resource() -> EditorDiscourseDialog:
	if active_conversation_item == null:
		return null
	return active_conversation_item.get_metadata(0)["resource"]


func get_open_file_paths() -> Array[String]:
	var paths: Array[String] = []
	for conv in get_root().get_children():
		paths.append(conv.get_metadata(0)["resource"].resource_path)
	return paths


func add_conversation(data: EditorDiscourseDialog, select: bool = false, signal_select: bool = true) -> void:
	var new_conversation: TreeItem = get_root().create_child()
	var text: String = data.resource_path.get_file().get_basename()
	new_conversation.set_tooltip_text(0, data.resource_path)
	new_conversation.set_text(0, text)
	new_conversation.set_metadata(0, {"resource": data, "unsaved": false, "offset_changed": false})
	new_conversation.add_button(
			0,
			get_theme_icon("GuiClose", "EditorIcons"),
			0,
			false,
			"Close Conversation")
	
	if select:
		if signal_select:
			new_conversation.select(0)
		else:
			item_selected.disconnect(_on_conversation_selected)
			new_conversation.select(0)
			item_selected.connect(_on_conversation_selected)


func select_conversation(data: EditorDiscourseDialog, emit_select: bool = true) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["resource"] == data:
			if emit_select:
				item.select(0)
			else:
				item_selected.disconnect(_on_conversation_selected)
				item.select(0)
				item_selected.connect(_on_conversation_selected)
			return


func is_conversation_open(conversation: EditorDiscourseDialog) -> bool:
	for item in get_root().get_children():
		if item.get_metadata(0)["resource"] == conversation:
			return true
	return false


func get_unsaved_conversation_resources() -> Array[EditorDiscourseDialog]:
	var unsaved: Array[EditorDiscourseDialog] = []
	for item in get_root().get_children():
		var resource: EditorDiscourseDialog = item.get_metadata(0)["resource"]
		if item.get_metadata(0)["unsaved"]:
			unsaved.append(item.get_metadata(0)["resource"])
	return unsaved


func get_unsaved_layout_resources() -> Array[EditorDiscourseDialog]:
	var unsaved: Array[EditorDiscourseDialog] = []
	for item in get_root().get_children():
		var resource: EditorDiscourseDialog = item.get_metadata(0)["resource"]
		if item.get_metadata(0)["offset_changed"]:
			unsaved.append(item.get_metadata(0)["resource"])
	return unsaved


func set_conversations_saved() -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["unsaved"]:
			item.set_text(0, item.get_text(0).trim_suffix("*"))
			item.get_metadata(0)["unsaved"] = false
			item.get_metadata(0)["offset_changed"] = false


func remove_conversation(dialog: EditorDiscourseDialog, select_previous: bool = true) -> void:
	if active_conversation_item != null and active_conversation_item.get_metadata(0)["resource"] == dialog:
		var target: TreeItem = active_conversation_item
		var last_opened: TreeItem = _last_opened
		
		active_conversation_item = null
		_last_opened = null
		
		if last_opened != null and select_previous:
			var meta: Dictionary = last_opened.get_metadata(0)
			active_unsaved = meta["unsaved"]
			active_offset_changed = meta["offset_changed"]
			active_conversation_item = last_opened
			item_selected.disconnect(_on_conversation_selected)
			last_opened.select(0)
			item_selected.connect(_on_conversation_selected)
		else:
			active_unsaved = false
			active_offset_changed = false
		
		target.free()
	else:
		for item in get_root().get_children():
			if item.get_metadata(0)["resource"] == dialog:
				if item == _last_opened:
					_last_opened = null
				item.free()
				return


func set_conversation_item_active(conv: EditorDiscourseDialog) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["resource"] == conv:
			active_conversation_item = item
			return


func set_all_files_saved() -> void:
	for conv_item in get_root().get_children():
		if conv_item.get_metadata(0)["unsaved"]:
			conv_item.set_text(0, conv_item.get_text(0).trim_suffix("*"))
		conv_item.get_metadata(0)["unsaved"] = false
		conv_item.get_metadata(0)["offset_changed"] = false
	
	active_offset_changed = false
	active_unsaved = false
