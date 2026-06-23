class_name NFCatalogEntry
extends RefCounted
## An entry object for a catalog.

## The name of the entry.
var name: String = ""
## The description of the entry.
var description: String = ""
var _custom: bool = false
var _valid: bool = false
## Custom data assigned to this entry. It can be accessed through this member
## or directly by calling [code]MyEntry.my_custom_data[/code]
var custom_data: Dictionary[StringName, Variant] = {}


func _get(property: StringName) -> Variant:
	if custom_data.has(property):
		return custom_data[property]
	return null


## Returns if this entry is from a built-in item, or was added in programatically.
func is_custom() -> bool:
	return _custom


## Returns [code]true[/code] if this entry is inside of a catalog. Catalogs,
## to prevent crashes on invalid access, will return a non-valid item when
## accessing an inexistent item.
func is_valid() -> bool:
	return _valid
