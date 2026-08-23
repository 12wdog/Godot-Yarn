extends GlobalInputHandler

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputHandler.register_global_handler(self)

func handle_input(_event: InputEvent) -> bool:
	if _event.is_action_pressed("glb_debug"):
		ConsoleUi.toggle_console()
		return true
	
	return false
