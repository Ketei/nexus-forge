@tool
extends SyntaxHighlighter

const ESCAPED_TOKENS: PackedStringArray = [
	"\\", ".", "^", "$", "*", "+", "?", "|", "(", ")", "[", "]", "{", "}",
	"-", "/", ":", "="
]

var regex_engine: RegEx = null
var _token_matches: Dictionary[String, Color] = {}


func _init() -> void:
	regex_engine = RegEx.new()


func _get_line_syntax_highlighting(line: int) -> Dictionary:
	if _token_matches.is_empty():
		return {}
	
	var color_map: Dictionary = {}
	var text_edit: TextEdit = get_text_edit()
	
	if text_edit == null:
		return color_map
	
	var default_color: Color = text_edit.get_theme_color("font_color")
	var text: String = text_edit.get_line(line)
	
	for reg_match in regex_engine.search_all(text):
		var match_string: String = reg_match.get_string()
		
		if not _token_matches.has(match_string):
			continue
		
		var begin: int = reg_match.get_start()
		var end: int = reg_match.get_end()
		
		var colorfor_token: Color = _token_matches[match_string]
		
		color_map[begin] = {"color": colorfor_token}
		if not color_map.has(end):
			color_map[end] = {"color": default_color}

	return color_map


func add_token(token: String, color: Color) -> void:
	var escaped_token: String = token
	_token_matches[token] = color


func compile_highlighter() -> void:
	if _token_matches.is_empty():
		regex_engine.clear()
		return
	
	var escaped_tokens: Array[String] = []
	
	for token in _token_matches:
		var escaped_token: String = token
		for existing_token in ESCAPED_TOKENS:
			if escaped_token.contains(existing_token):
				escaped_token = escaped_token.replace(existing_token, "\\" + existing_token)
		escaped_tokens.append(escaped_token)
	
	escaped_tokens.sort_custom(
			func(a:String,b:String) -> bool:
				return b.length() < a.length())
	
	var token_string: String = "|".join(escaped_tokens)
	var compile_pattern: String = "(?<!\\w)(" + token_string + ")(?!\\w)"
	regex_engine.compile(compile_pattern)


func clear_tokens() -> void:
	_token_matches.clear()
