@tool
extends PanelContainer

@onready var search_line_edit: LineEdit = %SearchLineEdit
@onready var open_dialog_list: Tree = %OpenDialogList



func _ready() -> void:
	search_line_edit.text_changed.connect(on_text_changed)


func on_text_changed(new_text: String) -> void:
	var stripped_text: String = new_text.strip_edges().to_lower()
	
	if stripped_text.is_empty():
		for item:TreeItem in open_dialog_list.get_tree_children():
			if not item.visible:
				item.visible = true
	else:
		for item:TreeItem in open_dialog_list.get_tree_children():
			if item.get_text(0).to_lower().contains(stripped_text):
				item.visible = true
			else:
				item.visible = false
		
	
