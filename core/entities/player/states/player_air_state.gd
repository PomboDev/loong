class_name PlayerAirState extends PlayerState

const FIRST_JUMP_CUT: float = 0.6
const SECOND_JUMP_CUT: float = 0.9
const THIRD_JUMP_CUT: float = 1.0

@onready var jump_state: PlayerJumpState = %PlayerJumpState
@onready var wall_state: PlayerWallState = %PlayerWallState
@onready var homing_state: PlayerHomingAttackState = %PlayerHomingAttackState
@onready var ledge_grab_state: PlayerLedgeGrabState = %PlayerLedgeGrabState

@export var air_control: float = 0.1
@export var jump_cut_decel: float = 20.0
@export var combo_air_control_loss: float = 0.2

var _jump_cut_target: float = -1.0


func enter() -> void :
	_jump_cut_target = -1.0

	if player.velocity.y <= 0.0:
		jump_state.coyote_timer.run()

	set_anim_condition(ANIM_C_JUMP, true)
	player.lock_rotation = true


func exit() -> void :
	set_anim_condition(ANIM_C_JUMP, false)
	player.lock_rotation = false


func physics_update(delta: float) -> void :
	if player.is_on_floor():
		if player.wish_direction.length() > 0:
			transition_requested.emit("PlayerRunState")
		else:
			transition_requested.emit("PlayerIdleState")
		return

	player.apply_gravity(delta)

	var jump_vel: = player.jump_velocity
	set_anim_blend(ANIM_B_JUMP, clampf(player.velocity.y / jump_vel, -1.0, 1.0))

	if state_machine.previous_state is PlayerSkidJumpState:
		set_anim_blend(ANIM_B_SKID_JUMP, clampf(player.velocity.y / jump_vel, -1.0, 1.0))

	if jump_state.can_jump():
		transition_requested.emit("PlayerJumpState")
		return

	if player.input.was_released(&"jump"):
		_apply_jump_cut()

	if _jump_cut_target >= 0.0 and player.velocity.y > _jump_cut_target:
		player.velocity.y = move_toward(player.velocity.y, _jump_cut_target, jump_cut_decel * delta)

	var target: Vector3 = player.wish_direction * player.movement_speed * player.input_magnitude
	var current: Vector3 = Vector3(player.velocity.x, 0, player.velocity.z)
	var loss: float = combo_air_control_loss * jump_state.jump_combo_count
	if state_machine.previous_state is PlayerSkidJumpState:
		loss *= 0.3
	var effective_air_control: float = air_control * clampf(1.0 - loss, 0.0, 1.0)
	var new_vel: Vector3 = current.lerp(target, effective_air_control * delta * 10.0)

	player.velocity.x = new_vel.x
	player.velocity.z = new_vel.z

	if player.input.was_pressed(&"use_jade") and not homing_state.is_on_cooldown():
		var homing_candidate: Node3D = homing_state.find_homing_target()
		if homing_candidate:
			homing_state.set_target(homing_candidate)
			transition_requested.emit("PlayerHomingAttackState")
			return

	if (
		not state_machine.previous_state is PlayerDiveState
		and player.input.was_pressed(&"interact")
	):
		transition_requested.emit("PlayerDiveState")
		return

	if player.wish_direction.length() > 0 and wall_state.check_wall():
		var ledge_data: Dictionary = ledge_grab_state.check_ledge()
		if not ledge_data.is_empty():
			ledge_grab_state._ledge_data = ledge_data
			transition_requested.emit("PlayerLedgeGrabState")
			return

		if player.velocity.y < 5.0 and player.velocity.y > -5.0:
			transition_requested.emit("PlayerWallState")
			return


func _apply_jump_cut() -> void :
	if player.state_machine.previous_state.name == "PlayerSkidJumpState":
		return

	var cut_scale: float
	match jump_state.jump_combo_count:
		1:
			cut_scale = FIRST_JUMP_CUT
		2:
			cut_scale = SECOND_JUMP_CUT
		_:
			cut_scale = THIRD_JUMP_CUT

	_jump_cut_target = player.velocity.y * cut_scale
