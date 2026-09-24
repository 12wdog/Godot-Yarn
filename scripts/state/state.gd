@abstract
class_name State
extends Node

var state_machine : M_StateMachine

@abstract func enter() -> void
@abstract func exit() -> void
@abstract func process(delta : float) -> void
@abstract func physics_process(delta : float) -> void
