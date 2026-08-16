class_name PlayerJumpState extends PlayerState

@export var jump_combo_multiplier: float = 0.25
@export var jump_combo_window: float = 0.1
@export var coyote_time: float = 0.15

@onready var coyote_timer: Clock = Clock.new(coyote_time)
@onready var jump_combo_timer: Clock = Clock.new(jump_combo_window)

var jump_count: int = 1
var jump_combo_count: int = 0


func enter() -> void :
	if jump_combo_timer.is_running():
		jump_combo_count += 1
		if jump_combo_count > 2:
			jump_combo_count = 0
	else:
		jump_combo_count = 0

	player.jump_buffer_timer.finish()
	player.snap_rotation(player.wish_direction)
	player.lock_rotation = true
	jump()


func physics_update(_delta: float) -> void :
	transition_requested.emit("PlayerAirState")


func reset() -> void :
	if jump_count > 0:
		jump_combo_timer.run()
	jump_count = 0


func jump() -> void :
	player.jump_buffer_timer.finish()
	coyote_timer.finish()

	if jump_combo_count == 2 and player.wish_direction.length() <= 0:
		jump_combo_count = 0

	var multiplier: float = 1.0 + (jump_combo_multiplier * jump_combo_count)
	player.velocity.y = player.jump_velocity * multiplier
	player.jump_buffer_timer.finish()

	jump_count += 1
	transition_requested.emit("PlayerAirState")


func try_jump() -> void :
	if can_jump() == false:
		return
	jump()


func can_jump() -> bool:
	if player.jump_buffer_timer.is_finished():
		return false

	if player.is_on_floor() or coyote_timer.is_running():
		return jump_count < player.max_jump_count

	var effective_count = max(jump_count, 1)
	return effective_count < player.max_jump_count
