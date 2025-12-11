@tool
extends LineEdit



func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has_all(["type", "files"]) and typeof(data["files"]) == TYPE_ARRAY and data["files"].size() == 1


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data["files"].is_empty():
		return
	text = data["files"][0]
