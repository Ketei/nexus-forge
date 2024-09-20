class_name VariablesManagerClass
extends Node


signal variable_updated


# Idea

# The main root will consist of an array full of dictionaries. Each dictinary
# contains the data.

# [{folder_name: "alksjd", "variables": {}, "subfolders": []}]

# "variable_key": 



var _exposed_variables: Array[Dictionary] = []


static func get_folder_structure() -> Dictionary:
	return {
		"folder_name": "",
		"variables": [], # Contains dicts obtained via get_variable_structure.
		"subfolders": [] # This contains dictionaries with this same structure.
	}


static func get_variable_structure() -> Dictionary:
	return {
		"name": "",
		"value": null,
		"hint": ""
	}
