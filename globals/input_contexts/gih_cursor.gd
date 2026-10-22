extends GlobalInputHandler

@export var cursor: UI_Cursor


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputHandler.register_global_handler(self)


func handle_input(event: InputEvent) -> bool:
	if event.is_action_pressed("glb_cursor_primary"):
		cursor.send_primary_pressed()
		return true

	if event.is_action_released("glb_cursor_primary"):
		cursor.send_primary_released()
		return true

	if event.is_action_pressed("glb_cursor_secondary"):
		cursor.send_secondary_pressed()
		return true

	if event.is_action_released("glb_cursor_secondary"):
		cursor.send_secondary_released()
		return true

	return false
