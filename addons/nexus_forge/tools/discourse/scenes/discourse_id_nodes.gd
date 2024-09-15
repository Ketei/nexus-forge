extends PanelContainer


@onready var id_nodes: Tree = %IDNodes
@onready var search_ids_line: LineEdit = $MarginContainer/IDsContainer/HeaderContainer/SearchIDsLine


func _ready() -> void:
	search_ids_line.text_changed.connect(on_filter_text_changed)


func on_filter_text_changed(new_filter: String) -> void:
	if new_filter.is_empty():
		for tree_item:TreeItem in id_nodes.tree_root.get_children():
			if not tree_item.visible:
				tree_item.visible = true
	else:
		for tree_item:TreeItem in id_nodes.tree_root.get_children():
			tree_item.visible = tree_item.get_text(0).to_lower().begins_with(new_filter.to_lower())
