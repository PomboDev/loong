class_name PlayerHopState extends PlayerState


@export var normal_hop_height: float = 4.0
@export var hop_turn_weight: float = 0.85
@export var dive_recovery_boost: float = 2.0
@export var dive_recovery_height: float = 6.0
@export var air_control: float = 0.1

@onready var jump_state: PlayerJumpState = %PlayerJumpState
@onready var run_state: PlayerRunState = %PlayerRunState
@onready var wall_state: PlayerWallState = %PlayerWallState
@onready var homing_state: PlayerHomingAttackState = %PlayerHomingAttackState

var is_boosted: bool = false


func enter() -> void :
	player.jump_buffer_timer.finish()

	var move_dir: = Vector3.ZERO

	if player.wish_direction.length() > 0.1:
		move_dir = player.wish_direction.normalized()

	var speed: float = 0.0
	var height: float = normal_hop_height

	if is_boosted:
		speed = player.movement_speed + dive_recovery_boost
		height = dive_recovery_height
	else:
		speed = player.movement_speed * 0.5

	player.velocity.x = move_dir.x * speed
	player.velocity.z = move_dir.z * speed
	player.velocity.y = height

	player.jump_buffer_timer.finish()

	jump_state.jump_count += 1

	set_anim_condition(ANIM_C_HOP, true)
	set_anim_blend(ANIM_B_HOP, 1.0)

	if move_dir.length() > 0.01:
		player.snap_rotation(move_dir)
		player.lock_rotation = true
	else:
		player.lock_rotation = false

func exit() -> void :
	set_anim_condition(ANIM_C_HOP, false)
	set_anim_blend(ANIM_B_HOP, 0.0)
	player.lock_rotation = false

func physics_update(delta: float) -> void :
	player.apply_gravity(delta)

	if player.is_on_floor():
		if player.velocity.y < 0:
			if run_state.can_run():
				transition_requested.emit("PlayerRunState")
			else:
				transition_requested.emit("PlayerIdleState")
			return

	var target: Vector3 = player.wish_direction * player.movement_speed * player.input_magnitude
	var current: Vector3 = Vector3(player.velocity.x, 0, player.velocity.z)
	var new_vel: Vector3 = current.lerp(target, air_control * delta * 10.0)
	player.velocity.x = new_vel.x
	player.velocity.z = new_vel.z

	if jump_state.can_jump():
		transition_requested.emit("PlayerJumpState")
		return

	if player.input.was_pressed(&"use_jade") and not homing_state.is_on_cooldown():
		var homing_candidate: Node3D = homing_state.find_homing_target()
		if homing_candidate:
			homing_state.set_target(homing_candidate)
			transition_requested.emit("PlayerHomingAttackState")
			return

	if player.input.was_pressed(&"interact"):
		transition_requested.emit("PlayerDiveState")
		return

	if player.wish_direction.length() > 0 and wall_state.check_wall():
		transition_requested.emit("PlayerWallState")
		return
