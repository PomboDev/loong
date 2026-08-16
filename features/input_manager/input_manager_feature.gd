extends Node

var mouse_sensitivity: float = 0.005
var controller_sensitivity: float = 2.0
var auto_capture_mouse: bool = true

var tracked_actions: Array[StringName] = [
	&"jump", 
	&"interact", 
	&"use_jade", 
]

var move_vector: Vector2 = Vector2.ZERO
var look_vector: Vector2 = Vector2.ZERO
var is_input_enabled: bool = true

var _current_states: Dictionary = {}
var _previous_states: Dictionary = {}

func _ready() -> void :
	if auto_capture_mouse:
		capture_mouse()

	for action in tracked_actions:
		_current_states[action] = false
		_previous_states[action] = false

func _physics_process(delta: float) -> void :
	if not is_input_enabled:
		_reset_state()
		return

	_update_input_history()

	move_vector = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_backward")

	var stick_look = Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down")
	if stick_look.length_squared() > 0:
		look_vector += stick_look * controller_sensitivity * delta

func _unhandled_input(event: InputEvent) -> void :
	if not is_input_enabled:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look_vector += event.relative * mouse_sensitivity

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		capture_mouse()

	if event.is_action_pressed(&"ui_cancel"):
		release_mouse()

func _update_input_history() -> void :
	for action in tracked_actions:
		_previous_states[action] = _current_states[action]
		_current_states[action] = Input.is_action_pressed(action)

func was_pressed(action: StringName) -> bool:
	return _current_states.get(action, false) and not _previous_states.get(action, false)

func was_released(action: StringName) -> bool:
	return not _current_states.get(action, false) and _previous_states.get(action, false)

func is_held(action: StringName) -> bool:
	return _current_states.get(action, false)

func get_look_delta() -> Vector2:
	var current_look = look_vector
	look_vector = Vector2.ZERO
	return current_look

func capture_mouse() -> void :
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func release_mouse() -> void :
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _reset_state() -> void :
	move_vector = Vector2.ZERO
	look_vector = Vector2.ZERO

	for action in tracked_actions:
		_current_states[action] = false
		_previous_states[action] = false
