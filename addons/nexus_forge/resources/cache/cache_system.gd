@icon("res://addons/nexus_forge/icons/cache_icon.svg")
class_name Cache
extends RefCounted
## A basic implemetation of a Least Recently Used Cache (LRU Cache)
##
## Takes advantage of Godot's references by holding one until it leaves the
## LRU. This cache can also hold raw data.[br]
## An LRU has a defined size, and will hold references until the cache is full
## after that, adding a new item will release the least recently accessed item
## from the cache, freeing one slot and filling it with the newly cached item.
## [br]
## [br]
## [b]IMPORTANT:[/b] While [Cache] will automatically clean itself
## when its reference counter drops to 0 it is highly recommended to
## manually call [method Cache.clear] as soon as you no longer need the [Cache].
## This ensures that it clears all its references and allows
## the memory to be safely released.


## Max size of the cache.
var max_size: int = 50: # Custom set that resizes _cache_map if larger
	set(new_size):
		var clamped_size: int = maxi(new_size, 1)
		_resize_cache(clamped_size)
		max_size = clamped_size
var _cache_map: Dictionary[String, CacheLink] = {}
var _newest_used: CacheLink = null
var _oldest_used: CacheLink = null


func _resize_cache(target_size: int) -> void:
	var current_size: int = _cache_map.size()
	if current_size <= target_size:
		return
	
	while target_size < current_size:
		_remove_oldest()
		current_size -= 1


func _remove_oldest() -> void:
	if _oldest_used == null:
		return
	
	var target_link: CacheLink = _oldest_used
	
	_cache_map.erase(target_link.key)
	
	if target_link.newer_link != null:
		target_link.newer_link.older_link = null
	
	_oldest_used = target_link.newer_link
	
	if _newest_used == target_link:
		_newest_used = null
	
	# Releasing all internal references to prevent memory leaks due to
	# cyclical referencing.
	target_link.clear()


func _move_to_newest(link: CacheLink) -> void:
	if link == _newest_used:
		return
	
	if link.older_link != null:
		link.older_link.newer_link = link.newer_link
	
	if link.newer_link != null:
		link.newer_link.older_link = link.older_link
	
	if link == _oldest_used:
		_oldest_used = link.newer_link
	
	link.older_link = _newest_used
	link.newer_link = null
	
	if _newest_used != null:
		_newest_used.newer_link = link
	
	_newest_used = link
	
	if _oldest_used == null:
		_oldest_used = link


func _add_to_newest(link: CacheLink) -> void:
	if _newest_used != null:
		link.older_link = _newest_used
		_newest_used.newer_link = link
		
	if _oldest_used == null:
		_oldest_used = link
	
	_newest_used = link
	
	_cache_map[link.key] = link


## It adds [param data] to the cache with the id param key.[br]
## If the item was already cached it moves it to the front of the
## cache (newest used).
func cache_data(key: String, data: Variant) -> void:
	if _cache_map.has(key):
		var link: CacheLink = _cache_map[key]
		
		if link.data != data:
			link.data = data
		
		_move_to_newest(link)
		return
	
	var current_size: int = _cache_map.size()
	
	while max_size <= current_size:
		_remove_oldest()
		current_size -= 1
	
	var new_link: CacheLink = CacheLink.new()
	
	new_link.key = key
	new_link.data = data
	_add_to_newest(new_link)


## Returns the cached item assigned to [param key] or [code]null[/code] if
## the item isn't in the cache.
func get_cache(key: String) -> Variant:
	if _cache_map.has(key):
		return _cache_map[key].data
	return null


## Returns true if an item with key [param key] is in the cache.
func is_in_cache(key: String) -> bool:
	return _cache_map.has(key)


## Returns the current size of the cache.
func size() -> int:
	return _cache_map.size()


## Clears the cache.
func clear() -> void:
	for cache_key in _cache_map.keys():
		var link = _cache_map[cache_key]
		if is_instance_valid(link):
			_cache_map[cache_key].clear()
	_cache_map.clear()
	_newest_used = null
	_oldest_used = null


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for cache_key in _cache_map.keys():
			_cache_map[cache_key].clear()
		_cache_map.clear()
		_newest_used = null
		_oldest_used = null
