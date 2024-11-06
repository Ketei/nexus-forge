class_name ItemDefinition
extends Resource


@export var item_id: StringName = &""
@export var item_name: String = ""
@export var item_sprite: String = ""
@export var item_type: String = ""
@export var item_materials: Array[String] = []
@export var item_flags: int = 0
@export var item_level: int = 0
@export var item_value: int = 0
@export var custom_data: Dictionary = {}


func get_sprite_res() -> Texture2D:
	return load(item_sprite)


func has_sprite() -> bool:
	return not item_sprite.is_empty()


func set_custom_data(data_id: String, data: Variant) -> void:
	custom_data[data_id] = data


func get_custom_data(data_id: String) -> Variant:
	return custom_data[data_id]


func get_custom_data_keys() -> Array:
	return custom_data.keys()


func erase_custom_data(data_id: String) -> void:
	custom_data.erase(data_id)


## Returns true if item has data_id. If data_type is passed then it'll also check
## if it's of that type.
func has_custom_data(data_id: String, data_type: int = -1) -> bool:
	if -1 < data_type:
		return custom_data.has(data_id) and typeof(custom_data[data_id]) == data_type
	return custom_data.has(data_id)
