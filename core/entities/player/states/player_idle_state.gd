class_name PlayerIdleState extends PlayerState

@onready var run_state: PlayerRunState = %PlayerRunState
@onready var jump_state: PlayerJumpState = %PlayerJumpState
@onready var homing_state: PlayerHomingAttackState = %PlayerHomingAttackState



func enter() -> void :
	set_anim_condition(ANIM_C_IDLE, true)
	jump_state.reset()
	homing_state.reset()
	player.velocity = Vector3.ZERO



func exit() -> void :
	set_anim_condition(ANIM_C_IDLE, false)


func physics_update(_delta: float) -> void :
	if run_state.can_run():
		transition_requested.emit("PlayerRunState")
		return

	if jump_state.can_jump():
		transition_requested.emit("PlayerJumpState")
		return

	if player.is_on_floor() == false:
		transition_requested.emit("PlayerAirState")
		return

	player.apply_gravity(_delta)
