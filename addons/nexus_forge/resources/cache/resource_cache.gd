class_name NFLRUResourceCache
extends NFLRUCache


## Returns a resource from cache or loads it into the cache and returns it.
func get_resource(path: String) -> Resource:
	var res: Resource = null
	var found: bool = false
	
	if thread_safe:
		_mutex.lock()
	
	if _cache_map.has(path):
		var link: NFLRUCacheLink = _cache_map[path]
		_move_to_newest(link)
		res = link.data
		found = true
	
	if thread_safe:
		_mutex.unlock()
	
	if found:
		return res
	
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
