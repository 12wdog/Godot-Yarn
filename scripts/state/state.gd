@icon("res://textures/icons/state.png")
@abstract
class_name State
extends Node

var state_machine : M_StateMachine

@abstract func enter() -> void
@abstract func exit() -> void
@abstract func update(delta : float) -> void
@abstract func physics_update(delta : float) -> void
