extends Tree


const RANGE_MAX: int = 9999
var root_tree: TreeItem


func _ready() -> void:
	root_tree = create_item()
	
	#create_variant("stronk")


func validate_variant_id(variant_id: String) -> String:
	var desired_id: String = "new_variant" if variant_id.is_empty() else variant_id
	var modified_id: String = desired_id
	var iteration_count: int = 1
	while has_id(modified_id):
		modified_id = str(desired_id, "_", iteration_count)
		iteration_count += 1
	return modified_id


func has_id(id_string: String) -> bool:
	for item in root_tree.get_children():
		if item.get_text(0) == id_string:
			return true
	return false


func create_variant(variant_id: String, variant_refs: String, species_id: String, race_id: String) -> void:
	var valid_id: String = validate_variant_id(variant_id)
	var new_variant: TreeItem = create_item(root_tree)
	new_variant.set_text(0, valid_id)
	new_variant.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_variant.set_text(1, variant_refs)
	new_variant.set_editable(1, true)
	new_variant.add_button(1, load("res://addons/nexus_forge/common_icons/trash_bin.svg"))
	for race_stat in NexusForge.Races.species[species_id]["races"][race_id]["stats"]:
		create_stat(race_stat, new_variant)
	new_variant.collapsed = true


func create_stat(stat_name: String, variant_tree: TreeItem) -> TreeItem:
	var new_stat: TreeItem = create_item(variant_tree)
	#var step: float = 1.0 if is_int else RANGE_FLOAT_STEP
	new_stat.set_text(0, stat_name)
	new_stat.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_stat.set_range_config(1, -100, 100, 1)
	
	new_stat.set_editable(1, true)
	
	return new_stat


func get_stat_variant_data() -> Dictionary:
	var variant_stats: Dictionary = {}
	for variant in root_tree.get_children():
		variant_stats[variant.get_text(0)] = {}
		for variant_stat in variant.get_children():
			variant_stats[variant.get_text(0)][variant_stat.get_text(0)] = variant_stat.get_range(1)
	return variant_stats
