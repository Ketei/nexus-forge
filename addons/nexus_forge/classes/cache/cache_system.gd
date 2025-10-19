class_name Cache
extends RefCounted


## Max size of the cache.
var max_size: int = 50: # Custom set that resizes cache_map if larger
	set(new_size):
		var clamped_size: int = maxi(new_size, 1)
		_resize_cache(clamped_size)
		max_size = clamped_size
var cache_map: Dictionary[String, CacheLink] = {}
var newest_used: CacheLink = null
var oldest_used: CacheLink = null


func _resize_cache(target_size: int) -> void:
	var current_size: int = cache_map.size()
	if current_size <= target_size:
		return
	
	while target_size < current_size:
		_remove_oldest()
		current_size -= 1


func _remove_oldest() -> void:
	if oldest_used == null:
		return
	
	var target_link: CacheLink = oldest_used
	
	cache_map.erase(target_link.key)
	
	if target_link.newer_link != null:
		target_link.newer_link.older_link = null
	
	oldest_used = target_link.newer_link
	
	if newest_used == target_link:
		newest_used = null
	
	# Releasing all internal references to prevent memory leaks due to
	# cyclical referencing.
	target_link.clear()


func _move_to_newest(link: CacheLink) -> void:
	if link == oldest_used:
		link.newer_link.older_link = null
		newest_used.newer_link = link
		link.older_link = newest_used # Newest used is now the second.
		oldest_used = link.newer_link # Update oldest
		newest_used = link # Update newest
		link.newer_link = null # link is the newest_sed, so there is no newest
	elif link != newest_used:
		link.older_link.newer_link = link.newer_link
		link.newer_link.older_link = link.older_link
		newest_used.newer_link = link
		link.newer_link = null
		link.older_link = newest_used
		newest_used = link


func _add_to_newest(link: CacheLink) -> void:
	if newest_used != null:
		link.older_link = newest_used
		newest_used.newer_link = link
		
	if oldest_used == null:
		oldest_used = link
	
	newest_used = link
	
	cache_map[link.key] = link


func cache_data(key: String, data: Variant) -> void:
	if cache_map.has(key):
		var link: CacheLink = cache_map[key]
		
		if link.data != data:
			link.data = data
		
		_move_to_newest(link)
		return
	
	var current_size: int = cache_map.size()
	
	while max_size <= current_size:
		_remove_oldest()
		current_size -= 1 # We reduce the size by 1. Should end up at 49
	
	var new_link: CacheLink = CacheLink.new()
	
	new_link.key = key
	new_link.data = data
	_add_to_newest(new_link)


func get_cache(key: String) -> Variant:
	if cache_map.has(key):
		return cache_map[key].data
	return null


func is_in_cache(key: String) -> bool:
	return cache_map.has(key)


func size() -> int:
	return cache_map.size()


func clear() -> void:
	for cache_key in cache_map.keys():
		cache_map[cache_key].clear()
	cache_map.clear()
	newest_used = null
	oldest_used = null
