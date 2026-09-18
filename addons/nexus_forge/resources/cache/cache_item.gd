class_name NFLRUCacheLink
extends RefCounted


var data: Variant = null
var key: String = ""
var newer_link: NFLRUCacheLink = null
var older_link: NFLRUCacheLink = null


func clear() -> void:
	data = null
	key = ""
	newer_link = null
	older_link = null
