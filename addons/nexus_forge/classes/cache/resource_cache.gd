class_name ResourceCache
extends Cache


## Returns a resource from cache or loads it into the cache and returns it.
func get_resource(path: String) -> Resource:
	if is_in_cache(path):
		_move_to_newest(cache_map[path])
		return get_cache(path)
	
	var res: Resource = load(path)
	
	if res != null:
		cache_data(path, res)
	
	return res


func cache_resource(resource: Resource):
	if resource == null:
		return
	
	if is_in_cache(resource.resource_path):
		_move_to_newest(cache_map[resource.resource_path])
		return
	
	cache_data(resource.resource_path, resource)
