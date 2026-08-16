class_name PlayerHomingAttackState extends PlayerState

@export var windup_duration: float = 0.01
@export var homing_speed: float = 15.0
@export var max_homing_time: float = 1.0
@export var arrival_threshold: float = 1.2
@export var bounce_velocity: float = 6.0
@export var miss_cooldown: float = 2.0

@export var homing_height_bias: float = 0.5
@export var waviness_frequency: float = 0.25
@export var waviness_amplitude: float = 0.25

@export var scan_angle: float = 5.0
@export var scan_distance: float = 10.0
@export var scan_sphere_radius: float = 1.0

var _homing_hit_targets: Array[Node3D] = []
var _timer: float = 0.0
var _target: Node3D = null

var _p0: Vector3
var _p1: Vector3
var _p2: Vector3
var _p3: Vector3

var _wave_axis: Vector3 = Vector3.ZERO
var _wave_side_flip: float = 1.0
var _current_waviness_amplitude: float = 0.0
var _wave_freq_term: float = 0.0
var _arrival_sq: float = 0.0

var _total_duration: float = 0.0
var _is_winding_up: bool = true
var _cooldown_timer: Clock = Clock.new()


func is_on_cooldown() -> bool:
	return _cooldown_timer.is_running()


func enter() -> void :
	_timer = 0.0
	_is_winding_up = true
	_wave_side_flip *= -1.0
	_arrival_sq = arrival_threshold * arrival_threshold
	_wave_freq_term = waviness_frequency * TAU

	if not is_instance_valid(_target):
		transition_requested.emit("PlayerAirState")
		return

	var dive_dir: = player.wish_direction
	if dive_dir.length() < 0.1:
		dive_dir = player.skin_mesh.global_transform.basis.z

	player.snap_rotation(dive_dir)

	_p0 = player.global_position
	var target_pos: Vector3 = _target.global_position
	_p3 = target_pos

	var to_target: Vector3 = _p3 - _p0
	var distance: float = to_target.length()
	var direction: Vector3 = to_target.normalized()

	_total_duration = distance / homing_speed
	_current_waviness_amplitude = min(waviness_amplitude, distance * 0.25)

	if direction.y > 0.5:
		_p1 = _p0 + (direction + Vector3.UP).normalized() * homing_height_bias
	else:
		_p1 = _p0 + (Vector3.UP * homing_height_bias)

	var approach_bias: float = homing_height_bias * 0.5
	_p2 = _p3 + (Vector3.UP * approach_bias)

	var forward_flat: Vector3 = Vector3(direction.x, 0, direction.z).normalized()
	if forward_flat.length_squared() < 0.01:
		forward_flat = Vector3.FORWARD

	_wave_axis = forward_flat.cross(Vector3.UP).normalized() * _wave_side_flip
	if _wave_axis.length_squared() < 0.01:
		_wave_axis = Vector3.RIGHT * _wave_side_flip

	player.velocity = Vector3.ZERO
	set_anim_condition(ANIM_C_DIVE, true)
	player.lock_rotation = true

func exit() -> void :
	_target = null
	set_anim_condition(ANIM_C_DIVE, false)
	player.lock_rotation = false


func update(_delta: float) -> void :
	pass


func physics_update(delta: float) -> void :
	_timer += delta

	if not is_instance_valid(_target):
		_miss()
		return

	if _is_winding_up:
		if _timer >= windup_duration:
			_is_winding_up = false
			_timer = 0.0
		return

	if _timer >= max_homing_time:
		_miss()
		return

	var p_pos: Vector3 = player.global_position
	_p3 = _target.global_position

	if p_pos.distance_squared_to(_p3) <= _arrival_sq or _timer >= _total_duration:
		_hit()
		return

	var t: float = _timer / _total_duration
	if t > 1.0:
		t = 1.0

	var desired_pos: Vector3 = _p0.bezier_interpolate(_p1, _p2, _p3, t)

	var taper: float = 1.0 - t
	var wave_offset: Vector3 = (
		_wave_axis * sin(t * _wave_freq_term) * _current_waviness_amplitude * taper
	)

	player.velocity = ((desired_pos + wave_offset) - p_pos) / delta


func reset() -> void :
	_homing_hit_targets.clear()


func set_target(target: Node3D) -> void :
	_target = target


func find_homing_target() -> Node3D:
	var camera: Camera3D = Context.camera_node
	if not camera:
		camera = get_viewport().get_camera_3d()
	if not camera:
		return null

	var cam_transform: Transform3D = camera.global_transform
	var origin: Vector3 = cam_transform.origin
	var forward: Vector3 = - cam_transform.basis.z

	var best_target: Node3D = null
	var best_score: float = - INF

	var right: Vector3 = cam_transform.basis.x
	var up: Vector3 = cam_transform.basis.y
	var angle_rad: float = deg_to_rad(scan_angle)

	var directions: Array[Vector3] = [
		forward, 
		forward.rotated(right, angle_rad), 
		forward.rotated(right, - angle_rad), 
		forward.rotated(up, angle_rad), 
		forward.rotated(up, - angle_rad)
	]

	var exclude: Array[RID] = [player.get_rid()]
	for t in _homing_hit_targets:
		if t is CollisionObject3D:
			exclude.append(t.get_rid())

	var evaluated_ids: Dictionary = {}

	for dir: Vector3 in directions:
		var motion: Vector3 = dir * scan_distance
		var results: Array[Dictionary] = CasterFeature.sweep_sphere(
			origin, scan_sphere_radius, motion, exclude, 1, false, true
		)

		for result: Dictionary in results:
			var collider: Node3D = result.get("collider") as Node3D
			if not collider:
				continue

			var target_node: Node3D = collider
			if not target_node.is_in_group("jade_target"):
				var p: Node = target_node.get_parent()
				if p and p.is_in_group("jade_target"):
					target_node = p as Node3D
				else:
					continue

			var t_id: int = target_node.get_instance_id()
			if evaluated_ids.has(t_id):
				continue
			evaluated_ids[t_id] = true

			if _homing_hit_targets.has(target_node):
				continue

			var t_pos: Vector3 = target_node.global_position
			var dist_sq: float = origin.distance_squared_to(t_pos)
			var to_target_vec: Vector3 = (t_pos - origin).normalized()
			var dot: float = forward.dot(to_target_vec)

			var score: float = dot * 100.0 - sqrt(dist_sq)

			if score > best_score:
				best_score = score
				best_target = target_node

	return best_target


func _hit() -> void :
	_homing_hit_targets.append(_target)
	var x_offset: float = -0.5 if _wave_side_flip < 0.0 else 0.5
	player.velocity = (Vector3.UP * bounce_velocity) + (Vector3(x_offset, 0, 2.0) * _wave_side_flip)
	set_anim_condition(ANIM_C_HOP, true)
	transition_requested.emit("PlayerAirState")
	await get_tree().create_timer(0.5).timeout
	set_anim_condition(ANIM_C_HOP, false)


func _miss() -> void :
	if player.velocity.y > 0.0:
		player.velocity.y = 0.0
	_cooldown_timer.run()
	transition_requested.emit("PlayerAirState")
