@tool
extends Tree


const RANGE_MAX: int = 9999
var root_tree: TreeItem
var variant_refs: Array = []

func _ready() -> void:
	root_tree = create_item()


func validate_variant_id(variant_id: String, skip_tree: TreeItem) -> String:
	var desired_id: String = "new_variant" if variant_id.is_empty() else variant_id
	var modified_id: String = desired_id
	var iteration_count: int = 1
	while has_id(modified_id, skip_tree):
		modified_id = str(desired_id, "_", iteration_count)
		iteration_count += 1
	return modified_id


func has_id(id_string: String, skip_tree: TreeItem) -> bool:
	for item in root_tree.get_children():
		if item == skip_tree:
			continue
		if item.get_text(0) == id_string:
			return true
	return false


func create_variant(variant_id: String, variant_ref: String, stats: Dictionary) -> void:
	var new_variant: TreeItem = create_item(root_tree)
	var valid_id: String = validate_variant_id(variant_id, new_variant)
	var ref_idx: int = variant_refs.find(variant_ref)
	
	new_variant.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_variant.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	
	new_variant.set_editable(0, true)
	new_variant.set_editable(1, true)
	
	new_variant.set_text(0, valid_id)
	new_variant.set_text(1, ",".join(variant_refs))
	if ref_idx != -1:
		new_variant.set_range(1, ref_idx)
	
	new_variant.add_button(1, load("res://addons/nexus_forge/common_icons/trash_bin.svg"))
	
	for race_stat in stats:
		create_stat(race_stat, stats[race_stat], new_variant)
	
	new_variant.collapsed = true


func update_refs(refs: Array) -> void:
	for variant in root_tree.get_children():
		var fix_range: int = refs.find(variant_refs[variant.get_range(1)])
		variant.set_text(1, ",".join(refs))
		if fix_range != -1:
			variant.set_range(1, fix_range)
	variant_refs = refs


func update_ref_id(from: String, to: String) -> void:
	var old_idx: int = variant_refs.find(from)
	variant_refs[old_idx] = to
	
	for variant in root_tree.get_children():
		variant.set_text(1, ",".join(variant_refs))


func set_variant_stat(variant_id: String, stat_id: String, stat_value: int) -> void:
	for variant in root_tree.get_children():
		if variant.get_text(0) == variant_id:
			for stat in variant.get_children():
				if stat.get_text(0) == stat_id:
					stat.set_range(1, clampi(stat_value, -RANGE_MAX, RANGE_MAX))
					return


func update_race_stats(stats: Array) -> void:
	for variant in root_tree.get_children():
		for stat_tree in variant.get_children():
			if not stats.has(stat_tree.get_text(0)):
				stat_tree.free()
		
		for stat in stats:
			var has_stat: bool = false
			for stat_tree in variant.get_children():
				if stat_tree.get_text(0) == stat:
					has_stat = true
					break
			if not has_stat:
				create_stat(stat, 0, variant)


func add_stat_to_variants(stat: String) -> void:
	for variant in root_tree.get_children():
		create_stat(stat, 0, variant)


func remove_stat_from_variants(stat: String) -> void:
	for variant in root_tree.get_children():
		for stat_tree in variant.get_children():
			if stat_tree.get_text(0) == stat:
				stat_tree.free()
				break


func update_stat_id(old_id: String, new_id: String) -> void:
	for variant in root_tree.get_children():
		for stat in variant.get_children():
			if stat.get_text(0) == old_id:
				stat.set_text(0, new_id)
				break


func clear_variants() -> void:
	for variant in root_tree.get_children():
		variant.free()


func create_stat(stat_name: String, stat_value: int, variant_tree: TreeItem) -> TreeItem:
	var new_stat: TreeItem = create_item(variant_tree)
	new_stat.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_stat.set_range_config(1, -RANGE_MAX, RANGE_MAX, 1)
	
	new_stat.set_text(0, stat_name)
	new_stat.set_range(1, stat_value)
	
	new_stat.set_editable(1, true)
	
	return new_stat


func get_stat_variant_data() -> Dictionary:
	var variant_stats: Dictionary = {}
	for variant in root_tree.get_children():
		variant_stats[variant.get_text(0)] = {
			"sheet": variant_refs[variant.get_range(1)],
			"stats": {}
		}
		for variant_stat in variant.get_children():
			variant_stats[variant.get_text(0)]["stats"][variant_stat.get_text(0)] = variant_stat.get_range(1)
	return variant_stats
