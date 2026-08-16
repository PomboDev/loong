class_name StateMachine extends Node

@export var initial_state: State

var current_state: State
var previous_state: State
var states: Dictionary = {}

func _ready() -> void :
	await owner.ready

	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.transition_requested.connect(on_child_transition)

	if initial_state:
		initial_state.enter()
		previous_state = current_state
		current_state = initial_state

func _process(delta: float) -> void :
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void :
	if current_state:
		current_state.physics_update(delta)

func on_child_transition(new_state_name: String) -> void :
	var new_state = states.get(new_state_name.to_lower())
	if !new_state:
		Log.warn("State does not exist: " + new_state_name)
		return

	if current_state:
		current_state.exit()

	new_state.enter()
	previous_state = current_state
	current_state = new_state
