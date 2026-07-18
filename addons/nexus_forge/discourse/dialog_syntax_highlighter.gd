class_name NFEditorDialogSyntaxHighlighter
extends SyntaxHighlighter


static var regex_engine: RegEx = null

static var _token_colors: Dictionary[String, Color] = {}

var _use_tokens: Dictionary[String, bool] = {}
var match_unused_under_any: bool = false


func _init() -> void:
	if regex_engine == null:
		regex_engine = RegEx.new()
		regex_engine.compile("\\{(\\![a-zA-Z\\_][a-zA-Z0-9\\_]*(?:\\|[^\\}]+)?|(?!\\!)[^\\}]+)\\}")
	
	if _token_colors.is_empty():
		_token_colors = {
			"!": Color("57b3fa"), # Methods
			"$": Color("41ffb1"), # Variables
			"&": Color("ffeda1"), # Format Strings
			"?": Color("ff7085"), # Random Picks
			"*": Color("d0afff")} # Everything Else
	
	if _use_tokens.is_empty():
		for token in _token_colors.keys():
			_use_tokens[token] = true


func _get_line_syntax_highlighting(line: int) -> Dictionary:
	var color_map: Dictionary = {}
	var text_edit: TextEdit = get_text_edit()
	
	if text_edit == null:
		return color_map
	
	var text: String = text_edit.get_line(line)
	var default_col: Color = text_edit.get_theme_color(&"font_color")
	
	for reg_match in regex_engine.search_all(text):
		var match_string: String = reg_match.get_string(1)
		var begin: int = reg_match.get_start()
		var end: int = reg_match.get_end()
		var token: String = match_string[0] if match_string[0] != "*" else ""
		
		if _use_tokens.has(token):
			if not _use_tokens[token]:
				if match_unused_under_any:
					token = ""
				else:
					continue
			elif token != "*":
				if match_string.length() <= 1:
					continue
		else:
			if not _use_tokens["*"]:
				continue
		
		var colorfor_token: Color = _token_colors[token] if _token_colors.has(token) else _token_colors["*"]
		
		color_map[begin] = {"color": colorfor_token}
		if not color_map.has(end):
			color_map[end] = {"color": default_col}
	
	return color_map


func set_use_token(token: String, use: bool) -> void:
	if _use_tokens.has(token):
		_use_tokens[token] = use
