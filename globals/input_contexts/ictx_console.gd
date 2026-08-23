extends InputContext

const CONTEXT := &"CONSOLE"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputHandler.register_context(CONTEXT, self)

func handle_input(_event: InputEvent) -> void:
	if _event.is_action_pressed("console_close"):
		ConsoleUi.toggle_console()
