class_name CacheLink
extends RefCounted


var data: Variant = null
var key: String = ""
var newer_link: CacheLink = null
var older_link: CacheLink = null


func clear() -> void:
	data = null
	key = ""
	newer_link = null
	older_link = null
