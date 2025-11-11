@icon("res://addons/nexus_forge/icons/dialog_full.svg")
class_name DiscourseDialog
extends Resource
## The base class for Discourse dialogs.

## The types of nodes.
const NodeTypes := DialogParser.NodeTypes

## The UUID of the entry node.
@export_storage var entry_node: StringName = ""
## The default base language.
@export_storage var base_language: String = ""

@export_storage var dialog_nodes: Dictionary[StringName, Dictionary] = {}

var parsed_dialog_cache: Cache

## Returns a new DiscourseDialog depending if the game is running in release
## mode or editor mode.
static func new_dialog() -> DiscourseDialog:
	if OS.has_feature("editor"):
		return EditorDiscourseDialog.new()
	else:
		return ReleaseDiscourseDialog.new()


func _init() -> void:
	parsed_dialog_cache = Cache.new()
