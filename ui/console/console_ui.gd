class_name ConsoleUi
extends Control

@onready var terminal := $VBoxContainer/PanelContainer/RichTextLabel
@onready var input_line := $VBoxContainer/PanelContainer2/LineEdit

static var _instance: ConsoleUi

static func toggle_console() -> void:
	if _instance == null:
		_instance = preload("res://ui/console/console_ui.tscn").instantiate()

	var opened := Systems.ui.toggle_overlay(_instance)

	if opened:
		Systems.input.push_context(ICTX_Console.CONTEXT)
	else:
		Systems.input.pop_context()


func _ready() -> void:
	_instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	Console.wr.connect(_write_to_terminal)
	Console.clr.connect(_clear_terminal)
	input_line.text_submitted.connect(_send_to_console)

func _write_to_terminal(message) -> void:
	terminal.append_text("\n%s" % str(message))
	await get_tree().process_frame
	terminal.scroll_to_line(terminal.get_line_count())

func _send_to_console(message : String) -> void:
	terminal.append_text("\n> %s" % message)
	Console._command(message)
	input_line.text = ""
	
func _clear_terminal() -> void:
	terminal.text = ""
