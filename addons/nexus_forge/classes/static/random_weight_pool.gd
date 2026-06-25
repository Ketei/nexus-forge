class_name RandomWeightedPool
extends RefCounted
## An object which can store items each associated with a specific weight
## that influences the likelihood of selection.


var _items: Array[NFWeightedPoolEntry] = []
var _sorted: bool = false
var _max_weight: float = 0.0


## Adds [param item] to the item pool and assigns it the [param weight] provided.
func add_weighted(item: Variant, weight: float) -> void:
	if _sorted:
		_sorted = false
	var new_item: NFWeightedPoolEntry = NFWeightedPoolEntry.new()
	new_item.value = item
	new_item.weight = weight
	_items.append(new_item)


## Returns a randomly selected item according to the assigned weights.
func pick_weighted(pop_item: bool = false) -> Variant:
	if _items.is_empty():
		return null
	
	if not _sorted:
		_items.sort_custom(_sort_weighted)
		var cummulative: float = 0.0
		for item in _items:
			cummulative += item.weight
		_max_weight = cummulative
		_sorted = true
	
	var weight: float = randf_range(0.0, _max_weight)
	var accumulated: float = 0.0
	
	for item_idx in range(_items.size()):
		var item: NFWeightedPoolEntry = _items[item_idx]
		accumulated += item.weight
		if weight <= accumulated:
			if pop_item:
				_max_weight -= item.weight
				_items.remove_at(item_idx)
			return item.value
	
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
			"item": item.value,
			"weight": item.weight})
	return items


## Removes [param item] from the pool.
func remove_item(item: Variant) -> bool:
	for item_idx in range(_items.size()):
		if _items[item_idx].value == item:
			_max_weight -= _items[item_idx].value
			_items.remove_at(item_idx)
			return true
	return false


## Clears the item pool.
func clear_pool() -> void:
	_items.clear()
	_sorted = false
	_max_weight = 0.0


func _sort_weighted(item_a: NFWeightedPoolEntry, item_b: NFWeightedPoolEntry) -> bool:
	return item_a.weight > item_b.weight


class NFWeightedPoolEntry extends RefCounted:
	var value = null
	var weight: float = 0.0:
		set(w):
			weight = maxf(0.001, w)
