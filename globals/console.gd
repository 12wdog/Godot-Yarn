extends Node


signal wr(message)
signal clr()


# Commands are cached once when the autoload initializes.
# Dictionary gives us O(1) command lookup and also makes it easy
# to expose the command list to an autocomplete UI.
var _commands: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cache_commands()




# -------------------------------------------------------------------
# Commands
# -------------------------------------------------------------------

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

# -------------------------------------------------------------------
# Command registration
# -------------------------------------------------------------------

func _cache_commands() -> void:
	_commands.clear()

	var script = get_script()

	if script == null:
		return

	for method in script.get_script_method_list():
		var method_name: StringName = method.name

		# Anything beginning with "_" is considered internal.
		if method_name.begins_with("_"):
			continue

		_commands[method_name] = true


func _get_commands() -> Array[StringName]:
	return Array(_commands.keys(), TYPE_STRING_NAME, "", null)


# -------------------------------------------------------------------
# Command execution
# -------------------------------------------------------------------

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


# -------------------------------------------------------------------
# Tokenizer
#
# Converts:
#
#     spawn "big enemy" -count 5
#
# Into:
#
#     ["spawn", "big enemy", "-count", "5"]
#
# Supports:
#     "quoted strings"
#     \"escaped quotes\"
#     \\escaped backslashes
# -------------------------------------------------------------------

func _tokenize(input: String) -> Array[String]:
	var tokens: Array[String] = []

	var current := ""
	var in_quotes := false
	var escaped := false
	var token_started := false

	for c in input:
		# Handle escaped characters.
		if escaped:
			current += c
			escaped = false
			token_started = true
			continue

		if c == "\\":
			escaped = true
			token_started = true
			continue

		# Toggle quoted mode.
		if c == '"':
			in_quotes = !in_quotes
			token_started = true
			continue

		# Whitespace outside quotes terminates the token.
		if (c == " " or c == "\t") and not in_quotes:
			if token_started:
				tokens.append(current)
				current = ""
				token_started = false
			continue

		current += c
		token_started = true

	# Handle a trailing backslash.
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

			# Everything following the flag belongs to it until
			# another flag is encountered.
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


# -------------------------------------------------------------------
# Determines whether a token is a flag.
#
# "-count"  -> true
# "--count" -> true
# "-5"      -> false
# "-3.14"   -> false
# "hello"   -> false
# -------------------------------------------------------------------

func _is_flag(arg: String) -> bool:
	if not arg.begins_with("-"):
		return false

	# Negative numbers are values, not flags.
	if arg.is_valid_int() or arg.is_valid_float():
		return false

	return true


# -------------------------------------------------------------------
# Converts strings into useful Variant types.
#
# "123"       -> 123
# "3.14"      -> 3.14
# "true"      -> true
# "false"     -> false
# "null"      -> null
# "hello"     -> "hello"
# -------------------------------------------------------------------

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
