class_name PlayerLedgeGrabState extends PlayerState

const HOP_FORCE: float = 8.0
const CLIMB_FORWARD_FORCE: float = 5.0
const WALL_JUMP_FORCE: float = 8.0

@export var ledge_detect_length: float = 0.7
@export var ledge_detect_height_offset: float = 0.5
@export var ledge_max_height: float = 1.0
@export var ledge_grab_offset: Vector3 = Vector3(0, -0.6, 0.4)
@export var ledge_hop_timer: float = 0.5
@export var max_ledge_slope: float = 30.0

var _ledge_timer: Clock = Clock.new(ledge_hop_timer)
var _ledge_data: Dictionary = {}
var _snap_tween: Tween



func enter() -> void :
	_ledge_timer.run()

	if _ledge_data.is_empty():
		var data = check_ledge()
		if data.is_empty():
			transition_requested.emit("PlayerAirState")
			return
		_ledge_data = data

	_snap_to_ledge()
	player.velocity = Vector3.ZERO
	set_anim_condition(ANIM_C_WALL_STICK, true)
	player.lock_rotation = true


func exit() -> void :
	if _snap_tween:
		_snap_tween.kill()
	_ledge_data = {}
	set_anim_condition(ANIM_C_WALL_STICK, false)
	player.lock_rotation = false


func physics_update(_delta: float) -> void :
	player.velocity = Vector3.ZERO

	if player.input.was_pressed(&"jump"):
		_perform_wall_jump()
		return

	if player.input_magnitude > 0.5 and _ledge_timer.is_finished():
		var input_dir_local = _get_input_dir_relative_to_wall()

		if input_dir_local.z > 0.5 or input_dir_local.y < -0.5:
			transition_requested.emit("PlayerAirState")
			return

		if input_dir_local.z < -0.5:
			_climb_up()
			return


func _snap_to_ledge() -> void :
	var target_pos: Vector3 = _ledge_data["position"]
	var wall_normal: Vector3 = _ledge_data["normal"]
	var surface_normal: Vector3 = _ledge_data["surface_normal"]

	var back = wall_normal
	var right = surface_normal.cross(back).normalized()
	var up = back.cross(right).normalized()

	var target_basis = Basis(right, up, back)
	var correct_offset = target_basis * ledge_grab_offset
	var final_pos = target_pos + correct_offset

	if _snap_tween:
		_snap_tween.kill()

	_snap_tween = create_tween().set_parallel(true)
	_snap_tween.tween_property(player, "global_position", final_pos, 0.1).set_trans(Tween.TRANS_SINE)

	var target_quat = target_basis.get_rotation_quaternion()
	_snap_tween.tween_property(player.skin_mesh, "quaternion", target_quat, 0.1).set_trans(Tween.TRANS_SINE)



func _perform_wall_jump() -> void :
	var wall_normal: Vector3 = _ledge_data["normal"]
	var jump_dir = (Vector3.UP * 1.5 + wall_normal).normalized()
	player.velocity = jump_dir * WALL_JUMP_FORCE
	transition_requested.emit("PlayerAirState")


func _climb_up() -> void :
	var wall_normal: Vector3 = _ledge_data["normal"]

	player.velocity = Vector3.UP * HOP_FORCE + ( - wall_normal * CLIMB_FORWARD_FORCE)
	transition_requested.emit("PlayerAirState")


func _get_input_dir_relative_to_wall() -> Vector3:
	player._calculate_wish_direction()
	var wish_dir = player.wish_direction

	var wall_normal: Vector3 = _ledge_data["normal"]
	var wall_forward = - wall_normal
	var wall_right = wall_forward.cross(Vector3.UP)

	var dot_fwd = wish_dir.dot(wall_forward)
	var dot_right = wish_dir.dot(wall_right)

	return Vector3(dot_right, 0, - dot_fwd)


func check_ledge() -> Dictionary:
	var exclude: Array[RID] = [player.get_rid()]
	var forward_dir: Vector3 = - player.skin_mesh.global_transform.basis.z

	var forward_start: Vector3 = player.global_position + Vector3.UP * ledge_detect_height_offset
	var forward_hit: Dictionary = CasterFeature.raycast(
		forward_start, forward_dir, ledge_detect_length, exclude
	)

	if forward_hit.is_empty():
		return {}

	var above_start: Vector3 = (
		player.global_position + Vector3.UP * (ledge_detect_height_offset + ledge_max_height)
	)
	var above_hit: Dictionary = CasterFeature.raycast(
		above_start, forward_dir, ledge_detect_length, exclude
	)

	if not above_hit.is_empty():
		return {}

	var down_start: Vector3 = (
		forward_hit.position + (forward_dir * 0.05) + Vector3.UP * ledge_max_height
	)
	var down_hit: Dictionary = CasterFeature.raycast(
		down_start, Vector3.DOWN, ledge_max_height * 2.0, exclude
	)

	if down_hit.is_empty():
		return {}

	if down_hit.normal.angle_to(Vector3.UP) > deg_to_rad(max_ledge_slope):
		return {}

	var wall_normal = forward_hit.normal
	var surface_point = down_hit.position

	var dist = (surface_point - forward_hit.position).dot(wall_normal)
	var edge_point = surface_point - wall_normal * dist

	return {
		"position": edge_point, 
		"normal": forward_hit.normal, 
		"surface_normal": down_hit.normal, 
		"collider": down_hit.collider
	}
