class_name M_StateMachine
extends Module

var states : Dictionary[StringName, State] = {}
var default_state : State = null

func _ready() -> void:
	for child in get_children():
		if not child is State:
			Log.warn('Child "%s" in state machine "%s" is not a State. Skipping.' % [child.name, self.name])
			continue
			
		var state := child as State
		
		var key = state.get(&"STATE_KEY")
		if not key is StringName:
			Log.warn('State "%s" does not have StringName "STATE_KEY" defined. Skipping.' % state.name)
			continue
		
		if states.has(key):
			var existing = states[key]
			Log.warn('Child "%s" and child "%s" share the same state key of "%s" in state machine "%s." Skipping.' % [state.name, existing.name, key, self.name])
			continue
			
		state.state_machine = self
		states[key] = state
		if default_state == null:
			default_state = state
	
	if default_state:
		default_state.enter()
	else:
		Log.warn('No valid states found for "%s."' % self.name)

func change_state(state : StringName) -> void:
	if not states.has(state):
		Log.warn('Unknown state "%s" on state machine "%s"' % [state, self.name])
		return
	
	var new_state := states[state]
	if default_state:
		default_state.exit()
	default_state = new_state
	default_state.enter()

func _process(delta: float) -> void:
	if default_state:
		default_state.process(delta)

func _physics_process(delta: float) -> void:
	if default_state:
		default_state.process(delta)
