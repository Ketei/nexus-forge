class_name ResourceCache
extends Cache


## Returns a resource from cache or loads it into the cache and returns it.
func get_resource(path: String) -> Resource:
	if is_in_cache(path):
		_move_to_newest(_cache_map[path])
		return get_cache(path)
	
	var res: Resource = load(path)
	
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
	
	if is_in_cache(resource.resource_path):
		_move_to_newest(_cache_map[resource.resource_path])
		return
	
	cache_data(resource.resource_path, resource)
