class_name Random
extends Node


static func create_weighted_pool() -> Random.RandomWeightedPool:
	return RandomWeightedPool.new()


class RandomWeightedPool extends RefCounted:
	var _items: Array = []
	var _sorted: bool = false
	var _max_weight: float = 0.0
	
	# weight, item, total
	func add_weighted(item: Variant, weight: float) -> void:
		if _sorted:
			_sorted = false
		_items.append([maxf(0.01, weight), item, 0.0])
	
	
	func pick_weighted() -> Variant:
		if not _sorted:
			_items.sort_custom(_sort_weighted)
			var cummulative: float = 0.0
			for item in _items:
				cummulative += item[0]
				item[2] = cummulative
			_max_weight = cummulative
			_sorted = true
		
		var weight: float = randf_range(0.0, _max_weight)
		
		for item in _items:
			if weight <= item[2]:
				return item[1]
		
		return null
	
	
	func pool_size() -> int:
		return _items.size()
	
	
	func pool_items() -> Array:
		var pool_items: Array = []
		for item in _items:
			pool_items.append({
				"item": item[1],
				"weight": item[0]
			})
		return pool_items()
	
	
	func erase_weighted(item: Variant) -> bool:
		for item_idx in range(_items.size()):
			if _items[item_idx][1] == item:
				_items.remove_at(item_idx)
				return true
		return false
	
	
	func clear_weighted() -> void:
		_items.clear()
		_sorted = false
		_max_weight = 0.0
	
	
	func _sort_weighted(item_a: Array, item_b: Array) -> bool:
		return item_a[0] > item_b[0]
