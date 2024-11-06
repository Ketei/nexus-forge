class_name Arrays
extends Node
## A collection of static functions to modify arrays.


## Returns a random item on the array and removes it.
static func pop_random(array_to_pop: Array) -> Variant:
	if array_to_pop.is_empty():
		return null
	var random_index: int = randi_range(0, array_to_pop.size())
	return array_to_pop.pop_at(random_index)


## Switches the data on the [param at] array on the [param from] and [param to]
## indexes.
static func switch_indexes(from: int, to: int, at: Array) -> void:
	var array_size: int = at.size() - 1
	if array_size < from or array_size < to:
		return
	
	var second_memory = at[to]
	at[to] = at[from]
	at[from] = second_memory


## Searches array for target using the Binary Search Algorithm
static func binary_search(array: Array, target: Variant) -> int:
	var low: int = 0
	var high: int = array.size() - 1
	
	while low <= high:
		var mid_val: float = low + (high - low) / 2
		var mid: int = roundi(mid_val)
		
		if array[mid] == target:
			return mid
		elif array[mid] < target: # Right Half
			low = mid + 1
		else: # Left Half
			high = mid - 1
	
	return -1


static func move_item(array: Array, from_idx: int, to_idx: int) -> void:
	var insert_item: Variant = array[from_idx]
	
	array.remove_at(from_idx)
	array.insert(to_idx, insert_item)


static func insert_sorted_asc(array: Array, item: Variant) -> void:
	var insert: bool = false
	for idx in range(array.size()):
		if item < array[idx]:
			array.insert(idx, item)
			insert = true
			break
	if not insert:
		array.append(item)


static func insert_sorted_desc(array: Array, item: Variant) -> void:
	var insert: bool = false
	for idx in range(array.size()):
		if array[idx] < item:
			array.insert(idx, item)
			insert = true
			break
	if not insert:
		array.append(item)


static func sort_custom_alphabetically_asc(string_a: String, string_b: String) -> bool:
	return string_a.naturalnocasecmp_to(string_b) < 0


static func sort_custom_alphabetically_desc(string_a: String, string_b: String) -> bool:
	return string_b.naturalnocasecmp_to(string_a) < 0
