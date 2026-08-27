extends Node


signal wr(message)
signal clr()


var _commands: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cache_commands()

# commands

func clear(args : Dictionary) -> void:
	if args.has('h'):
		wr.emit("[b][color=cyan]clear[/color][/b]\t\t[color=green][-h][/color]")
		wr.emit("\tClears the terminal.")
		wr.emit("\n\t[color=green]h:[/color] Lists this message.")
		return
	
	clr.emit()

func list(args : Dictionary) -> void:
	if args.has("h"):
		wr.emit("[b][color=cyan]list[/color][/b] [color=green][-h][/color]")
		wr.emit("\tLists all existing commands.")
		wr.emit("\n\t[color=green]h:[/color] Lists this message.")
		return
	
	wr.emit("Here are all valid commands:")
	for command in _get_commands():
		wr.emit("\t[color=cyan]%s[/color]" % command)

# end of commands

func _cache_commands() -> void:
	_commands.clear()
	
	var script = get_script()
	
	if script == null:
		return
	
	for method in script.get_script_method_list():
		var method_name: StringName = method.name
		
		if method_name.begins_with("_"):
			continue
		
		_commands[method_name] = true


func _get_commands() -> Array[StringName]:
	return Array(_commands.keys(), TYPE_STRING_NAME, "", null)


func _command(input: String) -> void:
	Log.debug("Handling command: \"%s\"" % input)
	
	input = input.strip_edges()
	
	if input.is_empty():
		return
	
	var tokens := _tokenize(input)
	
	if tokens.is_empty():
		return
	
	var command: StringName = tokens[0]
	
	if not _commands.has(command):
		wr.emit("Unknown command \"%s\"" % command)
		return
	
	var args := _arg_parse(tokens.slice(1))
	
	call(command, args)

func _tokenize(input: String) -> Array[String]:
	var tokens: Array[String] = []
	
	var current := ""
	var in_quotes := false
	var escaped := false
	var token_started := false
	
	for c in input:
		if escaped:
			current += c
			escaped = false
			token_started = true
			continue
		
		if c == "\\":
			escaped = true
			token_started = true
			continue
		
		if c == '"':
			in_quotes = !in_quotes
			token_started = true
			continue
		
		if (c == " " or c == "\t") and not in_quotes:
			if token_started:
				tokens.append(current)
				current = ""
				token_started = false
			continue
		
		current += c
		token_started = true
	
	if escaped:
		current += "\\"
	
	if token_started:
		tokens.append(current)
	
	return tokens


# -------------------------------------------------------------------
# Argument parser
#
# Positional arguments:
#
#     teleport 100 200 300
#
# Becomes:
#
#     {
#         "arg0": 100,
#         "arg1": 200,
#         "arg2": 300
#     }
#
#
# Named arguments:
#
#     spawn enemy -count 5 -name "Big Enemy"
#
# Becomes:
#
#     {
#         "arg0": "enemy",
#         "count": 5,
#         "name": "Big Enemy"
#     }
#
#
# Flags:
#
#     noclip -silent
#
# Becomes:
#
#     {
#         "silent": true
#     }
#
#
# Multiple values:
#
#     give weapon -count 5 -pos 10 20 30
#
# Becomes:
#
#     {
#         "arg0": "weapon",
#         "count": 5,
#         "pos": [10, 20, 30]
#     }
# -------------------------------------------------------------------

func _arg_parse(args: Array[String]) -> Dictionary:
	var output: Dictionary = {}
	
	var unnamed_arg_count := 0
	var i := 0
	
	while i < args.size():
		var arg := args[i]
		
		if _is_flag(arg):
			var key := arg.trim_prefix("-")
			var values: Array = []
			i += 1
			
			while i < args.size() and not _is_flag(args[i]):
				values.append(_handle_arg(args[i]))
				i += 1
			
			if values.is_empty():
				output[key] = true
			elif values.size() == 1:
				output[key] = values[0]
			else:
				output[key] = values
		
		else:
			output["arg%d" % unnamed_arg_count] = _handle_arg(arg)
			unnamed_arg_count += 1
			i += 1
	
	return output


func _is_flag(arg: String) -> bool:
	if not arg.begins_with("-"):
		return false
	
	if arg.is_valid_int() or arg.is_valid_float():
		return false
	
	return true


func _handle_arg(arg: String) -> Variant:
	var lower := arg.to_lower()
	if lower == "true":
		return true
	if lower == "false":
		return false
	if lower == "null":
		return null
	if arg.is_valid_int():
		return arg.to_int()
	if arg.is_valid_float():
		return arg.to_float()
	return arg
