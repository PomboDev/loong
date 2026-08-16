class_name PlayerRunState extends PlayerState

@onready var jump_state: PlayerJumpState = %PlayerJumpState
@onready var skid_state: PlayerSkidState = %PlayerSkidState
@onready var homing_state: PlayerHomingAttackState = %PlayerHomingAttackState
@onready var ledge_grab_state: PlayerLedgeGrabState = %PlayerLedgeGrabState
@export var wall_push_speed_multiplier: float = 0.01


func enter() -> void :
	jump_state.reset()
	homing_state.reset()
	set_anim_condition(ANIM_C_RUN, true)
	set_anim_condition(ANIM_C_WALK, true)


func exit() -> void :
	set_anim_condition(ANIM_C_RUN, false)
	set_anim_condition(ANIM_C_WALK, false)


func physics_update(delta: float) -> void :
	if not player.is_on_floor():
		player.apply_gravity(delta)

	if jump_state.can_jump():
		transition_requested.emit("PlayerJumpState")
		return

	if not player.is_on_floor():
		transition_requested.emit("PlayerAirState")
		return

	if player.input.was_pressed(&"interact") and player.wish_direction.length() > 0.1:
		transition_requested.emit("PlayerDiveState")
		return

	if skid_state._should_skid():
		transition_requested.emit("PlayerSkidState")
		return

	var current_horizontal: = Vector3(player.velocity.x, 0, player.velocity.z)
	var current_speed: = current_horizontal.length()

	if player.wish_direction.is_zero_approx():
		var new_speed: = move_toward(current_speed, 0.0, player.friction * delta)
		var braked: = current_horizontal.normalized() * new_speed
		player.velocity.x = braked.x
		player.velocity.z = braked.z
	else:
		var base_speed: float = player.movement_speed

		if player.is_on_wall():
			var wall_normal = player.get_wall_normal()
			if player.wish_direction.dot(wall_normal) < -0.1:
				base_speed *= wall_push_speed_multiplier

		var target_speed: float = base_speed * player.input_magnitude
		var new_speed: float = current_speed

		if current_speed > target_speed:
			new_speed = move_toward(current_speed, target_speed, player.friction * 0.5 * delta)
		else:
			new_speed = min(current_speed + player.acceleration * delta, target_speed)

		var current_dir: = current_horizontal.normalized()
		if current_dir.is_zero_approx():
			current_dir = player.wish_direction

		var turn_speed: float = 15.0
		var blended_dir: = (
			current_dir
			.lerp(player.wish_direction, clampf(turn_speed * delta, 0.0, 1.0))
			.normalized()
		)
		player.velocity.x = blended_dir.x * new_speed
		player.velocity.z = blended_dir.z * new_speed

		var speed_ratio: float = new_speed / player.movement_speed
		set_anim_blend(ANIM_B_WALK, speed_ratio)

		if speed_ratio > 0.5:
			set_anim_condition(ANIM_C_RUN, true)
			set_anim_condition(ANIM_C_WALK, false)
		else:
			set_anim_condition(ANIM_C_RUN, false)
			set_anim_condition(ANIM_C_WALK, true)

	if player.velocity.length() == 0:
		transition_requested.emit("PlayerIdleState")


func can_run() -> bool:
	return player.wish_direction.length() > 0.0
