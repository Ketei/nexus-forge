extends Tree


var file_root: TreeItem = null


func _ready() -> void:
	file_root = create_item()


func add_file(file_text) -> TreeItem:
	var new_item = create_item(file_root)
	new_item.set_text(0, file_text)
	return new_item
