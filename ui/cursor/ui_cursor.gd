class_name UI_Cursor
extends Control

@export var cursor_speed := 800.0
@export var ray_length := 1000.0
@export var camera: Camera3D

@onready var cursor: Control = $Cursor

var cursor_position := Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	cursor_position = get_viewport_rect().size * 0.5

	# The visual cursor must never block UI underneath it.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_update_visual()


func _process(delta: float) -> void:
	_update_cursor_position(delta)
	_update_visual()


func _update_cursor_position(delta: float) -> void:
	var input := Input.get_vector(
		"glb_cursor_left",
		"glb_cursor_right",
		"glb_cursor_up",
		"glb_cursor_down"
	)

	if input.length_squared() > 0.0:
		cursor_position += input * cursor_speed * delta
		_clamp_cursor_position()

		# Keep Godot's mouse position synchronized with our virtual cursor.
		Input.warp_mouse(cursor_position)
	else:
		cursor_position = get_viewport().get_mouse_position()


func _clamp_cursor_position() -> void:
	cursor_position = cursor_position.clamp(
		Vector2.ZERO,
		get_viewport_rect().size
	)


func _update_visual() -> void:
	cursor.global_position = cursor_position


func send_primary_pressed() -> void:
	_send_mouse_button(MOUSE_BUTTON_LEFT, true)


func send_primary_released() -> void:
	_send_mouse_button(MOUSE_BUTTON_LEFT, false)


func send_secondary_pressed() -> void:
	_send_mouse_button(MOUSE_BUTTON_RIGHT, true)


func send_secondary_released() -> void:
	_send_mouse_button(MOUSE_BUTTON_RIGHT, false)


func _send_mouse_button(button: MouseButton, pressed: bool) -> void:
	print("Cursor Click")
	var event := InputEventMouseButton.new()

	event.position = cursor_position
	event.global_position = cursor_position
	event.button_index = button
	event.pressed = pressed

	get_viewport().push_input(event)
	# Only attempt a 3D interaction on a primary click.
	#
	# We specifically do this on release, which matches how buttons
	# normally finish their activation.
	if (
		button == MOUSE_BUTTON_LEFT
		and not pressed
		and not get_viewport().is_input_handled()
	):
		_handle_3d_primary()

 
func _handle_3d_primary() -> void:
	var hit := get_3d_hit()

	if hit.is_empty():
		return

	# This is intentionally left as a hook for your 3D interaction
	# system. You can replace this with a signal later.
	#
	# Example:
	# 3d_primary_clicked.emit(hit)
	print("3D hit: ", hit)


func get_3d_hit() -> Dictionary:
	if not is_instance_valid(camera):
		return {}

	var origin := camera.project_ray_origin(cursor_position)
	var direction := camera.project_ray_normal(cursor_position)

	var query := PhysicsRayQueryParameters3D.create(
		origin,
		origin + direction * ray_length
	)

	return camera.get_world_3d().direct_space_state.intersect_ray(query)
