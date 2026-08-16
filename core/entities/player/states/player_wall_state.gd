class_name PlayerWallState extends PlayerState

@onready var jump_state: PlayerJumpState = %PlayerJumpState
@onready var homing_state: PlayerHomingAttackState = %PlayerHomingAttackState
@onready var ledge_grab_state: PlayerLedgeGrabState = %PlayerLedgeGrabState

@export var wall_slide_speed: float = 2.0
@export var wall_gravity_scale: float = 0.3
@export var wall_stop_duration: float = 0.15
@export var wall_disengage_time: float = 0.2
@export var wall_stick_time: float = 0.2
@export var wall_jump_height: float = 5.0
@export var wall_jump_push_back: float = 4.0
@export var wall_stick_push: float = 2.0
@export var wall_check_distance: float = 0.6
@export var wall_check_layer: int = 1
@export var wall_jump_cooldown: float = 0.3

var _is_pressing_into_wall: bool = false
var _is_input_away_from_wall: bool = false
var _wall_normal: Vector3 = Vector3.ZERO
var _wall_jump_timer: Clock = Clock.new(wall_jump_cooldown)
var _disengage_timer: Clock = Clock.new(wall_disengage_time)
var _wall_stick_timer: Clock = Clock.new(wall_stick_time)


func enter() -> void :
	jump_state.reset()
	homing_state.reset()
	_check_wall_status()
	_wall_stick_timer.run()
	_disengage_timer.run()
	set_anim_condition(ANIM_C_WALL_STICK, true)

	if player.velocity.y < 0.0:
		player.velocity.y = 0.0

	player.snap_rotation( - _wall_normal)
	player.lock_rotation = true


func exit() -> void :
	set_anim_condition(ANIM_C_WALL_STICK, false)
	player.lock_rotation = false


func physics_update(delta: float) -> void :
	if player.jump_buffer_timer.is_running() and _wall_jump_timer.is_finished():
		_perform_wall_jump()
		return

	if not _check_wall_status():
		transition_requested.emit("PlayerAirState")
		return

	if player.is_on_floor():
		transition_requested.emit("PlayerIdleState")
		return

	var ledge_data: Dictionary = ledge_grab_state.check_ledge()
	if not ledge_data.is_empty():
		ledge_grab_state._ledge_data = ledge_data
		transition_requested.emit("PlayerLedgeGrabState")
		return

	_check_input()

	if not _is_pressing_into_wall:
		if _wall_stick_timer.is_finished():
			transition_requested.emit("PlayerAirState")
			return
	else:
		_wall_stick_timer.run()

	if _is_pressing_into_wall:
		_disengage_timer.run()

	if _is_input_away_from_wall and _disengage_timer.is_finished():
		transition_requested.emit("PlayerAirState")
		return

	var stick_force: Vector3 = - _wall_normal * wall_stick_push
	player.velocity.x = stick_force.x
	player.velocity.z = stick_force.z

	if player.velocity.y > 0.0:
		player.velocity.y -= player.get_gravity().length() * delta
	else:
		player.velocity.y -= player.get_gravity().length() * wall_gravity_scale * delta

	if player.velocity.y < - wall_slide_speed:
		player.velocity.y = - wall_slide_speed


func _check_input() -> void :
	_is_pressing_into_wall = false
	_is_input_away_from_wall = false

	if player.wish_direction.length() > 0.1:
		var dot: float = player.wish_direction.dot(_wall_normal)
		if dot < -0.1:
			_is_pressing_into_wall = true
		elif dot > 0.1:
			_is_input_away_from_wall = true


func check_wall() -> bool:
	if player.wish_direction.length() < 0.1 or _wall_jump_timer.is_running():
		return false

	var ground_check: Dictionary = CasterFeature.raycast(
		player.global_position, Vector3.DOWN, 1.0, [player.get_rid()]
	)
	if not ground_check.is_empty():
		return false

	var input_2d: = Vector2(player.wish_direction.x, player.wish_direction.z)
	var angle: = input_2d.angle()
	var snapped_angle: = snappedf(angle, PI / 4.0)
	var check_dir: = Vector3(cos(snapped_angle), 0.0, sin(snapped_angle))

	var ray_result: Dictionary = CasterFeature.raycast(
		player.global_position, check_dir, wall_check_distance, [player.get_rid()]
	)
	if not ray_result.is_empty():
		if not _is_straight_wall(ray_result.normal):
			return false

		_wall_normal = ray_result.normal
		return true
	return false


func _check_wall_status() -> bool:
	var ray_dir: = - _wall_normal if _wall_normal.length() > 0.1 else player.wish_direction
	if ray_dir.length() < 0.1:
		ray_dir = - player.global_transform.basis.z

	var ray_result: = CasterFeature.raycast(
		player.global_position, ray_dir, wall_check_distance + 0.1, [player.get_rid()]
	)
	if not ray_result.is_empty():
		if not _is_straight_wall(ray_result.normal):
			return false

		_wall_normal = ray_result.normal
		return true
	elif _wall_normal != Vector3.ZERO:
		pass

	return false


func _is_straight_wall(normal: Vector3) -> bool:
	return abs(normal.y) < 0.1


func _perform_wall_jump() -> void :
	_wall_jump_timer.run()
	if _wall_normal == Vector3.ZERO:
		_wall_normal = - player.wish_direction.normalized()

	player.velocity = _wall_normal * wall_jump_push_back
	player.velocity.y = wall_jump_height

	var look_target: = player.position + _wall_normal
	look_target.y = player.position.y
	player.skin_mesh.look_at(look_target)
	player.skin_mesh.rotation.y += PI

	jump_state.jump_count = 1
	transition_requested.emit("PlayerAirState")
