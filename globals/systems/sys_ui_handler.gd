extends Node

var canvas: CanvasLayer
var primary_layer: Control
var overlay_layer: Control

var primary_ui: Control
var _pause_requests := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	canvas = CanvasLayer.new()
	canvas.name = "UICanvas"
	add_child(canvas)

	primary_layer = Control.new()
	primary_layer.name = "PrimaryLayer"
	primary_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(primary_layer)

	overlay_layer = Control.new()
	overlay_layer.name = "OverlayLayer"
	overlay_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay_layer)


func show_primary(ui: Control) -> void:
	if primary_ui == ui:
		return

	if primary_ui != null:
		primary_ui.queue_free()

	primary_ui = ui
	primary_layer.add_child(primary_ui)


func clear_primary() -> void:
	if primary_ui == null:
		return

	primary_ui.queue_free()
	primary_ui = null


func show_overlay(ui: Control) -> void:
	if ui.get_parent() == overlay_layer:
		return

	overlay_layer.add_child(ui)
	_register_pause_request(ui)


func hide_overlay(ui: Control) -> void:
	if ui.get_parent() != overlay_layer:
		return

	_unregister_pause_request(ui)
	overlay_layer.remove_child(ui)


func toggle_overlay(ui: Control) -> bool:
	if ui.get_parent() == overlay_layer:
		hide_overlay(ui)
		return false
		
	show_overlay(ui)
	return true


func _register_pause_request(ui: Control) -> void:
	var pausable: M_UIPausable = Module.has_module(ui, M_UIPausable)

	if pausable != null and pausable.pauses_game:
		_pause_requests += 1
		_update_pause_state()


func _unregister_pause_request(ui: Control) -> void:
	var pausable: M_UIPausable = Module.has_module(ui, M_UIPausable)

	if pausable != null and pausable.pauses_game:
		_pause_requests = maxi(_pause_requests - 1, 0)
		_update_pause_state()


func _update_pause_state() -> void:
	get_tree().paused = _pause_requests > 0


func is_primary_active() -> bool:
	return primary_ui != null


func is_overlay_active(ui: Control) -> bool:
	return ui.get_parent() == overlay_layer


func is_paused() -> bool:
	return _pause_requests > 0
