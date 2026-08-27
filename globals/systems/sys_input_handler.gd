extends Node


var _current_context: StringName = &""
var _context_stack: Array[StringName] = []

var _contexts: Dictionary = {}
var _global_handlers: Array[GlobalInputHandler] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if _handle_global_input(event):
		get_viewport().set_input_as_handled()
		return
		
	if _current_context == &"":
		return
	
	var input_context: Node = _contexts.get(_current_context)
	
	if input_context == null:
		return
		
	if input_context.handle_input(event):
		get_viewport().set_input_as_handled()


func register_global_handler(handler: GlobalInputHandler) -> void:
	if handler in _global_handlers:
		return
	
	_global_handlers.append(handler)


func unregister_global_handler(handler: Node) -> void:
	_global_handlers.erase(handler)


func _handle_global_input(event: InputEvent) -> bool:
	for handler : GlobalInputHandler in _global_handlers:
		if handler.handle_input(event):
			return true
		
	return false


func register_context(context_name: StringName, context: Node) -> void:
	if _contexts.has(context_name):
		Log.warn("Input context already registered: %s" % context_name)
		return
	
	_contexts[context_name] = context


func unregister_context(context_name: StringName) -> void:
	_contexts.erase(context_name)
	
	if _current_context == context_name:
		_current_context = &""
		
	_context_stack.erase(context_name)


func set_context(context_name: StringName) -> void:
	_context_stack.clear()
	_set_context(context_name)

func _set_context(context_name: StringName) -> void:
	if context_name == &"":
		_current_context = &""
		return
	
	if not _contexts.has(context_name):
		Log.warn("Cannot activate unregistered input context: %s" % context_name)
		return
	
	_current_context = context_name

func get_context() -> StringName:
	return _current_context


func is_context(context_name: StringName) -> bool:
	return _current_context == context_name


func push_context(context_name: StringName) -> void:
	if not _contexts.has(context_name):
		Log.warn("Cannot push unregistered input context: %s" % context_name)
		return
	
	_context_stack.push_back(_current_context)
	_set_context(context_name)


func pop_context() -> void:
	if _context_stack.is_empty():
		Log.warn("Cannot pop input context: stack is empty")
		return
		
	var previous_context : StringName = _context_stack.pop_back()
	_set_context(previous_context)


func clear_context_stack() -> void:
	_context_stack.clear()


func get_context_stack() -> Array[StringName]:
	return _context_stack.duplicate()
