@icon("res://addons/nexus_forge/icons/dialog_full.svg")
class_name DiscourseDialog
extends Resource
## The base class for Discourse dialogs.


enum LocalizationFormat {
	STRING = 0,
	VAR_ACCESS = 1,
	METHOD_CALL = 2,
}

enum LocalizationType {
	TEXT = 0,
	CHOICES = 1,
}

## The types of nodes.
const NodeType := DialogParser.NodeTypes

## The UUID of the entry node.
@export_storage var entry_node: StringName = ""

# Generated on export
@export_storage var node_logic: Dictionary[StringName, Dictionary] = {
	#&"9156f183-6761-4259-9dde-1a81d12fb047": {
		#"type": NodeType.DIALOG, # On save
		#"character_id": "ABC", # On save
		#"persist": true, # On save
		#"character_settings": {}, # On export. In memory on debug.
		#"dialog_settings": {}, # On export. In memory on debug.
		#"text_source": &"", # On export. In memory on debug.
		#"next_node": &"" # On export. In memory on debug.
	#},
	#&"9156f183-6761-4259-9dde-1a81d12fb048": {
		#"type": NodeType.OPTIONS,
		#"choices": [{
			#"next_node": &"",
			#"settings": {
				#"available": true, # On export.
				#"unlocked": true, # On export.
			#}
		#}]
	#}
}

# Generated on export.
@export_storage var id_map: Dictionary[StringName, StringName] = {
	#&"Greeting": &"9156f183-6761-4259-9dde-1a81d12fb047"
}

# ---- On editor file -----

# -------------------------

var parsed_dialog_cache: Cache
var locale_file # File that contains localized dialogs

## Returns a new DiscourseDialog depending if the game is running in release
## mode or editor mode.
static func new_dialog() -> DiscourseDialog:
	if OS.has_feature("editor"):
		#return EditorDiscourseDialog.new()
		return null
	else:
		return ReleaseDiscourseDialog.new()


func _init() -> void:
	parsed_dialog_cache = Cache.new()


## Returns the dialog UUID assiged to the custom [param id].
func get_id_target(id: StringName) -> StringName:
	if id_map.has(id):
		return id_map[id]
	return &""


## Returns true if [param id] is mapped to a dialog UUID.
func has_id(id: String) -> bool:
	return id_map.has(id)


## Assigns the [param id] to the dialog's [param uuid]. Returns [code]true[/code]
## if the assignment was successful. If the UUID doesn't exist it'll return
## [code]false[/code].
func link_id(id: String, uuid: StringName) -> bool:
	if node_logic.has(uuid):
		id_map[id] = uuid
		return true
	return false
