class_name DiscourseDialog
extends Resource

const NodeTypes := DialogParser.NodeTypes

@export var entry_node: StringName = ""
@export var base_language: String = ""

# THis is editor only.
@export var node_localization: Dictionary[StringName, Dictionary] = {
	#"a809f219-f5e1-4dc2-a041-4d200062dd53": {
		#"common": {"dialog": "10-5=5"}},
	#"629de91c-d6c1-4f67-a287-b6899695b0a6": {
		#"en": {
			#"base": {"dialog": "Common English"},
			#"US": {"dialog": "American English, bro!"},
			#"GB": {"dialog": "British English, sir."}},
		#"es": {
			#"base": {"dialog": "Ingles comun."}}},
	#"fccfaeaa-6014-4841-ab77-770775afd4e7": {
		#"en": {
			#"base": {"options": ["grey", "green"]},
			#"GB": {"options": ["gray", "green"]}}}
}


@export var localized_strings: Dictionary[String, Dictionary] = {
	#"TITLE": {
		#"en": {
			#"base": {
				#"text": "Hello {-player}",
				#"arguments": {
					#"player": {
						#"default": ":3",
						#"custom": {
							#"wulfre": "bear",
							#"other": "{player}"}}}},
			#"US": "Hello burgor",
			#"GB": "Salutations tea tea"},
		#"es": {
			#"base": {
				#"text": ""
			#}
		#}
	#}
}










var parsed_dialog_cache: Cache
@export var dialog_nodes: Dictionary[StringName, Dictionary] = {}
var storex = {
		NodeTypes.DIALOG: {
			"node_type": NodeTypes.DIALOG,
			"character_id": &"",
			"persist": true,
			"character_settings": {
				"display_name": "",
				"portrait_id": "",
				"display_name_logic": &"",
				"portrait_id_logic": &""},
			"dialog_settings": &"",
			"text_source": &"", # External source for the dialog
			"next_node": &""},
		NodeTypes.OPTIONS: {
			"node_type": null,
			"options": [{"text": "", "next_node": "", "settings": &""}, {}]},
		NodeTypes.BRANCH: {
			"node_type": null,
			"result": &"", # What node provides the result
			"case_true": &"",
			"case_false": &""},
		NodeTypes.CONDITION_SELECT: {
			"node_type": null,
			"result": &"", # What node provides the result
			"true_value": &"",
			"false_value": &""},
		NodeTypes.COMPARATION: {
			"node_type": null,
			"operator": OP_EQUAL,
			"value_a": &"",
			"value_b": &""},
		NodeTypes.EVENT: {
			"variable_path": &"",
			"variable": &"",
			"value": &"",
			"callable": &"",
			"signal": &"",
			"next_node": &""},
		NodeTypes.MATCH: {
			"case_default": &"",
			"match_value": &"",
			"cases": [
				{"value": 0, "next_node": &""},
				{"value": "X3", "next_node": &""}]},
		NodeTypes.PAUSE: {
			"next_node": &""},
		NodeTypes.RANDOM: {
			"default_override": &"",
			"options": [
				{"target": &"", "weight": &""}]},
		NodeTypes.TYPE_GUARD: {
			"type": TYPE_INT,
			"value": &"",
			"fallback": 100},
		NodeTypes.VALUE: {
			"value": 50},
		NodeTypes.SIGNAL: {
			"signal": &"",
			"arguments": [&"", &""]}, # Sources for the arguments
		NodeTypes.CALLABLE: {
			"method": &"",
			"arguments": [&""]},
		NodeTypes.CALLABLE_RETURN: {
			"method": &"",
			"arguments": [&"", &""]},
		NodeTypes.VARIABLE_GET: {
			"path": &"",
			"variable": &""},
		NodeTypes.RANDOM_VALUE: {
			"random_type": TYPE_BOOL,
			"min_value": 0.0,
			"max_value": 100.0,
			"min_source": &"",
			"max_source": &""},
		NodeTypes.RESOURCE: {
			"uuid": ""},
		NodeTypes.DATA_EVENT: {
			"variable_path": &"",
			"variable": &"",
			"value": &"",
			"callable": &"",
			"signal": &"",
			"data_source": &""}} # Where is the data to get.
#var data: Dictionary = {
	#&"UUID_A": {"type": DataTypes.DATA, "data": "Hello World"},
	#&"UUID_B": {
		#"type": DataTypes.CALLABLE,
		#"method": &"method_name",
		#"arguments": [&"UUID_A", &"UUID_C"]},
	#&"UUID_P": {"type": DataTypes.DATA, "data": "wulfre"}} # This allows for multiple steps
#
#
#var dialog_steps: Dictionary = {
	#&"UUID": {
		#"step_type": NodeTypes.DIALOG,
		#"character_id": "ketei",
		#"persist": true,
		#"dialog_settings": {"font": "", "scene": "", "speed": 0.1},
		#"character_settings": {"display_name": "", "portrait_id": ""},
		#"text_source": &"UUID_A", # points to _data
		#"next_node": &"UUID2"}, # points to _dialog_steps
	#&"UUID2": {
		#"step_type": NodeTypes.CALLABLE_RETURN,
		#"method": &"get_random_text",
		#"arguments": [&"UUID_P"]}} # All arguments are stored in _data


static func new_dialog() -> DiscourseDialog:
	if OS.has_feature("editor"):
		return EditorDiscourseDialog.new()
	else:
		return ReleaseDiscourseDialog.new()


func _init() -> void:
	parsed_dialog_cache = Cache.new()
