class_name NFLRUResourceCache
extends NFLRUCache


## Returns a resource from cache or loads it into the cache and returns it.
func get_resource(path: String) -> Resource:
	var res: RefCounted = null
	var found: bool = false
	
	if thread_safe:
		_mutex.lock()
	
	if _cache_map.has(path):
		var link: NFLRUCacheLink = _cache_map[path]
		_move_to_newest(link)
		if link.data is Resource:
			res = link.data
			found = true
	
	if thread_safe:
		_mutex.unlock()
	
	if found:
		return res
	
	if ResourceLoader.exists(path):
		res = load(path)
	
	if res != null:
		cache_data(path, res)
	
	return res


## Adds a [param resource] to the cache and marks it as the newest used. 
## If already in the cache, it'll be marked as the newest used.[br]
## The resource must be a loaded file (have
## a non-empty [member Resource.resource_path]) for it to be cached.
func cache_resource(resource: Resource):
	if resource == null or resource.resource_path.is_empty():
		return
	
	cache_data(resource.resource_path, resource)


## It adds [param data] to the cache with the id param key.[br]
## If the item was already cached it moves it to the front of the
## cache (newest used).
func cache_data(key: String, data: Variant) -> void:
	if data is Resource:
		super.cache_data(key, data)
