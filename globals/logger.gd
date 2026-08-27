extends Node

enum Level { 
	DEBUG = 0, 
	INFO = 1, 
	WARN = 2, 
	ERROR = 3,
	}

const LEVEL_NAMES = ["DEBUG","INFO","WARN","ERROR"]
const LEVEL_COLORS = ["gray","white","yellow","red"]

var log_path : String
var log_file: FileAccess


func _init():
	log_path = ("user://log-%s.log" % Time.get_date_string_from_system())
	log_file = FileAccess.open(log_path, FileAccess.WRITE_READ)
	if log_file:
		log_file.seek_end()


# ---------- public helpers ----------

func debug(msg): _log(msg, Level.DEBUG)
func info(msg):  _log(msg, Level.INFO)
func warn(msg):  _log(msg, Level.WARN)
func error(msg): _log(msg, Level.ERROR)


# ---------- core logger ----------

func _log(message:String, level:int):

	# Skip debug logs in exported builds
	if level < Level.WARN and not OS.is_debug_build():
		return

	var stack := get_stack()
	if stack.size() < 3:
		return

	var caller : Dictionary = stack[2]

	var full_path:String = caller.source
	var line:int = caller.line
	var func_name:String = caller.function

	var level_name:String = LEVEL_NAMES[level]
	var color:String = LEVEL_COLORS[level]
	var time:String = Time.get_datetime_string_from_system()

	# clickable console string
	var clickable := "%s:%d" % [full_path, line]

	var console_line := "[%s] [%s] %s -> %s(): %s" % [
		time, level_name, clickable, func_name, message
	]

	print_rich("[color=%s]%s[/color]" % [color, console_line])

	# -------- file logging with stack trace --------
	if log_file:
		var text : String
		if level <= Level.INFO:
			text = console_line + "\n"
		else:
			text = console_line + "\n\nSTACK TRACE:\n"

			for s in stack:
				text += "  at %s (%s:%d)\n" % [
					s.function,
					s.source,
					s.line
				]

			text += "\n"

		log_file.store_string(text)
		log_file.flush()
