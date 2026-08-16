class_name PlayerDiveState extends PlayerState

@export var dive_forward_impulse: float = 7.0
@export var dive_vertical_impulse: float = 7.0
@export var dive_friction: float = 0.5

@onready var jump_state: PlayerJumpState = %PlayerJumpState
@onready var run_state: PlayerRunState = %PlayerRunState
@onready var hop_state: PlayerHopState = %PlayerHopState

var _hop_time_window: Clock = Clock.new(0.3)
var _can_hop: bool = false

func enter() -> void :
	player.dive_buffer_timer.finish()

	var dive_dir: = player.wish_direction
	if dive_dir.length() < 0.1:
		dive_dir = player.skin_mesh.global_transform.basis.z

	player.velocity.x = dive_dir.x * dive_forward_impulse
	player.velocity.z = dive_dir.z * dive_forward_impulse
	player.velocity.y = dive_vertical_impulse
	set_anim_condition(ANIM_C_DIVE, true)
	player.snap_rotation(dive_dir)
	player.lock_rotation = true

func exit() -> void :
	_can_hop = false
	set_anim_condition(ANIM_C_DIVE, false)
	_hop_time_window.finish()
	player.lock_rotation = false

func physics_update(delta: float) -> void :
	player.apply_gravity(delta, 1.5)

	_update_hop_window()

	if _can_hop and (player.dive_buffer_timer.is_running() or player.jump_buffer_timer.is_running()):
		_perform_hop()
		return

	if player.is_on_floor():
		player.velocity.x = move_toward(player.velocity.x, 0, dive_friction * delta * 10.0)
		player.velocity.z = move_toward(player.velocity.z, 0, dive_friction * delta * 10.0)
		if player.velocity.length() < 1.5:
			if run_state.can_run():
				transition_requested.emit("PlayerRunState")
			else:
				transition_requested.emit("PlayerIdleState")
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, 0.5 * delta)
		player.velocity.z = move_toward(player.velocity.z, 0, 0.5 * delta)


func _update_hop_window() -> void :
	var hit: = CasterFeature.raycast(player.global_position, Vector3.DOWN, 0.75, [player.get_rid()])
	if not hit.is_empty() and _hop_time_window.is_finished():
		_hop_time_window.run()
		_can_hop = true

func _perform_hop() -> void :
	hop_state.is_boosted = _hop_time_window.is_running()

	if hop_state.is_boosted:
		_hop_time_window.finish()

	if player.jump_buffer_timer.is_running():
		player.jump_buffer_timer.finish()

	if player.dive_buffer_timer.is_running():
		player.dive_buffer_timer.finish()

	transition_requested.emit("PlayerHopState")

func can_dive() -> bool:
	return player.dive_buffer_timer.is_running()
