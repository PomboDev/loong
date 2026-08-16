@abstract class_name State
extends Node

@warning_ignore("unused_signal")
signal transition_requested(new_state_name: String)

@onready var state_machine: StateMachine = get_parent()

@abstract func enter() -> void 

@abstract func exit() -> void 

@abstract func update(_delta: float) -> void 

@abstract func physics_update(_delta: float) -> void 
