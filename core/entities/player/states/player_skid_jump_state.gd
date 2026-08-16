class_name PlayerSkidJumpState extends PlayerState

@export var jump_bonus: float = 3.5
@export var horizontal_boost_factor: float = 1.0


func enter() -> void :
	player.jump_buffer_timer.finish()
	player.velocity.y = player.jump_velocity + jump_bonus
	set_anim_blend(ANIM_B_SKID_JUMP, 1.0)
	player.snap_rotation(player.wish_direction)
	player.lock_rotation = true


func physics_update(_delta: float) -> void :
	if player.wish_direction.length() > 0.1:
		var boost: = player.wish_direction * player.movement_speed * horizontal_boost_factor
		player.velocity.x = boost.x
		player.velocity.z = boost.z
	transition_requested.emit("PlayerAirState")
