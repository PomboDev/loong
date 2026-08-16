class_name PlayerSkidState extends PlayerState

@export var skid_jump_bonus: float = 3.5
@export var skid_deceleration: float = 9.0
@export var skid_min_duration: float = 0.4
@export var skid_speed_threshold: float = 4.25
@export var skid_direction_threshold: float = -0.6

var skid_timer: float = 0.0
var skid_direction: Vector3 = Vector3.ZERO

@onready var jump_state: PlayerJumpState = %PlayerJumpState


func enter() -> void :
	skid_timer = 0.0
	skid_direction = Vector3(player.velocity.x, 0, player.velocity.z).normalized()
	player.snap_rotation(skid_direction)
	set_anim_condition(ANIM_C_SKID, true)
	player.lock_rotation = true


func exit() -> void :
	set_anim_condition(ANIM_C_SKID, false)
	player.lock_rotation = false
	player.snap_rotation(player.wish_direction)


func physics_update(delta: float) -> void :
	skid_timer += delta

	if jump_state.can_jump():
		transition_requested.emit("PlayerSkidJumpState")
		return

	if not player.is_on_floor():
		transition_requested.emit("PlayerAirState")
		return

	player.velocity.x = move_toward(player.velocity.x, 0.0, skid_deceleration * delta)
	player.velocity.z = move_toward(player.velocity.z, 0.0, skid_deceleration * delta)

	var current_speed: = Vector2(player.velocity.x, player.velocity.z).length()
	if skid_timer >= skid_min_duration:
		if current_speed < skid_speed_threshold * 0.15:
			transition_requested.emit("PlayerRunState")
			return

		if player.wish_direction.length() > 0.1:
			var velocity_dir: = Vector3(player.velocity.x, 0, player.velocity.z).normalized()
			var alignment: = player.wish_direction.dot(velocity_dir)

			if alignment > -0.1:
				transition_requested.emit("PlayerRunState")
				return

	if current_speed < 0.5:
		transition_requested.emit("PlayerRunState")


func _should_skid() -> bool:
	var current_horizontal: = Vector3(player.velocity.x, 0, player.velocity.z)
	var speed: = current_horizontal.length()

	if speed < skid_speed_threshold:
		return false

	if player.wish_direction.length() < 0.1:
		return false

	var velocity_dir: = current_horizontal.normalized()
	var input_alignment: = player.wish_direction.dot(velocity_dir)
	return input_alignment < skid_direction_threshold
