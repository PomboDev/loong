class_name Player extends CharacterBody3D

var input: = InputManagerFeature

@onready var skin_mesh: Node3D = %SkinMesh
@onready var state_machine: StateMachine = %StateMachine
@onready var anim_tree: AnimationTree = %AnimationTree
@onready var jade: DragonPearl = %DragonPearl

@export var gravity_multiplier: float = 1.2
@export var movement_speed: float = 5.0
@export var acceleration: float = 20.0
@export var friction: float = 40.0
@export var jump_velocity: float = 6.0
@export var max_jump_count: int = 1
@export var max_dive_count: int = 2
@export var jump_buffer_time: float = 0.2
@export var dive_buffer_time: float = 0.1
@export var rotation_speed: float = 10.0
@export var safe_spot_interval: float = 0.5
@export var void_threshold: float = -10.0

var safe_position: Vector3 = Vector3.ZERO
var safe_spot_check_cooldown: float = 0.0

var last_wall_normal: Vector3 = Vector3.ZERO
var wish_direction: Vector3 = Vector3.ZERO
var jump_buffer_timer: Clock = Clock.new(jump_buffer_time)
var dive_buffer_timer: Clock = Clock.new(dive_buffer_time)
var input_magnitude: float = 0.0
var lock_rotation: bool = false


func _ready() -> void :
	Context.player = self
	safe_position = global_position
	CameraManagerFeature.initialize_with_target(self)


func _process(_delta: float) -> void :
	pass


func _physics_process(delta: float) -> void :
	if InputManagerFeature.was_pressed(&"jump"):
		jump_buffer_timer.run()

	if InputManagerFeature.was_pressed(&"interact"):
		dive_buffer_timer.run()

	_calculate_wish_direction()
	move_and_slide()
	_handle_rotation(delta)

	_check_safe_spot(delta)
	_check_void_fall()


func apply_gravity(delta: float, gravity_scale: float = 1.0) -> void :
	velocity += get_gravity() * gravity_multiplier * gravity_scale * delta


func _calculate_wish_direction() -> void :
	var move_input: Vector2 = InputManagerFeature.move_vector
	input_magnitude = clampf(move_input.length(), 0.0, 1.0)
	if move_input.is_zero_approx():
		wish_direction = Vector3.ZERO
		return

	var cam: Camera3D = Context.camera_node
	if not cam:
		wish_direction = Vector3(move_input.x, 0.0, move_input.y).normalized()
		return

	var cam_xform: Transform3D = cam.global_transform
	var forward: = - cam_xform.basis.z
	var right: = cam_xform.basis.x

	forward.y = 0.0
	right.y = 0.0
	wish_direction = (
		(forward.normalized() * - move_input.y + right.normalized() * move_input.x).normalized()
	)


func _handle_rotation(delta: float) -> void :
	if lock_rotation:
		return

	if wish_direction.length() > 0.01:
		var target_angle: float = atan2(wish_direction.x, wish_direction.z)
		skin_mesh.rotation.y = lerp_angle(
			skin_mesh.rotation.y, target_angle, rotation_speed * delta
		)


func snap_rotation(direction: Vector3) -> void :
	if direction.length() > 0.01:
		skin_mesh.rotation.y = atan2(direction.x, direction.z)


func _check_safe_spot(delta: float) -> void :
	safe_spot_check_cooldown += delta
	if safe_spot_check_cooldown < safe_spot_interval:
		return

	if not is_on_floor():
		return

	var result: Dictionary = CasterFeature.raycast(global_position + Vector3.UP, Vector3.DOWN, 2.0)
	if not result.is_empty():
		if result.normal.angle_to(Vector3.UP) < floor_max_angle:
			safe_position = global_position
			safe_spot_check_cooldown = 0.0


func _check_void_fall() -> void :
	if global_position.y < void_threshold:
		teleport_to_safe_spot()


func teleport_to_safe_spot() -> void :
	global_position = safe_position
	velocity = Vector3.ZERO
