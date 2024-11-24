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
	var second_memory: Variant = at[to]
	at[to] = at[from]
	at[from] = second_memory


## Searches array for target using the Binary Search Algorithm on an array
## in ascending order. Returns the [param target]'s index or [code]-1[/code]
## if the item isn't found.
static func binary_search(array: Array, target: Variant) -> int:
	var low: int = 0
	var high: int = array.size() - 1
	
	while low <= high:
		var mid: int = low + (high - low) / 2#roundi(low + (high - low) / 2.0)
		
		if array[mid] == target: # Bingo
			return mid
		elif array[mid] < target: # Right Half
			low = mid + 1
		else: # Left Half
			high = mid - 1
	
	return -1


## Searches array for target using the Binary Search Algorithm on an array
## in descending order. Returns the [param target]'s index or [code]-1[/code]
## if the item isn't found.
static func binary_search_desc(array: Array, target: Variant) -> int:
	var low: int = 0
	var high: int = array.size() - 1

	while low <= high:
		var mid: int = (low + high) / 2
		
		if array[mid] == target:
			return mid  # Bingo
		elif array[mid] > target:
			low = mid + 1  # Search on the Right
		else:
			high = mid - 1  # Search on the Left
	return -1


## Moves an item from the [param array] from [param from_idx] to [param to_idx]
static func move_item(array: Array, from_idx: int, to_idx: int) -> void:
	var insert_item: Variant = array[from_idx]
	
	array.remove_at(from_idx)
	array.insert(to_idx, insert_item)


## Inserts an item into an array that is sorted in ascending order. Calling
## it on an unsorted array will result in unexpected behavior. 
static func insert_sorted_asc(array: Array, item: Variant) -> void:
	array.insert(array.bsearch(item, false), item)


## Inserts an item into an array that is sorted in descending order. Calling
## it on an unsorted array will result in unexpected behavior. 
static func insert_sorted_desc(array: Array, item: Variant) -> void:
	var low: int = 0
	var high: int = array.size() - 1
	
	while low <= high:
		var mid: int = (low + high) / 2
	
		if array[mid] > item:
			low = mid + 1  # We should insert before this element
		else:
			high = mid - 1  # We should insert after this element
	
	array.insert(low, item)


## A non-case-sensitive alphabetical ascending string sort.
static func sort_custom_alphabetically_asc(string_a: String, string_b: String) -> bool:
	return string_a.naturalnocasecmp_to(string_b) < 0


## A non-case_sensitive alphabetical descending string sort.
static func sort_custom_alphabetically_desc(string_a: String, string_b: String) -> bool:
	return string_b.naturalnocasecmp_to(string_a) < 0
