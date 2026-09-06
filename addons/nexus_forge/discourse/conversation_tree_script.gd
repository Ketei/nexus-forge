@tool
extends Tree


signal conversation_selected(dialog_id: int)
signal conversation_close_pressed(dialog_id: int)


const SELECTED_COLOR: Color = Color.SKY_BLUE

var active_conversation_item: TreeItem = null:
	set(new_conversation):
		if active_conversation_item != null:
			active_conversation_item.clear_custom_color(0)
		active_conversation_item = new_conversation
		if new_conversation != null:
			new_conversation.set_custom_color(0, SELECTED_COLOR)
var active_unsaved: bool = false:
	set(u):
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


func ready_plugin() -> void:
	create_item()
	
	item_mouse_selected.connect(_on_conversation_mouse_selected)
	button_clicked.connect(_on_close_conversation_button_clicked)


func _on_conversation_mouse_selected(_mouse_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	var selected: TreeItem = get_selected()
	active_conversation_item = selected
	conversation_selected.emit(selected.get_metadata(0)["id"])


func _on_close_conversation_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	var data: Dictionary = item.get_metadata(0)
	if id == 0:
		conversation_close_pressed.emit(data["id"])


func get_selected_id() -> int:
	if active_conversation_item == null:
		return -1
	return active_conversation_item.get_metadata(0)["id"]


func add_conversation(id: int, path: String, select: bool = false, signal_select: bool = true) -> void:
	var new_conversation: TreeItem = get_root().create_child()
	var text: String = path.get_file().get_basename()
	new_conversation.set_tooltip_text(0, path)
	new_conversation.set_text(0, text)
	new_conversation.set_metadata(0, {"id": id, "unsaved": false})
	new_conversation.add_button(
			0,
			get_theme_icon("GuiClose", "EditorIcons"),
			0,
			false,
			"Close Conversation")
	
	if select:
		active_conversation_item = new_conversation
		new_conversation.select(0)
		if signal_select:
			conversation_selected.emit()


func select_conversation(conversation_id: int, emit_select: bool = true) -> void:
	var item: TreeItem = get_conversation_item(conversation_id)
	
	if item == null:
		return
	
	active_conversation_item = item
	item.select(0)
	if emit_select:
		conversation_selected.emit(conversation_id)


func set_conversations_saved() -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["unsaved"]:
			item.set_text(0, item.get_text(0).trim_suffix("*"))
			item.get_metadata(0)["unsaved"] = false


func set_dialog_unsaved(dialog_id: int, unsaved: bool) -> void:
	var target: TreeItem = get_conversation_item(dialog_id)
	
	if target == null:
		return
	
	var previous_unsaved: bool = target.get_metadata(0)["unsaved"]
	
	if previous_unsaved != unsaved:
		if previous_unsaved:
			target.set_text(0, target.get_text(0).trim_suffix("*"))
		else:
			target.set_text(0, target.get_text(0) + "*")
	
	target.get_metadata(0)["unsaved"] = unsaved


func remove_conversation(dialog_id: int) -> void:
	var target: TreeItem = get_conversation_item(dialog_id)
	
	if target == null:
		return
	
	if active_conversation_item == target:
		active_conversation_item = null
	
	target.free()


func set_all_files_saved() -> void:
	for conv_item in get_root().get_children():
		if conv_item.get_metadata(0)["unsaved"]:
			conv_item.set_text(0, conv_item.get_text(0).trim_suffix("*"))
		conv_item.get_metadata(0)["unsaved"] = false
	
	active_unsaved = false


func get_conversation_item(conversation_id: int) -> TreeItem:
	for item in get_root().get_children():
		if item.get_metadata(0)["id"] == conversation_id:
			return item
	return null


func get_last_item_instance_id() -> int:
	if get_root().get_child_count() == 0:
		return 0
	return get_root().get_child(-1).get_metadata(0)["id"]
