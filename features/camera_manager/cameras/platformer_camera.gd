class_name PlatformerCamera extends BaseCamera3D

@export var enable_smoothing: bool = false
@export var smooth_speed: float = 30.0

@export var target_distance: float = 2.8
@export var min_distance: float = 2.0
@export var max_distance: float = 10.0
@export var height_offset: float = 1.0

@export var look_sensitivity: Vector2 = Vector2(1.0, 1.0)

@export var collision_radius: float = 0.35
@export_flags_3d_physics var collision_mask: int = 1
@export var collision_offset: float = 0.2

var _current_pitch: float = 0.0
var _current_yaw: float = 0.0
var _pivot_pos: Vector3
var _actual_distance: float = 3.2
var _sphere_shape: SphereShape3D

func _ready() -> void :
	_sphere_shape = SphereShape3D.new()
	_sphere_shape.radius = collision_radius
	_actual_distance = target_distance
	_current_pitch = deg_to_rad(10.0)

func _unhandled_input(event: InputEvent) -> void :
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_distance = clamp(target_distance - 0.5, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_distance = clamp(target_distance + 0.5, min_distance, max_distance)

func activate() -> void :
	if player:
		_pivot_pos = player.global_position + Vector3(0, height_offset, 0)

		var cam_rot = camera_node.global_transform.basis.get_euler()
		_current_yaw = cam_rot.y
		_current_pitch = cam_rot.x

		_actual_distance = target_distance

func deactivate() -> void :
	pass

func update_camera(delta: float) -> void :
	if not player or not camera_node:
		return

	_process_rotation_input(delta)
	_update_pivot(delta)
	_solve_collision()
	_apply_transform()

func _process_rotation_input(_delta: float) -> void :
	var look_delta = InputManagerFeature.get_look_delta()

	if look_delta.length_squared() > 0:
		_current_yaw -= look_delta.x
		_current_pitch -= look_delta.y

	_current_pitch = clamp(_current_pitch, deg_to_rad(-50.0), deg_to_rad(75.0))

func _update_pivot(delta: float) -> void :
	var target_head = player.global_position + Vector3(0, height_offset, 0)
	if enable_smoothing:
		_pivot_pos = _pivot_pos.lerp(target_head, smooth_speed * delta)
	else:
		_pivot_pos = target_head

func _solve_collision() -> void :
	var rot_basis = Basis(Vector3.UP, _current_yaw) * Basis(Vector3.RIGHT, _current_pitch)
	var backward_dir = rot_basis.z

	var origin = _pivot_pos
	var cast_vec = backward_dir * target_distance

	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = _sphere_shape
	query.transform = Transform3D(Basis(), origin)
	query.motion = cast_vec
	query.collision_mask = collision_mask

	if player:
		query.exclude = [player.get_rid()]

	var space_state = get_world_3d().direct_space_state
	var result = space_state.cast_motion(query)

	if result:
		var safe_fraction = result[0]
		var collision_dist = (target_distance * safe_fraction) - collision_offset
		_actual_distance = max(0.2, collision_dist)
	else:
		_actual_distance = target_distance

func _apply_transform() -> void :
	var rot_basis = Basis(Vector3.UP, _current_yaw) * Basis(Vector3.RIGHT, _current_pitch)
	var final_pos = _pivot_pos + (rot_basis.z * _actual_distance)

	camera_node.global_position = final_pos
	camera_node.look_at(_pivot_pos)
