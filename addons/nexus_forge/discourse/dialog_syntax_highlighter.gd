@tool
class_name NFEditorDialogSyntaxHighlighter
extends SyntaxHighlighter


static var _regex_engine: RegEx = null

static var _token_colors: Dictionary[String, Color] = {}

var _use_tokens: Dictionary[String, bool] = {}

## Determines the fallback behavior for tokens that have been disabled
## via [method NFEditorDialogSyntaxHighlighter.set_use_token].
## If [code]true[/code], matched tokens that are currently disabled
## will fall back to being highlighted as generic [code]*[/code] tokens
## If [code]false[/code], disabled tokens are skipped entirely by
## the highlighter and will retain the default font color.
var match_unused_under_any: bool = false


static func _static_init() -> void:
	_regex_engine = RegEx.new()
	_regex_engine.compile("\\{(\\![a-zA-Z\\_][a-zA-Z0-9\\_]*(?:\\|[^\\}]+)?|(?!\\!)[^\\}]+)\\}")
	_token_colors = {
			"!": Color("57b3fa"), # Methods
			"$": Color("41ffb1"), # Variables
			"&": Color("ffeda1"), # Format Strings
			"?": Color("ff7085"), # Random Picks
			"*": Color("d0afff")} # Everything Else


func _init() -> void:
	for token in _token_colors.keys():
		_use_tokens[token] = true


func _get_line_syntax_highlighting(line: int) -> Dictionary:
	var color_map: Dictionary = {}
	var text_edit: TextEdit = get_text_edit()
	
	if text_edit == null:
		return color_map
	
	var text: String = text_edit.get_line(line)
	var default_col: Color = text_edit.get_theme_color(&"font_color")
	
	for reg_match in _regex_engine.search_all(text):
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


## Sets if the highlighter should use any of the defined tokens.[br]
## Currently available: [code]!, [code]$[/code], [code]&[/code],
## [code]?[/code] and [code]*[/code].[br] 
## Token [code]*[/code] represents anything contained within curly brackets.
func set_use_token(token: String, use: bool) -> void:
	if _use_tokens.has(token):
		_use_tokens[token] = use
