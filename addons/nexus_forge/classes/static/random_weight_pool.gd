class_name RandomWeightedPool
extends RefCounted
## An object which can store items each associated with a specific weight
## that influences the likelihood of selection.


var _items: Array = []
var _sorted: bool = false
var _max_weight: float = 0.0


## Adds [param item] to the item pool and assigns it the [param weight] provided.
func add_weighted(item: Variant, weight: float) -> void:
	if _sorted:
		_sorted = false
	_items.append([maxf(0.01, weight), item, 0.0])


## Returns a randomly selected item according to the assigned weights.
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


## Returns the current size of the item pool.
func pool_size() -> int:
	return _items.size()


## Returns an array of dictionary which contains the [code]item[/code]s
## and [code]weight[/code]s of the items in the pool.
func pool_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for item in _items:
		items.append({
			"item": item[1],
			"weight": item[0]
		})
	return items


## Removes [param item] from the pool.
func remove_item(item: Variant) -> bool:
	for item_idx in range(_items.size()):
		if _items[item_idx][1] == item:
			_items.remove_at(item_idx)
			return true
	return false


## Clears the item pool.
func clear_pool() -> void:
	_items.clear()
	_sorted = false
	_max_weight = 0.0


func _sort_weighted(item_a: Array, item_b: Array) -> bool:
	return item_a[0] > item_b[0]
