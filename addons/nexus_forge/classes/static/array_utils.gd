class_name ArrayUtils
extends RefCounted
## A collection of static functions to modify arrays.


## Removes a random item on the array and returns it.
static func pop_random(from: Array) -> Variant:
	if from.is_empty():
		return null
	var random_index: int = randi_range(0, from.size())
	return from.pop_at(random_index)


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
	var max_size: int = array.size()
	
	if 0 < max_size:
		var clamped_idx: int = clampi(array.bsearch(target), 0, max_size - 1)
		return clamped_idx if array[clamped_idx] == target else -1
	else:
		return -1


## Searches array for target using the Binary Search Algorithm. This method is
## for when [param array] is in descending order.
static func bsearch_array_desc(array: Array, target: Variant) -> int:
	var low: int = 0
	var high: int = array.size() - 1
	
	while low <= high:
		var mid_val: float = low + (high - low) / 2.0
		var mid: int = roundi(mid_val)
		
		if array[mid] == target:
			return mid
		elif array[mid] < target: # Right Half
			low = mid + 1
		else: # Left Half
			high = mid - 1
	
	return -1


## Moves an item on the [param array] from [param from_idx] to [param to_idx].
static func move_item(array: Array, from_idx: int, to_idx: int) -> void:
	var insert_item: Variant = array[from_idx]
	
	array.remove_at(from_idx)
	array.insert(to_idx, insert_item)


## Inserts [param item] on [param array] in an ascending order.[br]
## Function expects [param array] to already be sorted.
static func insert_sorted_asc(array: Array, item: Variant) -> void:
	array.insert(array.bsearch(item), item)


## Inserts [param item] on [param array] in a descending order[br]
## Function expects [param array] to already be sorted.
static func insert_sorted_desc(array: Array, item: Variant) -> void:
	var low: int = 0
	var high: int = array.size() - 1
	
	while low <= high:
		@warning_ignore("integer_division")
		var mid: int = (low + high) / 2
	
		if array[mid] > item:
			low = mid + 1  # We should insert before this element
		else:
			high = mid - 1  # We should insert after this element
	
	array.insert(low, item)


## Simple sorting fucntion for [method Array.sort_custom][br]
## Does a simple [code]item_b < item_a[/code][br]
## Usage: [code]Array.sort_custom(ArrayUtils.sort_custom_desc)[/code]
static func sort_custom_desc(item_a: Variant, item_b: Variant) -> bool:
	return item_b < item_a


## Simple sorting function for [method Array.sort_custom] when the arrays
## contain strings. Sorts item in an alphabetically ascending order. Case insensitive.[br]
## Usage: [code]Array.sort_custom(ArrayUtils.sort_custom_alphabetically_asc)[/code]
static func sort_custom_alphabetically_asc(string_a: String, string_b: String) -> bool:
	return string_a.naturalnocasecmp_to(string_b) < 0


## Simple sorting function for [method Array.sort_custom] when the arrays
## contain strings. Sorts item in an alphabetically descending order. Case insensitive.[br]
## Usage: [code]Array.sort_custom(ArrayUtils.sort_custom_alphabetically_desc)[/code]
static func sort_custom_alphabetically_desc(string_a: String, string_b: String) -> bool:
	return string_b.naturalnocasecmp_to(string_a) < 0


## Returns true if the array contains the string [param what]. It performs a 
## non-case-sensitive comparison.
static func containsn(array: Array, what: String) -> bool:
	what = what.to_upper()
	
	for element in array:
		match typeof(element):
			TYPE_STRING:
				if element.to_upper() == what:
					return true
			_:
				continue
	return false


## Appends to [param append_to] the items from [param from] that it doesn't
## already have.
static func append_uniques(append_to: Array, from: Array) -> void:
	for item in from:
		if not append_to.has(item):
			append_to.append(item)


## Clamps [param index] to be between 0 and the size of [param to_array].
static func clamp_index(to_array: Variant, index: int) -> int:
	return clampi(index, 0, to_array.size())


## Inserts the items from [param items] to the array [param to] in an ascending
## order.[br]
## Function expects [param to] to be already sorted.
static func insert_uniques_asc(to: Array, items: Array) -> void:
	for item in items:
		if not to.has(item):
			insert_sorted_asc(to, item)


## Removes the items from [param substract] that exist on [param from].
static func substract_array(from: Array, substract: Array) -> void:
	var remove_count: int = 0
	var MAX_ITEMS: int = from.size()
	
	if from.is_empty():
		return
	
	for item in substract:
		var found_idx: int = from.find(item)
		if found_idx != -1:
			from.remove_at(found_idx)
			remove_count += 1
		if MAX_ITEMS <= remove_count:
			break


## Returns an array containing the unique items from both arrays.[br]
## [code]difference([a,b], [b,c])[/code] = [code][a, c][/code]
static func symetric_difference(array_a: Array, array_b: Array) -> Array:
	var difference_items: Array = []
	for item in array_a:
		if not array_b.has(item):
			difference_items.append(item)
	for item in array_b:
		if not array_a.has(item):
			difference_items.append(item)
	return difference_items


## Removes the item from the [param array] at [param position] without
## preserving the array order and thus preventing index shifting.[br]
## This is more efficient than removing an item from an index at the cost
## of not preserving the order of items in the array.
static func swap_remove(array: Array, index: int) -> void:
	var size: int = array.size()
	
	if size == 0 or index < 0 or size <= index:
		return
	
	if 2 <= size:
		array[index] = array[size - 1]
	
	array.resize(size - 1)


## Costructor for an array with default parameters set.
static func create_typed(type: int, from: Array = [], class_string: StringName = &"", script: Variant = null) -> Array:
	return Array(from, type, class_string, script)


## Constructor for a 2D array.
static func create_2d(size_x: int, size_y: int, type: int = -1) -> Array[Array]:
	if size_x <= 0 or size_y <= 0:
		return create_typed(TYPE_ARRAY)
	
	var y_array: Array[Array] = []
	y_array.resize(size_y)
	
	if 0 <= type and type < TYPE_MAX:
		for array_idx in range(size_x):
			var x_array: Array = create_typed(type) if type != -1 else []
			x_array.resize(size_x)
			y_array[array_idx] = x_array
	
	return y_array


## Resizes a 2D array.
static func resize_2d(array: Array[Array], new_width: int, new_height: int) -> void:
	new_width = maxi(0, new_width)
	new_height = maxi(0, new_height)
	
	if array.size() != new_height:
		array.resize(new_height)
	
	if 0 < new_height:
		for x_arr in array:
			x_arr.resize(new_width)


## Replaces all instances of [param find] with [param replace_with] on the
## array [param in_array]
static func replace_all(in_array: Variant, find: Variant, replace_with: Variant) -> void:
	var index_found: int = in_array.find(find)
	
	while index_found != -1:
		in_array[index_found] = replace_with
		index_found = in_array.find(find, index_found)
